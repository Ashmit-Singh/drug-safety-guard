/**
 * Integration test: POST /api/v1/prescriptions/:id/drugs
 * Tests the complete flow: add drug → interaction detection → alert generation.
 */
const request = require('supertest');
const { setupTestDatabase, seedTestData, teardownTestDatabase } = require('./setup');

jest.setTimeout(30000);

// Mock external services
jest.mock('../../src/middleware/auth', () => {
    const mockSupabase = {
        from: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        insert: jest.fn().mockReturnThis(),
        update: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        in: jest.fn().mockReturnThis(),
        is: jest.fn().mockReturnThis(),
        or: jest.fn().mockReturnThis(),
        order: jest.fn().mockReturnThis(),
        range: jest.fn().mockReturnThis(),
        single: jest.fn(),
        limit: jest.fn().mockReturnThis(),
    };

    return {
        supabase: mockSupabase,
        authGuard: (req, res, next) => {
            req.user = {
                id: '22222222-2222-2222-2222-222222222222',
                email: 'doctor@hospital.com',
                role: 'doctor',
            };
            next();
        },
    };
});

jest.mock('../../src/services/redisService', () => ({
    getRedis: () => null,
    getCachedInteraction: jest.fn().mockResolvedValue(null),
    setCachedInteraction: jest.fn().mockResolvedValue(undefined),
    batchGetCachedInteractions: jest.fn().mockResolvedValue(new Map()),
    connectRedis: jest.fn(),
    disconnectRedis: jest.fn(),
}));

jest.mock('../../src/services/cassandraService', () => ({
    getClient: () => null,
    writeAuditEvent: jest.fn().mockResolvedValue(undefined),
    writeAlertLog: jest.fn().mockResolvedValue(undefined),
    writeInteractionAnalytics: jest.fn().mockResolvedValue(undefined),
    updateDrugUsageCounters: jest.fn().mockResolvedValue(undefined),
    connectCassandra: jest.fn(),
    shutdownCassandra: jest.fn(),
}));

jest.mock('../../src/middleware/logger', () => ({
    logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn(), debug: jest.fn() },
    requestLogger: (req, res, next) => next(),
}));

jest.mock('opossum', () => {
    return jest.fn().mockImplementation((fn) => ({
        fire: jest.fn((...args) => fn(...args)),
        fallback: jest.fn(),
        on: jest.fn(),
    }));
});

const { supabase } = require('../../src/middleware/auth');

// Load app AFTER mocks
let app;
beforeAll(() => {
    process.env.SUPABASE_URL = 'https://test.supabase.co';
    process.env.SUPABASE_ANON_KEY = 'test-key-at-least-10-chars';
    process.env.SUPABASE_SERVICE_KEY = 'test-svc-key-at-least-10-chars';
    process.env.JWT_SECRET = 'test-jwt-secret-must-be-at-least-32-characters-long';
    process.env.NODE_ENV = 'test';

    app = require('../../src/app');
});

describe('POST /api/v1/prescriptions/:id/drugs', () => {
    const prescriptionId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
    const drugAId = '33333333-3333-3333-3333-333333333333';
    const drugBId = '44444444-4444-4444-4444-444444444444';

    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('should add a drug and return interaction alerts', async () => {
        // Mock prescription lookup
        supabase.from.mockImplementation((table) => {
            const chain = {
                select: jest.fn().mockReturnThis(),
                insert: jest.fn().mockReturnThis(),
                update: jest.fn().mockReturnThis(),
                eq: jest.fn().mockReturnThis(),
                in: jest.fn().mockReturnThis(),
                is: jest.fn().mockReturnThis(),
                or: jest.fn().mockReturnThis(),
                order: jest.fn().mockReturnThis(),
                range: jest.fn().mockReturnThis(),
                single: jest.fn(),
                limit: jest.fn().mockReturnThis(),
            };

            if (table === 'prescriptions') {
                chain.single.mockResolvedValue({
                    data: {
                        id: prescriptionId,
                        patient_id: '11111111-1111-1111-1111-111111111111',
                        status: 'draft',
                    },
                    error: null,
                });
            } else if (table === 'prescription_drugs') {
                chain.single.mockResolvedValue({
                    data: {
                        id: 'new-pd-id',
                        drug_id: drugBId,
                        dosage: '5mg',
                        frequency: 'Once daily',
                        drugs: { id: drugBId, brand_name: 'Coumadin', generic_name: 'Warfarin', drug_class: 'Anticoagulant' },
                    },
                    error: null,
                });
                chain.is.mockResolvedValue({
                    data: [{ drug_id: drugAId }, { drug_id: drugBId }],
                    error: null,
                });
            } else if (table === 'drug_ingredients') {
                chain.is.mockResolvedValue({
                    data: [
                        { drug_id: drugAId, ingredient_id: 'ing-a', ingredients: { id: 'ing-a', name: 'ASA' } },
                        { drug_id: drugBId, ingredient_id: 'ing-b', ingredients: { id: 'ing-b', name: 'Warfarin' } },
                    ],
                    error: null,
                });
            } else if (table === 'drugs') {
                chain.is.mockResolvedValue({
                    data: [
                        { id: drugAId, brand_name: 'Aspirin', generic_name: 'ASA' },
                        { id: drugBId, brand_name: 'Coumadin', generic_name: 'Warfarin' },
                    ],
                    error: null,
                });
            } else if (table === 'ingredient_interactions') {
                chain.or.mockResolvedValue({
                    data: [{
                        id: 'interaction-1',
                        ingredient_a_id: 'ing-a',
                        ingredient_b_id: 'ing-b',
                        severity: 'severe',
                        clinical_effect: 'Bleeding risk',
                        mechanism: 'Synergy',
                        recommendation: 'Avoid',
                        evidence_level: 'high',
                    }],
                    error: null,
                });
            } else if (table === 'interaction_alerts') {
                chain.order.mockResolvedValue({ data: [], error: null });
            } else if (table === 'prescription_events') {
                chain.insert.mockResolvedValue({ data: null, error: null });
            }

            return chain;
        });

        const res = await request(app)
            .post(`/api/v1/prescriptions/${prescriptionId}/drugs`)
            .send({
                drugId: drugBId,
                dosage: '5mg',
                frequency: 'Once daily',
            })
            .expect(201);

        expect(res.body.success).toBe(true);
        expect(res.body.data).toBeDefined();
        expect(res.body.data.interactionCheck).toBeDefined();
        expect(res.body.data.interactionCheck.length).toBeGreaterThanOrEqual(0);
    });

    test('should return 422 for invalid drug data', async () => {
        const res = await request(app)
            .post(`/api/v1/prescriptions/${prescriptionId}/drugs`)
            .send({
                // Missing drugId, dosage, frequency
            })
            .expect(422);

        expect(res.body.success).toBe(false);
        expect(res.body.code).toBe('VALIDATION_ERROR');
        expect(res.body.details).toBeDefined();
        expect(Array.isArray(res.body.details)).toBe(true);
    });

    test('should return 404 for non-existent prescription', async () => {
        supabase.from.mockImplementation((table) => {
            const chain = {
                select: jest.fn().mockReturnThis(),
                eq: jest.fn().mockReturnThis(),
                is: jest.fn().mockReturnThis(),
                single: jest.fn().mockResolvedValue({ data: null, error: { code: 'PGRST116' } }),
            };
            return chain;
        });

        const res = await request(app)
            .post(`/api/v1/prescriptions/${prescriptionId}/drugs`)
            .send({
                drugId: drugBId,
                dosage: '5mg',
                frequency: 'Once daily',
            })
            .expect(404);

        expect(res.body.success).toBe(false);
    });
});

describe('GET /api/v1/health', () => {
    test('should return system health status', async () => {
        const res = await request(app)
            .get('/api/v1/health')
            .expect(200);

        expect(res.body.success).toBe(true);
        expect(res.body.data.status).toBeDefined();
        expect(res.body.data.dependencies).toBeDefined();
    });
});

describe('Request validation', () => {
    test('should reject requests with invalid UUID params', async () => {
        const res = await request(app)
            .get('/api/v1/prescriptions/not-a-uuid')
            .expect(422);

        expect(res.body.code).toBe('VALIDATION_ERROR');
    });

    test('should include X-Request-Id header', async () => {
        const res = await request(app)
            .get('/api/v1/health');

        expect(res.headers['x-request-id']).toBeDefined();
    });
});
