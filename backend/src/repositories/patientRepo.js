/**
 * PATIENT REPOSITORY — Data access for patients table.
 */
const { supabase } = require('../middleware/auth');

async function findAll({ limit = 20, offset = 0 } = {}) {
    const { data, error, count } = await supabase
        .from('patients')
        .select('id, first_name, last_name, date_of_birth, gender, blood_type, created_at', { count: 'exact' })
        .is('deleted_at', null)
        .order('last_name', { ascending: true })
        .range(offset, offset + limit - 1);

    if (error) throw error;
    return { data: data || [], total: count };
}

async function findById(id) {
    const { data, error } = await supabase
        .from('patients')
        .select('*')
        .eq('id', id)
        .is('deleted_at', null)
        .single();

    if (error) return null;
    return data;
}

async function create({ firstName, lastName, dateOfBirth, gender, bloodType, allergies, medicalConditions }) {
    const { data, error } = await supabase
        .from('patients')
        .insert({
            first_name: firstName,
            last_name: lastName,
            date_of_birth: dateOfBirth,
            gender,
            blood_type: bloodType,
            allergies,
            medical_conditions: medicalConditions,
        })
        .select()
        .single();

    if (error) throw error;
    return data;
}

async function getPrescriptionIds(patientId) {
    const { data } = await supabase
        .from('prescriptions')
        .select('id')
        .eq('patient_id', patientId)
        .is('deleted_at', null);

    return (data || []).map(p => p.id);
}

module.exports = { findAll, findById, create, getPrescriptionIds };
