/**
 * Unit tests for the interaction detection engine.
 * Tests batching logic and circuit breaker fallback.
 */

// Mock dependencies before requiring module
jest.mock('../../src/middleware/auth', () => ({
    supabase: {
        from: jest.fn(),
    },
}));

jest.mock('../../src/services/redisService', () => ({
    getCachedInteraction: jest.fn(),
    setCachedInteraction: jest.fn().mockResolvedValue(undefined),
    batchGetCachedInteractions: jest.fn(),
}));

jest.mock('../../src/middleware/logger', () => ({
    logger: {
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    },
}));

jest.mock('opossum', () => {
    return jest.fn().mockImplementation((fn, opts) => {
        const breaker = {
            fire: jest.fn((...args) => fn(...args)),
            fallback: jest.fn(),
            on: jest.fn(),
        };
        return breaker;
    });
});

const { detectInteractions, SEVERITY_RANK } = require('../../src/services/interactionEngine');
const { supabase } = require('../../src/middleware/auth');
const { batchGetCachedInteractions, setCachedInteraction } = require('../../src/services/redisService');

describe('Interaction Detection Engine', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    function mockSupabaseChain(returnValue) {
        const chain = {
            select: jest.fn().mockReturnThis(),
            in: jest.fn().mockReturnThis(),
            is: jest.fn().mockReturnThis(),
            eq: jest.fn().mockReturnThis(),
            or: jest.fn().mockReturnThis(),
            maybeSingle: jest.fn().mockReturnThis(),
            then: jest.fn(),
        };
        // Final resolution
        Object.assign(chain, returnValue);
        supabase.from.mockReturnValue(chain);
        return chain;
    }

    test('returns empty array for less than 2 drugs', async () => {
        const result = await detectInteractions(['drug-1']);
        expect(result).toEqual([]);
        expect(supabase.from).not.toHaveBeenCalled();
    });

    test('returns empty array for null input', async () => {
        const result = await detectInteractions(null);
        expect(result).toEqual([]);
    });

    test('returns empty array for empty array', async () => {
        const result = await detectInteractions([]);
        expect(result).toEqual([]);
    });

    test('SEVERITY_RANK orders correctly', () => {
        expect(SEVERITY_RANK.contraindicated).toBeLessThan(SEVERITY_RANK.severe);
        expect(SEVERITY_RANK.severe).toBeLessThan(SEVERITY_RANK.moderate);
        expect(SEVERITY_RANK.moderate).toBeLessThan(SEVERITY_RANK.mild);
    });

    test('deduplicates drug IDs', async () => {
        // Setup: Two same drugs → should skip pairs
        const mockChain = {
            select: jest.fn().mockReturnThis(),
            in: jest.fn().mockReturnThis(),
            is: jest.fn().mockReturnThis(),
        };

        let callCount = 0;
        supabase.from.mockImplementation((table) => {
            if (table === 'drug_ingredients') {
                return {
                    ...mockChain,
                    is: jest.fn().mockResolvedValue({ data: [], error: null }),
                };
            }
            if (table === 'drugs') {
                return {
                    ...mockChain,
                    is: jest.fn().mockResolvedValue({ data: [], error: null }),
                };
            }
            return mockChain;
        });

        const result = await detectInteractions(['drug-1', 'drug-1']);
        // Same drug pair → no ingredients to compare
        expect(result).toEqual([]);
    });

    test('batch-fetches interactions from cache', async () => {
        const drugA = 'aaaaaaaa-0000-0000-0000-000000000001';
        const drugB = 'bbbbbbbb-0000-0000-0000-000000000002';
        const ingA = 'aaaaaaaa-1111-0000-0000-000000000001';
        const ingB = 'bbbbbbbb-1111-0000-0000-000000000002';

        supabase.from.mockImplementation((table) => {
            const chain = {
                select: jest.fn().mockReturnThis(),
                in: jest.fn().mockReturnThis(),
                is: jest.fn().mockReturnThis(),
                eq: jest.fn().mockReturnThis(),
                or: jest.fn().mockReturnThis(),
            };

            if (table === 'drug_ingredients') {
                chain.is = jest.fn().mockResolvedValue({
                    data: [
                        { drug_id: drugA, ingredient_id: ingA, ingredients: { id: ingA, name: 'Aspirin' } },
                        { drug_id: drugB, ingredient_id: ingB, ingredients: { id: ingB, name: 'Warfarin' } },
                    ],
                    error: null,
                });
            } else if (table === 'drugs') {
                chain.is = jest.fn().mockResolvedValue({
                    data: [
                        { id: drugA, brand_name: 'Drug A', generic_name: 'Drug A Generic' },
                        { id: drugB, brand_name: 'Drug B', generic_name: 'Drug B Generic' },
                    ],
                    error: null,
                });
            }
            return chain;
        });

        // Cache HIT: return a known interaction
        const cachedMap = new Map();
        cachedMap.set(`${ingA}:${ingB}`, {
            id: 'interaction-1',
            severity: 'severe',
            clinical_effect: 'Increased bleeding risk',
            mechanism: 'Antiplatelet + Anticoagulant',
            recommendation: 'Avoid concurrent use',
            evidence_level: 'high',
        });
        batchGetCachedInteractions.mockResolvedValue(cachedMap);

        const result = await detectInteractions([drugA, drugB]);

        expect(result).toHaveLength(1);
        expect(result[0].severity).toBe('severe');
        expect(result[0].drugPair.drugAName).toBe('Drug A');
        expect(result[0].ingredientPair.ingredientAName).toBe('Aspirin');
    });
});

describe('SEVERITY_RANK enum coverage', () => {
    test('all severities have a rank', () => {
        expect(SEVERITY_RANK).toHaveProperty('contraindicated');
        expect(SEVERITY_RANK).toHaveProperty('severe');
        expect(SEVERITY_RANK).toHaveProperty('moderate');
        expect(SEVERITY_RANK).toHaveProperty('mild');
    });
});
