/**
 * V1 Route Registry
 * All v1 routes use the Controller → Service → Repository pattern.
 * Validation is handled by validate() middleware (no inline .parse()).
 * Sanitization is applied to text fields that could contain XSS.
 */
const express = require('express');
const { authGuard } = require('../../middleware/auth');
const { rbacGuard } = require('../../middleware/rbac');
const { validate } = require('../../middleware/validate');
const { sanitize } = require('../../middleware/sanitize');
const schemas = require('../../validators/schemas');
const { interactionCheckLimiter } = require('../../middleware/rateLimiter');

// Controllers
const prescriptionCtrl = require('../../controllers/prescriptionController');
const alertCtrl = require('../../controllers/alertController');
const drugCtrl = require('../../controllers/drugController');
const patientCtrl = require('../../controllers/patientController');

const router = express.Router();

// ─── Prescriptions ─────────────────────────────────────
router.post('/prescriptions',
    authGuard, rbacGuard('doctor', 'admin'),
    validate(schemas.createPrescription),
    sanitize(['diagnosis', 'notes']),
    prescriptionCtrl.create
);

router.get('/prescriptions/:id',
    authGuard, rbacGuard('patient', 'doctor', 'admin'),
    validate(schemas.uuidParam, 'params'),
    prescriptionCtrl.getById
);

router.post('/prescriptions/:id/drugs',
    authGuard, rbacGuard('doctor', 'admin'),
    validate(schemas.addDrug),
    sanitize(['instructions']),
    prescriptionCtrl.addDrug
);

router.delete('/prescriptions/:id/drugs/:drugId',
    authGuard, rbacGuard('doctor', 'admin'),
    prescriptionCtrl.removeDrug
);

router.get('/prescriptions/:id/safety-check',
    authGuard, rbacGuard('patient', 'doctor', 'admin'),
    prescriptionCtrl.safetyCheck
);

// ─── Alerts ────────────────────────────────────────────
// IMPORTANT: /batch-acknowledge MUST be before /:id routes
router.post('/alerts/batch-acknowledge',
    authGuard, rbacGuard('doctor', 'admin'),
    validate(schemas.batchAcknowledge),
    alertCtrl.batchAcknowledge
);

router.get('/alerts',
    authGuard, rbacGuard('doctor', 'admin'),
    validate(schemas.alertFilters, 'query'),
    alertCtrl.list
);

router.get('/alerts/:id',
    authGuard, rbacGuard('patient', 'doctor', 'admin'),
    alertCtrl.getById
);

router.post('/alerts/:id/acknowledge',
    authGuard, rbacGuard('doctor', 'admin'),
    validate(schemas.acknowledgeAlert),
    alertCtrl.acknowledge
);

router.get('/alerts/patient/:patientId',
    authGuard, rbacGuard('patient', 'doctor', 'admin'),
    validate(schemas.paginationQuery, 'query'),
    alertCtrl.getPatientAlerts
);

// ─── Drugs ─────────────────────────────────────────────
router.get('/drugs',
    authGuard,
    validate(schemas.paginationQuery, 'query'),
    drugCtrl.list
);

router.get('/drugs/search',
    authGuard,
    validate(schemas.drugSearch, 'query'),
    drugCtrl.search
);

router.get('/drugs/:id',
    authGuard,
    drugCtrl.getById
);

router.get('/drugs/:id/ingredients',
    authGuard,
    drugCtrl.getIngredients
);

// ─── Ingredients ───────────────────────────────────────
router.get('/ingredients',
    authGuard,
    validate(schemas.paginationQuery, 'query'),
    drugCtrl.listIngredients
);

router.get('/ingredients/search',
    authGuard,
    validate(schemas.drugSearch, 'query'),
    drugCtrl.searchIngredients
);

router.get('/ingredients/:id',
    authGuard,
    drugCtrl.getIngredient
);

router.get('/ingredients/:id/interactions',
    authGuard,
    drugCtrl.getIngredientInteractions
);

// ─── Patients ──────────────────────────────────────────
router.get('/patients',
    authGuard, rbacGuard('doctor', 'admin'),
    validate(schemas.paginationQuery, 'query'),
    patientCtrl.list
);

router.get('/patients/:id',
    authGuard, rbacGuard('patient', 'doctor', 'admin'),
    patientCtrl.getById
);

router.post('/patients',
    authGuard, rbacGuard('doctor', 'admin'),
    validate(schemas.createPatient),
    sanitize(['firstName', 'lastName']),
    patientCtrl.create
);

router.get('/patients/:id/prescriptions',
    authGuard, rbacGuard('patient', 'doctor', 'admin'),
    validate(schemas.paginationQuery, 'query'),
    patientCtrl.getPrescriptions
);

// ─── Interactions ──────────────────────────────────────
const { detectInteractions } = require('../../services/interactionEngine');
const { sendSuccess } = require('../../utils/response');

router.post('/interactions/check',
    authGuard, interactionCheckLimiter,
    validate(schemas.interactionCheck),
    async (req, res, next) => {
        try {
            const interactions = await detectInteractions(req.validated.drugIds);
            sendSuccess(res, { interactions, count: interactions.length });
        } catch (err) {
            next(err);
        }
    }
);

// ─── Analytics (kept as legacy routes for now) ─────────
const analyticsRoutes = require('../analytics');
router.use('/analytics', analyticsRoutes);

// ─── Doctors (kept as legacy routes for now) ───────────
const doctorRoutes = require('../doctors');
router.use('/doctors', doctorRoutes);

module.exports = router;
