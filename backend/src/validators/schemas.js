/**
 * Centralized Zod schemas for all API endpoints.
 * Used by the validate() middleware — never called inline in routes.
 */
const { z } = require('zod');

// ─── Common ────────────────────────────────────────────
const uuidParam = z.object({
    id: z.string().uuid(),
});

const paginationQuery = z.object({
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
});

const cursorPaginationQuery = z.object({
    limit: z.coerce.number().int().min(1).max(100).default(20),
    cursor: z.string().datetime().optional(), // ISO8601 cursor for keyset pagination
});

// ─── Prescriptions ─────────────────────────────────────
const createPrescription = z.object({
    patientId: z.string().uuid(),
    doctorId: z.string().uuid(),
    diagnosis: z.string().max(1000).optional(),
    notes: z.string().max(2000).optional(),
    validUntil: z.string().datetime().optional(),
});

const addDrug = z.object({
    drugId: z.string().uuid(),
    dosage: z.string().min(1).max(100),
    frequency: z.string().min(1).max(100),
    duration: z.string().max(100).optional(),
    instructions: z.string().max(500).optional(),
});

// ─── Alerts ────────────────────────────────────────────
const alertFilters = z.object({
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
    severity: z.enum(['mild', 'moderate', 'severe', 'contraindicated']).optional(),
    status: z.enum(['active', 'acknowledged', 'overridden', 'resolved']).optional(),
});

const acknowledgeAlert = z.object({
    overrideReason: z.string().max(500).optional(),
});

const batchAcknowledge = z.object({
    alertIds: z.array(z.string().uuid()).min(1).max(50),
    overrideReason: z.string().max(500).optional(),
});

// ─── Patients ──────────────────────────────────────────
const createPatient = z.object({
    firstName: z.string().min(1).max(100),
    lastName: z.string().min(1).max(100),
    dateOfBirth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    gender: z.enum(['Male', 'Female', 'Other']),
    bloodType: z.enum(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']).optional(),
    allergies: z.array(z.string().max(100)).max(100).optional(),
    medicalConditions: z.array(z.string().max(200)).max(50).optional(),
});

// ─── Drugs ─────────────────────────────────────────────
const drugSearch = z.object({
    q: z.string().min(1).max(200),
});

// ─── Interactions ──────────────────────────────────────
const interactionCheck = z.object({
    drugIds: z.array(z.string().uuid()).min(2).max(20),
});

// ─── Doctors ───────────────────────────────────────────
const createDoctor = z.object({
    firstName: z.string().min(1).max(100),
    lastName: z.string().min(1).max(100),
    specialization: z.string().max(200).optional(),
    licenseNumber: z.string().max(50),
    department: z.string().max(200).optional(),
});

module.exports = {
    uuidParam,
    paginationQuery,
    cursorPaginationQuery,
    createPrescription,
    addDrug,
    alertFilters,
    acknowledgeAlert,
    batchAcknowledge,
    createPatient,
    drugSearch,
    interactionCheck,
    createDoctor,
};
