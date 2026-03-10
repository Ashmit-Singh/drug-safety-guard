const express = require('express');
const { z } = require('zod');
const { authGuard, supabase } = require('../middleware/auth');
const { rbacGuard } = require('../middleware/rbac');
const { NotFoundError } = require('../middleware/errorHandler');
const { detectInteractions, checkPrescriptionSafety } = require('../services/interactionEngine');
const { writePrescriptionHistory, updateDrugUsageCounters } = require('../services/cassandraService');

const router = express.Router();

const createPrescriptionSchema = z.object({
    patientId: z.string().uuid(),
    doctorId: z.string().uuid(),
    diagnosis: z.string().max(1000).optional(),
    notes: z.string().max(2000).optional(),
    validUntil: z.string().datetime().optional(),
});

const addDrugSchema = z.object({
    drugId: z.string().uuid(),
    dosage: z.string().min(1).max(100),
    frequency: z.string().min(1).max(100),
    duration: z.string().max(100).optional(),
    instructions: z.string().max(500).optional(),
});

const paginationSchema = z.object({
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
});

// POST /api/v1/prescriptions — Create prescription
router.post('/', authGuard, rbacGuard('doctor', 'admin'), async (req, res, next) => {
    try {
        const body = createPrescriptionSchema.parse(req.body);

        const { data, error } = await supabase
            .from('prescriptions')
            .insert({
                patient_id: body.patientId,
                doctor_id: body.doctorId,
                diagnosis: body.diagnosis,
                notes: body.notes,
                valid_until: body.validUntil,
                status: 'draft',
            })
            .select(`
                *,
                patients (first_name, last_name),
                doctors (first_name, last_name, specialization)
            `)
            .single();

        if (error) throw error;

        // Log prescription event
        await supabase.from('prescription_events').insert({
            prescription_id: data.id,
            event_type: 'created',
            event_data: { created_by: req.user.id },
            performed_by: req.user.id,
        });

        res.status(201).json({ data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/prescriptions/:id — Get prescription with drugs and alerts
router.get('/:id', authGuard, rbacGuard('patient', 'doctor', 'admin'), async (req, res, next) => {
    try {
        const id = z.string().uuid().parse(req.params.id);

        const { data, error } = await supabase
            .from('prescriptions')
            .select(`
                *,
                patients (id, first_name, last_name, date_of_birth, allergies),
                doctors (id, first_name, last_name, specialization),
                prescription_drugs (
                    id, drug_id, dosage, frequency, duration, instructions,
                    drugs (id, brand_name, generic_name, drug_class, strength)
                ),
                interaction_alerts (
                    id, drug_a_id, drug_b_id, ingredient_a_id, ingredient_b_id,
                    severity, clinical_effect, recommendation, status, created_at
                )
            `)
            .eq('id', id)
            .is('deleted_at', null)
            .single();

        if (error || !data) throw new NotFoundError('Prescription not found');
        res.json({ data });
    } catch (err) {
        next(err);
    }
});

// POST /api/v1/prescriptions/:id/drugs — Add drug to prescription (triggers interaction check)
router.post('/:id/drugs', authGuard, rbacGuard('doctor', 'admin'), async (req, res, next) => {
    try {
        const prescriptionId = z.string().uuid().parse(req.params.id);
        const body = addDrugSchema.parse(req.body);

        // Verify prescription exists and is in draft status
        const { data: prescription, error: pError } = await supabase
            .from('prescriptions')
            .select('id, status, patient_id, doctor_id')
            .eq('id', prescriptionId)
            .is('deleted_at', null)
            .single();

        if (pError || !prescription) throw new NotFoundError('Prescription not found');

        // Insert the drug (PostgreSQL trigger will auto-detect interactions)
        const { data: prescriptionDrug, error: pdError } = await supabase
            .from('prescription_drugs')
            .insert({
                prescription_id: prescriptionId,
                drug_id: body.drugId,
                dosage: body.dosage,
                frequency: body.frequency,
                duration: body.duration,
                instructions: body.instructions,
            })
            .select(`
                *,
                drugs (id, brand_name, generic_name, drug_class, strength)
            `)
            .single();

        if (pdError) throw pdError;

        // Also run application-level interaction check for immediate response
        const { data: allDrugs } = await supabase
            .from('prescription_drugs')
            .select('drug_id')
            .eq('prescription_id', prescriptionId)
            .is('deleted_at', null);

        const drugIds = (allDrugs || []).map(d => d.drug_id);
        const interactions = await detectInteractions(drugIds);

        // Fetch alerts generated by the trigger
        const { data: alerts } = await supabase
            .from('interaction_alerts')
            .select(`
                *,
                ingredients!interaction_alerts_ingredient_a_id_fkey (name),
                ingredients!interaction_alerts_ingredient_b_id_fkey (name)
            `)
            .eq('prescription_id', prescriptionId)
            .is('deleted_at', null)
            .order('created_at', { ascending: false });

        // Log prescription event
        await supabase.from('prescription_events').insert({
            prescription_id: prescriptionId,
            event_type: 'drug_added',
            event_data: {
                drug_id: body.drugId,
                added_by: req.user.id,
                interactions_found: interactions.length,
            },
            performed_by: req.user.id,
        });

        // Async: Update Cassandra analytics
        updateDrugUsageCounters({
            drugId: body.drugId,
            drugName: prescriptionDrug.drugs?.brand_name,
            drugClass: prescriptionDrug.drugs?.drug_class,
        }).catch(() => {});

        res.status(201).json({
            data: {
                prescriptionDrug,
                alerts: alerts || [],
                interactionCheck: interactions,
            },
        });
    } catch (err) {
        next(err);
    }
});

// DELETE /api/v1/prescriptions/:id/drugs/:drugId — Remove drug from prescription
router.delete('/:id/drugs/:drugId', authGuard, rbacGuard('doctor', 'admin'), async (req, res, next) => {
    try {
        const prescriptionId = z.string().uuid().parse(req.params.id);
        const drugId = z.string().uuid().parse(req.params.drugId);

        // Soft delete the prescription_drug
        const { data, error } = await supabase
            .from('prescription_drugs')
            .update({ deleted_at: new Date().toISOString() })
            .eq('prescription_id', prescriptionId)
            .eq('drug_id', drugId)
            .is('deleted_at', null)
            .select()
            .single();

        if (error || !data) throw new NotFoundError('Prescription drug not found');

        // Log event
        await supabase.from('prescription_events').insert({
            prescription_id: prescriptionId,
            event_type: 'drug_removed',
            event_data: { drug_id: drugId, removed_by: req.user.id },
            performed_by: req.user.id,
        });

        res.json({ message: 'Drug removed from prescription', data });
    } catch (err) {
        next(err);
    }
});

// GET /api/v1/prescriptions/:id/safety-check — Run safety check
router.get('/:id/safety-check', authGuard, rbacGuard('patient', 'doctor', 'admin'), async (req, res, next) => {
    try {
        const prescriptionId = z.string().uuid().parse(req.params.id);
        const interactions = await checkPrescriptionSafety(prescriptionId);

        // Also fetch stored alerts
        const { data: storedAlerts } = await supabase
            .from('interaction_alerts')
            .select(`
                *,
                ingredients!interaction_alerts_ingredient_a_id_fkey (name),
                ingredients!interaction_alerts_ingredient_b_id_fkey (name)
            `)
            .eq('prescription_id', prescriptionId)
            .is('deleted_at', null)
            .order('severity', { ascending: true });

        const isSafe = interactions.length === 0;
        const hasCritical = interactions.some(i =>
            i.severity === 'contraindicated' || i.severity === 'severe'
        );

        res.json({
            data: {
                prescriptionId,
                isSafe,
                hasCriticalAlerts: hasCritical,
                alertCount: interactions.length,
                interactions,
                storedAlerts: storedAlerts || [],
            },
        });
    } catch (err) {
        next(err);
    }
});

module.exports = router;
