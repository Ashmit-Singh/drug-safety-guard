/**
 * PRESCRIPTION SERVICE (TypeScript)
 * Business logic layer — orchestrates workflows.
 */
import * as prescriptionRepo from '../repositories/prescriptionRepo';
import { detectInteractions, checkPrescriptionSafety } from './interactionEngine';
import { logDrugUsage } from './auditService';
import { NotFoundError } from '../middleware/errorHandler';
import {
    CreatePrescriptionInput,
    AddDrugInput,
    User,
    Prescription,
    InteractionAlert,
    Alert,
    PrescriptionDrug,
} from '../types';

interface AddDrugResult {
    prescriptionDrug: PrescriptionDrug;
    alerts: Alert[];
    interactionCheck: InteractionAlert[];
}

interface SafetyCheckResult {
    prescriptionId: string;
    isSafe: boolean;
    hasCriticalAlerts: boolean;
    alertCount: number;
    interactions: InteractionAlert[];
    storedAlerts: Alert[];
}

export async function createPrescription(
    body: CreatePrescriptionInput,
    user: User
): Promise<Prescription> {
    const prescription = await prescriptionRepo.create(body);

    await prescriptionRepo.insertEvent(
        prescription.id,
        'created',
        { created_by: user.id },
        user.id
    );

    return prescription;
}

export async function getPrescription(id: string): Promise<Prescription> {
    const prescription = await prescriptionRepo.findById(id);
    if (!prescription) throw new NotFoundError('Prescription not found');
    return prescription;
}

export async function addDrug(
    prescriptionId: string,
    drugData: AddDrugInput,
    user: User
): Promise<AddDrugResult> {
    const prescription = await prescriptionRepo.findById(prescriptionId);
    if (!prescription) throw new NotFoundError('Prescription not found');

    const prescriptionDrug = await prescriptionRepo.addDrug(prescriptionId, drugData);
    const drugIds = await prescriptionRepo.getDrugIds(prescriptionId);
    const interactions = await detectInteractions(drugIds);
    const alerts = await prescriptionRepo.getAlerts(prescriptionId);

    await prescriptionRepo.insertEvent(
        prescriptionId,
        'drug_added',
        { drug_id: drugData.drugId, added_by: user.id, interactions_found: interactions.length },
        user.id
    );

    logDrugUsage({
        drugId: drugData.drugId,
        drugName: prescriptionDrug.drugs?.brand_name ?? 'Unknown',
        drugClass: prescriptionDrug.drugs?.drug_class ?? 'Unknown',
    });

    return { prescriptionDrug, alerts, interactionCheck: interactions };
}

export async function removeDrug(
    prescriptionId: string,
    drugId: string,
    user: User
): Promise<PrescriptionDrug> {
    const removed = await prescriptionRepo.removeDrug(prescriptionId, drugId);
    if (!removed) throw new NotFoundError('Prescription drug not found');

    await prescriptionRepo.insertEvent(
        prescriptionId,
        'drug_removed',
        { drug_id: drugId, removed_by: user.id },
        user.id
    );

    return removed;
}

export async function safetyCheck(prescriptionId: string): Promise<SafetyCheckResult> {
    const interactions = await checkPrescriptionSafety(prescriptionId);
    const storedAlerts = await prescriptionRepo.getAlerts(prescriptionId);

    return {
        prescriptionId,
        isSafe: interactions.length === 0,
        hasCriticalAlerts: interactions.some(
            (i) => i.severity === 'contraindicated' || i.severity === 'severe'
        ),
        alertCount: interactions.length,
        interactions,
        storedAlerts,
    };
}
