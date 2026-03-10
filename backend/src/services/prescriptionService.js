/**
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * PRESCRIPTION SERVICE — Business logic layer
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * Orchestrates the prescription workflow:
 * - Creating prescriptions
 * - Adding drugs (with interaction detection)
 * - Removing drugs (with re-check)
 * - Safety checks
 * 
 * All audit writes go through auditService (reliable queue).
 */
const prescriptionRepo = require('../repositories/prescriptionRepo');
const { detectInteractions, checkPrescriptionSafety } = require('./interactionEngine');
const { logDrugUsage } = require('./auditService');
const { NotFoundError } = require('../middleware/errorHandler');

async function createPrescription(body, user) {
    const prescription = await prescriptionRepo.create(body);

    // Log event
    await prescriptionRepo.insertEvent(
        prescription.id,
        'created',
        { created_by: user.id },
        user.id
    );

    return prescription;
}

async function getPrescription(id) {
    const prescription = await prescriptionRepo.findById(id);
    if (!prescription) throw new NotFoundError('Prescription not found');
    return prescription;
}

/**
 * Add a drug to a prescription and run interaction detection.
 * This is the CORE safety flow:
 * 1. Verify prescription exists & is in draft
 * 2. Insert the drug
 * 3. Fetch all drugs on this prescription
 * 4. Run interaction engine
 * 5. Fetch any DB-persisted alerts
 * 6. Log events + analytics
 */
async function addDrug(prescriptionId, drugData, user) {
    // 1. Verify prescription
    const prescription = await prescriptionRepo.findById(prescriptionId);
    if (!prescription) throw new NotFoundError('Prescription not found');

    // 2. Insert drug
    const prescriptionDrug = await prescriptionRepo.addDrug(prescriptionId, drugData);

    // 3. Get all drug IDs on this prescription
    const drugIds = await prescriptionRepo.getDrugIds(prescriptionId);

    // 4. Run interaction detection (application-level, single source of truth)
    const interactions = await detectInteractions(drugIds);

    // 5. Get DB-persisted alerts (from trigger, if still enabled)
    const alerts = await prescriptionRepo.getAlerts(prescriptionId);

    // 6. Log prescription event
    await prescriptionRepo.insertEvent(
        prescriptionId,
        'drug_added',
        {
            drug_id: drugData.drugId,
            added_by: user.id,
            interactions_found: interactions.length,
        },
        user.id
    );

    // 7. Async: Update analytics (reliable, not fire-and-forget)
    logDrugUsage({
        drugId: drugData.drugId,
        drugName: prescriptionDrug.drugs?.brand_name,
        drugClass: prescriptionDrug.drugs?.drug_class,
    });

    return {
        prescriptionDrug,
        alerts,
        interactionCheck: interactions,
    };
}

async function removeDrug(prescriptionId, drugId, user) {
    const removed = await prescriptionRepo.removeDrug(prescriptionId, drugId);
    if (!removed) throw new NotFoundError('Prescription drug not found');

    // Log event
    await prescriptionRepo.insertEvent(
        prescriptionId,
        'drug_removed',
        { drug_id: drugId, removed_by: user.id },
        user.id
    );

    return removed;
}

async function safetyCheck(prescriptionId) {
    const interactions = await checkPrescriptionSafety(prescriptionId);
    const storedAlerts = await prescriptionRepo.getAlerts(prescriptionId);

    const isSafe = interactions.length === 0;
    const hasCritical = interactions.some(i =>
        i.severity === 'contraindicated' || i.severity === 'severe'
    );

    return {
        prescriptionId,
        isSafe,
        hasCriticalAlerts: hasCritical,
        alertCount: interactions.length,
        interactions,
        storedAlerts,
    };
}

module.exports = {
    createPrescription,
    getPrescription,
    addDrug,
    removeDrug,
    safetyCheck,
};
