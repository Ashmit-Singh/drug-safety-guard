const express = require('express');
const { z } = require('zod');
const { authGuard, supabase } = require('../middleware/auth');
const { rbacGuard } = require('../middleware/rbac');

const router = express.Router();

const paginationSchema = z.object({
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
});

// GET /api/v1/ingredients — List ingredients
router.get('/', authGuard, rbacGuard('patient', 'doctor', 'admin', 'pharmacist'), async (req, res, next) => {
    try {
        const { limit, offset } = paginationSchema.parse(req.query);

        const { data, error, count } = await supabase
            .from('ingredients')
            .select('*', { count: 'exact' })
            .is('deleted_at', null)
            .order('name', { ascending: true })
            .range(offset, offset + limit - 1);

        if (error) throw error;
        res.json({ data, pagination: { total: count, limit, offset } });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/ingredients/search?q= — Search ingredients
router.get('/search', authGuard, rbacGuard('patient', 'doctor', 'admin', 'pharmacist'), async (req, res, next) => {
    try {
        const q = z.string().min(1).max(100).parse(req.query.q);
        const { limit } = paginationSchema.parse(req.query);

        const { data, error } = await supabase
            .from('ingredients')
            .select('id, name, cas_number, category')
            .is('deleted_at', null)
            .ilike('name', `%${q}%`)
            .order('name', { ascending: true })
            .limit(limit);

        if (error) throw error;
        res.json({ data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/ingredients/:id — Get ingredient by ID
router.get('/:id', authGuard, rbacGuard('patient', 'doctor', 'admin', 'pharmacist'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);

        const { data, error } = await supabase
            .from('ingredients')
            .select(`
                *,
                drug_ingredients (
                    drug_id,
                    drugs (id, brand_name, generic_name, drug_class)
                )
            `)
            .eq('id', id)
            .is('deleted_at', null)
            .single();

        if (error) throw error;
        res.json({ data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/ingredients/:id/interactions — Get ingredient interactions
router.get('/:id/interactions', authGuard, rbacGuard('doctor', 'admin', 'pharmacist'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);

        const { data: interactionsA } = await supabase
            .from('ingredient_interactions')
            .select(`
                *,
                ingredients!ingredient_interactions_ingredient_b_id_fkey (id, name)
            `)
            .eq('ingredient_a_id', id)
            .is('deleted_at', null);

        const { data: interactionsB } = await supabase
            .from('ingredient_interactions')
            .select(`
                *,
                ingredients!ingredient_interactions_ingredient_a_id_fkey (id, name)
            `)
            .eq('ingredient_b_id', id)
            .is('deleted_at', null);

        const interactions = [...(interactionsA || []), ...(interactionsB || [])];
        res.json({ data: interactions });
    } catch (err) {
        next(err);
    }
});

module.exports = router;
