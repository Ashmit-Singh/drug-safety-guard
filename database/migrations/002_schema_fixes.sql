-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MIGRATION 002: Schema Fixes (DB-01 → DB-05)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Applied after: 001_initial_schema.sql
-- Rollback: See ROLLBACK section at bottom
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BEGIN;

-- ─── DB-01: Alert deduplication index ──────────────────
-- Without this, the trigger's EXISTS check does a sequential scan.
-- CONCURRENTLY cannot be used inside a transaction, so we use IF NOT EXISTS.
CREATE INDEX IF NOT EXISTS idx_alerts_dedup
    ON interaction_alerts(prescription_id, interaction_id)
    WHERE deleted_at IS NULL;

-- ─── DB-02: Severity ranking functions ─────────────────
-- PostgreSQL MAX() on ENUMs uses alphabetical order, not clinical severity.
-- 'contraindicated' > 'severe' > 'moderate' > 'mild'
-- These IMMUTABLE functions enable correct MAX(severity_rank(col)).

CREATE OR REPLACE FUNCTION severity_rank(s severity_level)
RETURNS INT LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE s
        WHEN 'contraindicated' THEN 4
        WHEN 'severe' THEN 3
        WHEN 'moderate' THEN 2
        WHEN 'mild' THEN 1
        ELSE 0
    END;
$$;

CREATE OR REPLACE FUNCTION severity_from_rank(r INT)
RETURNS severity_level LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE r
        WHEN 4 THEN 'contraindicated'::severity_level
        WHEN 3 THEN 'severe'::severity_level
        WHEN 2 THEN 'moderate'::severity_level
        WHEN 1 THEN 'mild'::severity_level
        ELSE 'mild'::severity_level
    END;
$$;

-- Update get_patient_drug_history to use correct severity ordering
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
        severity_from_rank(MAX(severity_rank(ia.severity))) AS max_severity
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


-- ─── DB-03: Full-state snapshot in drug_versions ───────
-- The existing `changes` JSONB only stores diffs, making rollback impossible.
-- `full_snapshot` captures the complete OLD row on UPDATE.

ALTER TABLE drug_versions
    ADD COLUMN IF NOT EXISTS full_snapshot JSONB NOT NULL DEFAULT '{}';

-- Update the versioning trigger to capture full snapshot
CREATE OR REPLACE FUNCTION fn_drug_version_snapshot()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        UPDATE drug_versions
        SET full_snapshot = row_to_json(OLD)::jsonb
        WHERE drug_id = NEW.id
          AND version_number = (
              SELECT MAX(version_number) FROM drug_versions WHERE drug_id = NEW.id
          );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if not exists (safe idempotent)
DROP TRIGGER IF EXISTS trg_drug_version_snapshot ON drugs;
CREATE TRIGGER trg_drug_version_snapshot
    AFTER UPDATE ON drugs
    FOR EACH ROW
    EXECUTE FUNCTION fn_drug_version_snapshot();


-- ─── DB-04: Drop redundant index ──────────────────────
-- idx_interactions_pair is redundant with uq_ingredient_pair UNIQUE constraint
DROP INDEX IF EXISTS idx_interactions_pair;


-- ─── DB-05: Acknowledger lookup index ──────────────────
CREATE INDEX IF NOT EXISTS idx_alerts_acknowledged_by
    ON interaction_alerts(acknowledged_by)
    WHERE acknowledged_by IS NOT NULL AND deleted_at IS NULL;


-- ─── S-06: Array length constraints on patients ────────
-- Prevents unbounded array insertion for allergies and conditions
ALTER TABLE patients
    ADD CONSTRAINT chk_allergies_length
    CHECK (allergies IS NULL OR array_length(allergies, 1) <= 100);

ALTER TABLE patients
    ADD CONSTRAINT chk_conditions_length
    CHECK (medical_conditions IS NULL OR array_length(medical_conditions, 1) <= 50);

COMMIT;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ROLLBACK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- To undo this migration, run the following:
--
-- DROP INDEX IF EXISTS idx_alerts_dedup;
-- DROP INDEX IF EXISTS idx_alerts_acknowledged_by;
-- DROP FUNCTION IF EXISTS severity_rank(severity_level);
-- DROP FUNCTION IF EXISTS severity_from_rank(INT);
-- DROP TRIGGER IF EXISTS trg_drug_version_snapshot ON drugs;
-- DROP FUNCTION IF EXISTS fn_drug_version_snapshot();
-- ALTER TABLE drug_versions DROP COLUMN IF EXISTS full_snapshot;
-- ALTER TABLE patients DROP CONSTRAINT IF EXISTS chk_allergies_length;
-- ALTER TABLE patients DROP CONSTRAINT IF EXISTS chk_conditions_length;
-- CREATE INDEX idx_interactions_pair ON ingredient_interactions(ingredient_a_id, ingredient_b_id) WHERE deleted_at IS NULL;
