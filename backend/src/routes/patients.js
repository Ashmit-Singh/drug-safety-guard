const express = require('express');
const { z } = require('zod');
const { authGuard, supabase } = require('../middleware/auth');
const { rbacGuard } = require('../middleware/rbac');
const { NotFoundError } = require('../middleware/errorHandler');

const router = express.Router();

// Validation schemas
const createPatientSchema = z.object({
    firstName: z.string().min(1).max(100),
    lastName: z.string().min(1).max(100),
    dateOfBirth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    gender: z.string().max(20).optional(),
    bloodType: z.string().max(5).optional(),
    allergies: z.array(z.string()).optional(),
    medicalConditions: z.array(z.string()).optional(),
    emergencyContactName: z.string().max(200).optional(),
    emergencyContactPhone: z.string().max(20).optional(),
    insuranceId: z.string().max(100).optional(),
});

const paginationSchema = z.object({
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
});

// POST /api/v1/patients — Create patient
router.post('/', authGuard, rbacGuard('doctor', 'admin'), async (req, res, next) => {
    try {
        const body = createPatientSchema.parse(req.body);

        const { data, error } = await supabase
            .from('patients')
            .insert({
                first_name: body.firstName,
                last_name: body.lastName,
                date_of_birth: body.dateOfBirth,
                gender: body.gender,
                blood_type: body.bloodType,
                allergies: body.allergies,
                medical_conditions: body.medicalConditions,
                emergency_contact_name: body.emergencyContactName,
                emergency_contact_phone: body.emergencyContactPhone,
                insurance_id: body.insuranceId,
            })
            .select()
            .single();

        if (error) throw error;
        res.status(201).json({ data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/patients/:id — Get patient by ID
router.get('/:id', authGuard, rbacGuard('patient', 'doctor', 'admin'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);

        const { data, error } = await supabase
            .from('patients')
            .select('*')
            .eq('id', id)
            .is('deleted_at', null)
            .single();

        if (error || !data) throw new NotFoundError('Patient not found');
        res.json({ data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/patients/:id/prescriptions — Get patient's prescriptions
router.get('/:id/prescriptions', authGuard, rbacGuard('patient', 'doctor', 'admin'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);
        const { limit, offset } = paginationSchema.parse(req.query);

        const { data, error, count } = await supabase
            .from('prescriptions')
            .select(`
                *,
                doctors (first_name, last_name, specialization),
                prescription_drugs (
                    id, drug_id, dosage, frequency, duration,
                    drugs (brand_name, generic_name, drug_class)
                )
            `, { count: 'exact' })
            .eq('patient_id', id)
            .is('deleted_at', null)
            .order('prescribed_at', { ascending: false })
            .range(offset, offset + limit - 1);

        if (error) throw error;
        res.json({ data, pagination: { total: count, limit, offset } });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/patients/:id/alerts — Get patient's alerts
router.get('/:id/alerts', authGuard, rbacGuard('patient', 'doctor', 'admin'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);
        const { limit, offset } = paginationSchema.parse(req.query);

        // Get patient's prescription IDs first
        const { data: prescriptions } = await supabase
            .from('prescriptions')
            .select('id')
            .eq('patient_id', id)
            .is('deleted_at', null);

        const prescriptionIds = (prescriptions || []).map(p => p.id);

        if (prescriptionIds.length === 0) {
            return res.json({ data: [], pagination: { total: 0, limit, offset } });
        }

        const { data, error, count } = await supabase
            .from('interaction_alerts')
            .select(`
                *,
                drugs!interaction_alerts_drug_a_id_fkey (brand_name, generic_name),
                drugs!interaction_alerts_drug_b_id_fkey (brand_name, generic_name),
                ingredients!interaction_alerts_ingredient_a_id_fkey (name),
                ingredients!interaction_alerts_ingredient_b_id_fkey (name)
            `, { count: 'exact' })
            .in('prescription_id', prescriptionIds)
            .is('deleted_at', null)
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);

        if (error) throw error;
        res.json({ data, pagination: { total: count, limit, offset } });
    } catch (err) {
        next(err);
    }
});

module.exports = router;
