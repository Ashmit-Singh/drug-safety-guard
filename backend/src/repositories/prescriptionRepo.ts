/**
 * PRESCRIPTION REPOSITORY (TypeScript)
 * Pure data-access layer — zero business logic.
 */
import { supabase } from '../middleware/auth';
import {
    Prescription,
    PrescriptionDrug,
    Alert,
    CreatePrescriptionInput,
    AddDrugInput,
    PaginatedResult,
} from '../types';

const PRESCRIPTION_COLUMNS = `
    id, patient_id, doctor_id, diagnosis, notes, status,
    prescribed_at, valid_until, created_at, updated_at, deleted_at
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

export async function create(input: CreatePrescriptionInput): Promise<Prescription> {
    const { data, error } = await supabase
        .from('prescriptions')
        .insert({
            patient_id: input.patientId,
            doctor_id: input.doctorId,
            diagnosis: input.diagnosis,
            notes: input.notes,
            valid_until: input.validUntil,
            status: 'draft',
        })
        .select(`
            ${PRESCRIPTION_COLUMNS},
            patients (first_name, last_name),
            doctors (first_name, last_name, specialization)
        `)
        .single();

    if (error) throw error;
    return data as unknown as Prescription;
}

export async function findById(id: string): Promise<Prescription | null> {
    const { data, error } = await supabase
        .from('prescriptions')
        .select(PRESCRIPTION_FULL)
        .eq('id', id)
        .is('deleted_at', null)
        .single();

    if (error) return null;
    return data as unknown as Prescription;
}

export async function findByPatientId(
    patientId: string,
    { limit = 20, offset = 0 }: { limit?: number; offset?: number } = {}
): Promise<PaginatedResult<Prescription>> {
    const { data, error, count } = await supabase
        .from('prescriptions')
        .select(PRESCRIPTION_COLUMNS, { count: 'exact' })
        .eq('patient_id', patientId)
        .is('deleted_at', null)
        .order('prescribed_at', { ascending: false })
        .range(offset, offset + limit - 1);

    if (error) throw error;
    return { data: (data || []) as Prescription[], total: count ?? 0 };
}

export async function addDrug(
    prescriptionId: string,
    input: AddDrugInput
): Promise<PrescriptionDrug> {
    const { data, error } = await supabase
        .from('prescription_drugs')
        .insert({
            prescription_id: prescriptionId,
            drug_id: input.drugId,
            dosage: input.dosage,
            frequency: input.frequency,
            duration: input.duration,
            instructions: input.instructions,
        })
        .select('*, drugs (id, brand_name, generic_name, drug_class, strength)')
        .single();

    if (error) throw error;
    return data as PrescriptionDrug;
}

export async function removeDrug(
    prescriptionId: string,
    drugId: string
): Promise<PrescriptionDrug | null> {
    const { data, error } = await supabase
        .from('prescription_drugs')
        .update({ deleted_at: new Date().toISOString() })
        .eq('prescription_id', prescriptionId)
        .eq('drug_id', drugId)
        .is('deleted_at', null)
        .select()
        .single();

    if (error) return null;
    return data as PrescriptionDrug;
}

export async function getDrugIds(prescriptionId: string): Promise<string[]> {
    const { data, error } = await supabase
        .from('prescription_drugs')
        .select('drug_id')
        .eq('prescription_id', prescriptionId)
        .is('deleted_at', null);

    if (error) throw error;
    return (data || []).map((d: { drug_id: string }) => d.drug_id);
}

export async function getAlerts(prescriptionId: string): Promise<Alert[]> {
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
    return (data || []) as unknown as Alert[];
}

export async function insertEvent(
    prescriptionId: string,
    eventType: string,
    eventData: Record<string, unknown>,
    performedBy: string
): Promise<void> {
    await supabase.from('prescription_events').insert({
        prescription_id: prescriptionId,
        event_type: eventType,
        event_data: eventData,
        performed_by: performedBy,
    });
}
