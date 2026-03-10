-- ╔══════════════════════════════════════════════════════════════╗
-- ║  DRUG INTERACTION SAFETY & PRESCRIPTION VALIDATION SYSTEM  ║
-- ║  PostgreSQL / Supabase DDL                                  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CUSTOM TYPES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DO $$ BEGIN
    CREATE TYPE severity_level AS ENUM ('mild', 'moderate', 'severe', 'contraindicated');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE prescription_status AS ENUM ('draft', 'pending_review', 'approved', 'dispensed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('patient', 'doctor', 'admin', 'pharmacist');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE alert_status AS ENUM ('active', 'acknowledged', 'overridden', 'resolved');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE consent_type AS ENUM ('treatment', 'data_sharing', 'research');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: users
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_id UUID UNIQUE NOT NULL,              -- Supabase Auth UID
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'patient',
    phone VARCHAR(20),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_users_auth_id ON users(auth_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users(role) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: patients
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20),
    blood_type VARCHAR(5),
    allergies TEXT[],
    medical_conditions TEXT[],
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    insurance_id VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_patients_user_id ON patients(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_patients_name ON patients(last_name, first_name) WHERE deleted_at IS NULL;
CREATE INDEX idx_patients_dob ON patients(date_of_birth) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: doctors
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS doctors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(200) NOT NULL,
    license_number VARCHAR(100) UNIQUE NOT NULL,
    hospital_id UUID,
    department VARCHAR(200),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_doctors_user_id ON doctors(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_doctors_license ON doctors(license_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_doctors_specialization ON doctors(specialization) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: drugs
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS drugs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_name VARCHAR(255) NOT NULL,
    generic_name VARCHAR(255) NOT NULL,
    drug_class VARCHAR(200),
    manufacturer VARCHAR(255),
    ndc_code VARCHAR(50) UNIQUE,             -- National Drug Code
    dosage_form VARCHAR(100),                -- tablet, capsule, injection, etc.
    strength VARCHAR(100),
    route_of_administration VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    requires_prescription BOOLEAN NOT NULL DEFAULT TRUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_drugs_brand_name ON drugs USING gin(brand_name gin_trgm_ops) WHERE deleted_at IS NULL;
CREATE INDEX idx_drugs_generic_name ON drugs USING gin(generic_name gin_trgm_ops) WHERE deleted_at IS NULL;
CREATE INDEX idx_drugs_class ON drugs(drug_class) WHERE deleted_at IS NULL;
CREATE INDEX idx_drugs_ndc ON drugs(ndc_code) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: ingredients
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS ingredients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) UNIQUE NOT NULL,
    cas_number VARCHAR(50),                  -- Chemical Abstracts Service number
    category VARCHAR(200),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_ingredients_name ON ingredients USING gin(name gin_trgm_ops) WHERE deleted_at IS NULL;
CREATE INDEX idx_ingredients_cas ON ingredients(cas_number) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: drug_ingredients (junction table)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS drug_ingredients (
    drug_id UUID NOT NULL REFERENCES drugs(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    is_active_ingredient BOOLEAN NOT NULL DEFAULT TRUE,
    concentration VARCHAR(100),
    unit VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    PRIMARY KEY (drug_id, ingredient_id)
);

CREATE INDEX idx_drug_ingredients_ingredient ON drug_ingredients(ingredient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_drug_ingredients_drug ON drug_ingredients(drug_id) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: ingredient_interactions
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS ingredient_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ingredient_a_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    ingredient_b_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    severity severity_level NOT NULL,
    clinical_effect TEXT NOT NULL,
    mechanism TEXT,
    recommendation TEXT NOT NULL,
    evidence_level VARCHAR(50),              -- established, theoretical, case_report
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT chk_ingredient_order CHECK (ingredient_a_id < ingredient_b_id),
    CONSTRAINT uq_ingredient_pair UNIQUE (ingredient_a_id, ingredient_b_id)
);

CREATE INDEX idx_interactions_a ON ingredient_interactions(ingredient_a_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_interactions_b ON ingredient_interactions(ingredient_b_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_interactions_severity ON ingredient_interactions(severity) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SEVERITY RANKING FUNCTION
-- Needed because MAX() on ENUMs uses alphabetical order,
-- not clinical severity (contraindicated > severe > moderate > mild)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE OR REPLACE FUNCTION severity_rank(s severity_level)
RETURNS INT AS $$
    SELECT CASE s
        WHEN 'contraindicated' THEN 4
        WHEN 'severe' THEN 3
        WHEN 'moderate' THEN 2
        WHEN 'mild' THEN 1
        ELSE 0
    END;
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION rank_to_severity(r INT)
RETURNS severity_level AS $$
    SELECT CASE r
        WHEN 4 THEN 'contraindicated'::severity_level
        WHEN 3 THEN 'severe'::severity_level
        WHEN 2 THEN 'moderate'::severity_level
        WHEN 1 THEN 'mild'::severity_level
        ELSE 'mild'::severity_level
    END;
$$ LANGUAGE sql IMMUTABLE;
CREATE INDEX idx_interactions_pair ON ingredient_interactions(ingredient_a_id, ingredient_b_id) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: prescriptions
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS prescriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
    status prescription_status NOT NULL DEFAULT 'draft',
    diagnosis TEXT,
    notes TEXT,
    prescribed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    pharmacy_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_prescriptions_doctor ON prescriptions(doctor_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_prescriptions_status ON prescriptions(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_prescriptions_date ON prescriptions(prescribed_at DESC) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: prescription_drugs (junction table)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS prescription_drugs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    drug_id UUID NOT NULL REFERENCES drugs(id) ON DELETE RESTRICT,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,         -- e.g., "twice daily"
    duration VARCHAR(100),                   -- e.g., "7 days"
    instructions TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_prescription_drug UNIQUE (prescription_id, drug_id)
);

CREATE INDEX idx_prescription_drugs_prescription ON prescription_drugs(prescription_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_prescription_drugs_drug ON prescription_drugs(drug_id) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: interaction_alerts
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS interaction_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    drug_a_id UUID NOT NULL REFERENCES drugs(id) ON DELETE CASCADE,
    drug_b_id UUID NOT NULL REFERENCES drugs(id) ON DELETE CASCADE,
    ingredient_a_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    ingredient_b_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    interaction_id UUID NOT NULL REFERENCES ingredient_interactions(id) ON DELETE CASCADE,
    severity severity_level NOT NULL,
    clinical_effect TEXT NOT NULL,
    recommendation TEXT NOT NULL,
    status alert_status NOT NULL DEFAULT 'active',
    acknowledged_by UUID REFERENCES users(id) ON DELETE SET NULL,
    acknowledged_at TIMESTAMPTZ,
    override_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_alerts_prescription ON interaction_alerts(prescription_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_alerts_severity ON interaction_alerts(severity) WHERE deleted_at IS NULL;
CREATE INDEX idx_alerts_status ON interaction_alerts(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_alerts_created ON interaction_alerts(created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_alerts_patient ON interaction_alerts(prescription_id, severity) WHERE deleted_at IS NULL AND status = 'active';
CREATE INDEX idx_alerts_dedup ON interaction_alerts(prescription_id, interaction_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_alerts_acknowledged_by ON interaction_alerts(acknowledged_by) WHERE acknowledged_by IS NOT NULL AND deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: audit_log
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_action ON audit_log(action);
CREATE INDEX idx_audit_table ON audit_log(table_name);
CREATE INDEX idx_audit_created ON audit_log(created_at DESC);
CREATE INDEX idx_audit_record ON audit_log(table_name, record_id);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: prescription_events
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS prescription_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,        -- created, drug_added, drug_removed, approved, dispensed, cancelled
    event_data JSONB,
    performed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_events_prescription ON prescription_events(prescription_id);
CREATE INDEX idx_events_type ON prescription_events(event_type);
CREATE INDEX idx_events_created ON prescription_events(created_at DESC);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: patient_consents
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS patient_consents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    consent_type consent_type NOT NULL,
    granted BOOLEAN NOT NULL DEFAULT FALSE,
    granted_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    document_url TEXT,
    ip_address INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_consents_patient ON patient_consents(patient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_consents_type ON patient_consents(consent_type) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE: drug_versions
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE TABLE IF NOT EXISTS drug_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    drug_id UUID NOT NULL REFERENCES drugs(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    changes JSONB NOT NULL,
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    effective_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_drug_version UNIQUE (drug_id, version_number)
);

CREATE INDEX idx_drug_versions_drug ON drug_versions(drug_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_drug_versions_date ON drug_versions(effective_date DESC) WHERE deleted_at IS NULL;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UPDATED_AT TRIGGER FUNCTION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT unnest(ARRAY[
            'users', 'patients', 'doctors', 'drugs', 'ingredients',
            'drug_ingredients', 'ingredient_interactions', 'prescriptions',
            'prescription_drugs', 'interaction_alerts', 'patient_consents',
            'drug_versions'
        ])
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS trg_update_%I_updated_at ON %I;
            CREATE TRIGGER trg_update_%I_updated_at
                BEFORE UPDATE ON %I
                FOR EACH ROW
                EXECUTE FUNCTION update_updated_at_column();
        ', tbl, tbl, tbl, tbl);
    END LOOP;
END $$;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TRIGGER 1: AFTER INSERT ON prescription_drugs
-- Auto-detect drug interactions at ingredient level
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE OR REPLACE FUNCTION fn_check_drug_interactions()
RETURNS TRIGGER AS $$
DECLARE
    rec RECORD;
    new_drug_id UUID;
    presc_id UUID;
BEGIN
    new_drug_id := NEW.drug_id;
    presc_id := NEW.prescription_id;

    -- Find all interactions between the new drug's ingredients
    -- and ingredients of all OTHER drugs already in this prescription
    FOR rec IN
        SELECT DISTINCT
            new_drug_id AS drug_a_id,
            pd.drug_id AS drug_b_id,
            CASE WHEN di_new.ingredient_id < di_existing.ingredient_id
                 THEN di_new.ingredient_id ELSE di_existing.ingredient_id END AS ing_a,
            CASE WHEN di_new.ingredient_id < di_existing.ingredient_id
                 THEN di_existing.ingredient_id ELSE di_new.ingredient_id END AS ing_b,
            ii.id AS interaction_id,
            ii.severity,
            ii.clinical_effect,
            ii.recommendation
        FROM drug_ingredients di_new
        -- Join to other drugs in same prescription
        INNER JOIN prescription_drugs pd
            ON pd.prescription_id = presc_id
            AND pd.drug_id != new_drug_id
            AND pd.deleted_at IS NULL
        -- Get ingredients of those other drugs
        INNER JOIN drug_ingredients di_existing
            ON di_existing.drug_id = pd.drug_id
            AND di_existing.deleted_at IS NULL
        -- Look up interactions (using canonical ordering: a < b)
        INNER JOIN ingredient_interactions ii
            ON ii.deleted_at IS NULL
            AND ii.ingredient_a_id = LEAST(di_new.ingredient_id, di_existing.ingredient_id)
            AND ii.ingredient_b_id = GREATEST(di_new.ingredient_id, di_existing.ingredient_id)
        WHERE di_new.drug_id = new_drug_id
          AND di_new.deleted_at IS NULL
    LOOP
        -- Insert alert (skip duplicates for same prescription + interaction)
        INSERT INTO interaction_alerts (
            prescription_id, drug_a_id, drug_b_id,
            ingredient_a_id, ingredient_b_id, interaction_id,
            severity, clinical_effect, recommendation
        )
        SELECT
            presc_id, rec.drug_a_id, rec.drug_b_id,
            rec.ing_a, rec.ing_b, rec.interaction_id,
            rec.severity, rec.clinical_effect, rec.recommendation
        WHERE NOT EXISTS (
            SELECT 1 FROM interaction_alerts ia
            WHERE ia.prescription_id = presc_id
              AND ia.interaction_id = rec.interaction_id
              AND ia.deleted_at IS NULL
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_interactions ON prescription_drugs;
CREATE TRIGGER trg_check_interactions
    AFTER INSERT ON prescription_drugs
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_drug_interactions();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TRIGGER 2: AFTER INSERT ON interaction_alerts
-- Auto-append to audit_log
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE OR REPLACE FUNCTION fn_audit_alert_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (
        action, table_name, record_id, new_values
    ) VALUES (
        'INTERACTION_ALERT_CREATED',
        'interaction_alerts',
        NEW.id,
        jsonb_build_object(
            'prescription_id', NEW.prescription_id,
            'drug_a_id', NEW.drug_a_id,
            'drug_b_id', NEW.drug_b_id,
            'severity', NEW.severity,
            'clinical_effect', NEW.clinical_effect
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_alert ON interaction_alerts;
CREATE TRIGGER trg_audit_alert
    AFTER INSERT ON interaction_alerts
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_alert_insert();

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- STORED PROCEDURE: check_prescription_safety
-- Returns all active alerts for a given prescription
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE OR REPLACE FUNCTION check_prescription_safety(p_prescription_id UUID)
RETURNS TABLE (
    alert_id UUID,
    drug_a_name VARCHAR,
    drug_b_name VARCHAR,
    ingredient_a_name VARCHAR,
    ingredient_b_name VARCHAR,
    severity severity_level,
    clinical_effect TEXT,
    recommendation TEXT,
    alert_status alert_status,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ia.id AS alert_id,
        da.brand_name AS drug_a_name,
        db.brand_name AS drug_b_name,
        inga.name AS ingredient_a_name,
        ingb.name AS ingredient_b_name,
        ia.severity,
        ia.clinical_effect,
        ia.recommendation,
        ia.status AS alert_status,
        ia.created_at
    FROM interaction_alerts ia
    INNER JOIN drugs da ON da.id = ia.drug_a_id
    INNER JOIN drugs db ON db.id = ia.drug_b_id
    INNER JOIN ingredients inga ON inga.id = ia.ingredient_a_id
    INNER JOIN ingredients ingb ON ingb.id = ia.ingredient_b_id
    WHERE ia.prescription_id = p_prescription_id
      AND ia.deleted_at IS NULL
    ORDER BY
        CASE ia.severity
            WHEN 'contraindicated' THEN 1
            WHEN 'severe' THEN 2
            WHEN 'moderate' THEN 3
            WHEN 'mild' THEN 4
        END,
        ia.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- STORED PROCEDURE: get_patient_drug_history
-- Returns full prescription + drug timeline for a patient
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE OR REPLACE FUNCTION get_patient_drug_history(p_patient_id UUID)
RETURNS TABLE (
    prescription_id UUID,
    prescribed_at TIMESTAMPTZ,
    prescription_status prescription_status,
    doctor_name VARCHAR,
    drug_name VARCHAR,
    generic_name VARCHAR,
    dosage VARCHAR,
    frequency VARCHAR,
    duration VARCHAR,
    alert_count BIGINT,
    max_severity severity_level
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id AS prescription_id,
        p.prescribed_at,
        p.status AS prescription_status,
        (d.first_name || ' ' || d.last_name)::VARCHAR AS doctor_name,
        dr.brand_name AS drug_name,
        dr.generic_name,
        pd.dosage,
        pd.frequency,
        pd.duration,
        COUNT(ia.id) AS alert_count,
        rank_to_severity(MAX(severity_rank(ia.severity))) AS max_severity
    FROM prescriptions p
    INNER JOIN doctors d ON d.id = p.doctor_id
    INNER JOIN prescription_drugs pd ON pd.prescription_id = p.id AND pd.deleted_at IS NULL
    INNER JOIN drugs dr ON dr.id = pd.drug_id
    LEFT JOIN interaction_alerts ia ON ia.prescription_id = p.id AND ia.deleted_at IS NULL
    WHERE p.patient_id = p_patient_id
      AND p.deleted_at IS NULL
    GROUP BY p.id, p.prescribed_at, p.status, d.first_name, d.last_name,
             dr.brand_name, dr.generic_name, pd.dosage, pd.frequency, pd.duration
    ORDER BY p.prescribed_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ROW LEVEL SECURITY POLICIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Helper function to get current user's role
CREATE OR REPLACE FUNCTION public.user_role()
RETURNS user_role AS $$
    SELECT role FROM users WHERE auth_id = auth.uid() AND deleted_at IS NULL;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper function to get current user's ID
CREATE OR REPLACE FUNCTION public.app_user_id()
RETURNS UUID AS $$
    SELECT id FROM users WHERE auth_id = auth.uid() AND deleted_at IS NULL;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─── USERS TABLE RLS ───
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_select_own ON users FOR SELECT
    USING (auth_id = auth.uid() OR public.user_role() = 'admin');

CREATE POLICY users_update_own ON users FOR UPDATE
    USING (auth_id = auth.uid() OR public.user_role() = 'admin');

CREATE POLICY users_insert_admin ON users FOR INSERT
    WITH CHECK (public.user_role() = 'admin' OR auth_id = auth.uid());

-- ─── PATIENTS TABLE RLS ───
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY patients_select ON patients FOR SELECT
    USING (
        user_id = public.app_user_id()
        OR public.user_role() IN ('doctor', 'admin')
    );

CREATE POLICY patients_insert ON patients FOR INSERT
    WITH CHECK (public.user_role() IN ('doctor', 'admin'));

CREATE POLICY patients_update ON patients FOR UPDATE
    USING (
        user_id = public.app_user_id()
        OR public.user_role() IN ('doctor', 'admin')
    );

-- ─── DOCTORS TABLE RLS ───
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;

CREATE POLICY doctors_select ON doctors FOR SELECT
    USING (
        user_id = public.app_user_id()
        OR public.user_role() = 'admin'
        OR public.user_role() = 'patient'
    );

CREATE POLICY doctors_insert ON doctors FOR INSERT
    WITH CHECK (public.user_role() = 'admin');

CREATE POLICY doctors_update ON doctors FOR UPDATE
    USING (user_id = public.app_user_id() OR public.user_role() = 'admin');

-- ─── DRUGS TABLE RLS ───
ALTER TABLE drugs ENABLE ROW LEVEL SECURITY;

CREATE POLICY drugs_select ON drugs FOR SELECT
    USING (TRUE);  -- all authenticated users can read drugs

CREATE POLICY drugs_insert ON drugs FOR INSERT
    WITH CHECK (public.user_role() = 'admin');

CREATE POLICY drugs_update ON drugs FOR UPDATE
    USING (public.user_role() = 'admin');

CREATE POLICY drugs_delete ON drugs FOR DELETE
    USING (public.user_role() = 'admin');

-- ─── INGREDIENTS TABLE RLS ───
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;

CREATE POLICY ingredients_select ON ingredients FOR SELECT
    USING (TRUE);

CREATE POLICY ingredients_modify ON ingredients FOR ALL
    USING (public.user_role() = 'admin');

-- ─── PRESCRIPTIONS TABLE RLS ───
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY prescriptions_select ON prescriptions FOR SELECT
    USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = public.app_user_id())
        OR doctor_id IN (SELECT id FROM doctors WHERE user_id = public.app_user_id())
        OR public.user_role() IN ('admin', 'pharmacist')
    );

CREATE POLICY prescriptions_insert ON prescriptions FOR INSERT
    WITH CHECK (
        doctor_id IN (SELECT id FROM doctors WHERE user_id = public.app_user_id())
        OR public.user_role() = 'admin'
    );

CREATE POLICY prescriptions_update ON prescriptions FOR UPDATE
    USING (
        doctor_id IN (SELECT id FROM doctors WHERE user_id = public.app_user_id())
        OR public.user_role() = 'admin'
    );

-- ─── PRESCRIPTION_DRUGS TABLE RLS ───
ALTER TABLE prescription_drugs ENABLE ROW LEVEL SECURITY;

CREATE POLICY prescription_drugs_select ON prescription_drugs FOR SELECT
    USING (
        prescription_id IN (
            SELECT id FROM prescriptions
            WHERE patient_id IN (SELECT id FROM patients WHERE user_id = public.app_user_id())
               OR doctor_id IN (SELECT id FROM doctors WHERE user_id = public.app_user_id())
        )
        OR public.user_role() = 'admin'
    );

CREATE POLICY prescription_drugs_modify ON prescription_drugs FOR ALL
    USING (
        prescription_id IN (
            SELECT id FROM prescriptions
            WHERE doctor_id IN (SELECT id FROM doctors WHERE user_id = public.app_user_id())
        )
        OR public.user_role() = 'admin'
    );

-- ─── INTERACTION_ALERTS TABLE RLS ───
ALTER TABLE interaction_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY alerts_select ON interaction_alerts FOR SELECT
    USING (
        prescription_id IN (
            SELECT id FROM prescriptions
            WHERE patient_id IN (SELECT id FROM patients WHERE user_id = public.app_user_id())
               OR doctor_id IN (SELECT id FROM doctors WHERE user_id = public.app_user_id())
        )
        OR public.user_role() = 'admin'
    );

CREATE POLICY alerts_update ON interaction_alerts FOR UPDATE
    USING (
        public.user_role() IN ('doctor', 'admin')
    );

-- ─── INGREDIENT_INTERACTIONS TABLE RLS ───
ALTER TABLE ingredient_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY interactions_select ON ingredient_interactions FOR SELECT
    USING (TRUE);

CREATE POLICY interactions_modify ON ingredient_interactions FOR ALL
    USING (public.user_role() = 'admin');

-- ─── AUDIT_LOG TABLE RLS ───
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_select ON audit_log FOR SELECT
    USING (public.user_role() = 'admin');

CREATE POLICY audit_insert ON audit_log FOR INSERT
    WITH CHECK (
        public.user_role() = 'admin'
        OR current_setting('request.jwt.claim.role', true) = 'service_role'
    );  -- Restricted to admin and service role for audit integrity

-- ─── PATIENT_CONSENTS TABLE RLS ───
ALTER TABLE patient_consents ENABLE ROW LEVEL SECURITY;

CREATE POLICY consents_select ON patient_consents FOR SELECT
    USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = public.app_user_id())
        OR public.user_role() IN ('doctor', 'admin')
    );

CREATE POLICY consents_modify ON patient_consents FOR ALL
    USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = public.app_user_id())
        OR public.user_role() = 'admin'
    );

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SEED DATA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Ingredients
INSERT INTO ingredients (id, name, cas_number, category) VALUES
    ('a0000001-0000-0000-0000-000000000001', 'Warfarin Sodium', '129-06-6', 'Anticoagulant'),
    ('a0000001-0000-0000-0000-000000000002', 'Aspirin (Acetylsalicylic Acid)', '50-78-2', 'NSAID'),
    ('a0000001-0000-0000-0000-000000000003', 'Ibuprofen', '15687-27-1', 'NSAID'),
    ('a0000001-0000-0000-0000-000000000004', 'Metformin Hydrochloride', '1115-70-4', 'Biguanide'),
    ('a0000001-0000-0000-0000-000000000005', 'Lisinopril', '83915-83-7', 'ACE Inhibitor'),
    ('a0000001-0000-0000-0000-000000000006', 'Simvastatin', '79902-63-9', 'Statin'),
    ('a0000001-0000-0000-0000-000000000007', 'Amiodarone Hydrochloride', '19774-82-4', 'Antiarrhythmic'),
    ('a0000001-0000-0000-0000-000000000008', 'Fluconazole', '86386-73-4', 'Antifungal'),
    ('a0000001-0000-0000-0000-000000000009', 'Potassium Chloride', '7447-40-7', 'Electrolyte'),
    ('a0000001-0000-0000-0000-000000000010', 'Clopidogrel Bisulfate', '120202-66-6', 'Antiplatelet'),
    ('a0000001-0000-0000-0000-000000000011', 'Omeprazole', '73590-58-6', 'Proton Pump Inhibitor'),
    ('a0000001-0000-0000-0000-000000000012', 'Ciprofloxacin', '85721-33-1', 'Fluoroquinolone')
ON CONFLICT DO NOTHING;

-- Drugs
INSERT INTO drugs (id, brand_name, generic_name, drug_class, manufacturer, dosage_form, strength) VALUES
    ('b0000001-0000-0000-0000-000000000001', 'Coumadin', 'Warfarin', 'Anticoagulant', 'Bristol-Myers Squibb', 'Tablet', '5mg'),
    ('b0000001-0000-0000-0000-000000000002', 'Bayer Aspirin', 'Aspirin', 'NSAID/Analgesic', 'Bayer', 'Tablet', '325mg'),
    ('b0000001-0000-0000-0000-000000000003', 'Advil', 'Ibuprofen', 'NSAID', 'Pfizer', 'Tablet', '200mg'),
    ('b0000001-0000-0000-0000-000000000004', 'Glucophage', 'Metformin', 'Antidiabetic', 'Merck', 'Tablet', '500mg'),
    ('b0000001-0000-0000-0000-000000000005', 'Zestril', 'Lisinopril', 'ACE Inhibitor', 'AstraZeneca', 'Tablet', '10mg'),
    ('b0000001-0000-0000-0000-000000000006', 'Zocor', 'Simvastatin', 'Statin', 'Merck', 'Tablet', '20mg'),
    ('b0000001-0000-0000-0000-000000000007', 'Cordarone', 'Amiodarone', 'Antiarrhythmic', 'Wyeth', 'Tablet', '200mg'),
    ('b0000001-0000-0000-0000-000000000008', 'Diflucan', 'Fluconazole', 'Antifungal', 'Pfizer', 'Capsule', '150mg'),
    ('b0000001-0000-0000-0000-000000000009', 'Plavix', 'Clopidogrel', 'Antiplatelet', 'Sanofi', 'Tablet', '75mg'),
    ('b0000001-0000-0000-0000-000000000010', 'Prilosec', 'Omeprazole', 'PPI', 'AstraZeneca', 'Capsule', '20mg'),
    ('b0000001-0000-0000-0000-000000000011', 'Cipro', 'Ciprofloxacin', 'Antibiotic', 'Bayer', 'Tablet', '500mg')
ON CONFLICT DO NOTHING;

-- Drug-Ingredient mappings
INSERT INTO drug_ingredients (drug_id, ingredient_id) VALUES
    ('b0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000001'),  -- Coumadin -> Warfarin
    ('b0000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000002'),  -- Bayer -> Aspirin
    ('b0000001-0000-0000-0000-000000000003', 'a0000001-0000-0000-0000-000000000003'),  -- Advil -> Ibuprofen
    ('b0000001-0000-0000-0000-000000000004', 'a0000001-0000-0000-0000-000000000004'),  -- Glucophage -> Metformin
    ('b0000001-0000-0000-0000-000000000005', 'a0000001-0000-0000-0000-000000000005'),  -- Zestril -> Lisinopril
    ('b0000001-0000-0000-0000-000000000006', 'a0000001-0000-0000-0000-000000000006'),  -- Zocor -> Simvastatin
    ('b0000001-0000-0000-0000-000000000007', 'a0000001-0000-0000-0000-000000000007'),  -- Cordarone -> Amiodarone
    ('b0000001-0000-0000-0000-000000000008', 'a0000001-0000-0000-0000-000000000008'),  -- Diflucan -> Fluconazole
    ('b0000001-0000-0000-0000-000000000009', 'a0000001-0000-0000-0000-000000000010'),  -- Plavix -> Clopidogrel
    ('b0000001-0000-0000-0000-000000000010', 'a0000001-0000-0000-0000-000000000011'), -- Prilosec -> Omeprazole
    ('b0000001-0000-0000-0000-000000000011', 'a0000001-0000-0000-0000-000000000012') -- Cipro -> Ciprofloxacin
ON CONFLICT DO NOTHING;

-- Ingredient Interactions (canonical order: ingredient_a_id < ingredient_b_id)
INSERT INTO ingredient_interactions (ingredient_a_id, ingredient_b_id, severity, clinical_effect, mechanism, recommendation, evidence_level) VALUES
    -- Warfarin + Aspirin → SEVERE bleeding risk
    ('a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000002',
     'severe', 'Greatly increased risk of bleeding. Both agents impair hemostasis via different mechanisms.',
     'Warfarin inhibits vitamin K-dependent clotting factors; aspirin inhibits platelet aggregation via COX-1.',
     'Avoid combination unless clinically essential. Monitor INR closely. Consider PPI for GI protection.', 'established'),

    -- Warfarin + Ibuprofen → SEVERE bleeding risk
    ('a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000003',
     'severe', 'Increased risk of GI bleeding and prolonged INR. NSAIDs displace warfarin from protein binding.',
     'Ibuprofen inhibits COX-1/COX-2 and may displace warfarin from albumin binding sites.',
     'Use alternative analgesic (acetaminophen). If unavoidable, monitor INR every 3-5 days.', 'established'),

    -- Warfarin + Fluconazole → CONTRAINDICATED
    ('a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000008',
     'contraindicated', 'Fluconazole potently inhibits CYP2C9, dramatically increasing warfarin levels and bleeding risk.',
     'CYP2C9 inhibition reduces warfarin metabolism, leading to supratherapeutic INR levels.',
     'Do NOT co-administer. Use alternative antifungal. If unavoidable, reduce warfarin dose 50% and monitor INR daily.', 'established'),

    -- Warfarin + Amiodarone → SEVERE
    ('a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000007',
     'severe', 'Amiodarone inhibits warfarin metabolism, increasing INR and bleeding risk for weeks after initiation.',
     'Amiodarone inhibits CYP2C9 and CYP3A4. Effect persists due to extremely long half-life (40-55 days).',
     'Reduce warfarin dose by 33-50% when initiating amiodarone. Monitor INR weekly for first 3 months.', 'established'),

    -- Simvastatin + Amiodarone → SEVERE myopathy
    ('a0000001-0000-0000-0000-000000000006', 'a0000001-0000-0000-0000-000000000007',
     'severe', 'Increased risk of rhabdomyolysis. Amiodarone increases simvastatin plasma levels via CYP3A4 inhibition.',
     'CYP3A4 inhibition by amiodarone prevents simvastatin first-pass metabolism.',
     'Limit simvastatin dose to 20mg/day with amiodarone. Consider pravastatin or rosuvastatin as alternatives.', 'established'),

    -- Simvastatin + Fluconazole → CONTRAINDICATED
    ('a0000001-0000-0000-0000-000000000006', 'a0000001-0000-0000-0000-000000000008',
     'contraindicated', 'Fluconazole significantly increases simvastatin levels, dramatically increasing rhabdomyolysis risk.',
     'CYP3A4 inhibition by fluconazole prevents simvastatin metabolism.',
     'Do NOT co-administer. Suspend simvastatin during fluconazole therapy. Use pravastatin if statin is essential.', 'established'),

    -- Lisinopril + Potassium → MODERATE hyperkalemia
    ('a0000001-0000-0000-0000-000000000005', 'a0000001-0000-0000-0000-000000000009',
     'moderate', 'Risk of hyperkalemia. ACE inhibitors reduce aldosterone, retaining potassium.',
     'ACE inhibitors decrease aldosterone secretion, reducing renal potassium excretion.',
     'Monitor serum potassium within 1 week of co-prescription. Avoid if K+ > 5.0 mEq/L.', 'established'),

    -- Clopidogrel + Omeprazole → MODERATE reduced efficacy
    ('a0000001-0000-0000-0000-000000000010', 'a0000001-0000-0000-0000-000000000011',
     'moderate', 'Omeprazole inhibits CYP2C19, reducing conversion of clopidogrel to active metabolite.',
     'CYP2C19 inhibition decreases clopidogrel activation by up to 45%.',
     'Use pantoprazole instead of omeprazole. Separate dosing by 12 hours if PPI is required.', 'established'),

    -- Metformin + Ciprofloxacin → MODERATE glucose dysregulation
    ('a0000001-0000-0000-0000-000000000004', 'a0000001-0000-0000-0000-000000000012',
     'moderate', 'Ciprofloxacin may potentiate hypoglycemic effect of metformin. Cases of severe hypoglycemia reported.',
     'Fluoroquinolones may stimulate insulin release and interfere with glucose metabolism.',
     'Monitor blood glucose closely during concurrent use. Adjust metformin dose if needed.', 'case_report'),

    -- Aspirin + Ibuprofen → MODERATE reduced cardioprotection
    ('a0000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000003',
     'moderate', 'Ibuprofen may block the antiplatelet effect of low-dose aspirin, reducing cardioprotective benefit.',
     'Competitive COX-1 binding. Ibuprofen reversibly binds COX-1, preventing irreversible aspirin acetylation.',
     'Take aspirin 30 minutes before ibuprofen, or use alternative analgesic. Avoid chronic concurrent use.', 'established')
ON CONFLICT DO NOTHING;

-- Sample patients
INSERT INTO patients (id, first_name, last_name, date_of_birth, gender, blood_type, allergies, medical_conditions) VALUES
    ('c0000001-0000-0000-0000-000000000001', 'Alice', 'Thompson', '1965-03-14', 'Female', 'O+',
     ARRAY['Penicillin', 'Sulfa drugs'], ARRAY['Atrial fibrillation', 'Type 2 Diabetes']),
    ('c0000001-0000-0000-0000-000000000002', 'Robert', 'Chen', '1978-09-22', 'Male', 'A+',
     ARRAY['Codeine'], ARRAY['Hypertension', 'Hyperlipidemia']),
    ('c0000001-0000-0000-0000-000000000003', 'Maria', 'Garcia', '1990-11-07', 'Female', 'B+',
     NULL, ARRAY['Type 2 Diabetes', 'UTI (recurrent)'])
ON CONFLICT DO NOTHING;

-- Sample doctors
INSERT INTO doctors (id, first_name, last_name, specialization, license_number, department) VALUES
    ('d0000001-0000-0000-0000-000000000001', 'Dr. James', 'Wilson', 'Internal Medicine', 'LIC-2024-001', 'General Medicine'),
    ('d0000001-0000-0000-0000-000000000002', 'Dr. Sarah', 'Patel', 'Cardiology', 'LIC-2024-002', 'Cardiology')
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- END OF SCHEMA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
