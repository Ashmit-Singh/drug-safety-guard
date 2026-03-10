import { Request, Response, NextFunction } from 'express';

// ─── Database Models ─────────────────────────────────

export type SeverityLevel = 'mild' | 'moderate' | 'severe' | 'contraindicated';
export type PrescriptionStatus = 'draft' | 'active' | 'completed' | 'cancelled';
export type AlertStatus = 'active' | 'acknowledged' | 'overridden' | 'resolved';
export type UserRole = 'patient' | 'doctor' | 'pharmacist' | 'admin';

export interface User {
    id: string;
    authId: string;
    email: string;
    fullName: string;
    role: UserRole;
}

export interface Drug {
    id: string;
    brand_name: string;
    generic_name: string;
    drug_class: string | null;
    strength: string | null;
    manufacturer: string | null;
    created_at: string;
    updated_at: string;
    deleted_at: string | null;
}

export interface Ingredient {
    id: string;
    name: string;
    cas_number: string | null;
    category: string | null;
    description: string | null;
}

export interface Patient {
    id: string;
    first_name: string;
    last_name: string;
    date_of_birth: string;
    gender: string;
    blood_type: string | null;
    allergies: string[];
    medical_conditions: string[];
    created_at: string;
}

export interface Doctor {
    id: string;
    first_name: string;
    last_name: string;
    specialization: string | null;
    license_number: string;
    department: string | null;
}

export interface Prescription {
    id: string;
    patient_id: string;
    doctor_id: string;
    diagnosis: string | null;
    notes: string | null;
    status: PrescriptionStatus;
    prescribed_at: string;
    valid_until: string | null;
    created_at: string;
    updated_at: string;
    deleted_at: string | null;
    patients?: Patient;
    doctors?: Doctor;
    prescription_drugs?: PrescriptionDrug[];
    interaction_alerts?: Alert[];
}

export interface PrescriptionDrug {
    id: string;
    prescription_id: string;
    drug_id: string;
    dosage: string;
    frequency: string;
    duration: string | null;
    instructions: string | null;
    drugs?: Drug;
}

export interface Alert {
    id: string;
    prescription_id: string;
    drug_a_id: string;
    drug_b_id: string;
    ingredient_a_id: string;
    ingredient_b_id: string;
    severity: SeverityLevel;
    clinical_effect: string;
    mechanism: string | null;
    recommendation: string;
    status: AlertStatus;
    acknowledged_by: string | null;
    acknowledged_at: string | null;
    override_reason: string | null;
    created_at: string;
}

export interface IngredientInteraction {
    id: string;
    ingredient_a_id: string;
    ingredient_b_id: string;
    severity: SeverityLevel;
    clinical_effect: string;
    mechanism: string;
    recommendation: string;
    evidence_level: string;
    deleted_at: string | null;
}

// ─── API Request Types ───────────────────────────────

export interface CreatePrescriptionInput {
    patientId: string;
    doctorId: string;
    diagnosis?: string;
    notes?: string;
    validUntil?: string;
}

export interface AddDrugInput {
    drugId: string;
    dosage: string;
    frequency: string;
    duration?: string;
    instructions?: string;
}

export interface PaginationInput {
    limit: number;
    offset: number;
}

export interface AlertFilterInput extends PaginationInput {
    severity?: SeverityLevel;
    status?: AlertStatus;
}

export interface AcknowledgeInput {
    overrideReason?: string;
}

export interface BatchAcknowledgeInput {
    alertIds: string[];
    overrideReason?: string;
}

// ─── API Response Types ──────────────────────────────

export interface ApiMeta {
    requestId: string | null;
    timestamp: string;
}

export interface PaginationMeta {
    total: number;
    limit: number;
    offset: number;
    nextCursor: string | null;
    hasMore: boolean;
}

export interface ApiResponse<T = unknown> {
    success: boolean;
    data: T;
    meta: ApiMeta;
    pagination: PaginationMeta | null;
    _links?: Record<string, string>;
}

// ─── Interaction Engine Types ────────────────────────

export interface DrugPairInfo {
    drugAId: string;
    drugAName: string;
    drugAGeneric: string;
    drugBId: string;
    drugBName: string;
    drugBGeneric: string;
}

export interface IngredientPairInfo {
    ingredientAId: string;
    ingredientAName: string;
    ingredientBId: string;
    ingredientBName: string;
}

export interface InteractionAlert {
    interactionId: string;
    drugPair: DrugPairInfo;
    ingredientPair: IngredientPairInfo;
    severity: SeverityLevel;
    clinicalEffect: string;
    mechanism: string;
    recommendation: string;
    evidenceLevel: string;
}

export interface IngredientPairCheck {
    firstId: string;
    secondId: string;
    firstName: string;
    secondName: string;
    drugAId: string;
    drugBId: string;
}

// ─── Express Extensions ──────────────────────────────

export interface AuthenticatedRequest extends Request {
    user: User;
    requestId: string;
    validated: Record<string, unknown>;
}

export type AsyncHandler = (
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
) => Promise<void>;

// ─── Audit Types ─────────────────────────────────────

export interface AuditEvent {
    userId: string;
    userEmail: string;
    userRole: string;
    action: string;
    resourceType: string;
    resourceId: string;
    details: string;
    ipAddress: string | null;
    userAgent: string | null;
    requestMethod: string;
    requestPath: string;
    responseStatus: number;
    durationMs: number;
}

export interface DrugUsageEvent {
    drugId: string;
    drugName: string;
    drugClass: string;
}

// ─── Paginated Result ────────────────────────────────

export interface PaginatedResult<T> {
    data: T[];
    total: number;
}

// ─── Config ──────────────────────────────────────────

export interface AppConfig {
    NODE_ENV: 'development' | 'production' | 'test';
    PORT: number;
    SUPABASE_URL: string;
    SUPABASE_ANON_KEY: string;
    SUPABASE_SERVICE_KEY: string;
    JWT_SECRET: string;
    REDIS_URL: string;
    REDIS_PASSWORD?: string;
    CASSANDRA_HOSTS: string;
    CASSANDRA_DATACENTER: string;
    CASSANDRA_KEYSPACE: string;
    CASSANDRA_PORT: number;
    CASSANDRA_USERNAME?: string;
    CASSANDRA_PASSWORD?: string;
    RATE_LIMIT_WINDOW_MS: number;
    RATE_LIMIT_MAX: number;
    INTERACTION_CHECK_RATE_LIMIT_MAX: number;
    FLUTTER_WEB_ORIGIN: string;
    AUDIT_QUEUE_MAX_RETRIES: number;
    AUDIT_DEAD_LETTER_THRESHOLD: number;
}
