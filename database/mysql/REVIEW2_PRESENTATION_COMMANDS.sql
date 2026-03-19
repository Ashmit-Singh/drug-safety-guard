-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  DRUG SAFETY GUARD — MINI PROJECT REVIEW 2 — PRESENTATION COMMANDS        ║
-- ║  PBL II – Review 2 (15 Marks) | Lab Exp 4-6 (5 Marks)                     ║
-- ║  Review Period: 18.03.2026 – 25.03.2026                                   ║
-- ╠══════════════════════════════════════════════════════════════════════════════╣
-- ║  TASK 1: DML, Constraints, Sets                                           ║
-- ║  TASK 2: Subqueries, Joins, Views                                         ║
-- ║  TASK 3: Functions, Triggers, Cursors, Exception Handling                 ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ▶ Run drug_safety_demo.sql FIRST to set up the database, then run these demos.
USE drug_safety_db;


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                                                                            ║
-- ║   TASK 1:  DML + CONSTRAINTS + SETS                                        ║
-- ║                                                                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1.1  DML — SELECT (Basic Queries)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ► Show all patients
SELECT * FROM patients;

-- ► Show all drugs in catalog
SELECT * FROM drugs;

-- ► Show all known ingredient interactions
SELECT * FROM ingredient_interactions;

-- ► Filtered query: Find SEVERE and CONTRAINDICATED interactions only
SELECT 
    i1.name AS Ingredient_A, 
    i2.name AS Ingredient_B,
    ii.severity, 
    ii.clinical_effect
FROM ingredient_interactions ii
JOIN ingredients i1 ON ii.ingredient_a_id = i1.ingredient_id
JOIN ingredients i2 ON ii.ingredient_b_id = i2.ingredient_id
WHERE ii.severity IN ('severe', 'contraindicated')
ORDER BY FIELD(ii.severity, 'contraindicated', 'severe');

-- ► GROUP BY + Aggregate: Count alerts per severity level
SELECT severity, COUNT(*) AS total_alerts
FROM interaction_alerts
GROUP BY severity
ORDER BY FIELD(severity, 'contraindicated', 'severe', 'moderate', 'mild');

-- ► GROUP BY + HAVING: Patients with more than 1 alert
SELECT 
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    COUNT(ia.alert_id) AS total_alerts
FROM patients pt
JOIN prescriptions p ON pt.patient_id = p.patient_id
JOIN interaction_alerts ia ON p.prescription_id = ia.prescription_id
GROUP BY pt.patient_id, pt.first_name, pt.last_name
HAVING COUNT(ia.alert_id) > 1
ORDER BY total_alerts DESC;

-- ► ORDER BY: Drugs sorted alphabetically by generic name
SELECT drug_id, brand_name, generic_name, drug_class
FROM drugs
ORDER BY generic_name ASC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1.2  DML — INSERT (Adding new records)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ► Insert a new patient
INSERT INTO patients (first_name, last_name, date_of_birth, gender, blood_type, phone, email, medical_conditions)
VALUES ('Review', 'DemoPatient', '1990-01-15', 'Male', 'O+', '555-RVDM', 'review.demo@test.com', 'Hypertension');
SELECT * FROM patients WHERE phone = '555-RVDM';

-- ► Insert a new drug
INSERT INTO drugs (brand_name, generic_name, drug_class, manufacturer, dosage_form, strength)
VALUES ('DemoMed', 'Demozole', 'Test Class', 'TestPharm', 'Tablet', '10mg');
SELECT * FROM drugs WHERE brand_name = 'DemoMed';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1.3  DML — UPDATE (Modifying records)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ► Update patient allergy info
UPDATE patients SET allergies = 'Sulfa drugs' WHERE phone = '555-RVDM';
SELECT first_name, last_name, allergies FROM patients WHERE phone = '555-RVDM';

-- ► Update alert status from active to acknowledged
UPDATE interaction_alerts SET status = 'acknowledged' WHERE alert_id = 1;
SELECT alert_id, severity, status FROM interaction_alerts WHERE alert_id = 1;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1.4  DML — DELETE (Removing records)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ► Delete the demo drug we inserted
DELETE FROM drugs WHERE brand_name = 'DemoMed';
SELECT * FROM drugs WHERE brand_name = 'DemoMed';  -- Should return empty

-- ► Delete the demo patient (CASCADE will remove their prescriptions too)
DELETE FROM patients WHERE phone = '555-RVDM';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1.5  CONSTRAINTS DEMO
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ► Show table structure with constraints
SHOW CREATE TABLE patients;
SHOW CREATE TABLE drugs;
SHOW CREATE TABLE ingredient_interactions;
SHOW CREATE TABLE prescription_drugs;

-- ► ENTITY INTEGRITY: All tables have AUTO_INCREMENT PRIMARY KEYs
DESCRIBE patients;
DESCRIBE drugs;

-- ► NOT NULL constraint: This will FAIL
-- INSERT INTO patients (first_name) VALUES ('OnlyFirstName');

-- ► UNIQUE constraint: Duplicate phone number will FAIL
-- INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone)
-- VALUES ('Test','User','2000-01-01','Male','555-0101');

-- ► CHECK constraint: Future date of birth will FAIL
-- INSERT INTO patients (first_name, last_name, date_of_birth, gender)
-- VALUES ('Future','Baby','2030-01-01','Male');

-- ► CHECK constraint: Drug name too short will FAIL
-- INSERT INTO drugs (brand_name, generic_name) VALUES ('X', 'TooShort');

-- ► FOREIGN KEY (RESTRICT): Cannot delete a drug used in prescriptions
-- DELETE FROM drugs WHERE drug_id = 1;  -- FAILS: ON DELETE RESTRICT

-- ► FOREIGN KEY (CASCADE): Deleting a prescription cascades to prescription_drugs
-- (Demonstrated via the cascade behavior in patient delete above)

-- ► REFERENTIAL INTEGRITY: Self-referencing check prevents same ingredient pair
-- INSERT INTO ingredient_interactions (ingredient_a_id, ingredient_b_id, severity, clinical_effect, recommendation)
-- VALUES (1, 1, 'mild', 'Self interaction', 'N/A');  -- FAILS: chk_diff_ingredients


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1.6  SET OPERATIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ► UNION: All unique ingredient IDs involved in ANY interaction (from both sides)
SELECT ingredient_a_id AS ingredient_id FROM ingredient_interactions
UNION
SELECT ingredient_b_id FROM ingredient_interactions;

-- ► UNION ALL (with duplicates): All ingredient IDs (shows frequency)
SELECT ingredient_a_id AS ingredient_id, 'Side A' AS source FROM ingredient_interactions
UNION ALL
SELECT ingredient_b_id, 'Side B' FROM ingredient_interactions
ORDER BY ingredient_id;

-- ► UNION to combine drug info from different sources
SELECT brand_name, 'Prescribed' AS category FROM drugs
WHERE drug_id IN (SELECT DISTINCT drug_id FROM prescription_drugs)
UNION
SELECT brand_name, 'Never Prescribed' FROM drugs
WHERE drug_id NOT IN (SELECT DISTINCT drug_id FROM prescription_drugs);

-- ► INTERSECT equivalent (MySQL): Drugs that are BOTH prescribed AND have interactions
SELECT DISTINCT d.drug_id, d.brand_name
FROM drugs d
WHERE d.drug_id IN (SELECT DISTINCT drug_id FROM prescription_drugs)
  AND d.drug_id IN (
    SELECT di.drug_id FROM drug_ingredients di
    WHERE di.ingredient_id IN (
        SELECT ingredient_a_id FROM ingredient_interactions
        UNION SELECT ingredient_b_id FROM ingredient_interactions
    )
);

-- ► EXCEPT/MINUS equivalent (MySQL): Drugs prescribed but with NO known interactions
SELECT d.drug_id, d.brand_name, d.generic_name
FROM drugs d
WHERE d.drug_id IN (SELECT DISTINCT drug_id FROM prescription_drugs)
  AND d.drug_id NOT IN (
    SELECT di.drug_id FROM drug_ingredients di
    WHERE di.ingredient_id IN (
        SELECT ingredient_a_id FROM ingredient_interactions
        UNION SELECT ingredient_b_id FROM ingredient_interactions
    )
);


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                                                                            ║
-- ║   TASK 2:  SUBQUERIES + JOINS + VIEWS                                      ║
-- ║                                                                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2.1  SUBQUERIES / NESTED QUERIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ► Subquery with IN: Drugs containing dangerous ingredients
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

-- ► Subquery with EXISTS: Patients who have active severe alerts
SELECT patient_id, first_name, last_name, medical_conditions
FROM patients pt
WHERE EXISTS (
    SELECT 1 FROM prescriptions p
    JOIN interaction_alerts ia ON p.prescription_id = ia.prescription_id
    WHERE p.patient_id = pt.patient_id
      AND ia.status = 'active'
      AND ia.severity IN ('severe', 'contraindicated')
);

-- ► Correlated Subquery: Each drug with its prescription count
SELECT drug_id, brand_name, generic_name,
    (SELECT COUNT(DISTINCT pd.prescription_id) 
     FROM prescription_drugs pd 
     WHERE pd.drug_id = d.drug_id) AS times_prescribed
FROM drugs d
HAVING times_prescribed > 0
ORDER BY times_prescribed DESC;

-- ► Nested Subquery (3 levels): Patients with prescriptions containing dangerous drugs
SELECT patient_id, first_name, last_name
FROM patients
WHERE patient_id IN (
    SELECT p.patient_id FROM prescriptions p
    WHERE p.prescription_id IN (
        SELECT pd.prescription_id FROM prescription_drugs pd
        WHERE pd.drug_id IN (
            SELECT di.drug_id FROM drug_ingredients di
            JOIN ingredient_interactions ii ON di.ingredient_id = ii.ingredient_a_id
            WHERE ii.severity = 'contraindicated'
        )
    )
);

-- ► Subquery in FROM clause: Average alerts per prescription
SELECT AVG(alert_count) AS avg_alerts_per_prescription
FROM (
    SELECT p.prescription_id, COUNT(ia.alert_id) AS alert_count
    FROM prescriptions p
    LEFT JOIN interaction_alerts ia ON p.prescription_id = ia.prescription_id
    GROUP BY p.prescription_id
) AS prescription_alerts;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2.2  JOIN OPERATIONS (4 Types)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ► INNER JOIN: Prescriptions with patient and doctor names
--   Only returns matching rows from both tables
SELECT 
    p.prescription_id,
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    CONCAT(d.first_name, ' ', d.last_name)   AS doctor_name,
    p.status, p.diagnosis
FROM prescriptions p
INNER JOIN patients pt ON p.patient_id = pt.patient_id
INNER JOIN doctors d   ON p.doctor_id  = d.doctor_id
ORDER BY p.prescribed_at DESC;

-- ► LEFT JOIN: All drugs with ingredients (including drugs with no ingredient mapping)
--   Keeps all rows from LEFT table even if no match on right
SELECT 
    dr.drug_id, dr.brand_name, dr.generic_name, dr.strength,
    i.name AS ingredient_name, i.category AS ingredient_category
FROM drugs dr
LEFT JOIN drug_ingredients di ON dr.drug_id = di.drug_id
LEFT JOIN ingredients i       ON di.ingredient_id = i.ingredient_id
ORDER BY dr.brand_name;

-- ► RIGHT JOIN: All patients including those WITHOUT any prescriptions
--   Keeps all rows from RIGHT table
SELECT 
    pt.patient_id,
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    p.prescription_id, p.diagnosis, p.status
FROM prescriptions p
RIGHT JOIN patients pt ON p.patient_id = pt.patient_id
ORDER BY pt.last_name;

-- ► MULTI-TABLE JOIN (6 Tables): Complete alert details with all relationships
--   Joins interaction_alerts → prescriptions → patients → doctors → drugs (x2)
SELECT 
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    CONCAT(doc.first_name, ' ', doc.last_name) AS doctor_name,
    da.brand_name AS drug_a,
    db.brand_name AS drug_b,
    ia.severity,
    ia.clinical_effect,
    ia.recommendation,
    ia.status AS alert_status
FROM interaction_alerts ia
INNER JOIN prescriptions p  ON ia.prescription_id = p.prescription_id
INNER JOIN patients pt      ON p.patient_id = pt.patient_id
INNER JOIN doctors doc      ON p.doctor_id = doc.doctor_id
INNER JOIN drugs da         ON ia.drug_a_id = da.drug_id
INNER JOIN drugs db         ON ia.drug_b_id = db.drug_id
ORDER BY FIELD(ia.severity, 'contraindicated', 'severe', 'moderate', 'mild'), pt.last_name;

-- ► SELF-JOIN concept: Finding all drug pairs from the same prescription
SELECT 
    pd1.prescription_id,
    d1.brand_name AS drug_1,
    d2.brand_name AS drug_2
FROM prescription_drugs pd1
JOIN prescription_drugs pd2 ON pd1.prescription_id = pd2.prescription_id
                            AND pd1.drug_id < pd2.drug_id
JOIN drugs d1 ON pd1.drug_id = d1.drug_id
JOIN drugs d2 ON pd2.drug_id = d2.drug_id
ORDER BY pd1.prescription_id;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2.3  VIEWS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ► VIEW 1: Dangerous Prescriptions (severe/contraindicated alerts)
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

-- ► VIEW 2: Drug-Ingredient Catalog (complete composition)
CREATE OR REPLACE VIEW Drug_Ingredient_Catalog AS
SELECT 
    d.drug_id, d.brand_name, d.generic_name, d.drug_class, d.strength,
    i.name AS ingredient_name, i.category AS ingredient_category,
    di.is_active_ingredient, di.concentration
FROM drugs d
JOIN drug_ingredients di ON d.drug_id = di.drug_id
JOIN ingredients i       ON di.ingredient_id = i.ingredient_id
ORDER BY d.brand_name;

-- Query the view:
SELECT * FROM Drug_Ingredient_Catalog;

-- ► VIEW 3: Patient Prescription Summary (comprehensive overview)
CREATE OR REPLACE VIEW Patient_Prescription_Summary AS
SELECT 
    CONCAT(pt.first_name, ' ', pt.last_name) AS patient_name,
    p.prescription_id,
    CONCAT(doc.first_name, ' ', doc.last_name) AS doctor_name,
    p.diagnosis, p.status,
    GROUP_CONCAT(d.brand_name SEPARATOR ', ') AS drugs_prescribed,
    (SELECT COUNT(*) FROM interaction_alerts ia WHERE ia.prescription_id = p.prescription_id) AS alert_count
FROM patients pt
JOIN prescriptions p    ON pt.patient_id = p.patient_id
JOIN doctors doc        ON p.doctor_id = doc.doctor_id
LEFT JOIN prescription_drugs pd ON p.prescription_id = pd.prescription_id
LEFT JOIN drugs d       ON pd.drug_id = d.drug_id
GROUP BY pt.first_name, pt.last_name, p.prescription_id, doc.first_name, doc.last_name, p.diagnosis, p.status;

-- Query the view:
SELECT * FROM Patient_Prescription_Summary;


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                                                                            ║
-- ║   TASK 3:  FUNCTIONS + TRIGGERS + CURSORS + EXCEPTION HANDLING             ║
-- ║                                                                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3.1  STORED PROCEDURES / FUNCTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ──────────────────────────────────────────────────
-- PROCEDURE 1: sp_add_prescription
-- Purpose: Creates a new prescription and returns the ID
-- Concepts: IN/OUT parameters, LAST_INSERT_ID()
-- ──────────────────────────────────────────────────
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS sp_add_prescription(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_diagnosis TEXT,
    OUT p_prescription_id INT
)
BEGIN
    INSERT INTO prescriptions (patient_id, doctor_id, status, diagnosis)
    VALUES (p_patient_id, p_doctor_id, 'draft', p_diagnosis);
    SET p_prescription_id = LAST_INSERT_ID();
    SELECT CONCAT('✅ Prescription #', p_prescription_id, ' created successfully') AS result;
END //
DELIMITER ;

-- ► Demo: Create a new prescription
CALL sp_add_prescription(1, 2, 'Demo - Review presentation', @new_rx_id);
SELECT @new_rx_id AS new_prescription_id;


-- ──────────────────────────────────────────────────
-- PROCEDURE 2: sp_check_prescription_safety
-- Purpose: Checks a prescription for all dangerous drug interactions
-- Concepts: Multi-table JOIN within procedure, IN parameter
-- ──────────────────────────────────────────────────
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS sp_check_prescription_safety(
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
DELIMITER ;

-- ► Demo: Check prescription #1 (Alice: Warfarin + Aspirin)
CALL sp_check_prescription_safety(1);


-- ──────────────────────────────────────────────────
-- PROCEDURE 3: sp_patient_history
-- Purpose: Gets complete prescription history for a patient
-- Concepts: GROUP_CONCAT, LEFT JOIN, aggregate in subquery
-- ──────────────────────────────────────────────────
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS sp_patient_history(
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

-- ► Demo: Alice's prescription history (patient_id = 1)
CALL sp_patient_history(1);

-- ► Demo: James Wilson's history (patient_id = 4) — shows multiple interactions
CALL sp_patient_history(4);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3.2  TRIGGERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- The trigger `trg_check_drug_interactions` was already created in the
-- main demo script. It fires AFTER INSERT on prescription_drugs and
-- automatically generates interaction alerts.

-- ► Show the trigger definition:
SHOW TRIGGERS LIKE 'prescription_drugs';

-- ► TRIGGER LIVE DEMO — Watch it fire in real-time!

-- Step 1: Create a new demo patient
INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, email, medical_conditions)
VALUES ('Trigger', 'DemoPatient', '1985-05-15', 'Male', '555-TRIG', 'trigger.demo@test.com', 'AF + Fungal infection');
SET @trig_patient = LAST_INSERT_ID();
SELECT CONCAT('✅ Demo patient created (ID = ', @trig_patient, ')') AS step_1;

-- Step 2: Create a prescription for this patient
CALL sp_add_prescription(@trig_patient, 1, 'Trigger demo — AF + Fungal', @trig_rx);
SELECT CONCAT('✅ Prescription created (ID = ', @trig_rx, ')') AS step_2;

-- Step 3: Add Warfarin — NO alert expected
INSERT INTO prescription_drugs (prescription_id, drug_id, dosage, frequency, duration)
VALUES (@trig_rx, 1, '5mg', 'Once daily', '90 days');
SELECT '✅ Step 3: Warfarin added — checking alerts...' AS step_3;
SELECT * FROM interaction_alerts WHERE prescription_id = @trig_rx;
-- ↑ Should return EMPTY — no interaction yet

-- Step 4: Add Fluconazole — TRIGGER FIRES! CONTRAINDICATED interaction detected!
INSERT INTO prescription_drugs (prescription_id, drug_id, dosage, frequency, duration)
VALUES (@trig_rx, 8, '150mg', 'Once', '1 day');
SELECT '⚠️ Step 4: Fluconazole added — TRIGGER should fire!' AS step_4;

-- Step 5: Verify the auto-generated alert
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
WHERE ia.prescription_id = @trig_rx
ORDER BY ia.alert_id DESC;
-- ↑ Should show: Coumadin + Diflucan → CONTRAINDICATED

SELECT '✅ Step 5: TRIGGER successfully detected Warfarin + Fluconazole = CONTRAINDICATED!' AS result;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3.3  CURSORS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- A Cursor allows ROW-BY-ROW processing of query results.
-- Lifecycle: DECLARE → OPEN → FETCH (in loop) → CLOSE
-- Used when set-based SQL cannot express complex row-level logic.

DELIMITER //

CREATE PROCEDURE IF NOT EXISTS sp_scan_all_prescriptions_for_interactions()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_rx_id INT;
    DECLARE v_patient_name VARCHAR(255);
    
    -- STEP 1: DECLARE the cursor
    DECLARE cur_prescriptions CURSOR FOR
        SELECT DISTINCT p.prescription_id, 
               CONCAT(pt.first_name, ' ', pt.last_name)
        FROM prescriptions p
        JOIN patients pt ON p.patient_id = pt.patient_id
        WHERE p.status = 'approved';
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    -- Create temp table for accumulating results
    DROP TEMPORARY TABLE IF EXISTS temp_scan_results;
    CREATE TEMPORARY TABLE temp_scan_results (
        prescription_id INT,
        patient_name VARCHAR(255),
        drug_a VARCHAR(255),
        drug_b VARCHAR(255),
        severity VARCHAR(20),
        clinical_effect TEXT
    );
    
    -- STEP 2: OPEN the cursor
    OPEN cur_prescriptions;
    
    -- STEP 3: FETCH rows one by one in a loop
    read_loop: LOOP
        FETCH cur_prescriptions INTO v_rx_id, v_patient_name;
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        -- For each prescription, find all drug interaction pairs
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
    
    -- STEP 4: CLOSE the cursor
    CLOSE cur_prescriptions;
    
    -- Display all results sorted by severity
    SELECT * FROM temp_scan_results
    ORDER BY FIELD(severity, 'contraindicated', 'severe', 'moderate', 'mild');
    
    DROP TEMPORARY TABLE IF EXISTS temp_scan_results;
END //

DELIMITER ;

-- ► Demo: Run the cursor-based scan across ALL prescriptions
CALL sp_scan_all_prescriptions_for_interactions();


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3.4  EXCEPTION HANDLING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DECLARE HANDLER catches errors during procedure execution.
-- Difference from Triggers:
--   Triggers → react to DATA EVENTS (INSERT/UPDATE/DELETE)
--   Exception Handling → react to RUNTIME ERRORS
-- Use Triggers for business rules; Handlers for error recovery.

DELIMITER //

CREATE PROCEDURE IF NOT EXISTS sp_safe_add_drug_to_prescription(
    IN p_prescription_id INT,
    IN p_drug_id INT,
    IN p_dosage VARCHAR(100),
    IN p_frequency VARCHAR(100),
    IN p_duration VARCHAR(100)
)
BEGIN
    DECLARE v_error_code INT DEFAULT 0;
    DECLARE v_error_msg TEXT DEFAULT '';
    
    -- Handler 1: Duplicate entry (MySQL Error 1062)
    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        SELECT '❌ ERROR: This drug is ALREADY in this prescription.' AS error_message;
    END;
    
    -- Handler 2: Foreign key violation (MySQL Error 1452)
    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SELECT '❌ ERROR: Invalid prescription_id or drug_id. Record not found.' AS error_message;
    END;
    
    -- Handler 3: General exception (catches everything else)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_code = MYSQL_ERRNO,
            v_error_msg = MESSAGE_TEXT;
        SELECT CONCAT('❌ ERROR (', v_error_code, '): ', v_error_msg) AS error_message;
    END;
    
    -- Attempt the insert (trigger will auto-check interactions!)
    INSERT INTO prescription_drugs (prescription_id, drug_id, dosage, frequency, duration)
    VALUES (p_prescription_id, p_drug_id, p_dosage, p_frequency, p_duration);
    
    SELECT CONCAT('✅ Drug #', p_drug_id, ' added to prescription #', p_prescription_id,
                  '. Check interaction_alerts for any warnings.') AS success_message;
    
    -- Show any alerts generated by the trigger
    SELECT * FROM interaction_alerts 
    WHERE prescription_id = p_prescription_id 
    ORDER BY alert_id DESC LIMIT 5;
END //

DELIMITER ;

-- ► Demo 1: SUCCESS case — Add a drug that hasn't been added yet
CALL sp_safe_add_drug_to_prescription(@trig_rx, 2, '81mg', 'Once daily', '90 days');
-- ↑ Should succeed AND trigger an alert (Warfarin + Aspirin = SEVERE)

-- ► Demo 2: DUPLICATE error — Try adding the same drug again
CALL sp_safe_add_drug_to_prescription(@trig_rx, 2, '81mg', 'Once daily', '90 days');
-- ↑ Should show: "ERROR: This drug is ALREADY in this prescription."

-- ► Demo 3: FOREIGN KEY error — Invalid drug ID
CALL sp_safe_add_drug_to_prescription(@trig_rx, 9999, '10mg', 'Once daily', '7 days');
-- ↑ Should show: "ERROR: Invalid prescription_id or drug_id."

-- ► Demo 4: FOREIGN KEY error — Invalid prescription ID
CALL sp_safe_add_drug_to_prescription(99999, 1, '5mg', 'Once daily', '90 days');
-- ↑ Should show: "ERROR: Invalid prescription_id or drug_id."


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                                                                            ║
-- ║   BONUS: RELATIONAL ALGEBRA & TUPLE RELATIONAL CALCULUS                    ║
-- ║   (Theory concepts — shown as comments with SQL equivalents)               ║
-- ║                                                                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ═══ RELATIONAL ALGEBRA ═══

-- 1. SELECTION (σ): σ_{severity='severe'}(ingredient_interactions)
SELECT * FROM ingredient_interactions WHERE severity = 'severe';

-- 2. PROJECTION (π): π_{brand_name, drug_class}(drugs)
SELECT DISTINCT brand_name, drug_class FROM drugs;

-- 3. JOIN (⋈): prescriptions ⋈_{patient_id} patients
SELECT p.prescription_id, pt.first_name, pt.last_name, p.diagnosis
FROM prescriptions p JOIN patients pt ON p.patient_id = pt.patient_id;

-- 4. UNION (∪): π_{ingredient_a_id}(interactions) ∪ π_{ingredient_b_id}(interactions)
SELECT ingredient_a_id AS ingredient_id FROM ingredient_interactions
UNION
SELECT ingredient_b_id FROM ingredient_interactions;

-- 5. DIVISION (÷): Patients prescribed ALL of {Warfarin(1), Aspirin(2)}
SELECT pt.first_name, pt.last_name
FROM patients pt
WHERE NOT EXISTS (
    SELECT drug_id FROM (SELECT 1 AS drug_id UNION SELECT 2) AS required_drugs
    WHERE drug_id NOT IN (
        SELECT pd.drug_id FROM prescriptions p
        JOIN prescription_drugs pd ON p.prescription_id = pd.prescription_id
        WHERE p.patient_id = pt.patient_id
    )
);

-- ═══ TUPLE RELATIONAL CALCULUS (TRC) ═══

-- TRC 1: { t | t ∈ patients ∧ ∃p ∈ prescriptions(p.patient_id = t.patient_id) }
-- "All patients who have at least one prescription"
SELECT pt.* FROM patients pt
WHERE EXISTS (SELECT 1 FROM prescriptions p WHERE p.patient_id = pt.patient_id);

-- TRC 2: { t | t ∈ drugs ∧ ∃di ∈ drug_ingredients ∧ ∃ii ∈ ingredient_interactions(
--          di.drug_id = t.drug_id ∧ severity ∈ {'severe','contraindicated'}) }
-- "All drugs involved in severe/contraindicated interactions"
SELECT DISTINCT d.drug_id, d.brand_name, d.generic_name
FROM drugs d
WHERE EXISTS (
    SELECT 1 FROM drug_ingredients di
    JOIN ingredient_interactions ii ON (
        di.ingredient_id = ii.ingredient_a_id OR di.ingredient_id = ii.ingredient_b_id
    )
    WHERE di.drug_id = d.drug_id
      AND ii.severity IN ('severe', 'contraindicated')
);


-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  CLEANUP (Optional — run after demo if needed)                             ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- DELETE FROM patients WHERE phone IN ('555-TRIG', '555-RVDM');
-- DELETE FROM prescriptions WHERE prescription_id = @new_rx_id;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- END OF REVIEW 2 PRESENTATION COMMANDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
