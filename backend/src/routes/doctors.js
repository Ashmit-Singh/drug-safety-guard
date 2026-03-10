const express = require('express');
const { z } = require('zod');
const { authGuard, supabase } = require('../middleware/auth');
const { rbacGuard } = require('../middleware/rbac');
const { NotFoundError } = require('../middleware/errorHandler');

const router = express.Router();

const createDoctorSchema = z.object({
    firstName: z.string().min(1).max(100),
    lastName: z.string().min(1).max(100),
    specialization: z.string().min(1).max(200),
    licenseNumber: z.string().min(1).max(100),
    hospitalId: z.string().uuid().optional(),
    department: z.string().max(200).optional(),
});

const paginationSchema = z.object({
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
});

// POST /api/v1/doctors — Create doctor (admin only)
router.post('/', authGuard, rbacGuard('admin'), async (req, res, next) => {
    try {
        const body = createDoctorSchema.parse(req.body);

        const { data, error } = await supabase
            .from('doctors')
            .insert({
                first_name: body.firstName,
                last_name: body.lastName,
                specialization: body.specialization,
                license_number: body.licenseNumber,
                hospital_id: body.hospitalId,
                department: body.department,
            })
            .select()
            .single();

        if (error) throw error;
        res.status(201).json({ data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/doctors — List doctors
router.get('/', authGuard, rbacGuard('patient', 'doctor', 'admin'), async (req, res, next) => {
    try {
        const { limit, offset } = paginationSchema.parse(req.query);

        const { data, error, count } = await supabase
            .from('doctors')
            .select('*', { count: 'exact' })
            .is('deleted_at', null)
            .eq('is_active', true)
            .order('last_name', { ascending: true })
            .range(offset, offset + limit - 1);

        if (error) throw error;
        res.json({ data, pagination: { total: count, limit, offset } });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/doctors/:id — Get doctor by ID
router.get('/:id', authGuard, rbacGuard('patient', 'doctor', 'admin'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);

        const { data, error } = await supabase
            .from('doctors')
            .select('*')
            .eq('id', id)
            .is('deleted_at', null)
            .single();

        if (error || !data) throw new NotFoundError('Doctor not found');
        res.json({ data });
    } catch (err) {
        next(err);
    }
});

module.exports = router;
