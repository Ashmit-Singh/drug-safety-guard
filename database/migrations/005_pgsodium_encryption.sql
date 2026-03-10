-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MIGRATION 005: pgsodium Column Encryption
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Activates column-level encryption for PHI fields.
-- Requires: Supabase Pro plan OR self-hosted with pgsodium.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BEGIN;

-- Step 1: Enable pgsodium extension
CREATE EXTENSION IF NOT EXISTS pgsodium;

-- Step 2: Create encryption key
-- The key is managed by pgsodium's key management system.
-- Key material never leaves the database server.
SELECT pgsodium.create_key(
    name := 'drug_interaction_phi_key',
    key_type := 'aead-det'
);

-- Step 3: Encrypt PHI columns using Transparent Column Encryption (TCE)
-- These SECURITY LABEL statements tell Supabase to automatically
-- encrypt/decrypt the column data at the storage level.

-- Encrypt patients.allergies
SECURITY LABEL FOR pgsodium ON COLUMN patients.allergies
IS 'ENCRYPT WITH KEY ID (SELECT id FROM pgsodium.valid_key WHERE name = ''drug_interaction_phi_key'') ASSOCIATED (id)';

-- Encrypt patients.medical_conditions
SECURITY LABEL FOR pgsodium ON COLUMN patients.medical_conditions
IS 'ENCRYPT WITH KEY ID (SELECT id FROM pgsodium.valid_key WHERE name = ''drug_interaction_phi_key'') ASSOCIATED (id)';

-- Encrypt prescriptions.diagnosis
SECURITY LABEL FOR pgsodium ON COLUMN prescriptions.diagnosis
IS 'ENCRYPT WITH KEY ID (SELECT id FROM pgsodium.valid_key WHERE name = ''drug_interaction_phi_key'') ASSOCIATED (id)';

-- Encrypt prescriptions.notes
SECURITY LABEL FOR pgsodium ON COLUMN prescriptions.notes
IS 'ENCRYPT WITH KEY ID (SELECT id FROM pgsodium.valid_key WHERE name = ''drug_interaction_phi_key'') ASSOCIATED (id)';

COMMIT;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- VERIFICATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Run after migration to verify encryption is active:
--
-- SELECT * FROM pgsodium.valid_key WHERE name = 'drug_interaction_phi_key';
-- -- Should return 1 row with key details
--
-- SELECT objlabel FROM pg_catalog.pg_seclabels 
-- WHERE provider = 'pgsodium' AND objtype = 'column';
-- -- Should show 4 encrypted columns
--
-- INSERT INTO patients (first_name, last_name, date_of_birth, gender, allergies)
-- VALUES ('Test', 'Patient', '2000-01-01', 'Other', ARRAY['Penicillin']);
-- -- Data is automatically encrypted on write
--
-- SELECT allergies FROM patients WHERE first_name = 'Test';
-- -- Returns decrypted 'Penicillin' (transparent to queries)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ROLLBACK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECURITY LABEL FOR pgsodium ON COLUMN patients.allergies IS NULL;
-- SECURITY LABEL FOR pgsodium ON COLUMN patients.medical_conditions IS NULL;
-- SECURITY LABEL FOR pgsodium ON COLUMN prescriptions.diagnosis IS NULL;
-- SECURITY LABEL FOR pgsodium ON COLUMN prescriptions.notes IS NULL;
-- SELECT pgsodium.delete_key((SELECT id FROM pgsodium.valid_key WHERE name = 'drug_interaction_phi_key'));
