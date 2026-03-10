-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MIGRATION 003: RLS Policy Hardening (RLS-01 → RLS-05)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Applied after: 002_schema_fixes.sql
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BEGIN;

-- ─── RLS-01: Split drugs_modify into separate policies ─
-- FOR ALL policies need both USING and WITH CHECK.
-- Splitting into INSERT/UPDATE/DELETE gives explicit control.

DROP POLICY IF EXISTS drugs_modify ON drugs;

CREATE POLICY drugs_insert ON drugs FOR INSERT
    WITH CHECK (auth.user_role() = 'admin');

CREATE POLICY drugs_update ON drugs FOR UPDATE
    USING (auth.user_role() = 'admin')
    WITH CHECK (auth.user_role() = 'admin');

CREATE POLICY drugs_delete ON drugs FOR DELETE
    USING (auth.user_role() = 'admin');


-- ─── RLS-02: Add pharmacist to prescriptions_select ────
-- Pharmacists MUST verify prescriptions before dispensing.

DROP POLICY IF EXISTS prescriptions_select ON prescriptions;

CREATE POLICY prescriptions_select ON prescriptions FOR SELECT
    USING (
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.app_user_id())
        OR doctor_id IN (SELECT id FROM doctors WHERE user_id = auth.app_user_id())
        OR auth.user_role() IN ('admin', 'pharmacist')
    );


-- ─── RLS-03: Flatten prescription_drugs_select ─────────
-- Replace triple-nested subquery with a JOIN-based rewrite.
-- Before: SELECT ... WHERE prescription_id IN (SELECT ... WHERE patient_id IN (SELECT ...))
-- After:  Direct JOIN — O(n) instead of O(n³) plan explosion.

DROP POLICY IF EXISTS prescription_drugs_select ON prescription_drugs;

CREATE POLICY prescription_drugs_select ON prescription_drugs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM prescriptions p
            WHERE p.id = prescription_drugs.prescription_id
              AND p.deleted_at IS NULL
              AND (
                  p.patient_id IN (SELECT id FROM patients WHERE user_id = auth.app_user_id())
                  OR p.doctor_id IN (SELECT id FROM doctors WHERE user_id = auth.app_user_id())
                  OR auth.user_role() IN ('admin', 'pharmacist')
              )
        )
    );


-- ─── RLS-04: Change auth.user_role() to SECURITY INVOKER
-- SECURITY DEFINER runs as function owner (superuser).
-- SECURITY INVOKER runs as the calling user — safer.

CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY INVOKER
STABLE
AS $$
    SELECT COALESCE(
        current_setting('request.jwt.claims', true)::json->>'role',
        (SELECT role FROM public.users WHERE auth_id = auth.uid() LIMIT 1),
        'anonymous'
    );
$$;

-- Grant minimum necessary access for the invoker
GRANT SELECT (role) ON public.users TO authenticated;
GRANT SELECT (id, role) ON public.users TO authenticated;


-- ─── RLS-05: Restrict audit_log INSERT ─────────────────
-- Only admin users and service_role can insert audit records.
-- Prevents unprivileged users from polluting the audit trail.

DROP POLICY IF EXISTS audit_insert ON audit_log;

CREATE POLICY audit_insert ON audit_log FOR INSERT
    WITH CHECK (
        auth.user_role() = 'admin'
        OR current_setting('request.jwt.claims', true)::jsonb->>'role' = 'service_role'
    );

COMMIT;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- VERIFICATION TEST BLOCK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Run these after applying the migration to verify policies.
-- Uncomment and run manually in psql or Supabase SQL Editor.
--
-- -- Test RLS-01: Non-admin cannot insert drugs
-- SET LOCAL role TO authenticated;
-- SET LOCAL request.jwt.claims TO '{"role": "doctor"}';
-- INSERT INTO drugs (brand_name, generic_name) VALUES ('Test', 'Test');
-- -- Expected: ERROR: new row violates row-level security policy
--
-- -- Test RLS-02: Pharmacist can read prescriptions
-- SET LOCAL role TO authenticated;
-- SET LOCAL request.jwt.claims TO '{"role": "pharmacist"}';
-- SELECT count(*) FROM prescriptions;
-- -- Expected: SUCCESS (returns count)
--
-- -- Test RLS-05: Doctor cannot insert audit logs
-- SET LOCAL role TO authenticated;
-- SET LOCAL request.jwt.claims TO '{"role": "doctor"}';
-- INSERT INTO audit_log (user_id, action, table_name) VALUES (gen_random_uuid(), 'TEST', 'test');
-- -- Expected: ERROR: new row violates row-level security policy
--
-- -- Reset
-- RESET role;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ROLLBACK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DROP POLICY IF EXISTS drugs_insert ON drugs;
-- DROP POLICY IF EXISTS drugs_update ON drugs;
-- DROP POLICY IF EXISTS drugs_delete ON drugs;
-- CREATE POLICY drugs_modify ON drugs FOR ALL USING (auth.user_role() = 'admin');
-- 
-- DROP POLICY IF EXISTS prescriptions_select ON prescriptions;
-- CREATE POLICY prescriptions_select ON prescriptions FOR SELECT
--     USING (patient_id IN (...) OR doctor_id IN (...) OR auth.user_role() = 'admin');
--
-- DROP POLICY IF EXISTS prescription_drugs_select ON prescription_drugs;
-- -- Recreate original triple-nested version
--
-- DROP POLICY IF EXISTS audit_insert ON audit_log;
-- CREATE POLICY audit_insert ON audit_log FOR INSERT WITH CHECK (TRUE);
