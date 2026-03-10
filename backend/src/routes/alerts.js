const express = require('express');
const { z } = require('zod');
const { authGuard, supabase } = require('../middleware/auth');
const { rbacGuard } = require('../middleware/rbac');
const { NotFoundError } = require('../middleware/errorHandler');

const router = express.Router();

const paginationSchema = z.object({
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
    severity: z.enum(['mild', 'moderate', 'severe', 'contraindicated']).optional(),
    status: z.enum(['active', 'acknowledged', 'overridden', 'resolved']).optional(),
});

// GET /api/v1/alerts — List all alerts (with filters)
router.get('/', authGuard, rbacGuard('doctor', 'admin'), async (req, res, next) => {
    try {
        const { limit, offset, severity, status } = paginationSchema.parse(req.query);

        let query = supabase
            .from('interaction_alerts')
            .select(`
                *,
                prescriptions (
                    id,
                    patients (id, first_name, last_name)
                ),
                drugs!interaction_alerts_drug_a_id_fkey (brand_name, generic_name),
                drugs!interaction_alerts_drug_b_id_fkey (brand_name, generic_name),
                ingredients!interaction_alerts_ingredient_a_id_fkey (name),
                ingredients!interaction_alerts_ingredient_b_id_fkey (name)
            `, { count: 'exact' })
            .is('deleted_at', null)
            .order('created_at', { ascending: false });

        if (severity) query = query.eq('severity', severity);
        if (status) query = query.eq('status', status);
        query = query.range(offset, offset + limit - 1);

        const { data, error, count } = await query;
        if (error) throw error;

        res.json({ data, pagination: { total: count, limit, offset } });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/alerts/:id — Get alert detail
router.get('/:id', authGuard, rbacGuard('patient', 'doctor', 'admin'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);

        const { data, error } = await supabase
            .from('interaction_alerts')
            .select(`
                *,
                prescriptions (
                    id, prescribed_at, status,
                    patients (id, first_name, last_name, date_of_birth),
                    doctors (id, first_name, last_name, specialization)
                ),
                drugs!interaction_alerts_drug_a_id_fkey (id, brand_name, generic_name, drug_class),
                drugs!interaction_alerts_drug_b_id_fkey (id, brand_name, generic_name, drug_class),
                ingredients!interaction_alerts_ingredient_a_id_fkey (id, name, cas_number),
                ingredients!interaction_alerts_ingredient_b_id_fkey (id, name, cas_number),
                ingredient_interactions (severity, clinical_effect, mechanism, recommendation, evidence_level)
            `)
            .eq('id', id)
            .is('deleted_at', null)
            .single();

        if (error || !data) throw new NotFoundError('Alert not found');
        res.json({ data });
    } catch (err) {
        next(err);
    }
});

// POST /api/v1/alerts/batch-acknowledge — Batch acknowledge alerts
// IMPORTANT: This route MUST be defined before /:id routes to prevent
// Express matching "batch-acknowledge" as a UUID parameter.
router.post('/batch-acknowledge', authGuard, rbacGuard('doctor', 'admin'), async (req, res, next) => {
    try {
        const body = z.object({
            alertIds: z.array(z.string().uuid()).min(1).max(50),
            overrideReason: z.string().max(500).optional(),
        }).parse(req.body);

        const { data, error } = await supabase
            .from('interaction_alerts')
            .update({
                status: 'acknowledged',
                acknowledged_by: req.user.id,
                acknowledged_at: new Date().toISOString(),
                override_reason: body.overrideReason || null,
            })
            .in('id', body.alertIds)
            .eq('status', 'active')
            .is('deleted_at', null)
            .select();

        if (error) throw error;
        res.json({ message: `${(data || []).length} alerts acknowledged`, data });
    } catch (err) {
        next(err);
    }
});

// POST /api/v1/alerts/:id/acknowledge — Acknowledge an alert
router.post('/:id/acknowledge', authGuard, rbacGuard('doctor', 'admin'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);
        const overrideReason = z.string().max(500).optional().parse(req.body.overrideReason);

        const { data, error } = await supabase
            .from('interaction_alerts')
            .update({
                status: 'acknowledged',
                acknowledged_by: req.user.id,
                acknowledged_at: new Date().toISOString(),
                override_reason: overrideReason || null,
            })
            .eq('id', id)
            .eq('status', 'active')
            .is('deleted_at', null)
            .select()
            .single();

        if (error || !data) throw new NotFoundError('Active alert not found');

        // Log audit event
        await supabase.from('audit_log').insert({
            user_id: req.user.id,
            action: 'ALERT_ACKNOWLEDGED',
            table_name: 'interaction_alerts',
            record_id: id,
            new_values: {
                status: 'acknowledged',
                override_reason: overrideReason,
            },
        });

        res.json({ message: 'Alert acknowledged', data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/alerts/patient/:patientId — Get alerts for a patient
router.get('/patient/:patientId', authGuard, rbacGuard('patient', 'doctor', 'admin'), async (req, res, next) => {
    try {
        const patientId = z.string().uuid().parse(req.params.patientId);
        const { limit, offset } = paginationSchema.parse(req.query);

        // Get prescriptions for this patient
        const { data: prescriptions } = await supabase
            .from('prescriptions')
            .select('id')
            .eq('patient_id', patientId)
            .is('deleted_at', null);

        const prescriptionIds = (prescriptions || []).map(p => p.id);
        if (prescriptionIds.length === 0) {
            return res.json({ data: [], pagination: { total: 0, limit, offset } });
        }

        const { data, error, count } = await supabase
            .from('interaction_alerts')
            .select(`
                *,
                drugs!interaction_alerts_drug_a_id_fkey (brand_name),
                drugs!interaction_alerts_drug_b_id_fkey (brand_name),
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
