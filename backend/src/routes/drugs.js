const express = require('express');
const { z } = require('zod');
const { authGuard, supabase } = require('../middleware/auth');
const { rbacGuard } = require('../middleware/rbac');
const { NotFoundError } = require('../middleware/errorHandler');

const router = express.Router();

const paginationSchema = z.object({
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
});

// GET /api/v1/drugs — List drugs
router.get('/', authGuard, rbacGuard('patient', 'doctor', 'admin', 'pharmacist'), async (req, res, next) => {
    try {
        const { limit, offset } = paginationSchema.parse(req.query);

        const { data, error, count } = await supabase
            .from('drugs')
            .select('*', { count: 'exact' })
            .is('deleted_at', null)
            .eq('is_active', true)
            .order('brand_name', { ascending: true })
            .range(offset, offset + limit - 1);

        if (error) throw error;
        res.json({ data, pagination: { total: count, limit, offset } });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/drugs/search?q= — Search drugs by name
router.get('/search', authGuard, rbacGuard('patient', 'doctor', 'admin', 'pharmacist'), async (req, res, next) => {
    try {
        const q = z.string().min(1).max(100).parse(req.query.q);
        const { limit } = paginationSchema.parse(req.query);

        const { data, error } = await supabase
            .from('drugs')
            .select(`
                id, brand_name, generic_name, drug_class, 
                dosage_form, strength, manufacturer
            `)
            .is('deleted_at', null)
            .eq('is_active', true)
            .or(`brand_name.ilike.%${q}%,generic_name.ilike.%${q}%`)
            .order('brand_name', { ascending: true })
            .limit(limit);

        if (error) throw error;
        res.json({ data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/drugs/:id — Get drug by ID
router.get('/:id', authGuard, rbacGuard('patient', 'doctor', 'admin', 'pharmacist'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);

        const { data, error } = await supabase
            .from('drugs')
            .select('*')
            .eq('id', id)
            .is('deleted_at', null)
            .single();

        if (error || !data) throw new NotFoundError('Drug not found');
        res.json({ data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/drugs/:id/ingredients — Get drug's ingredients
router.get('/:id/ingredients', authGuard, rbacGuard('patient', 'doctor', 'admin', 'pharmacist'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);

        const { data, error } = await supabase
            .from('drug_ingredients')
            .select(`
                drug_id,
                ingredient_id,
                is_active_ingredient,
                concentration,
                unit,
                ingredients (id, name, cas_number, category, description)
            `)
            .eq('drug_id', id)
            .is('deleted_at', null);

        if (error) throw error;
        res.json({ data });
    } catch (err) {
        next(err);
    }
});

module.exports = router;
