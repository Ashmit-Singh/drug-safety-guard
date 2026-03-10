const express = require('express');
const { z } = require('zod');
const { authGuard } = require('../middleware/auth');
const { rbacGuard } = require('../middleware/rbac');
const { interactionCheckLimiter } = require('../middleware/rateLimiter');
const { detectInteractions } = require('../services/interactionEngine');

const router = express.Router();

// POST /api/v1/interactions/check — Ad-hoc interaction check (no prescription required)
router.post('/check',
    authGuard,
    rbacGuard('doctor', 'admin', 'pharmacist'),
    interactionCheckLimiter,
    async (req, res, next) => {
        try {
            const body = z.object({
                drugIds: z.array(z.string().uuid()).min(2).max(20),
            }).parse(req.body);

            const interactions = await detectInteractions(body.drugIds);

            const isSafe = interactions.length === 0;
            const hasCritical = interactions.some(i =>
                i.severity === 'contraindicated' || i.severity === 'severe'
            );

            res.json({
                data: {
                    isSafe,
                    hasCriticalAlerts: hasCritical,
                    drugCount: body.drugIds.length,
                    interactionCount: interactions.length,
                    interactions,
                },
            });
        } catch (err) {
            next(err);
        }
    }
);

module.exports = router;
