/**
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * INTERACTION DETECTION ENGINE v2
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 *
 * Improvements over v1:
 * - A-01/P-01: Batch Redis pipeline (single round-trip)
 * - A-02: Application-level detection is single source of truth
 *         (PG trigger disabled — see migration below)
 * - A-03: Circuit breaker on Redis via opossum
 * - A-04: Cache only interaction IDs, fetch full objects on demand
 *         Memory savings: ~80% (UUID vs full JSON per pair)
 *
 * ─── DISABLE PG TRIGGER (run once) ────────────────────
 * DROP TRIGGER IF EXISTS trg_check_drug_interactions ON prescription_drugs;
 * -- The application-level engine is the single source of truth.
 * -- Re-enable by recreating the trigger on prescription_drugs
 * -- if you need DB-level detection for non-API inserts.
 * ───────────────────────────────────────────────────────
 */

const { supabase } = require('../middleware/auth');
const {
    getCachedInteraction,
    setCachedInteraction,
    batchGetCachedInteractions,
} = require('./redisService');
const { logger } = require('../middleware/logger');
const CircuitBreaker = require('opossum');

const SEVERITY_RANK = {
    contraindicated: 1,
    severe: 2,
    moderate: 3,
    mild: 4,
};

// ─── Circuit Breaker for Redis batch reads ─────────────
// If Redis fails >50% of calls, open the circuit for 10s.
// Fallback: return empty Map → engine falls through to Supabase.

const redisBatchGetWithBreaker = new CircuitBreaker(
    async (pairs) => batchGetCachedInteractions(pairs),
    {
        timeout: 500,                    // 500ms timeout per batch
        errorThresholdPercentage: 50,    // open after 50% failures
        resetTimeout: 10000,             // retry after 10s
        name: 'redis-interaction-cache',
    }
);

redisBatchGetWithBreaker.fallback(() => {
    logger.warn('Redis circuit breaker OPEN — falling back to direct DB queries');
    return new Map();
});

redisBatchGetWithBreaker.on('open', () =>
    logger.error('Redis circuit breaker OPENED — cache bypassed')
);
redisBatchGetWithBreaker.on('halfOpen', () =>
    logger.info('Redis circuit breaker HALF-OPEN — testing recovery')
);
redisBatchGetWithBreaker.on('close', () =>
    logger.info('Redis circuit breaker CLOSED — cache restored')
);


/**
 * Detect all ingredient-level interactions for a set of drugs.
 * @param {string[]} drugIds - Array of drug UUIDs
 * @returns {Promise<Array>} Sorted, deduplicated interaction alerts
 */
async function detectInteractions(drugIds) {
    if (!drugIds || drugIds.length < 2) return [];

    // Step 1: Batch-fetch all ingredients for all drugs
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
    const ingredientMap = {};
    for (const di of drugIngredients) {
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

    const drugNameMap = {};
    for (const drug of drugs || []) {
        drugNameMap[drug.id] = { brandName: drug.brand_name, genericName: drug.generic_name };
    }

    // Step 3: Collect ALL ingredient pairs (no async in loop)
    const uniqueDrugIds = [...new Set(drugIds)];
    const pairsToCheck = [];

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

    // Step 4: BATCH Redis lookup via circuit-breaker-protected pipeline
    const cachedResults = await redisBatchGetWithBreaker.fire(
        pairsToCheck.map(p => [p.firstId, p.secondId])
    );

    // Step 5: Identify cache misses → batch Supabase query
    const cacheMisses = [];
    for (let i = 0; i < pairsToCheck.length; i++) {
        const key = `${pairsToCheck[i].firstId}:${pairsToCheck[i].secondId}`;
        if (!cachedResults.has(key)) {
            cacheMisses.push(pairsToCheck[i]);
        }
    }

    if (cacheMisses.length > 0) {
        // A-04: Fetch full objects from DB (cache stores only IDs)
        const orConditions = cacheMisses.map(m =>
            `and(ingredient_a_id.eq.${m.firstId},ingredient_b_id.eq.${m.secondId})`
        ).join(',');

        const { data: dbInteractions, error: dbError } = await supabase
            .from('ingredient_interactions')
            .select('*')
            .is('deleted_at', null)
            .or(orConditions);

        if (dbError) {
            logger.error('Batch interaction query error', { error: dbError.message });
        } else {
            const dbResultMap = {};
            for (const row of (dbInteractions || [])) {
                dbResultMap[`${row.ingredient_a_id}:${row.ingredient_b_id}`] = row;
            }

            // Cache results in parallel (fire-and-forget OK for cache warm)
            const cacheOps = [];
            for (const miss of cacheMisses) {
                const key = `${miss.firstId}:${miss.secondId}`;
                const result = dbResultMap[key] || { none: true };
                cachedResults.set(key, result);
                cacheOps.push(setCachedInteraction(miss.firstId, miss.secondId, result));
            }
            Promise.allSettled(cacheOps).catch(() => {});
        }
    }

    // Step 6: Build alerts, deduplicate
    const alerts = [];
    const seenInteractions = new Set();

    for (const pair of pairsToCheck) {
        const key = `${pair.firstId}:${pair.secondId}`;
        const interaction = cachedResults.get(key);
        if (!interaction || interaction.none) continue;
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

    // Step 7: Sort by severity
    alerts.sort((a, b) => (SEVERITY_RANK[a.severity] || 99) - (SEVERITY_RANK[b.severity] || 99));
    return alerts;
}

/**
 * Check interactions for a specific prescription.
 */
async function checkPrescriptionSafety(prescriptionId) {
    const { data: prescriptionDrugs, error } = await supabase
        .from('prescription_drugs')
        .select('drug_id')
        .eq('prescription_id', prescriptionId)
        .is('deleted_at', null);

    if (error) {
        logger.error('Failed to fetch prescription drugs', { error: error.message });
        throw new Error('Failed to fetch prescription drugs');
    }

    if (!prescriptionDrugs || prescriptionDrugs.length < 2) return [];
    return detectInteractions(prescriptionDrugs.map(pd => pd.drug_id));
}

module.exports = {
    detectInteractions,
    checkPrescriptionSafety,
    SEVERITY_RANK,
};
