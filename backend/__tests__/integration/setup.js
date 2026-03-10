/**
 * Integration test setup using pg-mem for in-memory PostgreSQL.
 * Provides a test database, supertest app instance, and helpers.
 */
const { newDb } = require('pg-mem');
const request = require('supertest');

let testDb;
let testClient;

/**
 * Initialize an in-memory PostgreSQL database with the application schema.
 */
async function setupTestDatabase() {
    testDb = newDb();

    // Register required PostgreSQL extensions
    testDb.public.registerFunction({
        name: 'gen_random_uuid',
        returns: 'uuid',
        implementation: () => require('crypto').randomUUID(),
    });

    testDb.public.registerFunction({
        name: 'now',
        returns: 'timestamptz',
        implementation: () => new Date().toISOString(),
    });

    // Create enum types
    testDb.public.none(`
        DO $$ BEGIN
            CREATE TYPE severity_level AS ENUM ('mild', 'moderate', 'severe', 'contraindicated');
        EXCEPTION WHEN duplicate_object THEN null;
        END $$;

        DO $$ BEGIN
            CREATE TYPE prescription_status AS ENUM ('draft', 'active', 'completed', 'cancelled');
        EXCEPTION WHEN duplicate_object THEN null;
        END $$;

        DO $$ BEGIN
            CREATE TYPE alert_status AS ENUM ('active', 'acknowledged', 'overridden', 'resolved');
        EXCEPTION WHEN duplicate_object THEN null;
        END $$;
    `);

    // Create core tables
    testDb.public.none(`
        CREATE TABLE IF NOT EXISTS patients (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            first_name VARCHAR(100) NOT NULL,
            last_name VARCHAR(100) NOT NULL,
            date_of_birth DATE NOT NULL,
            gender VARCHAR(20),
            blood_type VARCHAR(10),
            allergies TEXT[],
            medical_conditions TEXT[],
            user_id UUID,
            created_at TIMESTAMPTZ DEFAULT now(),
            deleted_at TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS doctors (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            first_name VARCHAR(100) NOT NULL,
            last_name VARCHAR(100) NOT NULL,
            specialization VARCHAR(200),
            license_number VARCHAR(50),
            department VARCHAR(200),
            user_id UUID,
            created_at TIMESTAMPTZ DEFAULT now(),
            deleted_at TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS drugs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            brand_name VARCHAR(255) NOT NULL,
            generic_name VARCHAR(255) NOT NULL,
            drug_class VARCHAR(255),
            strength VARCHAR(100),
            manufacturer VARCHAR(255),
            created_at TIMESTAMPTZ DEFAULT now(),
            updated_at TIMESTAMPTZ DEFAULT now(),
            deleted_at TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS ingredients (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            cas_number VARCHAR(50),
            category VARCHAR(100),
            description TEXT,
            created_at TIMESTAMPTZ DEFAULT now(),
            deleted_at TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS drug_ingredients (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            drug_id UUID REFERENCES drugs(id),
            ingredient_id UUID REFERENCES ingredients(id),
            role VARCHAR(50) DEFAULT 'active',
            strength_per_unit VARCHAR(100),
            created_at TIMESTAMPTZ DEFAULT now(),
            deleted_at TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS prescriptions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            patient_id UUID REFERENCES patients(id),
            doctor_id UUID REFERENCES doctors(id),
            diagnosis TEXT,
            notes TEXT,
            status prescription_status DEFAULT 'draft',
            prescribed_at TIMESTAMPTZ DEFAULT now(),
            valid_until TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT now(),
            updated_at TIMESTAMPTZ DEFAULT now(),
            deleted_at TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS prescription_drugs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            prescription_id UUID REFERENCES prescriptions(id),
            drug_id UUID REFERENCES drugs(id),
            dosage VARCHAR(100),
            frequency VARCHAR(100),
            duration VARCHAR(100),
            instructions TEXT,
            created_at TIMESTAMPTZ DEFAULT now(),
            deleted_at TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS ingredient_interactions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            ingredient_a_id UUID REFERENCES ingredients(id),
            ingredient_b_id UUID REFERENCES ingredients(id),
            severity severity_level NOT NULL,
            clinical_effect TEXT NOT NULL,
            mechanism TEXT,
            recommendation TEXT NOT NULL,
            evidence_level VARCHAR(50),
            created_at TIMESTAMPTZ DEFAULT now(),
            deleted_at TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS interaction_alerts (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            prescription_id UUID REFERENCES prescriptions(id),
            drug_a_id UUID REFERENCES drugs(id),
            drug_b_id UUID REFERENCES drugs(id),
            ingredient_a_id UUID REFERENCES ingredients(id),
            ingredient_b_id UUID REFERENCES ingredients(id),
            interaction_id UUID REFERENCES ingredient_interactions(id),
            severity severity_level NOT NULL,
            clinical_effect TEXT,
            recommendation TEXT,
            status alert_status DEFAULT 'active',
            acknowledged_by UUID,
            acknowledged_at TIMESTAMPTZ,
            override_reason TEXT,
            created_at TIMESTAMPTZ DEFAULT now(),
            deleted_at TIMESTAMPTZ
        );

        CREATE TABLE IF NOT EXISTS audit_log (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID,
            action VARCHAR(100),
            table_name VARCHAR(100),
            record_id UUID,
            old_values JSONB,
            new_values JSONB,
            created_at TIMESTAMPTZ DEFAULT now()
        );
    `);

    testClient = testDb.adapters.createPg();
    return { db: testDb, client: testClient };
}

/**
 * Seed test data: patients, doctors, drugs with known interactions.
 */
async function seedTestData(db) {
    const patientId = '11111111-1111-1111-1111-111111111111';
    const doctorId  = '22222222-2222-2222-2222-222222222222';
    const drugAId   = '33333333-3333-3333-3333-333333333333';
    const drugBId   = '44444444-4444-4444-4444-444444444444';
    const ingAId    = '55555555-5555-5555-5555-555555555555';
    const ingBId    = '66666666-6666-6666-6666-666666666666';

    db.public.none(`
        INSERT INTO patients (id, first_name, last_name, date_of_birth, gender)
        VALUES ('${patientId}', 'John', 'Doe', '1990-01-15', 'Male');

        INSERT INTO doctors (id, first_name, last_name, specialization, license_number)
        VALUES ('${doctorId}', 'Dr. Sarah', 'Smith', 'Cardiology', 'MD-12345');

        INSERT INTO drugs (id, brand_name, generic_name, drug_class, strength)
        VALUES
            ('${drugAId}', 'Aspirin', 'Acetylsalicylic Acid', 'NSAID', '325mg'),
            ('${drugBId}', 'Coumadin', 'Warfarin', 'Anticoagulant', '5mg');

        INSERT INTO ingredients (id, name, cas_number, category)
        VALUES
            ('${ingAId}', 'Acetylsalicylic Acid', '50-78-2', 'NSAID'),
            ('${ingBId}', 'Warfarin Sodium', '129-06-6', 'Anticoagulant');

        INSERT INTO drug_ingredients (drug_id, ingredient_id, role)
        VALUES
            ('${drugAId}', '${ingAId}', 'active'),
            ('${drugBId}', '${ingBId}', 'active');

        INSERT INTO ingredient_interactions (ingredient_a_id, ingredient_b_id, severity, clinical_effect, mechanism, recommendation, evidence_level)
        VALUES ('${ingAId}', '${ingBId}', 'severe', 'Increased bleeding risk', 'Antiplatelet + Anticoagulant synergy', 'Avoid concurrent use or monitor INR closely', 'high');
    `);

    return { patientId, doctorId, drugAId, drugBId, ingAId, ingBId };
}

async function teardownTestDatabase() {
    if (testClient) {
        await testClient.end();
    }
}

module.exports = {
    setupTestDatabase,
    seedTestData,
    teardownTestDatabase,
};
