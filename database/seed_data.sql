-- ╔══════════════════════════════════════════════════════════════╗
-- ║  DRUG SAFETY GUARD — COMPREHENSIVE SEED DATA               ║
-- ║  Run against your Supabase PostgreSQL database              ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DEV USER (for auth bypass linkage)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INSERT INTO users (id, auth_id, email, full_name, role, is_active)
VALUES ('de000000-0000-4000-a000-000000000001', 'de000000-0000-4000-a000-000000000002',
        'admin@drugsafety.dev', 'Dev Admin', 'admin', TRUE)
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ADDITIONAL INGREDIENTS (12 existing + 13 new = 25)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INSERT INTO ingredients (id, name, cas_number, category) VALUES
  ('a0000001-0000-0000-0000-000000000013', 'Acetaminophen', '103-90-2', 'Analgesic'),
  ('a0000001-0000-0000-0000-000000000014', 'Atorvastatin Calcium', '134523-03-8', 'Statin'),
  ('a0000001-0000-0000-0000-000000000015', 'Amlodipine Besylate', '111470-99-6', 'Calcium Channel Blocker'),
  ('a0000001-0000-0000-0000-000000000016', 'Metoprolol Succinate', '98418-47-4', 'Beta Blocker'),
  ('a0000001-0000-0000-0000-000000000017', 'Losartan Potassium', '124750-99-8', 'ARB'),
  ('a0000001-0000-0000-0000-000000000018', 'Hydrochlorothiazide', '58-93-5', 'Thiazide Diuretic'),
  ('a0000001-0000-0000-0000-000000000019', 'Levothyroxine Sodium', '55-03-8', 'Thyroid Hormone'),
  ('a0000001-0000-0000-0000-000000000020', 'Sertraline Hydrochloride', '79559-97-0', 'SSRI'),
  ('a0000001-0000-0000-0000-000000000021', 'Gabapentin', '60142-96-3', 'Anticonvulsant'),
  ('a0000001-0000-0000-0000-000000000022', 'Tramadol Hydrochloride', '36282-47-0', 'Opioid Analgesic'),
  ('a0000001-0000-0000-0000-000000000023', 'Diazepam', '439-14-5', 'Benzodiazepine'),
  ('a0000001-0000-0000-0000-000000000024', 'Lithium Carbonate', '554-13-2', 'Mood Stabilizer'),
  ('a0000001-0000-0000-0000-000000000025', 'Digoxin', '20830-75-5', 'Cardiac Glycoside')
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ADDITIONAL DRUGS (11 existing + 14 new = 25)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INSERT INTO drugs (id, brand_name, generic_name, drug_class, manufacturer, dosage_form, strength) VALUES
  ('b0000001-0000-0000-0000-000000000012', 'Tylenol', 'Acetaminophen', 'Analgesic', 'Johnson & Johnson', 'Tablet', '500mg'),
  ('b0000001-0000-0000-0000-000000000013', 'Lipitor', 'Atorvastatin', 'Statin', 'Pfizer', 'Tablet', '40mg'),
  ('b0000001-0000-0000-0000-000000000014', 'Norvasc', 'Amlodipine', 'CCB', 'Pfizer', 'Tablet', '5mg'),
  ('b0000001-0000-0000-0000-000000000015', 'Toprol-XL', 'Metoprolol', 'Beta Blocker', 'AstraZeneca', 'Tablet', '50mg'),
  ('b0000001-0000-0000-0000-000000000016', 'Cozaar', 'Losartan', 'ARB', 'Merck', 'Tablet', '50mg'),
  ('b0000001-0000-0000-0000-000000000017', 'Microzide', 'Hydrochlorothiazide', 'Diuretic', 'Watson', 'Capsule', '12.5mg'),
  ('b0000001-0000-0000-0000-000000000018', 'Synthroid', 'Levothyroxine', 'Thyroid', 'AbbVie', 'Tablet', '100mcg'),
  ('b0000001-0000-0000-0000-000000000019', 'Zoloft', 'Sertraline', 'SSRI', 'Pfizer', 'Tablet', '50mg'),
  ('b0000001-0000-0000-0000-000000000020', 'Neurontin', 'Gabapentin', 'Anticonvulsant', 'Pfizer', 'Capsule', '300mg'),
  ('b0000001-0000-0000-0000-000000000021', 'Ultram', 'Tramadol', 'Opioid', 'Janssen', 'Tablet', '50mg'),
  ('b0000001-0000-0000-0000-000000000022', 'Valium', 'Diazepam', 'Benzodiazepine', 'Roche', 'Tablet', '5mg'),
  ('b0000001-0000-0000-0000-000000000023', 'Lithobid', 'Lithium Carbonate', 'Mood Stabilizer', 'ANI Pharma', 'Tablet', '300mg'),
  ('b0000001-0000-0000-0000-000000000024', 'Lanoxin', 'Digoxin', 'Cardiac Glycoside', 'GlaxoSmithKline', 'Tablet', '0.25mg'),
  ('b0000001-0000-0000-0000-000000000025', 'Motrin', 'Ibuprofen', 'NSAID', 'Johnson & Johnson', 'Tablet', '400mg')
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DRUG-INGREDIENT MAPPINGS (new drugs)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INSERT INTO drug_ingredients (drug_id, ingredient_id) VALUES
  ('b0000001-0000-0000-0000-000000000012', 'a0000001-0000-0000-0000-000000000013'),
  ('b0000001-0000-0000-0000-000000000013', 'a0000001-0000-0000-0000-000000000014'),
  ('b0000001-0000-0000-0000-000000000014', 'a0000001-0000-0000-0000-000000000015'),
  ('b0000001-0000-0000-0000-000000000015', 'a0000001-0000-0000-0000-000000000016'),
  ('b0000001-0000-0000-0000-000000000016', 'a0000001-0000-0000-0000-000000000017'),
  ('b0000001-0000-0000-0000-000000000017', 'a0000001-0000-0000-0000-000000000018'),
  ('b0000001-0000-0000-0000-000000000018', 'a0000001-0000-0000-0000-000000000019'),
  ('b0000001-0000-0000-0000-000000000019', 'a0000001-0000-0000-0000-000000000020'),
  ('b0000001-0000-0000-0000-000000000020', 'a0000001-0000-0000-0000-000000000021'),
  ('b0000001-0000-0000-0000-000000000021', 'a0000001-0000-0000-0000-000000000022'),
  ('b0000001-0000-0000-0000-000000000022', 'a0000001-0000-0000-0000-000000000023'),
  ('b0000001-0000-0000-0000-000000000023', 'a0000001-0000-0000-0000-000000000024'),
  ('b0000001-0000-0000-0000-000000000024', 'a0000001-0000-0000-0000-000000000025'),
  ('b0000001-0000-0000-0000-000000000025', 'a0000001-0000-0000-0000-000000000003')
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ADDITIONAL INGREDIENT INTERACTIONS (10 existing + 12 new = 22)
-- ingredient_a_id < ingredient_b_id (canonical ordering)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INSERT INTO ingredient_interactions (id, ingredient_a_id, ingredient_b_id, severity, clinical_effect, mechanism, recommendation, evidence_level) VALUES
  -- Warfarin + Acetaminophen → Mild (high doses)
  ('e0000001-0000-0000-0000-000000000001',
   'a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000013',
   'mild', 'High-dose acetaminophen (>2g/day) may increase INR in warfarin-treated patients.',
   'Acetaminophen metabolites may interfere with vitamin K-dependent clotting factor synthesis.',
   'Limit acetaminophen to <2g/day. Monitor INR if used >3 days.', 'established'),

  -- Aspirin + Clopidogrel → Moderate (dual antiplatelet risk)
  ('e0000001-0000-0000-0000-000000000002',
   'a0000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000010',
   'moderate', 'Dual antiplatelet therapy increases bleeding risk but may be clinically indicated post-ACS.',
   'Both agents inhibit platelet aggregation via different mechanisms.',
   'Use only when clinically indicated. Monitor for signs of bleeding.', 'established'),

  -- Sertraline + Tramadol → Severe (serotonin syndrome)
  ('e0000001-0000-0000-0000-000000000003',
   'a0000001-0000-0000-0000-000000000020', 'a0000001-0000-0000-0000-000000000022',
   'severe', 'Risk of serotonin syndrome: agitation, hyperthermia, tremor, diaphoresis.',
   'Both agents increase serotonergic activity. Tramadol inhibits serotonin reuptake.',
   'Avoid combination. Use alternative analgesic. If unavoidable, monitor closely for serotonin syndrome symptoms.', 'established'),

  -- Sertraline + Warfarin → Moderate (bleeding)
  ('e0000001-0000-0000-0000-000000000004',
   'a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000020',
   'moderate', 'SSRIs inhibit platelet aggregation and may increase warfarin levels via CYP2C9 inhibition.',
   'Sertraline weakly inhibits CYP2C9 and impairs platelet serotonin uptake.',
   'Monitor INR closely when initiating or discontinuing SSRI. Watch for bleeding signs.', 'established'),

  -- Tramadol + Diazepam → Severe (respiratory depression)
  ('e0000001-0000-0000-0000-000000000005',
   'a0000001-0000-0000-0000-000000000022', 'a0000001-0000-0000-0000-000000000023',
   'severe', 'Combined CNS depression: risk of profound sedation, respiratory depression, coma, death.',
   'Additive CNS depressant effects.',
   'Avoid concurrent use. If essential, start low and monitor respiratory rate closely. FDA boxed warning.', 'established'),

  -- Lithium + Lisinopril → Severe (lithium toxicity)
  ('e0000001-0000-0000-0000-000000000006',
   'a0000001-0000-0000-0000-000000000005', 'a0000001-0000-0000-0000-000000000024',
   'severe', 'ACE inhibitors reduce lithium clearance, increasing risk of lithium toxicity.',
   'ACE inhibitors reduce GFR and increase proximal tubular reabsorption of lithium.',
   'Reduce lithium dose by 50% when starting ACE inhibitor. Monitor lithium levels weekly.', 'established'),

  -- Lithium + HCTZ → Severe (lithium toxicity)
  ('e0000001-0000-0000-0000-000000000007',
   'a0000001-0000-0000-0000-000000000018', 'a0000001-0000-0000-0000-000000000024',
   'severe', 'Thiazide diuretics reduce lithium clearance by 25%, risk of lithium toxicity.',
   'Thiazides increase sodium excretion, causing compensatory lithium reabsorption in proximal tubule.',
   'Avoid combination. If essential, reduce lithium dose and monitor levels every 5 days.', 'established'),

  -- Digoxin + Amiodarone → Severe
  ('e0000001-0000-0000-0000-000000000008',
   'a0000001-0000-0000-0000-000000000007', 'a0000001-0000-0000-0000-000000000025',
   'severe', 'Amiodarone increases digoxin levels by 70-100%, risk of digoxin toxicity.',
   'Amiodarone inhibits P-glycoprotein and renal clearance of digoxin.',
   'Reduce digoxin dose by 50% when starting amiodarone. Monitor digoxin levels.', 'established'),

  -- Metoprolol + Amlodipine → Moderate (hypotension/bradycardia)
  ('e0000001-0000-0000-0000-000000000009',
   'a0000001-0000-0000-0000-000000000015', 'a0000001-0000-0000-0000-000000000016',
   'moderate', 'Additive cardiodepressant effects: risk of bradycardia, hypotension, and heart failure exacerbation.',
   'Both agents decrease cardiac output through different mechanisms (calcium channel vs beta blockade).',
   'Monitor heart rate and blood pressure. Start with low doses. Common therapeutic combination but use with caution.', 'established'),

  -- Losartan + Potassium → Moderate (hyperkalemia)
  ('e0000001-0000-0000-0000-000000000010',
   'a0000001-0000-0000-0000-000000000009', 'a0000001-0000-0000-0000-000000000017',
   'moderate', 'ARBs reduce aldosterone, causing potassium retention. Risk of hyperkalemia with supplementation.',
   'Angiotensin II blockade reduces aldosterone-mediated potassium excretion.',
   'Monitor serum potassium within 1 week. Avoid if K+ >5.0 mEq/L.', 'established'),

  -- Ciprofloxacin + Warfarin → Moderate
  ('e0000001-0000-0000-0000-000000000011',
   'a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000012',
   'moderate', 'Ciprofloxacin inhibits CYP1A2, possibly increasing warfarin levels and INR.',
   'CYP1A2 inhibition may reduce R-warfarin metabolism.',
   'Monitor INR every 2-3 days during ciprofloxacin course. Adjust warfarin dose as needed.', 'established'),

  -- Atorvastatin + Fluconazole → Severe (rhabdomyolysis)
  ('e0000001-0000-0000-0000-000000000012',
   'a0000001-0000-0000-0000-000000000008', 'a0000001-0000-0000-0000-000000000014',
   'severe', 'Fluconazole inhibits CYP3A4, increasing atorvastatin levels and rhabdomyolysis risk.',
   'CYP3A4 inhibition prevents atorvastatin first-pass metabolism.',
   'Suspend atorvastatin during fluconazole therapy. Use pravastatin as alternative.', 'established')
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ADDITIONAL PATIENTS (3 existing + 7 new = 10)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INSERT INTO patients (id, first_name, last_name, date_of_birth, gender, blood_type, allergies, medical_conditions) VALUES
  ('c0000001-0000-0000-0000-000000000004', 'James', 'Wilson', '1955-06-18', 'Male', 'AB+',
   ARRAY['Latex'], ARRAY['CHF', 'Atrial fibrillation']),
  ('c0000001-0000-0000-0000-000000000005', 'Linda', 'Park', '1982-01-30', 'Female', 'O-',
   NULL, ARRAY['Hypothyroidism', 'Depression']),
  ('c0000001-0000-0000-0000-000000000006', 'Michael', 'Brown', '1970-12-05', 'Male', 'A-',
   ARRAY['Aspirin'], ARRAY['Hypertension', 'Chronic pain']),
  ('c0000001-0000-0000-0000-000000000007', 'Sarah', 'Johnson', '1945-08-20', 'Female', 'B-',
   ARRAY['Morphine', 'Iodine'], ARRAY['Osteoarthritis', 'Warfarin therapy']),
  ('c0000001-0000-0000-0000-000000000008', 'David', 'Lee', '1988-04-12', 'Male', 'O+',
   NULL, ARRAY['Bipolar disorder', 'Hypertension']),
  ('c0000001-0000-0000-0000-000000000009', 'Emma', 'Martinez', '1975-07-25', 'Female', 'A+',
   ARRAY['Penicillin'], ARRAY['Post-MI', 'Hyperlipidemia']),
  ('c0000001-0000-0000-0000-000000000010', 'William', 'Taylor', '1960-11-14', 'Male', 'AB-',
   NULL, ARRAY['DM Type 2', 'Neuropathy', 'Depression'])
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ADDITIONAL DOCTORS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INSERT INTO doctors (id, first_name, last_name, specialization, license_number, department) VALUES
  ('d0000001-0000-0000-0000-000000000003', 'Dr. Emily', 'Nguyen', 'Psychiatry', 'LIC-2024-003', 'Psychiatry'),
  ('d0000001-0000-0000-0000-000000000004', 'Dr. Michael', 'Roberts', 'Endocrinology', 'LIC-2024-004', 'Endocrinology')
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PRESCRIPTIONS (15 total)
-- Spread over last 30 days for trend data
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INSERT INTO prescriptions (id, patient_id, doctor_id, status, diagnosis, prescribed_at, created_at) VALUES
  ('f0000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000002',
   'approved', 'Atrial fibrillation management', NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),
  ('f0000001-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001',
   'approved', 'Type 2 Diabetes, routine', NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days'),
  ('f0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000002',
   'approved', 'Hypertension + Hyperlipidemia', NOW() - INTERVAL '22 days', NOW() - INTERVAL '22 days'),
  ('f0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000003', 'd0000001-0000-0000-0000-000000000001',
   'approved', 'UTI treatment', NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days'),
  ('f0000001-0000-0000-0000-000000000005', 'c0000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000002',
   'approved', 'CHF + AF maintenance', NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days'),
  ('f0000001-0000-0000-0000-000000000006', 'c0000001-0000-0000-0000-000000000005', 'd0000001-0000-0000-0000-000000000003',
   'approved', 'Hypothyroidism + Depression', NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days'),
  ('f0000001-0000-0000-0000-000000000007', 'c0000001-0000-0000-0000-000000000006', 'd0000001-0000-0000-0000-000000000001',
   'approved', 'Chronic pain management', NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days'),
  ('f0000001-0000-0000-0000-000000000008', 'c0000001-0000-0000-0000-000000000007', 'd0000001-0000-0000-0000-000000000001',
   'approved', 'Osteoarthritis + anticoagulation', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
  ('f0000001-0000-0000-0000-000000000009', 'c0000001-0000-0000-0000-000000000008', 'd0000001-0000-0000-0000-000000000003',
   'approved', 'Bipolar + Hypertension', NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days'),
  ('f0000001-0000-0000-0000-000000000010', 'c0000001-0000-0000-0000-000000000009', 'd0000001-0000-0000-0000-000000000002',
   'approved', 'Post-MI secondary prevention', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  ('f0000001-0000-0000-0000-000000000011', 'c0000001-0000-0000-0000-000000000010', 'd0000001-0000-0000-0000-000000000004',
   'approved', 'DM + Neuropathy + Depression', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
  ('f0000001-0000-0000-0000-000000000012', 'c0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001',
   'draft', 'Follow-up anticoagulation check', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  ('f0000001-0000-0000-0000-000000000013', 'c0000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000002',
   'approved', 'CHF exacerbation', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('f0000001-0000-0000-0000-000000000014', 'c0000001-0000-0000-0000-000000000006', 'd0000001-0000-0000-0000-000000000001',
   'approved', 'Acute pain + infection', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  ('f0000001-0000-0000-0000-000000000015', 'c0000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000002',
   'draft', 'Lipid panel follow-up', NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PRESCRIPTION DRUGS (multiple drugs per prescription)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INSERT INTO prescription_drugs (id, prescription_id, drug_id, dosage, frequency, duration) VALUES
  -- Rx1: Alice - Warfarin + Aspirin (INTERACTION: severe)
  ('ad000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', '5mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000002', 'f0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000002', '81mg', 'Once daily', '90 days'),
  -- Rx2: Alice - Metformin + Cipro (INTERACTION: moderate)
  ('ad000001-0000-0000-0000-000000000003', 'f0000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000004', '500mg', 'Twice daily', '30 days'),
  ('ad000001-0000-0000-0000-000000000004', 'f0000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000011', '500mg', 'Twice daily', '7 days'),
  -- Rx3: Robert - Zestril + Zocor + Norvasc
  ('ad000001-0000-0000-0000-000000000005', 'f0000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000005', '10mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000006', 'f0000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000006', '20mg', 'Once daily at bedtime', '90 days'),
  ('ad000001-0000-0000-0000-000000000007', 'f0000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000014', '5mg', 'Once daily', '90 days'),
  -- Rx4: Maria - Metformin + Cipro (INTERACTION: moderate)
  ('ad000001-0000-0000-0000-000000000008', 'f0000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000004', '1000mg', 'Twice daily', '30 days'),
  ('ad000001-0000-0000-0000-000000000009', 'f0000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000011', '500mg', 'Twice daily', '10 days'),
  -- Rx5: James - Warfarin + Cordarone + Digoxin (INTERACTIONS: severe x2)
  ('ad000001-0000-0000-0000-000000000010', 'f0000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000001', '3mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000011', 'f0000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000007', '200mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000012', 'f0000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000024', '0.125mg', 'Once daily', '90 days'),
  -- Rx6: Linda - Synthroid + Zoloft
  ('ad000001-0000-0000-0000-000000000013', 'f0000001-0000-0000-0000-000000000006', 'b0000001-0000-0000-0000-000000000018', '100mcg', 'Once daily on empty stomach', '90 days'),
  ('ad000001-0000-0000-0000-000000000014', 'f0000001-0000-0000-0000-000000000006', 'b0000001-0000-0000-0000-000000000019', '50mg', 'Once daily', '90 days'),
  -- Rx7: Michael - Tramadol + Gabapentin (pain management)
  ('ad000001-0000-0000-0000-000000000015', 'f0000001-0000-0000-0000-000000000007', 'b0000001-0000-0000-0000-000000000021', '50mg', 'Every 6 hours as needed', '14 days'),
  ('ad000001-0000-0000-0000-000000000016', 'f0000001-0000-0000-0000-000000000007', 'b0000001-0000-0000-0000-000000000020', '300mg', 'Three times daily', '30 days'),
  -- Rx8: Sarah - Warfarin + Ibuprofen (INTERACTION: severe)
  ('ad000001-0000-0000-0000-000000000017', 'f0000001-0000-0000-0000-000000000008', 'b0000001-0000-0000-0000-000000000001', '5mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000018', 'f0000001-0000-0000-0000-000000000008', 'b0000001-0000-0000-0000-000000000003', '400mg', 'Three times daily', '7 days'),
  -- Rx9: David - Lithium + Lisinopril + HCTZ (INTERACTIONS: severe x2)
  ('ad000001-0000-0000-0000-000000000019', 'f0000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000023', '300mg', 'Three times daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000020', 'f0000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000005', '10mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000021', 'f0000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000017', '12.5mg', 'Once daily', '90 days'),
  -- Rx10: Emma - Plavix + Prilosec + Aspirin (INTERACTIONS: moderate x2)
  ('ad000001-0000-0000-0000-000000000022', 'f0000001-0000-0000-0000-000000000010', 'b0000001-0000-0000-0000-000000000009', '75mg', 'Once daily', '365 days'),
  ('ad000001-0000-0000-0000-000000000023', 'f0000001-0000-0000-0000-000000000010', 'b0000001-0000-0000-0000-000000000010', '20mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000024', 'f0000001-0000-0000-0000-000000000010', 'b0000001-0000-0000-0000-000000000002', '81mg', 'Once daily', '365 days'),
  -- Rx11: William - Metformin + Zoloft + Tramadol (INTERACTION: serotonin syndrome)
  ('ad000001-0000-0000-0000-000000000025', 'f0000001-0000-0000-0000-000000000011', 'b0000001-0000-0000-0000-000000000004', '1000mg', 'Twice daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000026', 'f0000001-0000-0000-0000-000000000011', 'b0000001-0000-0000-0000-000000000019', '100mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000027', 'f0000001-0000-0000-0000-000000000011', 'b0000001-0000-0000-0000-000000000021', '50mg', 'Every 8 hours', '14 days'),
  -- Rx12: Alice follow-up - Warfarin + Tylenol (INTERACTION: mild)
  ('ad000001-0000-0000-0000-000000000028', 'f0000001-0000-0000-0000-000000000012', 'b0000001-0000-0000-0000-000000000001', '5mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000029', 'f0000001-0000-0000-0000-000000000012', 'b0000001-0000-0000-0000-000000000012', '500mg', 'Every 6 hours as needed', '7 days'),
  -- Rx13: James - Warfarin + Diflucan (INTERACTION: contraindicated!)
  ('ad000001-0000-0000-0000-000000000030', 'f0000001-0000-0000-0000-000000000013', 'b0000001-0000-0000-0000-000000000001', '3mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000031', 'f0000001-0000-0000-0000-000000000013', 'b0000001-0000-0000-0000-000000000008', '150mg', 'Once', '1 day'),
  -- Rx14: Michael - Tramadol + Valium (INTERACTION: severe respiratory dep)
  ('ad000001-0000-0000-0000-000000000032', 'f0000001-0000-0000-0000-000000000014', 'b0000001-0000-0000-0000-000000000021', '50mg', 'Every 6 hours', '5 days'),
  ('ad000001-0000-0000-0000-000000000033', 'f0000001-0000-0000-0000-000000000014', 'b0000001-0000-0000-0000-000000000022', '5mg', 'Three times daily', '5 days'),
  -- Rx15: Robert - Simvastatin + Cordarone (INTERACTION: severe)
  ('ad000001-0000-0000-0000-000000000034', 'f0000001-0000-0000-0000-000000000015', 'b0000001-0000-0000-0000-000000000006', '40mg', 'Once daily', '90 days'),
  ('ad000001-0000-0000-0000-000000000035', 'f0000001-0000-0000-0000-000000000015', 'b0000001-0000-0000-0000-000000000007', '200mg', 'Once daily', '90 days')
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- INTERACTION ALERTS (55 alerts spread over 30 days)
-- These populate the analytics dashboards
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Get interaction IDs from the ingredient_interactions table
-- We reference existing interactions from schema.sql seed data

-- Rx1 alerts: Warfarin+Aspirin
INSERT INTO interaction_alerts (prescription_id, drug_a_id, drug_b_id, ingredient_a_id, ingredient_b_id, interaction_id, severity, clinical_effect, recommendation, status, created_at) VALUES
  ('f0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000002',
   'a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000002',
   (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000001' AND ingredient_b_id='a0000001-0000-0000-0000-000000000002' LIMIT 1),
   'severe', 'Greatly increased risk of bleeding.', 'Avoid combination unless clinically essential.', 'active', NOW() - INTERVAL '28 days'),

  -- Rx2 alerts: Metformin+Cipro
  ('f0000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000011',
   'a0000001-0000-0000-0000-000000000004', 'a0000001-0000-0000-0000-000000000012',
   (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000004' AND ingredient_b_id='a0000001-0000-0000-0000-000000000012' LIMIT 1),
   'moderate', 'Ciprofloxacin may potentiate hypoglycemic effect.', 'Monitor blood glucose closely.', 'acknowledged', NOW() - INTERVAL '25 days'),

  -- Rx4 alerts: Maria Metformin+Cipro
  ('f0000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000011',
   'a0000001-0000-0000-0000-000000000004', 'a0000001-0000-0000-0000-000000000012',
   (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000004' AND ingredient_b_id='a0000001-0000-0000-0000-000000000012' LIMIT 1),
   'moderate', 'Ciprofloxacin may potentiate hypoglycemic effect.', 'Monitor blood glucose closely.', 'active', NOW() - INTERVAL '20 days'),

  -- Rx5 alerts: Warfarin+Amiodarone
  ('f0000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000007',
   'a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000007',
   (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000001' AND ingredient_b_id='a0000001-0000-0000-0000-000000000007' LIMIT 1),
   'severe', 'Amiodarone increases warfarin levels and bleeding risk.', 'Reduce warfarin dose by 33-50%.', 'active', NOW() - INTERVAL '18 days'),

  -- Rx5 alerts: Amiodarone+Digoxin
  ('f0000001-0000-0000-0000-000000000005', 'b0000001-0000-0000-0000-000000000007', 'b0000001-0000-0000-0000-000000000024',
   'a0000001-0000-0000-0000-000000000007', 'a0000001-0000-0000-0000-000000000025',
   'e0000001-0000-0000-0000-000000000008',
   'severe', 'Amiodarone increases digoxin levels by 70-100%.', 'Reduce digoxin dose by 50%.', 'active', NOW() - INTERVAL '18 days'),

  -- Rx8 alerts: Warfarin+Ibuprofen
  ('f0000001-0000-0000-0000-000000000008', 'b0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003',
   'a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000003',
   (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000001' AND ingredient_b_id='a0000001-0000-0000-0000-000000000003' LIMIT 1),
   'severe', 'Increased risk of GI bleeding.', 'Use alternative analgesic.', 'active', NOW() - INTERVAL '10 days'),

  -- Rx9 alerts: Lithium+Lisinopril
  ('f0000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000023', 'b0000001-0000-0000-0000-000000000005',
   'a0000001-0000-0000-0000-000000000005', 'a0000001-0000-0000-0000-000000000024',
   'e0000001-0000-0000-0000-000000000006',
   'severe', 'ACE inhibitors reduce lithium clearance.', 'Reduce lithium dose by 50%.', 'active', NOW() - INTERVAL '8 days'),

  -- Rx9 alerts: Lithium+HCTZ
  ('f0000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000023', 'b0000001-0000-0000-0000-000000000017',
   'a0000001-0000-0000-0000-000000000018', 'a0000001-0000-0000-0000-000000000024',
   'e0000001-0000-0000-0000-000000000007',
   'severe', 'Thiazides reduce lithium clearance by 25%.', 'Avoid combination.', 'active', NOW() - INTERVAL '8 days'),

  -- Rx10 alerts: Clopidogrel+Omeprazole
  ('f0000001-0000-0000-0000-000000000010', 'b0000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000010',
   'a0000001-0000-0000-0000-000000000010', 'a0000001-0000-0000-0000-000000000011',
   (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000010' AND ingredient_b_id='a0000001-0000-0000-0000-000000000011' LIMIT 1),
   'moderate', 'Omeprazole reduces clopidogrel activation.', 'Use pantoprazole instead.', 'acknowledged', NOW() - INTERVAL '7 days'),

  -- Rx10 alerts: Aspirin+Clopidogrel (dual antiplatelet)
  ('f0000001-0000-0000-0000-000000000010', 'b0000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000009',
   'a0000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000010',
   'e0000001-0000-0000-0000-000000000002',
   'moderate', 'Dual antiplatelet therapy increases bleeding risk.', 'Monitor for bleeding.', 'active', NOW() - INTERVAL '7 days'),

  -- Rx11 alerts: Sertraline+Tramadol (serotonin syndrome)
  ('f0000001-0000-0000-0000-000000000011', 'b0000001-0000-0000-0000-000000000019', 'b0000001-0000-0000-0000-000000000021',
   'a0000001-0000-0000-0000-000000000020', 'a0000001-0000-0000-0000-000000000022',
   'e0000001-0000-0000-0000-000000000003',
   'severe', 'Risk of serotonin syndrome.', 'Avoid combination. Use alternative analgesic.', 'active', NOW() - INTERVAL '5 days'),

  -- Rx12 alerts: Warfarin+Acetaminophen (mild)
  ('f0000001-0000-0000-0000-000000000012', 'b0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000012',
   'a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000013',
   'e0000001-0000-0000-0000-000000000001',
   'mild', 'High-dose acetaminophen may increase INR.', 'Limit to <2g/day.', 'active', NOW() - INTERVAL '3 days'),

  -- Rx13 alerts: Warfarin+Fluconazole (CONTRAINDICATED)
  ('f0000001-0000-0000-0000-000000000013', 'b0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000008',
   'a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000008',
   (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000001' AND ingredient_b_id='a0000001-0000-0000-0000-000000000008' LIMIT 1),
   'contraindicated', 'Fluconazole dramatically increases warfarin levels and bleeding risk.', 'Do NOT co-administer.', 'active', NOW() - INTERVAL '2 days'),

  -- Rx14 alerts: Tramadol+Diazepam (severe resp dep)
  ('f0000001-0000-0000-0000-000000000014', 'b0000001-0000-0000-0000-000000000021', 'b0000001-0000-0000-0000-000000000022',
   'a0000001-0000-0000-0000-000000000022', 'a0000001-0000-0000-0000-000000000023',
   'e0000001-0000-0000-0000-000000000005',
   'severe', 'Combined CNS depression: respiratory depression risk.', 'Avoid concurrent use. FDA boxed warning.', 'active', NOW() - INTERVAL '1 day'),

  -- Rx15 alerts: Simvastatin+Amiodarone (severe myopathy)
  ('f0000001-0000-0000-0000-000000000015', 'b0000001-0000-0000-0000-000000000006', 'b0000001-0000-0000-0000-000000000007',
   'a0000001-0000-0000-0000-000000000006', 'a0000001-0000-0000-0000-000000000007',
   (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000006' AND ingredient_b_id='a0000001-0000-0000-0000-000000000007' LIMIT 1),
   'severe', 'Risk of rhabdomyolysis.', 'Limit simvastatin to 20mg/day.', 'active', NOW())
ON CONFLICT DO NOTHING;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ADDITIONAL ALERTS for volume (duplicate prescriptions with different dates)
-- These create the trend line in analytics
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Generate more alerts across different days for trend data
INSERT INTO interaction_alerts (prescription_id, drug_a_id, drug_b_id, ingredient_a_id, ingredient_b_id, interaction_id, severity, clinical_effect, recommendation, status, created_at)
SELECT
  'f0000001-0000-0000-0000-000000000001',
  'b0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000002',
  'a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000002',
  (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000001' AND ingredient_b_id='a0000001-0000-0000-0000-000000000002' LIMIT 1),
  'severe', 'Increased bleeding risk.', 'Monitor INR closely.',
  CASE WHEN gs % 3 = 0 THEN 'acknowledged'::alert_status ELSE 'active'::alert_status END,
  NOW() - (gs || ' days')::INTERVAL
FROM generate_series(1, 25) gs;

INSERT INTO interaction_alerts (prescription_id, drug_a_id, drug_b_id, ingredient_a_id, ingredient_b_id, interaction_id, severity, clinical_effect, recommendation, status, created_at)
SELECT
  'f0000001-0000-0000-0000-000000000005',
  'b0000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000007',
  'a0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000007',
  (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000001' AND ingredient_b_id='a0000001-0000-0000-0000-000000000007' LIMIT 1),
  'severe', 'Warfarin + Amiodarone bleeding risk.', 'Reduce warfarin dose.',
  'active'::alert_status,
  NOW() - (gs || ' days')::INTERVAL
FROM generate_series(2, 15) gs;

INSERT INTO interaction_alerts (prescription_id, drug_a_id, drug_b_id, ingredient_a_id, ingredient_b_id, interaction_id, severity, clinical_effect, recommendation, status, created_at)
SELECT
  'f0000001-0000-0000-0000-000000000010',
  'b0000001-0000-0000-0000-000000000009', 'b0000001-0000-0000-0000-000000000010',
  'a0000001-0000-0000-0000-000000000010', 'a0000001-0000-0000-0000-000000000011',
  (SELECT id FROM ingredient_interactions WHERE ingredient_a_id='a0000001-0000-0000-0000-000000000010' AND ingredient_b_id='a0000001-0000-0000-0000-000000000011' LIMIT 1),
  'moderate', 'Omeprazole reduces clopidogrel activation.', 'Use pantoprazole.',
  'active'::alert_status,
  NOW() - (gs || ' days')::INTERVAL
FROM generate_series(1, 10) gs;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SUMMARY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Users:        1 (dev admin)
-- Ingredients:  25 (12 existing + 13 new)
-- Drugs:        25 (11 existing + 14 new)
-- Interactions: 22 (10 existing + 12 new)
-- Patients:     10 (3 existing + 7 new)
-- Doctors:       4 (2 existing + 2 new)
-- Prescriptions: 15
-- Prescription_drugs: 35
-- Interaction_alerts: ~65 (15 specific + ~50 generated for trends)
