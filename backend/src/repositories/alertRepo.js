/**
 * ALERT REPOSITORY — Data access for interaction_alerts table.
 */
const { supabase } = require('../middleware/auth');

const ALERT_LIST_COLUMNS = `
    id, prescription_id, drug_a_id, drug_b_id,
    ingredient_a_id, ingredient_b_id, severity,
    clinical_effect, recommendation, status,
    acknowledged_by, acknowledged_at, override_reason,
    created_at,
    prescriptions (
        id,
        patients (id, first_name, last_name)
    ),
    drugs!drug_a_id (brand_name, generic_name),
    drugs!drug_b_id (brand_name, generic_name),
    ingredients!ingredient_a_id (name),
    ingredients!ingredient_b_id (name)
`;

const ALERT_DETAIL_COLUMNS = `
    *,
    prescriptions (
        id, prescribed_at, status,
        patients (id, first_name, last_name, date_of_birth),
        doctors (id, first_name, last_name, specialization)
    ),
    drugs!drug_a_id (id, brand_name, generic_name, drug_class),
    drugs!drug_b_id (id, brand_name, generic_name, drug_class),
    ingredients!ingredient_a_id (id, name, cas_number),
    ingredients!ingredient_b_id (id, name, cas_number),
    ingredient_interactions (severity, clinical_effect, mechanism, recommendation, evidence_level)
`;

async function findAll({ limit = 20, offset = 0, severity, status } = {}) {
    let query = supabase
        .from('interaction_alerts')
        .select(ALERT_LIST_COLUMNS, { count: 'exact' })
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

    if (severity) query = query.eq('severity', severity);
    if (status) query = query.eq('status', status);
    query = query.range(offset, offset + limit - 1);

    const { data, error, count } = await query;
    if (error) throw error;
    return { data: data || [], total: count };
}

async function findById(id) {
    const { data, error } = await supabase
        .from('interaction_alerts')
        .select(ALERT_DETAIL_COLUMNS)
        .eq('id', id)
        .is('deleted_at', null)
        .single();

    if (error) return null;
    return data;
}

async function acknowledge(id, userId, overrideReason) {
    const { data, error } = await supabase
        .from('interaction_alerts')
        .update({
            status: 'acknowledged',
            acknowledged_by: userId,
            acknowledged_at: new Date().toISOString(),
            override_reason: overrideReason || null,
        })
        .eq('id', id)
        .eq('status', 'active')
        .is('deleted_at', null)
        .select()
        .single();

    if (error) return null;
    return data;
}

async function batchAcknowledge(alertIds, userId, overrideReason) {
    const { data, error } = await supabase
        .from('interaction_alerts')
        .update({
            status: 'acknowledged',
            acknowledged_by: userId,
            acknowledged_at: new Date().toISOString(),
            override_reason: overrideReason || null,
        })
        .in('id', alertIds)
        .eq('status', 'active')
        .is('deleted_at', null)
        .select();

    if (error) throw error;
    return data || [];
}

async function findByPatientPrescriptions(prescriptionIds, { limit = 20, offset = 0 } = {}) {
    if (prescriptionIds.length === 0) return { data: [], total: 0 };

    const { data, error, count } = await supabase
        .from('interaction_alerts')
        .select(`
            id, prescription_id, severity, clinical_effect, recommendation,
            status, created_at,
            drugs!drug_a_id (brand_name),
            drugs!drug_b_id (brand_name),
            ingredients!ingredient_a_id (name),
            ingredients!ingredient_b_id (name)
        `, { count: 'exact' })
        .in('prescription_id', prescriptionIds)
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);

    if (error) throw error;
    return { data: data || [], total: count };
}

async function insertAuditLog(userId, action, tableName, recordId, newValues) {
    await supabase.from('audit_log').insert({
        user_id: userId,
        action,
        table_name: tableName,
        record_id: recordId,
        new_values: newValues,
    });
}

module.exports = {
    findAll,
    findById,
    acknowledge,
    batchAcknowledge,
    findByPatientPrescriptions,
    insertAuditLog,
};
