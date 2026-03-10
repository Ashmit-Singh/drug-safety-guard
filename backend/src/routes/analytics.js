const express = require('express');
const { z } = require('zod');
const { authGuard, supabase } = require('../middleware/auth');
const { rbacGuard } = require('../middleware/rbac');

const router = express.Router();

// GET /api/v1/analytics/top-interactions — Top 10 most common interaction pairs
router.get('/top-interactions', authGuard, async (req, res, next) => {
    try {
        const days = z.coerce.number().int().min(1).max(365).default(30).parse(req.query.days);
        const since = new Date();
        since.setDate(since.getDate() - days);

        // Query interaction_alerts with simple columns
        const { data: alerts, error } = await supabase
            .from('interaction_alerts')
            .select('interaction_id, severity, clinical_effect, drug_a_id, drug_b_id, ingredient_a_id, ingredient_b_id')
            .gte('created_at', since.toISOString())
            .is('deleted_at', null)
            .order('created_at', { ascending: false })
            .limit(200);

        if (error) throw error;

        if (!alerts || alerts.length === 0) {
            return res.json({ data: [] });
        }

        // Aggregate by interaction_id
        const pairCounts = {};
        for (const alert of alerts) {
            const key = alert.interaction_id || `${alert.drug_a_id}-${alert.drug_b_id}`;
            if (!pairCounts[key]) {
                pairCounts[key] = {
                    interactionId: key,
                    severity: alert.severity,
                    clinicalEffect: alert.clinical_effect,
                    count: 0,
                };
            }
            pairCounts[key].count++;
        }

        const topPairs = Object.values(pairCounts)
            .sort((a, b) => b.count - a.count)
            .slice(0, 10);

        res.json({ data: topPairs });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/analytics/alert-trends — Alert volume over time
router.get('/alert-trends', authGuard, async (req, res, next) => {
    try {
        const days = z.coerce.number().int().min(7).max(90).default(30).parse(req.query.days);
        const since = new Date();
        since.setDate(since.getDate() - days);

        const { data: alerts, error } = await supabase
            .from('interaction_alerts')
            .select('id, severity, created_at')
            .gte('created_at', since.toISOString())
            .is('deleted_at', null)
            .order('created_at', { ascending: true });

        if (error) throw error;

        // Aggregate by date
        const dailyCounts = {};
        for (const alert of (alerts || [])) {
            const date = alert.created_at.split('T')[0];
            if (!dailyCounts[date]) {
                dailyCounts[date] = { date, total: 0, mild: 0, moderate: 0, severe: 0, contraindicated: 0 };
            }
            dailyCounts[date].total++;
            dailyCounts[date][alert.severity]++;
        }

        const trend = Object.values(dailyCounts).sort((a, b) => a.date.localeCompare(b.date));

        res.json({ data: trend });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/analytics/severity-distribution — Severity breakdown
router.get('/severity-distribution', authGuard, async (req, res, next) => {
    try {
        const { data: alerts, error } = await supabase
            .from('interaction_alerts')
            .select('severity')
            .is('deleted_at', null);

        if (error) throw error;

        const distribution = { mild: 0, moderate: 0, severe: 0, contraindicated: 0 };
        for (const alert of (alerts || [])) {
            distribution[alert.severity]++;
        }

        const total = Object.values(distribution).reduce((a, b) => a + b, 0);
        const data = Object.entries(distribution).map(([severity, count]) => ({
            severity,
            count,
            percentage: total > 0 ? Math.round((count / total) * 100 * 10) / 10 : 0,
        }));

        res.json({ data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/analytics/dashboard-stats — Dashboard summary statistics
router.get('/dashboard-stats', authGuard, async (req, res, next) => {
    try {
        const today = new Date().toISOString().split('T')[0];

        // Individual try-catch to prevent one failing query from crashing all stats
        let totalPrescriptions = 0, activePatients = 0, alertsToday = 0, severeAlerts = 0;

        try {
            const r = await supabase.from('prescriptions').select('id', { count: 'exact', head: true }).is('deleted_at', null);
            totalPrescriptions = r.count || 0;
        } catch (_) {}

        try {
            const r = await supabase.from('patients').select('id', { count: 'exact', head: true }).is('deleted_at', null);
            activePatients = r.count || 0;
        } catch (_) {}

        try {
            const r = await supabase.from('interaction_alerts').select('id', { count: 'exact', head: true })
                .gte('created_at', `${today}T00:00:00`)
                .is('deleted_at', null);
            alertsToday = r.count || 0;
        } catch (_) {}

        try {
            const r = await supabase.from('interaction_alerts').select('id', { count: 'exact', head: true })
                .in('severity', ['severe', 'contraindicated'])
                .eq('status', 'active')
                .is('deleted_at', null);
            severeAlerts = r.count || 0;
        } catch (_) {}

        res.json({
            data: { totalPrescriptions, activePatients, alertsToday, severeAlerts },
        });
    } catch (err) {
        // Fallback: return zeros instead of crashing
        res.json({
            data: { totalPrescriptions: 0, activePatients: 0, alertsToday: 0, severeAlerts: 0 },
        });
    }
});

module.exports = router;
