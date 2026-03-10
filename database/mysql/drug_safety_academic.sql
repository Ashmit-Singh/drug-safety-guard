-- ╔══════════════════════════════════════════════════════════════╗
-- ║  DRUG SAFETY GUARD — Academic DBMS Demo (MySQL Workbench)  ║
-- ║  Complete Package: Schema → Data → Queries → Procedures    ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 2: DATABASE SCHEMA (3NF)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DROP DATABASE IF EXISTS drug_safety_guard;
CREATE DATABASE drug_safety_guard;
USE drug_safety_guard;

-- Patients table
CREATE TABLE patients (
    patient_id    INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender        ENUM('Male','Female','Other') NOT NULL,
    blood_type    VARCHAR(5),
    phone         VARCHAR(20) UNIQUE,
    email         VARCHAR(255) UNIQUE,
    allergies     TEXT,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_dob CHECK (date_of_birth < CURDATE())
);

-- Drugs table
CREATE TABLE drugs (
    drug_id       INT AUTO_INCREMENT PRIMARY KEY,
    brand_name    VARCHAR(255) NOT NULL,
    generic_name  VARCHAR(255) NOT NULL,
    drug_class    VARCHAR(200),
    manufacturer  VARCHAR(255),
    dosage_form   VARCHAR(100),
    strength      VARCHAR(100),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_name CHECK (CHAR_LENGTH(brand_name) >= 2)
);

-- Drug interactions (direct drug-to-drug)
CREATE TABLE drug_interactions (
    interaction_id INT AUTO_INCREMENT PRIMARY KEY,
    drug_a_id      INT NOT NULL,
    drug_b_id      INT NOT NULL,
    severity       ENUM('mild','moderate','severe','contraindicated') NOT NULL,
    description    TEXT NOT NULL,
    recommendation TEXT NOT NULL,
    FOREIGN KEY (drug_a_id) REFERENCES drugs(drug_id) ON DELETE CASCADE,
    FOREIGN KEY (drug_b_id) REFERENCES drugs(drug_id) ON DELETE CASCADE,
    CONSTRAINT chk_diff CHECK (drug_a_id <> drug_b_id),
    CONSTRAINT uq_pair UNIQUE (drug_a_id, drug_b_id)
);

-- Prescriptions
CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id      INT NOT NULL,
    doctor_name     VARCHAR(255) NOT NULL,
    diagnosis       TEXT,
    status          ENUM('draft','approved','dispensed','cancelled') DEFAULT 'draft',
    prescribed_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
);

-- Prescription-drug junction
CREATE TABLE prescription_drugs (
    pd_id           INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    drug_id         INT NOT NULL,
    dosage          VARCHAR(100) NOT NULL,
    frequency       VARCHAR(100) NOT NULL,
    duration        VARCHAR(100),
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
    FOREIGN KEY (drug_id) REFERENCES drugs(drug_id) ON DELETE RESTRICT,
    CONSTRAINT uq_rx_drug UNIQUE (prescription_id, drug_id)
);

-- Safety alerts
CREATE TABLE alerts (
    alert_id        INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    drug_a_id       INT NOT NULL,
    drug_b_id       INT NOT NULL,
    severity        ENUM('mild','moderate','severe','contraindicated') NOT NULL,
    message         TEXT NOT NULL,
    status          ENUM('active','acknowledged','resolved') DEFAULT 'active',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
    FOREIGN KEY (drug_a_id) REFERENCES drugs(drug_id) ON DELETE CASCADE,
    FOREIGN KEY (drug_b_id) REFERENCES drugs(drug_id) ON DELETE CASCADE
);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 3: INSERT DATA (20+ records)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 10 Patients
INSERT INTO patients (first_name,last_name,date_of_birth,gender,blood_type,phone,email,allergies) VALUES
('Alice','Thompson','1965-03-14','Female','O+','555-0101','alice@mail.com','Penicillin'),
('Robert','Chen','1978-09-22','Male','A+','555-0102','robert@mail.com','Codeine'),
('Maria','Garcia','1990-11-07','Female','B+','555-0103','maria@mail.com',NULL),
('James','Wilson','1955-06-18','Male','AB+','555-0104','james@mail.com','Latex'),
('Linda','Park','1982-01-30','Female','O-','555-0105','linda@mail.com',NULL),
('Michael','Brown','1970-12-05','Male','A-','555-0106','michael@mail.com','Aspirin'),
('Sarah','Johnson','1945-08-20','Female','B-','555-0107','sarah@mail.com','Morphine'),
('David','Lee','1988-04-12','Male','O+','555-0108','david@mail.com',NULL),
('Emma','Martinez','1975-07-25','Female','A+','555-0109','emma@mail.com','Penicillin'),
('William','Taylor','1960-11-14','Male','AB-','555-0110','william@mail.com',NULL);

-- 20 Drugs
INSERT INTO drugs (brand_name,generic_name,drug_class,manufacturer,dosage_form,strength) VALUES
('Coumadin','Warfarin','Anticoagulant','Bristol-Myers','Tablet','5mg'),
('Bayer','Aspirin','NSAID','Bayer','Tablet','325mg'),
('Advil','Ibuprofen','NSAID','Pfizer','Tablet','200mg'),
('Glucophage','Metformin','Antidiabetic','Merck','Tablet','500mg'),
('Zestril','Lisinopril','ACE Inhibitor','AstraZeneca','Tablet','10mg'),
('Zocor','Simvastatin','Statin','Merck','Tablet','20mg'),
('Cordarone','Amiodarone','Antiarrhythmic','Wyeth','Tablet','200mg'),
('Diflucan','Fluconazole','Antifungal','Pfizer','Capsule','150mg'),
('Plavix','Clopidogrel','Antiplatelet','Sanofi','Tablet','75mg'),
('Prilosec','Omeprazole','PPI','AstraZeneca','Capsule','20mg'),
('Cipro','Ciprofloxacin','Antibiotic','Bayer','Tablet','500mg'),
('Tylenol','Paracetamol','Analgesic','J&J','Tablet','500mg'),
('Aleve','Naproxen','NSAID','Bayer','Tablet','220mg'),
('Zoloft','Sertraline','SSRI','Pfizer','Tablet','50mg'),
('Ultram','Tramadol','Opioid','Janssen','Tablet','50mg'),
('Valium','Diazepam','Benzodiazepine','Roche','Tablet','5mg'),
('Lithobid','Lithium','Mood Stabilizer','ANI Pharma','Tablet','300mg'),
('Lanoxin','Digoxin','Cardiac Glycoside','GSK','Tablet','0.25mg'),
('Toprol-XL','Metoprolol','Beta Blocker','AstraZeneca','Tablet','50mg'),
('Motrin','Ibuprofen','NSAID','J&J','Tablet','400mg');

-- 20 Drug Interactions
INSERT INTO drug_interactions (drug_a_id,drug_b_id,severity,description,recommendation) VALUES
(1,2,'severe','Warfarin+Aspirin: greatly increased bleeding risk','Avoid unless essential. Monitor INR'),
(1,3,'severe','Warfarin+Ibuprofen: GI bleeding and elevated INR','Use Paracetamol instead'),
(1,8,'contraindicated','Warfarin+Fluconazole: CYP2C9 inhibition, extreme bleeding risk','Do NOT co-prescribe'),
(1,7,'severe','Warfarin+Amiodarone: increased INR and bleeding','Reduce Warfarin dose 33-50%'),
(6,7,'severe','Simvastatin+Amiodarone: rhabdomyolysis risk','Limit Simvastatin to 20mg/day'),
(6,8,'contraindicated','Simvastatin+Fluconazole: extreme rhabdomyolysis risk','Suspend Simvastatin'),
(9,10,'moderate','Clopidogrel+Omeprazole: reduced antiplatelet effect','Use Pantoprazole instead'),
(4,11,'moderate','Metformin+Cipro: hypoglycemia risk','Monitor blood glucose closely'),
(2,3,'moderate','Aspirin+Ibuprofen: reduced cardioprotection','Take Aspirin 30 min before'),
(2,13,'moderate','Aspirin+Naproxen: additive GI bleeding risk','Avoid concurrent use'),
(12,1,'mild','Paracetamol+Warfarin: high-dose may increase INR','Limit to <2g/day'),
(14,15,'severe','Sertraline+Tramadol: serotonin syndrome risk','Use alternative analgesic'),
(15,16,'severe','Tramadol+Diazepam: respiratory depression','Avoid. FDA boxed warning'),
(5,17,'severe','Lisinopril+Lithium: lithium toxicity risk','Reduce Lithium dose 50%'),
(7,18,'severe','Amiodarone+Digoxin: digoxin levels increase 70-100%','Reduce Digoxin dose 50%'),
(2,9,'moderate','Aspirin+Clopidogrel: dual antiplatelet bleeding risk','Monitor for bleeding'),
(1,11,'moderate','Warfarin+Cipro: CYP1A2 inhibition raises INR','Monitor INR every 2-3 days'),
(3,13,'moderate','Ibuprofen+Naproxen: dual NSAID GI/renal toxicity','Never use 2 NSAIDs together'),
(1,14,'moderate','Warfarin+Sertraline: SSRI impairs platelets','Monitor INR when starting SSRI'),
(5,9,'moderate','Lisinopril+Clopidogrel: possible reduced efficacy','Monitor blood pressure');

-- 15 Prescriptions
INSERT INTO prescriptions (patient_id,doctor_name,diagnosis,status) VALUES
(1,'Dr. Sarah Patel','Atrial fibrillation','approved'),
(1,'Dr. James Wilson','Type 2 Diabetes','approved'),
(2,'Dr. Sarah Patel','Hypertension + Hyperlipidemia','approved'),
(3,'Dr. James Wilson','UTI treatment','approved'),
(4,'Dr. Sarah Patel','CHF + AF maintenance','approved'),
(5,'Dr. Emily Nguyen','Depression','approved'),
(6,'Dr. James Wilson','Chronic pain','approved'),
(7,'Dr. James Wilson','Osteoarthritis + Anticoagulation','approved'),
(8,'Dr. Emily Nguyen','Bipolar + Hypertension','approved'),
(9,'Dr. Sarah Patel','Post-MI prevention','approved'),
(10,'Dr. James Wilson','Diabetes + Neuropathy','approved'),
(1,'Dr. Sarah Patel','Follow-up anticoag','draft'),
(4,'Dr. Sarah Patel','CHF exacerbation','approved'),
(6,'Dr. James Wilson','Acute pain + Infection','approved'),
(2,'Dr. Sarah Patel','Lipid management','draft');

-- 20 Prescription Drugs
INSERT INTO prescription_drugs (prescription_id,drug_id,dosage,frequency,duration) VALUES
(1,1,'5mg','Once daily','90 days'),
(1,2,'81mg','Once daily','90 days'),
(2,4,'500mg','Twice daily','30 days'),
(2,11,'500mg','Twice daily','7 days'),
(3,5,'10mg','Once daily','90 days'),
(3,6,'20mg','At bedtime','90 days'),
(4,4,'1000mg','Twice daily','30 days'),
(4,11,'500mg','Twice daily','10 days'),
(5,1,'3mg','Once daily','90 days'),
(5,7,'200mg','Once daily','90 days'),
(5,18,'0.125mg','Once daily','90 days'),
(6,14,'50mg','Once daily','90 days'),
(7,15,'50mg','Every 6h PRN','14 days'),
(7,3,'400mg','Three times daily','7 days'),
(8,1,'5mg','Once daily','90 days'),
(8,3,'400mg','Three times daily','7 days'),
(9,17,'300mg','Three times daily','90 days'),
(9,5,'10mg','Once daily','90 days'),
(10,9,'75mg','Once daily','365 days'),
(10,10,'20mg','Once daily','90 days');

-- Pre-seed alerts
INSERT INTO alerts (prescription_id,drug_a_id,drug_b_id,severity,message) VALUES
(1,1,2,'severe','Warfarin+Aspirin: bleeding risk detected'),
(2,4,11,'moderate','Metformin+Cipro: hypoglycemia risk'),
(4,4,11,'moderate','Metformin+Cipro: hypoglycemia risk'),
(5,1,7,'severe','Warfarin+Amiodarone: bleeding risk'),
(5,7,18,'severe','Amiodarone+Digoxin: toxicity risk'),
(8,1,3,'severe','Warfarin+Ibuprofen: GI bleeding risk'),
(9,17,5,'severe','Lithium+Lisinopril: lithium toxicity risk'),
(10,9,10,'moderate','Clopidogrel+Omeprazole: reduced efficacy');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 4: SQL QUERIES FOR DEMO
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Simple Query: Select all drugs
SELECT * FROM drugs;

-- WHERE Query: Find severe and contraindicated interactions
SELECT d1.brand_name AS Drug_A, d2.brand_name AS Drug_B,
       di.severity, di.description
FROM drug_interactions di
JOIN drugs d1 ON di.drug_a_id = d1.drug_id
JOIN drugs d2 ON di.drug_b_id = d2.drug_id
WHERE di.severity IN ('severe','contraindicated')
ORDER BY di.severity;

-- GROUP BY Query: Count alerts per patient
SELECT CONCAT(p.first_name,' ',p.last_name) AS patient,
       COUNT(a.alert_id) AS total_alerts
FROM patients p
JOIN prescriptions rx ON p.patient_id = rx.patient_id
JOIN alerts a ON rx.prescription_id = a.prescription_id
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY total_alerts DESC;

-- ORDER BY Query: Sort drugs alphabetically
SELECT drug_id, brand_name, generic_name, drug_class
FROM drugs ORDER BY generic_name ASC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 5: JOINS (4 types)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- INNER JOIN: Prescriptions with patient names
SELECT rx.prescription_id, CONCAT(p.first_name,' ',p.last_name) AS patient,
       rx.doctor_name, rx.diagnosis, rx.status
FROM prescriptions rx
INNER JOIN patients p ON rx.patient_id = p.patient_id;

-- LEFT JOIN: All patients, even those without prescriptions
SELECT CONCAT(p.first_name,' ',p.last_name) AS patient,
       rx.prescription_id, rx.diagnosis
FROM patients p
LEFT JOIN prescriptions rx ON p.patient_id = rx.patient_id
ORDER BY p.last_name;

-- RIGHT JOIN: All drugs, even those not prescribed
SELECT d.brand_name, d.generic_name, pd.prescription_id, pd.dosage
FROM prescription_drugs pd
RIGHT JOIN drugs d ON pd.drug_id = d.drug_id
ORDER BY d.brand_name;

-- MULTI-TABLE JOIN: Full prescription details with alerts
SELECT CONCAT(p.first_name,' ',p.last_name) AS patient,
       rx.prescription_id, rx.doctor_name,
       d1.brand_name AS drug_a, d2.brand_name AS drug_b,
       a.severity, a.message
FROM alerts a
JOIN prescriptions rx ON a.prescription_id = rx.prescription_id
JOIN patients p ON rx.patient_id = p.patient_id
JOIN drugs d1 ON a.drug_a_id = d1.drug_id
JOIN drugs d2 ON a.drug_b_id = d2.drug_id
ORDER BY FIELD(a.severity,'contraindicated','severe','moderate','mild');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 6: SUBQUERIES / NESTED QUERIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Drugs that appear in dangerous interactions
SELECT drug_id, brand_name, generic_name FROM drugs
WHERE drug_id IN (
    SELECT drug_a_id FROM drug_interactions WHERE severity IN ('severe','contraindicated')
    UNION
    SELECT drug_b_id FROM drug_interactions WHERE severity IN ('severe','contraindicated')
);

-- Patients who received drugs with severe interactions
SELECT patient_id, first_name, last_name FROM patients
WHERE patient_id IN (
    SELECT rx.patient_id FROM prescriptions rx
    WHERE rx.prescription_id IN (
        SELECT a.prescription_id FROM alerts a
        WHERE a.severity IN ('severe','contraindicated')
    )
);

-- Drugs prescribed more than once
SELECT drug_id, brand_name,
    (SELECT COUNT(*) FROM prescription_drugs pd WHERE pd.drug_id = drugs.drug_id) AS times_prescribed
FROM drugs
WHERE drug_id IN (
    SELECT drug_id FROM prescription_drugs GROUP BY drug_id HAVING COUNT(*) > 1
) ORDER BY times_prescribed DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 7: VIEWS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE VIEW DangerousDrugPairs AS
SELECT d1.brand_name AS Drug_A, d2.brand_name AS Drug_B,
       di.severity, di.description, di.recommendation
FROM drug_interactions di
JOIN drugs d1 ON di.drug_a_id = d1.drug_id
JOIN drugs d2 ON di.drug_b_id = d2.drug_id
WHERE di.severity IN ('severe','contraindicated');

SELECT * FROM DangerousDrugPairs;

CREATE OR REPLACE VIEW PatientPrescriptionSummary AS
SELECT CONCAT(p.first_name,' ',p.last_name) AS patient_name,
       rx.prescription_id, rx.doctor_name, rx.diagnosis, rx.status,
       GROUP_CONCAT(d.brand_name SEPARATOR ', ') AS drugs_prescribed,
       (SELECT COUNT(*) FROM alerts a WHERE a.prescription_id = rx.prescription_id) AS alert_count
FROM patients p
JOIN prescriptions rx ON p.patient_id = rx.patient_id
LEFT JOIN prescription_drugs pd ON rx.prescription_id = pd.prescription_id
LEFT JOIN drugs d ON pd.drug_id = d.drug_id
GROUP BY p.first_name, p.last_name, rx.prescription_id, rx.doctor_name, rx.diagnosis, rx.status;

SELECT * FROM PatientPrescriptionSummary;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 10: STORED PROCEDURES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DELIMITER //

-- Procedure 1: Check if two drugs interact
CREATE PROCEDURE sp_check_interaction(IN p_drug_a INT, IN p_drug_b INT)
BEGIN
    SELECT d1.brand_name AS Drug_A, d2.brand_name AS Drug_B,
           di.severity, di.description, di.recommendation
    FROM drug_interactions di
    JOIN drugs d1 ON di.drug_a_id = d1.drug_id
    JOIN drugs d2 ON di.drug_b_id = d2.drug_id
    WHERE (di.drug_a_id = p_drug_a AND di.drug_b_id = p_drug_b)
       OR (di.drug_a_id = p_drug_b AND di.drug_b_id = p_drug_a);
END //

-- Procedure 2: Generate alerts for a prescription
CREATE PROCEDURE sp_generate_alerts(IN p_rx_id INT)
BEGIN
    INSERT INTO alerts (prescription_id, drug_a_id, drug_b_id, severity, message)
    SELECT p_rx_id, di.drug_a_id, di.drug_b_id, di.severity,
           CONCAT(d1.brand_name,'+',d2.brand_name,': ',di.description)
    FROM prescription_drugs pd1
    JOIN prescription_drugs pd2 ON pd1.prescription_id = pd2.prescription_id
                                AND pd1.drug_id < pd2.drug_id
    JOIN drug_interactions di ON
        (di.drug_a_id = pd1.drug_id AND di.drug_b_id = pd2.drug_id)
        OR (di.drug_a_id = pd2.drug_id AND di.drug_b_id = pd1.drug_id)
    JOIN drugs d1 ON pd1.drug_id = d1.drug_id
    JOIN drugs d2 ON pd2.drug_id = d2.drug_id
    WHERE pd1.prescription_id = p_rx_id;

    SELECT * FROM alerts WHERE prescription_id = p_rx_id ORDER BY alert_id DESC;
END //

-- Procedure 3: Patient history
CREATE PROCEDURE sp_patient_history(IN p_patient_id INT)
BEGIN
    SELECT rx.prescription_id, rx.diagnosis, rx.status, rx.prescribed_at,
           rx.doctor_name,
           GROUP_CONCAT(d.brand_name SEPARATOR ', ') AS drugs,
           (SELECT COUNT(*) FROM alerts a WHERE a.prescription_id = rx.prescription_id) AS alerts
    FROM prescriptions rx
    LEFT JOIN prescription_drugs pd ON rx.prescription_id = pd.prescription_id
    LEFT JOIN drugs d ON pd.drug_id = d.drug_id
    WHERE rx.patient_id = p_patient_id
    GROUP BY rx.prescription_id, rx.diagnosis, rx.status, rx.prescribed_at, rx.doctor_name
    ORDER BY rx.prescribed_at DESC;
END //

DELIMITER ;

-- Example calls:
CALL sp_check_interaction(1, 8);  -- Warfarin + Fluconazole
CALL sp_patient_history(1);       -- Alice's history


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 11: TRIGGERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DELIMITER //

-- Trigger 1: Auto-generate alert when drug added to prescription
CREATE TRIGGER trg_auto_alert
AFTER INSERT ON prescription_drugs
FOR EACH ROW
BEGIN
    INSERT INTO alerts (prescription_id, drug_a_id, drug_b_id, severity, message)
    SELECT NEW.prescription_id,
           LEAST(NEW.drug_id, pd.drug_id), GREATEST(NEW.drug_id, pd.drug_id),
           di.severity,
           CONCAT('ALERT: ', d1.brand_name,' + ',d2.brand_name,' — ',di.description)
    FROM prescription_drugs pd
    JOIN drug_interactions di ON
        (di.drug_a_id = NEW.drug_id AND di.drug_b_id = pd.drug_id)
        OR (di.drug_a_id = pd.drug_id AND di.drug_b_id = NEW.drug_id)
    JOIN drugs d1 ON d1.drug_id = LEAST(NEW.drug_id, pd.drug_id)
    JOIN drugs d2 ON d2.drug_id = GREATEST(NEW.drug_id, pd.drug_id)
    WHERE pd.prescription_id = NEW.prescription_id
      AND pd.drug_id != NEW.drug_id;
END //

DELIMITER ;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 12: CURSORS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- A CURSOR is a database object for row-by-row processing.
-- Lifecycle: DECLARE → OPEN → FETCH → CLOSE
-- Used when set-based SQL cannot express complex row logic.

DELIMITER //

CREATE PROCEDURE sp_scan_all_interactions()
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_rx INT;
    DECLARE v_patient VARCHAR(255);

    DECLARE cur CURSOR FOR
        SELECT rx.prescription_id, CONCAT(p.first_name,' ',p.last_name)
        FROM prescriptions rx JOIN patients p ON rx.patient_id = p.patient_id
        WHERE rx.status = 'approved';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    DROP TEMPORARY TABLE IF EXISTS scan_results;
    CREATE TEMPORARY TABLE scan_results (
        rx_id INT, patient VARCHAR(255),
        drug_a VARCHAR(255), drug_b VARCHAR(255),
        severity VARCHAR(20), description TEXT
    );

    OPEN cur;
    lp: LOOP
        FETCH cur INTO v_rx, v_patient;
        IF v_done THEN LEAVE lp; END IF;

        INSERT INTO scan_results
        SELECT v_rx, v_patient, d1.brand_name, d2.brand_name, di.severity, di.description
        FROM prescription_drugs pd1
        JOIN prescription_drugs pd2 ON pd1.prescription_id=pd2.prescription_id AND pd1.drug_id<pd2.drug_id
        JOIN drug_interactions di ON (di.drug_a_id=pd1.drug_id AND di.drug_b_id=pd2.drug_id)
            OR (di.drug_a_id=pd2.drug_id AND di.drug_b_id=pd1.drug_id)
        JOIN drugs d1 ON pd1.drug_id=d1.drug_id
        JOIN drugs d2 ON pd2.drug_id=d2.drug_id
        WHERE pd1.prescription_id = v_rx;
    END LOOP;
    CLOSE cur;

    SELECT * FROM scan_results
    ORDER BY FIELD(severity,'contraindicated','severe','moderate','mild');
    DROP TEMPORARY TABLE IF EXISTS scan_results;
END //

DELIMITER ;

CALL sp_scan_all_interactions();


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 13: EXCEPTION HANDLING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Exception Handling catches ERRORS during procedure execution.
-- Triggers react to DATA EVENTS; Handlers react to RUNTIME ERRORS.
-- Use Triggers for business rules; Handlers for error recovery.

DELIMITER //

CREATE PROCEDURE sp_safe_add_drug(
    IN p_rx INT, IN p_drug INT,
    IN p_dosage VARCHAR(100), IN p_freq VARCHAR(100), IN p_dur VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR 1062
        SELECT 'ERROR: Drug already in this prescription' AS result;
    DECLARE EXIT HANDLER FOR 1452
        SELECT 'ERROR: Invalid prescription or drug ID' AS result;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        DECLARE v_msg TEXT;
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        SELECT CONCAT('ERROR: ', v_msg) AS result;
    END;

    INSERT INTO prescription_drugs (prescription_id,drug_id,dosage,frequency,duration)
    VALUES (p_rx, p_drug, p_dosage, p_freq, p_dur);

    SELECT CONCAT('Success: Drug #',p_drug,' added to Rx #',p_rx) AS result;
    SELECT * FROM alerts WHERE prescription_id = p_rx ORDER BY alert_id DESC LIMIT 5;
END //

DELIMITER ;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION 14: LIVE DEMO SCRIPT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Step 1: Show all tables
SHOW TABLES;

-- Step 2: Show 20 records
SELECT * FROM patients;
SELECT * FROM drugs;
SELECT * FROM drug_interactions LIMIT 20;

-- Step 3: Run JOIN query (multi-table)
SELECT CONCAT(p.first_name,' ',p.last_name) AS patient,
       rx.prescription_id, d1.brand_name AS drug_a, d2.brand_name AS drug_b,
       a.severity, a.message
FROM alerts a
JOIN prescriptions rx ON a.prescription_id = rx.prescription_id
JOIN patients p ON rx.patient_id = p.patient_id
JOIN drugs d1 ON a.drug_a_id = d1.drug_id
JOIN drugs d2 ON a.drug_b_id = d2.drug_id;

-- Step 4: Run nested query
SELECT brand_name FROM drugs WHERE drug_id IN (
    SELECT drug_a_id FROM drug_interactions WHERE severity='contraindicated'
    UNION
    SELECT drug_b_id FROM drug_interactions WHERE severity='contraindicated'
);

-- Step 5: Show views
SELECT * FROM DangerousDrugPairs;
SELECT * FROM PatientPrescriptionSummary;

-- Step 6: Run stored procedure
CALL sp_check_interaction(1, 8);

-- Step 7: TRIGGER DEMO — Insert new patient + prescription + watch trigger fire
INSERT INTO patients (first_name,last_name,date_of_birth,gender,phone,email)
VALUES ('Demo','Patient','1985-05-15','Male','555-DEMO','demo@test.com');
SET @demo_pid = LAST_INSERT_ID();

INSERT INTO prescriptions (patient_id,doctor_name,diagnosis,status)
VALUES (@demo_pid,'Dr. Demo','Test trigger demo','approved');
SET @demo_rx = LAST_INSERT_ID();

-- Add Warfarin (no alert yet)
CALL sp_safe_add_drug(@demo_rx, 1, '5mg', 'Once daily', '90 days');
SELECT '↑ No alerts expected' AS note;

-- Add Fluconazole (TRIGGER fires! CONTRAINDICATED interaction!)
CALL sp_safe_add_drug(@demo_rx, 8, '150mg', 'Once', '1 day');
SELECT '↑ ALERT should appear: Warfarin + Fluconazole!' AS note;

-- Verify alert was created
SELECT * FROM alerts WHERE prescription_id = @demo_rx;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTIONS 8-9: RELATIONAL ALGEBRA & TRC
-- (Theory — shown as comments with SQL equivalents)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ═══ RELATIONAL ALGEBRA ═══
--
-- 1. SELECTION (σ): Filter rows by condition
--    σ_{severity='severe'}(drug_interactions)
SELECT * FROM drug_interactions WHERE severity = 'severe';

-- 2. PROJECTION (π): Select specific columns
--    π_{brand_name, drug_class}(drugs)
SELECT DISTINCT brand_name, drug_class FROM drugs;

-- 3. JOIN (⋈): Combine relations on matching keys
--    prescriptions ⋈_{patient_id} patients
SELECT rx.prescription_id, p.first_name, p.last_name, rx.diagnosis
FROM prescriptions rx JOIN patients p ON rx.patient_id = p.patient_id;

-- 4. UNION (∪): Combine results from two queries
--    π_{drug_a_id}(drug_interactions) ∪ π_{drug_b_id}(drug_interactions)
SELECT drug_a_id AS drug_id FROM drug_interactions
UNION
SELECT drug_b_id FROM drug_interactions;

-- 5. DIVISION (÷): Find patients prescribed ALL of {Warfarin, Aspirin}
SELECT p.first_name, p.last_name FROM patients p
WHERE NOT EXISTS (
    SELECT drug_id FROM (SELECT 1 AS drug_id UNION SELECT 2) req
    WHERE drug_id NOT IN (
        SELECT pd.drug_id FROM prescriptions rx
        JOIN prescription_drugs pd ON rx.prescription_id=pd.prescription_id
        WHERE rx.patient_id = p.patient_id
    )
);

-- ═══ TUPLE RELATIONAL CALCULUS ═══
--
-- TRC 1: { t | t ∈ patients ∧ ∃rx ∈ prescriptions(rx.patient_id = t.patient_id) }
-- "All patients who have at least one prescription"
SELECT * FROM patients p WHERE EXISTS (
    SELECT 1 FROM prescriptions rx WHERE rx.patient_id = p.patient_id
);

-- TRC 2: { t | t ∈ drugs ∧ ∃di ∈ drug_interactions(
--   (t.drug_id = di.drug_a_id ∨ t.drug_id = di.drug_b_id) ∧ di.severity = 'severe') }
-- "All drugs involved in severe interactions"
SELECT * FROM drugs d WHERE EXISTS (
    SELECT 1 FROM drug_interactions di
    WHERE (d.drug_id = di.drug_a_id OR d.drug_id = di.drug_b_id)
      AND di.severity IN ('severe','contraindicated')
);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- END OF ACADEMIC DEMO SCRIPT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
