/**
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * PRESCRIPTION REPOSITORY
 * ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 * Pure data-access layer for prescriptions and prescription_drugs.
 * Zero business logic — just queries.
 */
const { supabase } = require('../middleware/auth');

const PRESCRIPTION_COLUMNS = `
    id, patient_id, doctor_id, diagnosis, notes, status,
    prescribed_at, valid_until, created_at, updated_at
`;

const PRESCRIPTION_FULL = `
    ${PRESCRIPTION_COLUMNS},
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
`;

async function create({ patientId, doctorId, diagnosis, notes, validUntil }) {
    const { data, error } = await supabase
        .from('prescriptions')
        .insert({
            patient_id: patientId,
            doctor_id: doctorId,
            diagnosis,
            notes,
            valid_until: validUntil,
            status: 'draft',
        })
        .select(`
            ${PRESCRIPTION_COLUMNS},
            patients (first_name, last_name),
            doctors (first_name, last_name, specialization)
        `)
        .single();

    if (error) throw error;
    return data;
}

async function findById(id) {
    const { data, error } = await supabase
        .from('prescriptions')
        .select(PRESCRIPTION_FULL)
        .eq('id', id)
        .is('deleted_at', null)
        .single();

    if (error) return null;
    return data;
}

async function findByPatientId(patientId, { limit = 20, offset = 0 } = {}) {
    const { data, error, count } = await supabase
        .from('prescriptions')
        .select(PRESCRIPTION_COLUMNS, { count: 'exact' })
        .eq('patient_id', patientId)
        .is('deleted_at', null)
        .order('prescribed_at', { ascending: false })
        .range(offset, offset + limit - 1);

    if (error) throw error;
    return { data: data || [], total: count };
}

async function addDrug(prescriptionId, { drugId, dosage, frequency, duration, instructions }) {
    const { data, error } = await supabase
        .from('prescription_drugs')
        .insert({
            prescription_id: prescriptionId,
            drug_id: drugId,
            dosage,
            frequency,
            duration,
            instructions,
        })
        .select(`
            *,
            drugs (id, brand_name, generic_name, drug_class, strength)
        `)
        .single();

    if (error) throw error;
    return data;
}

async function removeDrug(prescriptionId, drugId) {
    const { data, error } = await supabase
        .from('prescription_drugs')
        .update({ deleted_at: new Date().toISOString() })
        .eq('prescription_id', prescriptionId)
        .eq('drug_id', drugId)
        .is('deleted_at', null)
        .select()
        .single();

    if (error) return null;
    return data;
}

async function getDrugIds(prescriptionId) {
    const { data, error } = await supabase
        .from('prescription_drugs')
        .select('drug_id')
        .eq('prescription_id', prescriptionId)
        .is('deleted_at', null);

    if (error) throw error;
    return (data || []).map(d => d.drug_id);
}

async function getAlerts(prescriptionId) {
    const { data, error } = await supabase
        .from('interaction_alerts')
        .select(`
            id, drug_a_id, drug_b_id, ingredient_a_id, ingredient_b_id,
            severity, clinical_effect, recommendation, status, created_at,
            ingredients!ingredient_a_id (name),
            ingredients!ingredient_b_id (name)
        `)
        .eq('prescription_id', prescriptionId)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
}

async function insertEvent(prescriptionId, eventType, eventData, performedBy) {
    await supabase.from('prescription_events').insert({
        prescription_id: prescriptionId,
        event_type: eventType,
        event_data: eventData,
        performed_by: performedBy,
    });
}

module.exports = {
    create,
    findById,
    findByPatientId,
    addDrug,
    removeDrug,
    getDrugIds,
    getAlerts,
    insertEvent,
};
