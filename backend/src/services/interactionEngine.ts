/**
 * INTERACTION DETECTION ENGINE (TypeScript)
 * Application-level drug interaction detection with:
 * - Batch Redis pipeline (single RTT)
 * - Circuit breaker (opossum)
 * - Batch Supabase queries for cache misses
 */
import { supabase } from '../middleware/auth';
import { getCachedInteraction, setCachedInteraction, batchGetCachedInteractions } from './redisService';
import { logger } from '../middleware/logger';
import CircuitBreaker from 'opossum';
import {
    InteractionAlert,
    IngredientPairCheck,
    IngredientInteraction,
    SeverityLevel,
} from '../types';

const SEVERITY_RANK: Record<SeverityLevel, number> = {
    contraindicated: 1,
    severe: 2,
    moderate: 3,
    mild: 4,
};

interface DrugIngredientRow {
    drug_id: string;
    ingredient_id: string;
    ingredients: { id: string; name: string } | null;
}

interface DrugNameRow {
    id: string;
    brand_name: string;
    generic_name: string;
}

// Circuit breaker configuration
const redisBatchGetWithBreaker = new CircuitBreaker(
    async (pairs: [string, string][]): Promise<Map<string, IngredientInteraction | { none: true }>> => {
        return batchGetCachedInteractions(pairs);
    },
    {
        timeout: 500,
        errorThresholdPercentage: 50,
        resetTimeout: 10000,
        name: 'redis-interaction-cache',
    }
);

redisBatchGetWithBreaker.fallback((): Map<string, never> => {
    logger.warn('Redis circuit breaker OPEN — falling back to direct DB queries');
    return new Map();
});

redisBatchGetWithBreaker.on('open', () => logger.error('Redis circuit breaker OPENED'));
redisBatchGetWithBreaker.on('halfOpen', () => logger.info('Redis circuit breaker HALF-OPEN'));
redisBatchGetWithBreaker.on('close', () => logger.info('Redis circuit breaker CLOSED'));

/**
 * Detect all ingredient-level interactions for a set of drugs.
 */
export async function detectInteractions(drugIds: string[]): Promise<InteractionAlert[]> {
    if (!drugIds || drugIds.length < 2) return [];

    // Step 1: Batch-fetch ingredients
    const { data: drugIngredients, error: diError } = await supabase
        .from('drug_ingredients')
        .select('drug_id, ingredient_id, ingredients (id, name)')
        .in('drug_id', drugIds)
        .is('deleted_at', null);

    if (diError) {
        logger.error('Failed to fetch drug ingredients', { error: diError.message });
        throw new Error('Failed to fetch drug ingredients');
    }

    // Step 2: Build maps
    const ingredientMap: Record<string, { ingredientId: string; ingredientName: string }[]> = {};
    for (const di of (drugIngredients as DrugIngredientRow[]) || []) {
        if (!ingredientMap[di.drug_id]) ingredientMap[di.drug_id] = [];
        ingredientMap[di.drug_id].push({
            ingredientId: di.ingredient_id,
            ingredientName: di.ingredients?.name || 'Unknown',
        });
    }

    const { data: drugs } = await supabase
        .from('drugs')
        .select('id, brand_name, generic_name')
        .in('id', drugIds)
        .is('deleted_at', null);

    const drugNameMap: Record<string, { brandName: string; genericName: string }> = {};
    for (const drug of (drugs as DrugNameRow[]) || []) {
        drugNameMap[drug.id] = { brandName: drug.brand_name, genericName: drug.generic_name };
    }

    // Step 3: Collect ingredient pairs
    const uniqueDrugIds = [...new Set(drugIds)];
    const pairsToCheck: IngredientPairCheck[] = [];

    for (let i = 0; i < uniqueDrugIds.length; i++) {
        for (let j = i + 1; j < uniqueDrugIds.length; j++) {
            const drugAId = uniqueDrugIds[i];
            const drugBId = uniqueDrugIds[j];
            const ingredientsA = ingredientMap[drugAId] || [];
            const ingredientsB = ingredientMap[drugBId] || [];

            for (const ingA of ingredientsA) {
                for (const ingB of ingredientsB) {
                    if (ingA.ingredientId === ingB.ingredientId) continue;
                    const [firstId, secondId] = ingA.ingredientId < ingB.ingredientId
                        ? [ingA.ingredientId, ingB.ingredientId]
                        : [ingB.ingredientId, ingA.ingredientId];
                    const [firstName, secondName] = ingA.ingredientId < ingB.ingredientId
                        ? [ingA.ingredientName, ingB.ingredientName]
                        : [ingB.ingredientName, ingA.ingredientName];
                    pairsToCheck.push({ firstId, secondId, firstName, secondName, drugAId, drugBId });
                }
            }
        }
    }

    if (pairsToCheck.length === 0) return [];

    // Step 4: Batch Redis lookup
    const cachedResults = await redisBatchGetWithBreaker.fire(
        pairsToCheck.map((p) => [p.firstId, p.secondId] as [string, string])
    ) as Map<string, IngredientInteraction | { none: true }>;

    // Step 5: Fetch cache misses from DB
    const cacheMisses = pairsToCheck.filter((p) => {
        const key = `${p.firstId}:${p.secondId}`;
        return !cachedResults.has(key);
    });

    if (cacheMisses.length > 0) {
        const orConditions = cacheMisses
            .map((m) => `and(ingredient_a_id.eq.${m.firstId},ingredient_b_id.eq.${m.secondId})`)
            .join(',');

        const { data: dbInteractions, error: dbError } = await supabase
            .from('ingredient_interactions')
            .select('*')
            .is('deleted_at', null)
            .or(orConditions);

        if (!dbError) {
            const dbResultMap: Record<string, IngredientInteraction> = {};
            for (const row of (dbInteractions || []) as IngredientInteraction[]) {
                dbResultMap[`${row.ingredient_a_id}:${row.ingredient_b_id}`] = row;
            }

            const cacheOps: Promise<void>[] = [];
            for (const miss of cacheMisses) {
                const key = `${miss.firstId}:${miss.secondId}`;
                const result = dbResultMap[key] || { none: true as const };
                cachedResults.set(key, result as any);
                cacheOps.push(setCachedInteraction(miss.firstId, miss.secondId, result));
            }
            Promise.allSettled(cacheOps).catch(() => {});
        }
    }

    // Step 6: Build deduplicated alerts
    const alerts: InteractionAlert[] = [];
    const seenInteractions = new Set<string>();

    for (const pair of pairsToCheck) {
        const key = `${pair.firstId}:${pair.secondId}`;
        const interaction = cachedResults.get(key);
        if (!interaction || 'none' in interaction) continue;
        if (seenInteractions.has(interaction.id)) continue;
        seenInteractions.add(interaction.id);

        alerts.push({
            interactionId: interaction.id,
            drugPair: {
                drugAId: pair.drugAId,
                drugAName: drugNameMap[pair.drugAId]?.brandName || 'Unknown',
                drugAGeneric: drugNameMap[pair.drugAId]?.genericName || 'Unknown',
                drugBId: pair.drugBId,
                drugBName: drugNameMap[pair.drugBId]?.brandName || 'Unknown',
                drugBGeneric: drugNameMap[pair.drugBId]?.genericName || 'Unknown',
            },
            ingredientPair: {
                ingredientAId: pair.firstId,
                ingredientAName: pair.firstName,
                ingredientBId: pair.secondId,
                ingredientBName: pair.secondName,
            },
            severity: interaction.severity,
            clinicalEffect: interaction.clinical_effect,
            mechanism: interaction.mechanism,
            recommendation: interaction.recommendation,
            evidenceLevel: interaction.evidence_level,
        });
    }

    alerts.sort((a, b) => (SEVERITY_RANK[a.severity] || 99) - (SEVERITY_RANK[b.severity] || 99));
    return alerts;
}

export async function checkPrescriptionSafety(prescriptionId: string): Promise<InteractionAlert[]> {
    const { data: prescriptionDrugs, error } = await supabase
        .from('prescription_drugs')
        .select('drug_id')
        .eq('prescription_id', prescriptionId)
        .is('deleted_at', null);

    if (error) throw new Error('Failed to fetch prescription drugs');
    if (!prescriptionDrugs || prescriptionDrugs.length < 2) return [];

    return detectInteractions(prescriptionDrugs.map((pd: { drug_id: string }) => pd.drug_id));
}

export { SEVERITY_RANK };
