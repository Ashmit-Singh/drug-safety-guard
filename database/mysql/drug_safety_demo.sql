-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  DRUG INTERACTION SAFETY & PRESCRIPTION VALIDATION SYSTEM              ║
-- ║  MySQL Workbench — Complete DBMS Demo Script                           ║
-- ║  Author: Drug Safety Guard Project                                     ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 1: DATABASE CREATION & TABLE DESIGN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DROP DATABASE IF EXISTS drug_safety_db;
CREATE DATABASE drug_safety_db;
USE drug_safety_db;

-- ─────────────────────────────────────
-- TABLE 1: PATIENTS
-- Stores patient demographic and medical data
-- Constraints: PK, NOT NULL, UNIQUE, CHECK
-- ─────────────────────────────────────
CREATE TABLE patients (
    patient_id      INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    date_of_birth   DATE NOT NULL,
    gender          ENUM('Male', 'Female', 'Other') NOT NULL,
    blood_type      VARCHAR(5),
    phone           VARCHAR(20) UNIQUE,
    email           VARCHAR(255) UNIQUE,
    allergies       TEXT,
    medical_conditions TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_dob CHECK (date_of_birth < CURDATE())
);

-- ─────────────────────────────────────
-- TABLE 2: DOCTORS
-- Stores prescribing physician information
-- Constraints: PK, NOT NULL, UNIQUE
-- ─────────────────────────────────────
CREATE TABLE doctors (
    doctor_id       INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    specialization  VARCHAR(200) NOT NULL,
    license_number  VARCHAR(100) UNIQUE NOT NULL,
    department      VARCHAR(200),
    phone           VARCHAR(20),
    email           VARCHAR(255) UNIQUE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────
-- TABLE 3: DRUGS
-- Master drug catalog with NDC codes
-- Constraints: PK, NOT NULL, UNIQUE, CHECK
-- ─────────────────────────────────────
CREATE TABLE drugs (
    drug_id         INT AUTO_INCREMENT PRIMARY KEY,
    brand_name      VARCHAR(255) NOT NULL,
    generic_name    VARCHAR(255) NOT NULL,
    drug_class      VARCHAR(200),
    manufacturer    VARCHAR(255),
    ndc_code        VARCHAR(50) UNIQUE,
    dosage_form     VARCHAR(100),
    strength        VARCHAR(100),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    description     TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_drug_name CHECK (CHAR_LENGTH(brand_name) >= 2)
);

-- ─────────────────────────────────────
-- TABLE 4: INGREDIENTS
-- Active pharmaceutical ingredients
-- Constraints: PK, UNIQUE, NOT NULL
-- ─────────────────────────────────────
CREATE TABLE ingredients (
    ingredient_id   INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(255) UNIQUE NOT NULL,
    cas_number      VARCHAR(50),
    category        VARCHAR(200),
    description     TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────
-- TABLE 5: DRUG_INGREDIENTS (Junction Table)
-- Maps drugs to their ingredient compositions
-- Constraints: Composite PK, FK (CASCADE)
-- ─────────────────────────────────────
CREATE TABLE drug_ingredients (
    drug_id         INT NOT NULL,
    ingredient_id   INT NOT NULL,
    is_active_ingredient BOOLEAN DEFAULT TRUE,
    concentration   VARCHAR(100),
    PRIMARY KEY (drug_id, ingredient_id),
    FOREIGN KEY (drug_id) REFERENCES drugs(drug_id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(ingredient_id) ON DELETE CASCADE
);

-- ─────────────────────────────────────
-- TABLE 6: INGREDIENT_INTERACTIONS
-- Known dangerous interactions between ingredients
-- Constraints: PK, FK, CHECK, UNIQUE pair
-- ─────────────────────────────────────
CREATE TABLE ingredient_interactions (
    interaction_id  INT AUTO_INCREMENT PRIMARY KEY,
    ingredient_a_id INT NOT NULL,
    ingredient_b_id INT NOT NULL,
    severity        ENUM('mild', 'moderate', 'severe', 'contraindicated') NOT NULL,
    clinical_effect TEXT NOT NULL,
    mechanism       TEXT,
    recommendation  TEXT NOT NULL,
    evidence_level  VARCHAR(50),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ingredient_a_id) REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_b_id) REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    CONSTRAINT chk_diff_ingredients CHECK (ingredient_a_id <> ingredient_b_id),
    CONSTRAINT uq_ingredient_pair UNIQUE (ingredient_a_id, ingredient_b_id)
);

-- ─────────────────────────────────────
-- TABLE 7: PRESCRIPTIONS
-- Prescription records linking patients and doctors
-- Constraints: PK, FK, CHECK, NOT NULL
-- ─────────────────────────────────────
CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id      INT NOT NULL,
    doctor_id       INT NOT NULL,
    status          ENUM('draft', 'pending_review', 'approved', 'dispensed', 'cancelled') DEFAULT 'draft',
    diagnosis       TEXT,
    notes           TEXT,
    prescribed_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
);

-- ─────────────────────────────────────
-- TABLE 8: PRESCRIPTION_DRUGS (Junction Table)
-- Drugs assigned to each prescription
-- Constraints: PK, FK (CASCADE), UNIQUE pair
-- ─────────────────────────────────────
CREATE TABLE prescription_drugs (
    pd_id           INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    drug_id         INT NOT NULL,
    dosage          VARCHAR(100) NOT NULL,
    frequency       VARCHAR(100) NOT NULL,
    duration        VARCHAR(100),
    instructions    TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
    FOREIGN KEY (drug_id) REFERENCES drugs(drug_id) ON DELETE RESTRICT,
    CONSTRAINT uq_prescription_drug UNIQUE (prescription_id, drug_id)
);

-- ─────────────────────────────────────
-- TABLE 9: INTERACTION_ALERTS
-- System-generated safety alerts
-- Constraints: PK, FK, NOT NULL
-- ─────────────────────────────────────
CREATE TABLE interaction_alerts (
    alert_id        INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    drug_a_id       INT NOT NULL,
    drug_b_id       INT NOT NULL,
    interaction_id  INT NOT NULL,
    severity        ENUM('mild', 'moderate', 'severe', 'contraindicated') NOT NULL,
    clinical_effect TEXT NOT NULL,
    recommendation  TEXT NOT NULL,
    status          ENUM('active', 'acknowledged', 'overridden', 'resolved') DEFAULT 'active',
    acknowledged_by INT NULL,
    acknowledged_at TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
    FOREIGN KEY (drug_a_id) REFERENCES drugs(drug_id) ON DELETE CASCADE,
    FOREIGN KEY (drug_b_id) REFERENCES drugs(drug_id) ON DELETE CASCADE,
    FOREIGN KEY (interaction_id) REFERENCES ingredient_interactions(interaction_id) ON DELETE CASCADE,
    FOREIGN KEY (acknowledged_by) REFERENCES doctors(doctor_id) ON DELETE SET NULL
);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 2: DATA INSERTION (20+ rows per table)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── PATIENTS (20 records) ─────────────────────
INSERT INTO patients (first_name, last_name, date_of_birth, gender, blood_type, phone, email, allergies, medical_conditions) VALUES
('Alice',    'Thompson',  '1965-03-14', 'Female', 'O+',  '555-0101', 'alice.t@email.com',    'Penicillin, Sulfa drugs',          'Atrial fibrillation, Type 2 Diabetes'),
('Robert',   'Chen',      '1978-09-22', 'Male',   'A+',  '555-0102', 'robert.c@email.com',   'Codeine',                          'Hypertension, Hyperlipidemia'),
('Maria',    'Garcia',    '1990-11-07', 'Female', 'B+',  '555-0103', 'maria.g@email.com',    NULL,                                'Type 2 Diabetes, Recurrent UTI'),
('James',    'Wilson',    '1955-06-18', 'Male',   'AB+', '555-0104', 'james.w@email.com',    'Latex',                             'CHF, Atrial fibrillation'),
('Linda',    'Park',      '1982-01-30', 'Female', 'O-',  '555-0105', 'linda.p@email.com',    NULL,                                'Hypothyroidism, Depression'),
('Michael',  'Brown',     '1970-12-05', 'Male',   'A-',  '555-0106', 'michael.b@email.com',  'Aspirin',                           'Hypertension, Chronic pain'),
('Sarah',    'Johnson',   '1945-08-20', 'Female', 'B-',  '555-0107', 'sarah.j@email.com',    'Morphine, Iodine',                  'Osteoarthritis, Warfarin therapy'),
('David',    'Lee',       '1988-04-12', 'Male',   'O+',  '555-0108', 'david.l@email.com',    NULL,                                'Bipolar disorder, Hypertension'),
('Emma',     'Martinez',  '1975-07-25', 'Female', 'A+',  '555-0109', 'emma.m@email.com',     'Penicillin',                        'Post-MI, Hyperlipidemia'),
('William',  'Taylor',    '1960-11-14', 'Male',   'AB-', '555-0110', 'william.t@email.com',  NULL,                                'DM Type 2, Neuropathy, Depression'),
('Priya',    'Sharma',    '1992-05-03', 'Female', 'B+',  '555-0111', 'priya.s@email.com',    'Shellfish',                         'Asthma'),
('Daniel',   'Kim',       '1968-02-17', 'Male',   'O+',  '555-0112', 'daniel.k@email.com',   NULL,                                'GERD, Hypertension'),
('Sophia',   'Nguyen',    '1985-08-29', 'Female', 'A-',  '555-0113', 'sophia.n@email.com',   'NSAIDs',                            'Rheumatoid arthritis'),
('Ahmed',    'Hassan',    '1973-04-11', 'Male',   'B-',  '555-0114', 'ahmed.h@email.com',    NULL,                                'Chronic kidney disease'),
('Olivia',   'White',     '1998-12-25', 'Female', 'O-',  '555-0115', 'olivia.w@email.com',   NULL,                                'Anxiety, Insomnia'),
('Carlos',   'Rivera',    '1950-09-08', 'Male',   'AB+', '555-0116', 'carlos.r@email.com',   'Sulfonamides',                      'COPD, Heart failure'),
('Grace',    'Patel',     '1987-06-19', 'Female', 'A+',  '555-0117', 'grace.p@email.com',    NULL,                                'Epilepsy'),
('Kenji',    'Tanaka',    '1979-03-21', 'Male',   'B+',  '555-0118', 'kenji.t@email.com',    'Latex, Penicillin',                 'Gout, Hypertension'),
('Hannah',   'Adams',     '1995-10-15', 'Female', 'O+',  '555-0119', 'hannah.a@email.com',   NULL,                                'Migraine'),
('Raj',      'Verma',     '1963-07-07', 'Male',   'A-',  '555-0120', 'raj.v@email.com',      'ACE inhibitors',                    'Diabetes, Coronary artery disease');

-- ─── DOCTORS (5 records) ───────────────────────
INSERT INTO doctors (first_name, last_name, specialization, license_number, department, phone, email) VALUES
('Dr. James',   'Wilson',  'Internal Medicine',  'LIC-2024-001', 'General Medicine', '555-9001', 'dr.wilson@hospital.com'),
('Dr. Sarah',   'Patel',   'Cardiology',         'LIC-2024-002', 'Cardiology',       '555-9002', 'dr.patel@hospital.com'),
('Dr. Emily',   'Nguyen',  'Psychiatry',         'LIC-2024-003', 'Psychiatry',       '555-9003', 'dr.nguyen@hospital.com'),
('Dr. Michael', 'Roberts', 'Endocrinology',      'LIC-2024-004', 'Endocrinology',    '555-9004', 'dr.roberts@hospital.com'),
('Dr. Ananya',  'Desai',   'Family Medicine',    'LIC-2024-005', 'Family Medicine',  '555-9005', 'dr.desai@hospital.com');

-- ─── INGREDIENTS (20 records) ──────────────────
INSERT INTO ingredients (name, cas_number, category) VALUES
('Warfarin Sodium',              '129-06-6',     'Anticoagulant'),
('Aspirin (Acetylsalicylic Acid)','50-78-2',     'NSAID'),
('Ibuprofen',                    '15687-27-1',   'NSAID'),
('Metformin Hydrochloride',      '1115-70-4',    'Biguanide'),
('Lisinopril',                   '83915-83-7',   'ACE Inhibitor'),
('Simvastatin',                  '79902-63-9',   'Statin'),
('Amiodarone Hydrochloride',     '19774-82-4',   'Antiarrhythmic'),
('Fluconazole',                  '86386-73-4',   'Antifungal'),
('Potassium Chloride',           '7447-40-7',    'Electrolyte'),
('Clopidogrel Bisulfate',        '120202-66-6',  'Antiplatelet'),
('Omeprazole',                   '73590-58-6',   'Proton Pump Inhibitor'),
('Ciprofloxacin',                '85721-33-1',   'Fluoroquinolone'),
('Acetaminophen (Paracetamol)',  '103-90-2',     'Analgesic'),
('Naproxen Sodium',              '26159-34-2',   'NSAID'),
('Sertraline Hydrochloride',     '79559-97-0',   'SSRI'),
('Tramadol Hydrochloride',       '36282-47-0',   'Opioid Analgesic'),
('Diazepam',                     '439-14-5',     'Benzodiazepine'),
('Lithium Carbonate',            '554-13-2',     'Mood Stabilizer'),
('Digoxin',                      '20830-75-5',   'Cardiac Glycoside'),
('Metoprolol Succinate',         '98418-47-4',   'Beta Blocker');

-- ─── DRUGS (20 records) ────────────────────────
INSERT INTO drugs (brand_name, generic_name, drug_class, manufacturer, dosage_form, strength) VALUES
('Coumadin',    'Warfarin',             'Anticoagulant',      'Bristol-Myers Squibb', 'Tablet',  '5mg'),
('Bayer Aspirin','Aspirin',             'NSAID/Analgesic',    'Bayer',                'Tablet',  '325mg'),
('Advil',       'Ibuprofen',            'NSAID',              'Pfizer',               'Tablet',  '200mg'),
('Glucophage',  'Metformin',            'Antidiabetic',       'Merck',                'Tablet',  '500mg'),
('Zestril',     'Lisinopril',           'ACE Inhibitor',      'AstraZeneca',          'Tablet',  '10mg'),
('Zocor',       'Simvastatin',          'Statin',             'Merck',                'Tablet',  '20mg'),
('Cordarone',   'Amiodarone',           'Antiarrhythmic',     'Wyeth',                'Tablet',  '200mg'),
('Diflucan',    'Fluconazole',          'Antifungal',         'Pfizer',               'Capsule', '150mg'),
('Plavix',      'Clopidogrel',          'Antiplatelet',       'Sanofi',               'Tablet',  '75mg'),
('Prilosec',    'Omeprazole',           'PPI',                'AstraZeneca',          'Capsule', '20mg'),
('Cipro',       'Ciprofloxacin',        'Antibiotic',         'Bayer',                'Tablet',  '500mg'),
('Tylenol',     'Acetaminophen',        'Analgesic',          'Johnson & Johnson',    'Tablet',  '500mg'),
('Aleve',       'Naproxen',             'NSAID',              'Bayer',                'Tablet',  '220mg'),
('Zoloft',      'Sertraline',           'SSRI',               'Pfizer',               'Tablet',  '50mg'),
('Ultram',      'Tramadol',             'Opioid Analgesic',   'Janssen',              'Tablet',  '50mg'),
('Valium',      'Diazepam',             'Benzodiazepine',     'Roche',                'Tablet',  '5mg'),
('Lithobid',    'Lithium Carbonate',    'Mood Stabilizer',    'ANI Pharma',           'Tablet',  '300mg'),
('Lanoxin',     'Digoxin',              'Cardiac Glycoside',  'GlaxoSmithKline',      'Tablet',  '0.25mg'),
('Toprol-XL',   'Metoprolol',           'Beta Blocker',       'AstraZeneca',          'Tablet',  '50mg'),
('Motrin',      'Ibuprofen',            'NSAID',              'Johnson & Johnson',    'Tablet',  '400mg');

-- ─── DRUG_INGREDIENTS (20 mappings) ────────────
INSERT INTO drug_ingredients (drug_id, ingredient_id, is_active_ingredient, concentration) VALUES
(1,  1,  TRUE, '5mg'),       -- Coumadin → Warfarin
(2,  2,  TRUE, '325mg'),     -- Bayer Aspirin → Aspirin
(3,  3,  TRUE, '200mg'),     -- Advil → Ibuprofen
(4,  4,  TRUE, '500mg'),     -- Glucophage → Metformin
(5,  5,  TRUE, '10mg'),      -- Zestril → Lisinopril
(6,  6,  TRUE, '20mg'),      -- Zocor → Simvastatin
(7,  7,  TRUE, '200mg'),     -- Cordarone → Amiodarone
(8,  8,  TRUE, '150mg'),     -- Diflucan → Fluconazole
(9,  10, TRUE, '75mg'),      -- Plavix → Clopidogrel
(10, 11, TRUE, '20mg'),      -- Prilosec → Omeprazole
(11, 12, TRUE, '500mg'),     -- Cipro → Ciprofloxacin
(12, 13, TRUE, '500mg'),     -- Tylenol → Paracetamol
(13, 14, TRUE, '220mg'),     -- Aleve → Naproxen
(14, 15, TRUE, '50mg'),      -- Zoloft → Sertraline
(15, 16, TRUE, '50mg'),      -- Ultram → Tramadol
(16, 17, TRUE, '5mg'),       -- Valium → Diazepam
(17, 18, TRUE, '300mg'),     -- Lithobid → Lithium
(18, 19, TRUE, '0.25mg'),    -- Lanoxin → Digoxin
(19, 20, TRUE, '50mg'),      -- Toprol-XL → Metoprolol
(20, 3,  TRUE, '400mg');     -- Motrin → Ibuprofen

-- ─── INGREDIENT_INTERACTIONS (20 pairs) ────────
INSERT INTO ingredient_interactions (ingredient_a_id, ingredient_b_id, severity, clinical_effect, mechanism, recommendation, evidence_level) VALUES
-- 1. Warfarin + Aspirin → SEVERE
(1, 2, 'severe',
 'Greatly increased risk of bleeding. Both impair hemostasis.',
 'Warfarin inhibits clotting factors; aspirin inhibits platelet aggregation via COX-1.',
 'Avoid unless clinically essential. Monitor INR closely.', 'established'),

-- 2. Warfarin + Ibuprofen → SEVERE
(1, 3, 'severe',
 'Increased GI bleeding risk and prolonged INR.',
 'Ibuprofen inhibits COX-1/COX-2 and displaces warfarin from albumin.',
 'Use acetaminophen instead. Monitor INR every 3-5 days.', 'established'),

-- 3. Warfarin + Fluconazole → CONTRAINDICATED
(1, 8, 'contraindicated',
 'Fluconazole potently inhibits CYP2C9, dramatically increasing warfarin levels.',
 'CYP2C9 inhibition reduces warfarin metabolism.',
 'Do NOT co-administer. Use alternative antifungal.', 'established'),

-- 4. Warfarin + Amiodarone → SEVERE
(1, 7, 'severe',
 'Amiodarone inhibits warfarin metabolism, increasing INR and bleeding risk.',
 'Amiodarone inhibits CYP2C9 and CYP3A4.',
 'Reduce warfarin dose by 33-50%. Monitor INR weekly.', 'established'),

-- 5. Simvastatin + Amiodarone → SEVERE (myopathy)
(6, 7, 'severe',
 'Increased rhabdomyolysis risk. Amiodarone raises simvastatin levels.',
 'CYP3A4 inhibition prevents simvastatin first-pass metabolism.',
 'Limit simvastatin to 20mg/day with amiodarone.', 'established'),

-- 6. Simvastatin + Fluconazole → CONTRAINDICATED
(6, 8, 'contraindicated',
 'Dramatically increased rhabdomyolysis risk.',
 'CYP3A4 inhibition by fluconazole.',
 'Do NOT co-administer. Suspend simvastatin during fluconazole.', 'established'),

-- 7. Lisinopril + Potassium → MODERATE
(5, 9, 'moderate',
 'Risk of hyperkalemia. ACE inhibitors retain potassium.',
 'ACE inhibitors decrease aldosterone secretion.',
 'Monitor serum potassium within 1 week.', 'established'),

-- 8. Clopidogrel + Omeprazole → MODERATE
(10, 11, 'moderate',
 'Omeprazole reduces clopidogrel activation by up to 45%.',
 'CYP2C19 inhibition decreases clopidogrel conversion.',
 'Use pantoprazole instead. Separate dosing by 12h.', 'established'),

-- 9. Metformin + Ciprofloxacin → MODERATE
(4, 12, 'moderate',
 'Ciprofloxacin may potentiate hypoglycemic effect of metformin.',
 'Fluoroquinolones may stimulate insulin release.',
 'Monitor blood glucose closely. Adjust metformin if needed.', 'case_report'),

-- 10. Aspirin + Ibuprofen → MODERATE
(2, 3, 'moderate',
 'Ibuprofen may block antiplatelet effect of low-dose aspirin.',
 'Competitive COX-1 binding.',
 'Take aspirin 30 min before ibuprofen.', 'established'),

-- 11. Aspirin + Naproxen → MODERATE
(2, 14, 'moderate',
 'Concurrent NSAIDs increase GI bleeding risk and may reduce cardioprotection.',
 'Both inhibit COX enzymes; additive GI toxicity.',
 'Avoid concurrent use. Use one NSAID at a time.', 'established'),

-- 12. Paracetamol + Warfarin → MILD
(1, 13, 'mild',
 'High-dose acetaminophen (>2g/day) may increase INR.',
 'Metabolites may interfere with clotting factor synthesis.',
 'Limit to <2g/day. Monitor INR if used >3 days.', 'established'),

-- 13. Sertraline + Tramadol → SEVERE (serotonin syndrome)
(15, 16, 'severe',
 'Risk of serotonin syndrome: agitation, hyperthermia, tremor.',
 'Both increase serotonergic activity.',
 'Avoid combination. Use alternative analgesic.', 'established'),

-- 14. Sertraline + Warfarin → MODERATE
(1, 15, 'moderate',
 'SSRIs inhibit platelet aggregation and may increase warfarin levels.',
 'Sertraline weakly inhibits CYP2C9.',
 'Monitor INR closely when starting SSRI.', 'established'),

-- 15. Tramadol + Diazepam → SEVERE (respiratory depression)
(16, 17, 'severe',
 'Combined CNS depression: profound sedation, respiratory depression.',
 'Additive CNS depressant effects.',
 'Avoid concurrent use. FDA boxed warning.', 'established'),

-- 16. Lithium + Lisinopril → SEVERE
(5, 18, 'severe',
 'ACE inhibitors reduce lithium clearance, risk of lithium toxicity.',
 'ACE inhibitors reduce GFR.',
 'Reduce lithium dose by 50%. Monitor levels weekly.', 'established'),

-- 17. Digoxin + Amiodarone → SEVERE
(7, 19, 'severe',
 'Amiodarone increases digoxin levels by 70-100%.',
 'Inhibits P-glycoprotein and renal clearance.',
 'Reduce digoxin dose by 50%. Monitor digoxin levels.', 'established'),

-- 18. Aspirin + Clopidogrel → MODERATE (dual antiplatelet)
(2, 10, 'moderate',
 'Dual antiplatelet: increased bleeding risk but may be indicated post-ACS.',
 'Both inhibit platelet aggregation via different mechanisms.',
 'Use only when clinically indicated. Monitor for bleeding.', 'established'),

-- 19. Ciprofloxacin + Warfarin → MODERATE
(1, 12, 'moderate',
 'Ciprofloxacin inhibits CYP1A2, possibly increasing warfarin levels.',
 'CYP1A2 inhibition may reduce R-warfarin metabolism.',
 'Monitor INR every 2-3 days during ciprofloxacin.', 'established'),

-- 20. Ibuprofen + Naproxen → MODERATE
(3, 14, 'moderate',
 'Dual NSAID use greatly increases GI bleeding and renal toxicity.',
 'Additive COX inhibition and GI mucosal damage.',
 'Never use two NSAIDs concurrently.', 'established');

-- ─── PRESCRIPTIONS (10 records) ────────────────
INSERT INTO prescriptions (patient_id, doctor_id, status, diagnosis) VALUES
(1,  2, 'approved',  'Atrial fibrillation management'),
(1,  1, 'approved',  'Type 2 Diabetes routine checkup'),
(2,  2, 'approved',  'Hypertension + Hyperlipidemia'),
(3,  1, 'approved',  'UTI treatment'),
(4,  2, 'approved',  'CHF + AF maintenance'),
(5,  3, 'approved',  'Hypothyroidism + Depression'),
(6,  1, 'approved',  'Chronic pain management'),
(7,  1, 'approved',  'Osteoarthritis + anticoagulation'),
(8,  3, 'approved',  'Bipolar + Hypertension'),
(9,  2, 'approved',  'Post-MI secondary prevention');

-- ─── PRESCRIPTION_DRUGS (multiple drugs per Rx) ─
-- NOTE: We disable the trigger temporarily for bulk insert
--       (trigger is created later in Section 8)
INSERT INTO prescription_drugs (prescription_id, drug_id, dosage, frequency, duration) VALUES
-- Rx 1: Alice → Warfarin + Aspirin (INTERACTION: severe!)
(1, 1, '5mg',   'Once daily',          '90 days'),
(1, 2, '81mg',  'Once daily',          '90 days'),
-- Rx 2: Alice → Metformin + Cipro (INTERACTION: moderate)
(2, 4, '500mg', 'Twice daily',         '30 days'),
(2, 11,'500mg', 'Twice daily',         '7 days'),
-- Rx 3: Robert → Zestril + Zocor
(3, 5, '10mg',  'Once daily',          '90 days'),
(3, 6, '20mg',  'Once daily at bedtime','90 days'),
-- Rx 4: Maria → Metformin + Cipro (INTERACTION: moderate)
(4, 4, '1000mg','Twice daily',         '30 days'),
(4, 11,'500mg', 'Twice daily',         '10 days'),
-- Rx 5: James → Warfarin + Amiodarone + Digoxin (INTERACTION: severe x2!)
(5, 1, '3mg',   'Once daily',          '90 days'),
(5, 7, '200mg', 'Once daily',          '90 days'),
(5, 18,'0.125mg','Once daily',         '90 days'),
-- Rx 6: Linda → Zoloft
(6, 14,'50mg',  'Once daily',          '90 days'),
-- Rx 7: Michael → Tramadol + Ibuprofen
(7, 15,'50mg',  'Every 6 hours PRN',   '14 days'),
(7, 3, '400mg', 'Three times daily',   '7 days'),
-- Rx 8: Sarah → Warfarin + Ibuprofen (INTERACTION: severe!)
(8, 1, '5mg',   'Once daily',          '90 days'),
(8, 3, '400mg', 'Three times daily',   '7 days'),
-- Rx 9: David → Lithium + Lisinopril (INTERACTION: severe!)
(9, 17,'300mg', 'Three times daily',   '90 days'),
(9, 5, '10mg',  'Once daily',          '90 days'),
-- Rx 10: Emma → Plavix + Prilosec + Aspirin (INTERACTION: moderate x2)
(10, 9, '75mg', 'Once daily',          '365 days'),
(10,10, '20mg', 'Once daily',          '90 days'),
(10, 2, '81mg', 'Once daily',          '365 days');

-- Pre-insert some alerts for analytics
INSERT INTO interaction_alerts (prescription_id, drug_a_id, drug_b_id, interaction_id, severity, clinical_effect, recommendation, status) VALUES
(1, 1, 2, 1, 'severe', 'Increased bleeding risk (Warfarin+Aspirin)', 'Monitor INR closely', 'active'),
(2, 4, 11, 9, 'moderate', 'Hypoglycemia risk (Metformin+Cipro)', 'Monitor glucose', 'acknowledged'),
(4, 4, 11, 9, 'moderate', 'Hypoglycemia risk (Metformin+Cipro)', 'Monitor glucose', 'active'),
(5, 1, 7, 4, 'severe', 'Bleeding risk (Warfarin+Amiodarone)', 'Reduce warfarin dose by 33-50%', 'active'),
(5, 7, 18, 17, 'severe', 'Digoxin toxicity (Amiodarone+Digoxin)', 'Reduce digoxin dose by 50%', 'active'),
(8, 1, 3, 2, 'severe', 'GI bleeding risk (Warfarin+Ibuprofen)', 'Use acetaminophen instead', 'active'),
(9, 17, 5, 16, 'severe', 'Lithium toxicity (Lithium+Lisinopril)', 'Reduce lithium dose by 50%', 'active'),
(10, 9, 10, 8, 'moderate', 'Reduced efficacy (Clopidogrel+Omeprazole)', 'Use pantoprazole', 'active'),
(10, 2, 9, 18, 'moderate', 'Dual antiplatelet bleeding (Aspirin+Clopidogrel)', 'Monitor for bleeding', 'active');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 3: JOIN QUERIES (4 queries)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── JOIN 1: INNER JOIN ────────────────────────
-- Show prescriptions with patient and doctor names
-- INNER JOIN returns only matching rows from both tables
SELECT 
    p.prescription_id,
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    CONCAT(d.first_name, ' ', d.last_name)   AS doctor_name,
    p.status,
    p.diagnosis,
    p.prescribed_at
FROM prescriptions p
INNER JOIN patients pt ON p.patient_id = pt.patient_id
INNER JOIN doctors d   ON p.doctor_id  = d.doctor_id
ORDER BY p.prescribed_at DESC;

-- ─── JOIN 2: LEFT JOIN ─────────────────────────
-- Show ALL drugs and their ingredients (including drugs with no mapped ingredient)
-- LEFT JOIN keeps all rows from the left table even if no match on right
SELECT 
    dr.drug_id,
    dr.brand_name,
    dr.generic_name,
    dr.strength,
    i.name AS ingredient_name,
    i.category AS ingredient_category,
    di.concentration
FROM drugs dr
LEFT JOIN drug_ingredients di ON dr.drug_id = di.drug_id
LEFT JOIN ingredients i       ON di.ingredient_id = i.ingredient_id
ORDER BY dr.brand_name;

-- ─── JOIN 3: RIGHT JOIN ────────────────────────
-- Show ALL patients and their prescriptions (including patients with no prescriptions)
-- RIGHT JOIN keeps all rows from the right table
SELECT 
    pt.patient_id,
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    p.prescription_id,
    p.diagnosis,
    p.status
FROM prescriptions p
RIGHT JOIN patients pt ON p.patient_id = pt.patient_id
ORDER BY pt.last_name;

-- ─── JOIN 4: MULTIPLE-TABLE JOIN ───────────────
-- Show dangerous drug interactions detected in prescriptions
-- Joins 6 tables to show complete alert details
SELECT 
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    da.brand_name AS drug_a,
    db.brand_name AS drug_b,
    ia.severity,
    ia.clinical_effect,
    ia.recommendation,
    ia.status AS alert_status,
    CONCAT(doc.first_name, ' ', doc.last_name) AS prescribing_doctor
FROM interaction_alerts ia
INNER JOIN prescriptions p  ON ia.prescription_id = p.prescription_id
INNER JOIN patients pt      ON p.patient_id = pt.patient_id
INNER JOIN doctors doc      ON p.doctor_id = doc.doctor_id
INNER JOIN drugs da         ON ia.drug_a_id = da.drug_id
INNER JOIN drugs db         ON ia.drug_b_id = db.drug_id
ORDER BY 
    FIELD(ia.severity, 'contraindicated', 'severe', 'moderate', 'mild'),
    pt.last_name;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 4: SUBQUERIES / NESTED QUERIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── SUBQUERY 1: ───────────────────────────────
-- Find drugs that contain ingredients involved in SEVERE or CONTRAINDICATED interactions
SELECT drug_id, brand_name, generic_name
FROM drugs
WHERE drug_id IN (
    SELECT di.drug_id
    FROM drug_ingredients di
    WHERE di.ingredient_id IN (
        SELECT ingredient_a_id FROM ingredient_interactions WHERE severity IN ('severe', 'contraindicated')
        UNION
        SELECT ingredient_b_id FROM ingredient_interactions WHERE severity IN ('severe', 'contraindicated')
    )
)
ORDER BY brand_name;

-- ─── SUBQUERY 2: ───────────────────────────────
-- Find patients who have prescriptions with active danger alerts
SELECT patient_id, first_name, last_name, medical_conditions
FROM patients
WHERE patient_id IN (
    SELECT p.patient_id
    FROM prescriptions p
    WHERE p.prescription_id IN (
        SELECT ia.prescription_id 
        FROM interaction_alerts ia 
        WHERE ia.status = 'active' 
          AND ia.severity IN ('severe', 'contraindicated')
    )
);

-- ─── SUBQUERY 3: ───────────────────────────────
-- Find drugs that appear in more than one prescription
SELECT drug_id, brand_name, generic_name,
    (SELECT COUNT(DISTINCT pd.prescription_id) 
     FROM prescription_drugs pd 
     WHERE pd.drug_id = drugs.drug_id) AS prescription_count
FROM drugs
WHERE drug_id IN (
    SELECT pd.drug_id
    FROM prescription_drugs pd
    GROUP BY pd.drug_id
    HAVING COUNT(DISTINCT pd.prescription_id) > 1
)
ORDER BY prescription_count DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 5: VIEWS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── VIEW 1: Dangerous_Prescriptions ───────────
-- Shows prescriptions containing drugs with severe/contraindicated interactions
CREATE OR REPLACE VIEW Dangerous_Prescriptions AS
SELECT 
    p.prescription_id,
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    CONCAT(doc.first_name, ' ', doc.last_name) AS doctor_name,
    da.brand_name AS drug_a,
    db.brand_name AS drug_b,
    ia.severity,
    ia.clinical_effect,
    ia.recommendation,
    ia.status AS alert_status,
    p.prescribed_at
FROM interaction_alerts ia
JOIN prescriptions p  ON ia.prescription_id = p.prescription_id
JOIN patients pt      ON p.patient_id = pt.patient_id
JOIN doctors doc      ON p.doctor_id = doc.doctor_id
JOIN drugs da         ON ia.drug_a_id = da.drug_id
JOIN drugs db         ON ia.drug_b_id = db.drug_id
WHERE ia.severity IN ('severe', 'contraindicated');

-- Query the view:
SELECT * FROM Dangerous_Prescriptions;

-- ─── VIEW 2: Drug_Ingredient_List ──────────────
-- Shows drugs with their complete ingredient compositions
CREATE OR REPLACE VIEW Drug_Ingredient_List AS
SELECT 
    d.drug_id,
    d.brand_name,
    d.generic_name,
    d.drug_class,
    d.strength,
    i.name AS ingredient_name,
    i.category AS ingredient_category,
    di.is_active_ingredient,
    di.concentration
FROM drugs d
JOIN drug_ingredients di ON d.drug_id = di.drug_id
JOIN ingredients i       ON di.ingredient_id = i.ingredient_id
ORDER BY d.brand_name;

-- Query the view:
SELECT * FROM Drug_Ingredient_List;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 6: STORED PROCEDURES (PL/SQL for MySQL)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DELIMITER //

-- ─── PROCEDURE 1: Add a new prescription ───────
CREATE PROCEDURE sp_add_prescription(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_diagnosis TEXT,
    OUT p_prescription_id INT
)
BEGIN
    INSERT INTO prescriptions (patient_id, doctor_id, status, diagnosis)
    VALUES (p_patient_id, p_doctor_id, 'draft', p_diagnosis);
    
    SET p_prescription_id = LAST_INSERT_ID();
    
    SELECT CONCAT('Prescription #', p_prescription_id, ' created successfully') AS result;
END //

-- ─── PROCEDURE 2: Check prescription safety ────
-- Returns all dangerous interactions in a given prescription
CREATE PROCEDURE sp_check_prescription_safety(
    IN p_prescription_id INT
)
BEGIN
    SELECT 
        da.brand_name AS drug_a,
        db.brand_name AS drug_b,
        ii.severity,
        ii.clinical_effect,
        ii.recommendation
    FROM prescription_drugs pd1
    JOIN prescription_drugs pd2 ON pd1.prescription_id = pd2.prescription_id
                                AND pd1.drug_id < pd2.drug_id
    JOIN drug_ingredients di1   ON pd1.drug_id = di1.drug_id
    JOIN drug_ingredients di2   ON pd2.drug_id = di2.drug_id
    JOIN ingredient_interactions ii ON (
        (ii.ingredient_a_id = di1.ingredient_id AND ii.ingredient_b_id = di2.ingredient_id)
        OR
        (ii.ingredient_a_id = di2.ingredient_id AND ii.ingredient_b_id = di1.ingredient_id)
    )
    JOIN drugs da ON pd1.drug_id = da.drug_id
    JOIN drugs db ON pd2.drug_id = db.drug_id
    WHERE pd1.prescription_id = p_prescription_id
    ORDER BY FIELD(ii.severity, 'contraindicated', 'severe', 'moderate', 'mild');
END //

-- ─── PROCEDURE 3: Patient prescription history ─
CREATE PROCEDURE sp_patient_history(
    IN p_patient_id INT
)
BEGIN
    SELECT 
        p.prescription_id,
        p.diagnosis,
        p.status,
        p.prescribed_at,
        CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
        GROUP_CONCAT(dr.brand_name SEPARATOR ', ') AS drugs_prescribed,
        COUNT(ia.alert_id) AS alert_count
    FROM prescriptions p
    JOIN doctors d ON p.doctor_id = d.doctor_id
    LEFT JOIN prescription_drugs pd ON p.prescription_id = pd.prescription_id
    LEFT JOIN drugs dr ON pd.drug_id = dr.drug_id
    LEFT JOIN interaction_alerts ia ON p.prescription_id = ia.prescription_id
    WHERE p.patient_id = p_patient_id
    GROUP BY p.prescription_id, p.diagnosis, p.status, p.prescribed_at, doctor_name
    ORDER BY p.prescribed_at DESC;
END //

DELIMITER ;

-- ─── CALL stored procedures ────────────────────
-- Example 1: Add a new prescription
CALL sp_add_prescription(11, 5, 'Asthma management', @new_rx_id);
SELECT @new_rx_id AS new_prescription_id;

-- Example 2: Check safety of prescription #1 (Warfarin + Aspirin)
CALL sp_check_prescription_safety(1);

-- Example 3: Patient history for Alice (patient_id = 1)
CALL sp_patient_history(1);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 7: CURSORS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- A Cursor is a database object that allows row-by-row processing of query
-- results. Unlike set-based SQL, cursors iterate through records one at a time.
--
-- Cursor Lifecycle:
--   1. DECLARE  — Define the cursor with a SELECT query
--   2. OPEN     — Execute the query and populate the result set
--   3. FETCH    — Retrieve one row at a time
--   4. CLOSE    — Release memory and resources
--
-- Why use cursors:
--   - When row-by-row logic is needed (e.g., complex conditional checks)
--   - When set-based operations cannot express the required logic
--   - For generating reports with custom formatting

DELIMITER //

CREATE PROCEDURE sp_scan_all_prescriptions_for_interactions()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_rx_id INT;
    DECLARE v_patient_name VARCHAR(255);
    DECLARE v_drug_a VARCHAR(255);
    DECLARE v_drug_b VARCHAR(255);
    DECLARE v_severity VARCHAR(20);
    DECLARE v_effect TEXT;
    
    -- Step 1: DECLARE cursor
    DECLARE cur_prescriptions CURSOR FOR
        SELECT DISTINCT p.prescription_id, 
               CONCAT(pt.first_name, ' ', pt.last_name)
        FROM prescriptions p
        JOIN patients pt ON p.patient_id = pt.patient_id
        WHERE p.status = 'approved';
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    -- Create temp table for results
    DROP TEMPORARY TABLE IF EXISTS temp_scan_results;
    CREATE TEMPORARY TABLE temp_scan_results (
        prescription_id INT,
        patient_name VARCHAR(255),
        drug_a VARCHAR(255),
        drug_b VARCHAR(255),
        severity VARCHAR(20),
        clinical_effect TEXT
    );
    
    -- Step 2: OPEN cursor
    OPEN cur_prescriptions;
    
    -- Step 3: FETCH loop
    read_loop: LOOP
        FETCH cur_prescriptions INTO v_rx_id, v_patient_name;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        -- For each prescription, check all drug pairs for interactions
        INSERT INTO temp_scan_results
        SELECT 
            v_rx_id, v_patient_name,
            da.brand_name, db.brand_name,
            ii.severity, ii.clinical_effect
        FROM prescription_drugs pd1
        JOIN prescription_drugs pd2 ON pd1.prescription_id = pd2.prescription_id
                                    AND pd1.drug_id < pd2.drug_id
        JOIN drug_ingredients di1   ON pd1.drug_id = di1.drug_id
        JOIN drug_ingredients di2   ON pd2.drug_id = di2.drug_id
        JOIN ingredient_interactions ii ON (
            (ii.ingredient_a_id = di1.ingredient_id AND ii.ingredient_b_id = di2.ingredient_id)
            OR
            (ii.ingredient_a_id = di2.ingredient_id AND ii.ingredient_b_id = di1.ingredient_id)
        )
        JOIN drugs da ON pd1.drug_id = da.drug_id
        JOIN drugs db ON pd2.drug_id = db.drug_id
        WHERE pd1.prescription_id = v_rx_id;
    END LOOP;
    
    -- Step 4: CLOSE cursor
    CLOSE cur_prescriptions;
    
    -- Display results
    SELECT * FROM temp_scan_results
    ORDER BY FIELD(severity, 'contraindicated', 'severe', 'moderate', 'mild');
    
    DROP TEMPORARY TABLE IF EXISTS temp_scan_results;
END //

DELIMITER ;

-- Run the cursor-based scan:
CALL sp_scan_all_prescriptions_for_interactions();


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 8: TRIGGERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Trigger: Automatically fires AFTER a drug is added to a prescription.
-- It checks all ingredient interactions between the new drug and
-- existing drugs in the same prescription, then inserts an alert
-- into INTERACTION_ALERTS for each dangerous combination found.

DELIMITER //

CREATE TRIGGER trg_check_drug_interactions
AFTER INSERT ON prescription_drugs
FOR EACH ROW
BEGIN
    -- Insert an alert for every interaction found between the newly added drug
    -- and any other drug already in the same prescription
    INSERT INTO interaction_alerts (
        prescription_id, drug_a_id, drug_b_id,
        interaction_id, severity, clinical_effect, recommendation
    )
    SELECT
        NEW.prescription_id,
        LEAST(NEW.drug_id, pd.drug_id),
        GREATEST(NEW.drug_id, pd.drug_id),
        ii.interaction_id,
        ii.severity,
        ii.clinical_effect,
        ii.recommendation
    FROM prescription_drugs pd
    JOIN drug_ingredients di_new      ON di_new.drug_id = NEW.drug_id
    JOIN drug_ingredients di_existing ON di_existing.drug_id = pd.drug_id
    JOIN ingredient_interactions ii ON (
        (ii.ingredient_a_id = di_new.ingredient_id AND ii.ingredient_b_id = di_existing.ingredient_id)
        OR
        (ii.ingredient_a_id = di_existing.ingredient_id AND ii.ingredient_b_id = di_new.ingredient_id)
    )
    WHERE pd.prescription_id = NEW.prescription_id
      AND pd.drug_id != NEW.drug_id;
END //

DELIMITER ;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 9: EXCEPTION HANDLING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Exception handling in MySQL uses DECLARE HANDLER to catch errors
-- during stored procedure execution. This prevents the procedure from
-- crashing and allows graceful error reporting.
--
-- Difference from Triggers:
--   Triggers: React to DATA EVENTS (INSERT/UPDATE/DELETE) automatically
--   Exception Handlers: React to ERRORS during procedure execution
--
-- When to use each:
--   Triggers: For business rule enforcement on data changes
--   Exception Handling: For error recovery in complex procedures

DELIMITER //

CREATE PROCEDURE sp_safe_add_drug_to_prescription(
    IN p_prescription_id INT,
    IN p_drug_id INT,
    IN p_dosage VARCHAR(100),
    IN p_frequency VARCHAR(100),
    IN p_duration VARCHAR(100)
)
BEGIN
    -- Declare error variables
    DECLARE v_error_code INT DEFAULT 0;
    DECLARE v_error_msg TEXT DEFAULT '';
    
    -- Exception handler for duplicate entry (error 1062)
    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        SELECT 'ERROR: This drug is already in the prescription.' AS error_message;
    END;
    
    -- Exception handler for foreign key constraint failure (error 1452)
    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SELECT 'ERROR: Invalid prescription_id or drug_id. Record not found.' AS error_message;
    END;
    
    -- General exception handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_code = MYSQL_ERRNO,
            v_error_msg = MESSAGE_TEXT;
        SELECT CONCAT('ERROR (', v_error_code, '): ', v_error_msg) AS error_message;
    END;
    
    -- Attempt the insert (trigger will auto-check interactions!)
    INSERT INTO prescription_drugs (prescription_id, drug_id, dosage, frequency, duration)
    VALUES (p_prescription_id, p_drug_id, p_dosage, p_frequency, p_duration);
    
    SELECT CONCAT('Drug #', p_drug_id, ' added to prescription #', p_prescription_id, 
                  '. Check interaction_alerts for any warnings.') AS success_message;
    
    -- Show any alerts generated by the trigger
    SELECT * FROM interaction_alerts 
    WHERE prescription_id = p_prescription_id 
    ORDER BY alert_id DESC LIMIT 5;
END //

DELIMITER ;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 10: PROJECT-SPECIFIC SQL DEMO WORKFLOW
-- Run these steps live during your demonstration
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─── STEP 1: Insert a new patient ──────────────
INSERT INTO patients (first_name, last_name, date_of_birth, gender, blood_type, phone, email, medical_conditions)
VALUES ('Demo', 'Patient', '1980-05-15', 'Male', 'A+', '555-DEMO', 'demo@test.com', 'Atrial flutter, Fungal infection');

SET @demo_patient_id = LAST_INSERT_ID();
SELECT CONCAT('✅ Step 1: Patient created (ID = ', @demo_patient_id, ')') AS step_1;

-- ─── STEP 2: Create a prescription ─────────────
CALL sp_add_prescription(@demo_patient_id, 1, 'Atrial flutter + Fungal infection treatment', @demo_rx_id);
SELECT CONCAT('✅ Step 2: Prescription created (ID = ', @demo_rx_id, ')') AS step_2;

-- ─── STEP 3: Add first drug (Warfarin) — no interaction yet
CALL sp_safe_add_drug_to_prescription(@demo_rx_id, 1, '5mg', 'Once daily', '90 days');
SELECT '✅ Step 3: Warfarin added — no alerts expected' AS step_3;

-- Verify: no alerts yet
SELECT * FROM interaction_alerts WHERE prescription_id = @demo_rx_id;

-- ─── STEP 4: Add second drug (Diflucan/Fluconazole) — TRIGGER fires!
-- This should automatically generate a CONTRAINDICATED alert
CALL sp_safe_add_drug_to_prescription(@demo_rx_id, 8, '150mg', 'Once', '1 day');
SELECT '⚠️ Step 4: Fluconazole added — TRIGGER should detect CONTRAINDICATED interaction!' AS step_4;

-- ─── STEP 5: Query the alerts generated by the trigger
SELECT 
    ia.alert_id,
    da.brand_name AS drug_a,
    db.brand_name AS drug_b,
    ia.severity,
    ia.clinical_effect,
    ia.recommendation,
    ia.status
FROM interaction_alerts ia
JOIN drugs da ON ia.drug_a_id = da.drug_id
JOIN drugs db ON ia.drug_b_id = db.drug_id
WHERE ia.prescription_id = @demo_rx_id
ORDER BY ia.alert_id DESC;

SELECT '✅ Step 5: Alert query complete — system detected dangerous Warfarin + Fluconazole interaction!' AS step_5;

-- ─── BONUS: Check full prescription safety
CALL sp_check_prescription_safety(@demo_rx_id);

-- ─── BONUS: Show view of all dangerous prescriptions
SELECT * FROM Dangerous_Prescriptions;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 11: RELATIONAL ALGEBRA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- Relational Algebra is a procedural query language that operates on
-- relations (tables) and produces new relations as output. It provides
-- the theoretical foundation for SQL.
--
-- ═══════════════════════════════════════════════
-- OPERATION 1: SELECTION (σ)
-- ═══════════════════════════════════════════════
-- Filters rows (tuples) that satisfy a given predicate.
-- Notation: σ_condition(Relation)
--
-- Example: Find all SEVERE ingredient interactions
--   σ_{severity = 'severe'}(ingredient_interactions)
--
-- SQL equivalent:
SELECT * FROM ingredient_interactions WHERE severity = 'severe';
--
-- ═══════════════════════════════════════════════
-- OPERATION 2: PROJECTION (π)
-- ═══════════════════════════════════════════════
-- Selects specific columns (attributes) from a relation.
-- Notation: π_{attr1, attr2}(Relation)
--
-- Example: Get only brand names and drug classes
--   π_{brand_name, drug_class}(drugs)
--
-- SQL equivalent:
SELECT DISTINCT brand_name, drug_class FROM drugs;
--
-- ═══════════════════════════════════════════════
-- OPERATION 3: JOIN (⋈)
-- ═══════════════════════════════════════════════
-- Combines tuples from two relations based on a matching condition.
-- Notation: R ⋈_{R.a = S.b} S   (theta join)
--           R ⋈ S                (natural join)
--
-- Example: Join prescriptions with patient names
--   prescriptions ⋈_{prescriptions.patient_id = patients.patient_id} patients
--
-- SQL equivalent:
SELECT p.prescription_id, pt.first_name, pt.last_name, p.diagnosis
FROM prescriptions p
JOIN patients pt ON p.patient_id = pt.patient_id;
--
-- ═══════════════════════════════════════════════
-- OPERATION 4: UNION (∪)
-- ═══════════════════════════════════════════════
-- Combines tuples from two union-compatible relations, removing duplicates.
-- Notation: R ∪ S
--
-- Example: Find all ingredient IDs involved in any interaction
--   π_{ingredient_a_id}(ingredient_interactions) ∪ π_{ingredient_b_id}(ingredient_interactions)
--
-- SQL equivalent:
SELECT ingredient_a_id AS ingredient_id FROM ingredient_interactions
UNION
SELECT ingredient_b_id FROM ingredient_interactions;
--
-- ═══════════════════════════════════════════════
-- OPERATION 5: DIVISION (÷)
-- ═══════════════════════════════════════════════
-- Finds tuples in R that are associated with ALL tuples in S.
-- Notation: R ÷ S
--
-- Example: Find patients who have been prescribed ALL of {Warfarin, Aspirin}
-- (i.e., patients whose set of prescribed drugs is a superset of {1, 2})
--
-- Division is not directly supported in SQL but can be simulated:
SELECT pt.first_name, pt.last_name
FROM patients pt
WHERE NOT EXISTS (
    -- "For each required drug, check that this patient has been prescribed it"
    SELECT drug_id FROM (SELECT 1 AS drug_id UNION SELECT 2) AS required_drugs
    WHERE drug_id NOT IN (
        SELECT pd.drug_id
        FROM prescriptions p
        JOIN prescription_drugs pd ON p.prescription_id = pd.prescription_id
        WHERE p.patient_id = pt.patient_id
    )
);
--
-- ═══════════════════════════════════════════════
-- COMBINED RA EXPRESSION 1: Finding Dangerous Prescriptions
-- ═══════════════════════════════════════════════
-- π_{patient_name, drug_a, drug_b, severity}(
--     σ_{severity ∈ {'severe','contraindicated'}}(
--         interaction_alerts ⋈ prescriptions ⋈ patients ⋈ drugs
--     )
-- )
--
-- SQL equivalent:
SELECT CONCAT(pt.first_name,' ',pt.last_name) AS patient_name,
       da.brand_name AS drug_a, db.brand_name AS drug_b, ia.severity
FROM interaction_alerts ia
JOIN prescriptions p ON ia.prescription_id = p.prescription_id
JOIN patients pt     ON p.patient_id = pt.patient_id
JOIN drugs da        ON ia.drug_a_id = da.drug_id
JOIN drugs db        ON ia.drug_b_id = db.drug_id
WHERE ia.severity IN ('severe', 'contraindicated');
--
-- ═══════════════════════════════════════════════
-- COMBINED RA EXPRESSION 2: Drugs containing a specific ingredient
-- ═══════════════════════════════════════════════
-- π_{brand_name, generic_name}(
--     drugs ⋈ (σ_{name = 'Warfarin Sodium'}(ingredients) ⋈ drug_ingredients)
-- )
--
-- SQL equivalent:
SELECT d.brand_name, d.generic_name
FROM drugs d
JOIN drug_ingredients di ON d.drug_id = di.drug_id
JOIN ingredients i ON di.ingredient_id = i.ingredient_id
WHERE i.name = 'Warfarin Sodium';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 12: TUPLE RELATIONAL CALCULUS (TRC)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- Tuple Relational Calculus is a NON-PROCEDURAL (declarative) query
-- language. Unlike Relational Algebra which specifies HOW to get data,
-- TRC specifies WHAT data to retrieve.
--
-- General form: { t | P(t) }
-- Reads as: "The set of all tuples t such that predicate P(t) is true"
--
-- ═══════════════════════════════════════════════
-- TRC EXPRESSION 1: Finding patients with prescriptions
-- ═══════════════════════════════════════════════
--
--   { t | t ∈ patients ∧ ∃p ∈ prescriptions (p.patient_id = t.patient_id) }
--
-- English: "The set of all patient tuples t such that there exists
--           a prescription tuple p where p's patient_id equals t's patient_id"
--
-- SQL equivalent:
SELECT pt.*
FROM patients pt
WHERE EXISTS (
    SELECT 1 FROM prescriptions p WHERE p.patient_id = pt.patient_id
);
--
-- ═══════════════════════════════════════════════
-- TRC EXPRESSION 2: Drugs with dangerous ingredient interactions
-- ═══════════════════════════════════════════════
--
--   { t | t ∈ drugs ∧ ∃di ∈ drug_ingredients ∧ ∃ii ∈ ingredient_interactions (
--       di.drug_id = t.drug_id ∧
--       (di.ingredient_id = ii.ingredient_a_id ∨ di.ingredient_id = ii.ingredient_b_id) ∧
--       ii.severity ∈ {'severe', 'contraindicated'}
--   )}
--
-- English: "The set of all drug tuples t such that there exists a
--           drug_ingredient linking to an ingredient_interaction
--           where the severity is severe or contraindicated"
--
-- SQL equivalent:
SELECT DISTINCT d.drug_id, d.brand_name, d.generic_name
FROM drugs d
WHERE EXISTS (
    SELECT 1
    FROM drug_ingredients di
    JOIN ingredient_interactions ii ON (
        di.ingredient_id = ii.ingredient_a_id OR di.ingredient_id = ii.ingredient_b_id
    )
    WHERE di.drug_id = d.drug_id
      AND ii.severity IN ('severe', 'contraindicated')
);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- END OF COMPLETE DEMO SCRIPT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
