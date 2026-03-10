-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MIGRATION 004: Data Retention & Encryption (HC)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BEGIN;

-- ─── HC-01: Column-level encryption via pgsodium ───────
-- NOTE: Requires Supabase Pro plan or self-hosted with:
-- CREATE EXTENSION IF NOT EXISTS pgsodium;
-- Key management is handled through `pgsodium.create_key()`

-- Encrypt PHI fields using transparent column encryption (TCE)
-- Uncomment when pgsodium is available on your Supabase instance:

-- SELECT pgsodium.create_key('Drug Interaction PHI Key');
-- 
-- SECURITY LABEL FOR pgsodium ON COLUMN patients.allergies
--   IS 'ENCRYPT WITH KEY ID (select id from pgsodium.valid_key where name = ''Drug Interaction PHI Key'') ASSOCIATED (id)';
-- 
-- SECURITY LABEL FOR pgsodium ON COLUMN patients.medical_conditions
--   IS 'ENCRYPT WITH KEY ID (select id from pgsodium.valid_key where name = ''Drug Interaction PHI Key'') ASSOCIATED (id)';
-- 
-- SECURITY LABEL FOR pgsodium ON COLUMN prescriptions.diagnosis
--   IS 'ENCRYPT WITH KEY ID (select id from pgsodium.valid_key where name = ''Drug Interaction PHI Key'') ASSOCIATED (id)';
-- 
-- SECURITY LABEL FOR pgsodium ON COLUMN prescriptions.notes
--   IS 'ENCRYPT WITH KEY ID (select id from pgsodium.valid_key where name = ''Drug Interaction PHI Key'') ASSOCIATED (id)';


-- ─── HC-04: Data retention policy ──────────────────────
-- HIPAA requires PHI retention for a minimum of 6 years.
-- This function hard-deletes records where deleted_at is
-- older than 7 years (6-year minimum + 1-year safety buffer).

CREATE OR REPLACE FUNCTION enforce_retention_policy()
RETURNS void AS $$
DECLARE
    retention_cutoff TIMESTAMPTZ := NOW() - INTERVAL '7 years';
    rx_count INT;
    rxd_count INT;
    alert_count INT;
BEGIN
    -- Delete old prescription drugs first (FK reference)
    DELETE FROM prescription_drugs
    WHERE deleted_at IS NOT NULL AND deleted_at < retention_cutoff;
    GET DIAGNOSTICS rxd_count = ROW_COUNT;

    -- Delete old interaction alerts
    DELETE FROM interaction_alerts
    WHERE deleted_at IS NOT NULL AND deleted_at < retention_cutoff;
    GET DIAGNOSTICS alert_count = ROW_COUNT;

    -- Delete old prescriptions
    DELETE FROM prescriptions
    WHERE deleted_at IS NOT NULL AND deleted_at < retention_cutoff;
    GET DIAGNOSTICS rx_count = ROW_COUNT;

    -- Log results
    INSERT INTO audit_log (user_id, action, table_name, record_id, new_values)
    VALUES (
        '00000000-0000-0000-0000-000000000000'::UUID, -- system user
        'DATA_RETENTION_POLICY',
        'system',
        gen_random_uuid(),
        jsonb_build_object(
            'prescriptions_deleted', rx_count,
            'prescription_drugs_deleted', rxd_count,
            'alerts_deleted', alert_count,
            'retention_cutoff', retention_cutoff::text
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule via pg_cron (hourly check, runs deletions when needed):
-- SELECT cron.schedule('retention-policy', '0 3 * * 0', 'SELECT enforce_retention_policy()');
-- This runs every Sunday at 3:00 AM

COMMIT;
