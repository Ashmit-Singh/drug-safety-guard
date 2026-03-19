# Chapter 3 — Presentation & Viva Guide
## Drug Safety Guard: DBMS Mini Project Review 2

> **Review Period**: 18.03.2026 – 25.03.2026  
> **Marks**: PBL II – Mini Project Review 2 (15 Marks) + Lab Exp 4–6 (5 Marks)  
> **Time**: ~8–10 minutes total (5 min presentation + 3–5 min viva)

---

# PART A: PRESENTATION SCRIPT

> 💡 **Tip**: Keep MySQL Workbench open with `drug_safety_demo.sql` already loaded. Run queries live as you speak — examiners love seeing real output.

---

## Slide 1 — Introduction & Problem Statement *(30 sec)*

> "Good morning. Our project is **Drug Safety Guard** — a database system that **automatically detects dangerous drug interactions** before a prescription reaches the patient.
>
> The problem: when a patient takes multiple medications, some drug combinations can cause life-threatening reactions — like Warfarin with Fluconazole, which causes uncontrolled bleeding. Globally, adverse drug interactions cause over **1.3 million emergency visits per year**.
>
> Our solution: we enforce safety checks **at the database level** using triggers, so no dangerous combination can ever slip through — regardless of which application accesses the data."

---

## Slide 2 — Database Design *(45 sec)*

> "The database is designed in **Third Normal Form** with **9 core tables**, organized in three layers:
>
> **Master Data**: `patients`, `doctors`, `drugs`, and `ingredients` — these store the base entities.
>
> **Transactional**: `prescriptions` and `prescription_drugs` — the junction table links drugs to prescriptions.
>
> **Safety Intelligence**: `ingredient_interactions` stores 20 clinically accurate interaction pairs with four severity levels. `interaction_alerts` stores the auto-generated warnings.
>
> The key design decision is **ingredient-level interactions** — we don't say 'Drug A interacts with Drug B.' We say 'Ingredient X interacts with Ingredient Y.' This means if a NEW drug enters the market containing Warfarin's active ingredient, all its interactions are **automatically known** — zero manual updates."

**ER Diagram to show:**
```
PATIENTS (1) ──< (M) PRESCRIPTIONS (M) >── (1) DOCTORS
                          |
                         (M)
                   PRESCRIPTION_DRUGS
                         (M)
                          |
                         (1)
                        DRUGS
                         (1)
                          |
                         (M)
                   DRUG_INGREDIENTS
                         (M)
                          |
                         (1)
                     INGREDIENTS ──< INGREDIENT_INTERACTIONS >── INGREDIENTS
                                              |
                                             (M)
                                      INTERACTION_ALERTS
```

---

## Slide 3 — Task 1: DML, Constraints, Sets *(1 min)*

> "For **Task 1**, I'll demonstrate DML operations and constraints."

### Run these queries live:

**DML — SELECT with WHERE, GROUP BY, ORDER BY:**
```sql
-- Severe/contraindicated interactions only
SELECT i1.name AS Ingredient_A, i2.name AS Ingredient_B, ii.severity
FROM ingredient_interactions ii
JOIN ingredients i1 ON ii.ingredient_a_id = i1.ingredient_id
JOIN ingredients i2 ON ii.ingredient_b_id = i2.ingredient_id
WHERE ii.severity IN ('severe', 'contraindicated')
ORDER BY ii.severity;
```

**Constraints — Show the table structure:**
```sql
SHOW CREATE TABLE patients;        -- PK, NOT NULL, UNIQUE, CHECK
SHOW CREATE TABLE prescription_drugs;  -- FK CASCADE, FK RESTRICT, UNIQUE pair
```

> "We use **5 types of constraints**: PRIMARY KEY, NOT NULL, UNIQUE, CHECK (e.g., date_of_birth must be in the past), and FOREIGN KEY with both CASCADE and RESTRICT policies."

**Set Operations — UNION:**
```sql
SELECT ingredient_a_id AS ingredient_id FROM ingredient_interactions
UNION
SELECT ingredient_b_id FROM ingredient_interactions;
```
> "UNION combines ingredient IDs from both sides of the interaction pair, removing duplicates. This gives us every ingredient involved in any known interaction."

---

## Slide 4 — Task 2: Subqueries, Joins, Views *(1.5 min)*

> "For **Task 2**, let me show our JOIN queries and subqueries."

### Run live:

**INNER JOIN (3 tables):**
```sql
SELECT p.prescription_id,
       CONCAT(pt.first_name, ' ', pt.last_name) AS patient,
       CONCAT(d.first_name, ' ', d.last_name) AS doctor,
       p.diagnosis
FROM prescriptions p
INNER JOIN patients pt ON p.patient_id = pt.patient_id
INNER JOIN doctors d ON p.doctor_id = d.doctor_id;
```

**LEFT JOIN:**
```sql
SELECT dr.brand_name, dr.generic_name, i.name AS ingredient
FROM drugs dr
LEFT JOIN drug_ingredients di ON dr.drug_id = di.drug_id
LEFT JOIN ingredients i ON di.ingredient_id = i.ingredient_id;
```
> "LEFT JOIN keeps ALL drugs even if they have no ingredient mapping."

**Multi-table JOIN (6 tables):**
```sql
SELECT CONCAT(pt.first_name, ' ', pt.last_name) AS patient,
       da.brand_name AS drug_a, db.brand_name AS drug_b,
       ia.severity, ia.clinical_effect
FROM interaction_alerts ia
JOIN prescriptions p ON ia.prescription_id = p.prescription_id
JOIN patients pt ON p.patient_id = pt.patient_id
JOIN doctors doc ON p.doctor_id = doc.doctor_id
JOIN drugs da ON ia.drug_a_id = da.drug_id
JOIN drugs db ON ia.drug_b_id = db.drug_id;
```

**Nested Subquery with EXISTS:**
```sql
SELECT first_name, last_name FROM patients pt
WHERE EXISTS (
    SELECT 1 FROM prescriptions p
    JOIN interaction_alerts ia ON p.prescription_id = ia.prescription_id
    WHERE p.patient_id = pt.patient_id
      AND ia.severity IN ('severe', 'contraindicated')
);
```
> "This finds patients who have prescriptions with severe alerts — uses a **correlated EXISTS subquery**."

**Views:**
```sql
SELECT * FROM Dangerous_Prescriptions;  -- Severe/contraindicated alerts
SELECT * FROM Patient_Prescription_Summary;  -- Complete overview
```
> "Views act as virtual tables. `Dangerous_Prescriptions` joins 6 tables into one simple query the doctor can use."

---

## Slide 5 — Task 3: Functions, Triggers, Cursors, Exception Handling *(2.5 min)*

> "This is the **core feature** of our system."

### 🔥 TRIGGER LIVE DEMO (the showstopper):

> "Watch the trigger in action — I'll create a patient, write a prescription, and add two drugs. The system will automatically detect a **CONTRAINDICATED** interaction."

```sql
-- Step 1: New patient
INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, email)
VALUES ('Demo', 'Patient', '1985-05-15', 'Male', '555-DEMO', 'demo@test.com');
SET @demo_pid = LAST_INSERT_ID();

-- Step 2: New prescription
CALL sp_add_prescription(@demo_pid, 1, 'Demo: AF + Fungal infection', @demo_rx);

-- Step 3: Add Warfarin — NO alert
CALL sp_safe_add_drug_to_prescription(@demo_rx, 1, '5mg', 'Once daily', '90 days');
SELECT * FROM interaction_alerts WHERE prescription_id = @demo_rx;
-- ↑ Empty — safe so far

-- Step 4: Add Fluconazole — TRIGGER FIRES! ⚠️
CALL sp_safe_add_drug_to_prescription(@demo_rx, 8, '150mg', 'Once', '1 day');
SELECT * FROM interaction_alerts WHERE prescription_id = @demo_rx;
-- ↑ CONTRAINDICATED alert auto-generated!
```

> "The trigger `trg_check_drug_interactions` fired automatically when Fluconazole was added. It cross-referenced all ingredient pairs and found that **Warfarin + Fluconazole is CONTRAINDICATED** — extreme bleeding risk. The alert was inserted without any application code."

### Stored Procedures:
```sql
CALL sp_check_prescription_safety(1);  -- Check Rx #1 for interactions
CALL sp_patient_history(1);            -- Alice's complete history
```

### Cursor Demo:
```sql
CALL sp_scan_all_prescriptions_for_interactions();
```
> "This cursor iterates **row-by-row** through all approved prescriptions, checking each one for interactions. It uses the full lifecycle: DECLARE → OPEN → FETCH loop → CLOSE."

### Exception Handling Demo:
```sql
-- Duplicate: should show error message
CALL sp_safe_add_drug_to_prescription(@demo_rx, 1, '5mg', 'Once daily', '90 days');

-- Invalid drug: should show error message  
CALL sp_safe_add_drug_to_prescription(@demo_rx, 9999, '10mg', 'Once daily', '7 days');
```
> "The procedure uses **DECLARE EXIT HANDLER** to catch MySQL error 1062 (duplicate) and 1452 (FK violation). Instead of crashing, it returns a clean error message."

---

## Slide 6 — Conclusion *(20 sec)*

> "Drug Safety Guard demonstrates how a well-designed relational database can enforce patient safety rules automatically. The trigger ensures **zero-miss detection** — every dangerous combination is caught at the database level. The system uses all required DBMS concepts: DML, constraints, sets, joins, subqueries, views, stored procedures, triggers, cursors, and exception handling. Thank you."

---
---

# PART B: VIVA QUESTIONS & ANSWERS

> 🎯 Below are **40+ likely viva questions** organized by topic. Read through all of them — you'll be asked ~5–10 during the review.

---

## B.1 — DATABASE DESIGN & NORMALIZATION

**Q1: Explain the normalization level of your database.**
> "Our database is in **Third Normal Form (3NF)**. Every non-key attribute depends on the primary key (1NF), depends on the whole key (2NF), and depends on nothing but the key (3NF). For example, `prescriptions` has `patient_id` as a foreign key, not `patient_first_name` — we don't store derived patient data in the prescription table."

**Q2: Why do you have a separate `ingredients` table? Why not store interactions at the drug level?**
> "Drug-level interactions are lossy. For example, Advil and Motrin are different drugs but both contain Ibuprofen. If we stored 'Advil interacts with Warfarin' at the drug level, we'd need to repeat it for every Ibuprofen-containing drug. Ingredient-level modeling means we store the interaction ONCE and detect it for ALL drugs containing that ingredient — past, present, and future."

**Q3: What is a junction table? Which ones do you have?**
> "A junction table resolves a many-to-many relationship. We have two:
> - `drug_ingredients` — maps drugs to their ingredients (a drug has many ingredients; an ingredient appears in many drugs)
> - `prescription_drugs` — maps drugs to prescriptions (a prescription has many drugs; a drug appears in many prescriptions)"

**Q4: What type of relationship does `ingredient_interactions` have?**
> "It's a **self-referencing many-to-many** relationship on the `ingredients` table. Both `ingredient_a_id` and `ingredient_b_id` reference the same `ingredients` table. We use a CHECK constraint `ingredient_a_id < ingredient_b_id` to store each pair only once in canonical order."

**Q5: Why is the date_of_birth CHECK constraint important?**
> "The constraint `CHECK (date_of_birth < CURDATE())` ensures no one can register with a future birth date. It's a **domain integrity** constraint that validates data at the database level, regardless of application logic."

---

## B.2 — CONSTRAINTS & INTEGRITY

**Q6: Name all constraint types used in your project.**
> "We use six:
> 1. **PRIMARY KEY** — `patient_id INT AUTO_INCREMENT` on every table
> 2. **FOREIGN KEY** — linking prescriptions to patients, drugs to prescriptions, etc.
> 3. **NOT NULL** — `first_name`, `last_name`, `severity`, etc.
> 4. **UNIQUE** — `email, phone` in patients, `(prescription_id, drug_id)` in prescription_drugs
> 5. **CHECK** — `date_of_birth < CURDATE()`, `ingredient_a_id <> ingredient_b_id`
> 6. **ENUM** — `severity ENUM('mild','moderate','severe','contraindicated')`"

**Q7: What is the difference between CASCADE and RESTRICT?**
> "**CASCADE**: When the parent is deleted, all children are automatically deleted. Example: deleting a prescription cascades to its `prescription_drugs` and `interaction_alerts`.
>
> **RESTRICT**: Prevents the parent from being deleted if children exist. Example: you cannot delete a drug that is referenced in `prescription_drugs` — this protects prescription integrity."

**Q8: What is referential integrity?**
> "Referential integrity ensures every foreign key value in a child table actually exists in the parent table. For example, `prescription_drugs.drug_id` must match an existing `drugs.drug_id`. If you try to insert drug_id = 999 when it doesn't exist, MySQL throws error 1452."

**Q9: What happens if you try to insert a duplicate drug into the same prescription?**
> "The `UNIQUE(prescription_id, drug_id)` constraint prevents it. MySQL throws error 1062 (duplicate entry). Our `sp_safe_add_drug_to_prescription` procedure catches this with a `DECLARE EXIT HANDLER FOR 1062` and returns a clean error message instead of crashing."

---

## B.3 — SQL QUERIES (DML)

**Q10: What are the four DML operations?**
> "**SELECT** (read), **INSERT** (create), **UPDATE** (modify), **DELETE** (remove). We demonstrate all four in our project."

**Q11: Explain the difference between WHERE and HAVING.**
> "**WHERE** filters rows BEFORE grouping. **HAVING** filters AFTER grouping. For example:
> - `WHERE severity = 'severe'` — filters individual rows
> - `HAVING COUNT(*) > 1` — filters groups that have more than one row"

**Q12: What is GROUP BY used for?**
> "GROUP BY groups rows that have the same value in specified columns, allowing us to use aggregate functions. For example, `GROUP BY patient_id` with `COUNT(alert_id)` gives us the number of alerts per patient."

**Q13: What set operations did you use?**
> "We used **UNION** to combine ingredient IDs from both sides of the interaction pair (`ingredient_a_id UNION ingredient_b_id`). UNION removes duplicates; UNION ALL keeps them. We also demonstrated INTERSECT and EXCEPT equivalents using `IN` and `NOT IN` subqueries (since MySQL doesn't natively support INTERSECT/EXCEPT)."

---

## B.4 — JOINS

**Q14: How many types of JOINs did you use? Explain each.**
> "Four types:
> 1. **INNER JOIN** — Returns only matching rows from both tables. We join prescriptions with patients and doctors.
> 2. **LEFT JOIN** — Returns ALL rows from the left table, even if no match on the right. We show all drugs including those with no ingredient mapping.
> 3. **RIGHT JOIN** — Returns ALL rows from the right table. We show all patients including those without prescriptions.
> 4. **Multi-table JOIN** — We join 6 tables: `interaction_alerts → prescriptions → patients → doctors → drugs(a) → drugs(b)` to show complete alert details."

**Q15: What is a CROSS JOIN?**
> "A CROSS JOIN returns the Cartesian product of two tables — every row from table A combined with every row from table B. We don't use it directly, but implicitly, when we check all drug pairs in a prescription, we're generating a pair-wise combination."

**Q16: What is a NATURAL JOIN?**
> "A NATURAL JOIN automatically joins tables on columns with the same name. We don't use it because it's fragile — if column names change, the query silently breaks. We prefer explicit `ON` conditions."

---

## B.5 — SUBQUERIES

**Q17: What is a correlated subquery?**
> "A correlated subquery references a column from the outer query. It executes once for EACH row of the outer query. Example:
> ```sql
> SELECT drug_id, brand_name,
>     (SELECT COUNT(*) FROM prescription_drugs pd WHERE pd.drug_id = drugs.drug_id) AS times_prescribed
> FROM drugs;
> ```
> Here, the inner query's `pd.drug_id = drugs.drug_id` references the outer `drugs` table."

**Q18: What is the difference between IN and EXISTS?**
> "Both filter based on a subquery.
> - **IN** compares a value against a list: `WHERE drug_id IN (SELECT drug_id FROM ...)`
> - **EXISTS** checks if ANY row is returned: `WHERE EXISTS (SELECT 1 FROM ...)`
> - EXISTS is generally faster for large datasets because it stops at the first match."

---

## B.6 — VIEWS

**Q19: What is a view? Why use it?**
> "A view is a **virtual table** defined by a SELECT query. It doesn't store data — it runs the query each time it's accessed. Benefits:
> - **Simplification**: The `Dangerous_Prescriptions` view hides a 6-table JOIN behind a simple `SELECT *`
> - **Security**: You can grant access to a view without exposing the underlying tables
> - **Consistency**: Complex business logic is defined once, not repeated in every query"

**Q20: Can you INSERT or UPDATE through a view?**
> "Only through **simple views** (single table, no JOINs, no GROUP BY, no aggregates). Our views are complex multi-table JOINs, so they are read-only."

---

## B.7 — STORED PROCEDURES

**Q21: What is a stored procedure? How is it different from a function?**
> "A stored procedure is a precompiled set of SQL statements stored in the database. Key differences from functions:
> - Procedures are called with `CALL`; functions are used in expressions
> - Procedures can have IN, OUT, INOUT parameters; functions only return a value
> - Procedures can execute DML (INSERT/UPDATE/DELETE); functions typically cannot"

**Q22: Explain the IN and OUT parameters in `sp_add_prescription`.**
> "**IN** parameters pass data into the procedure: `p_patient_id`, `p_doctor_id`, `p_diagnosis`. **OUT** parameters return data: `p_prescription_id` returns the auto-generated ID via `LAST_INSERT_ID()`. After calling, you access it with `SELECT @new_rx_id`."

**Q23: What is the advantage of stored procedures?**
> "1. **Performance** — Precompiled, reduces network round trips
> 2. **Security** — Users can execute procedures without direct table access
> 3. **Reusability** — Business logic is centralized, not scattered across applications
> 4. **Consistency** — Same logic executes regardless of which client connects"

---

## B.8 — TRIGGERS

**Q24: What is a trigger? When does it fire?**
> "A trigger is a stored program that **automatically executes** in response to a data event (INSERT, UPDATE, or DELETE). Our trigger `trg_check_drug_interactions` fires **AFTER INSERT** on `prescription_drugs`. Every time a drug is added to a prescription, the trigger automatically checks for interactions."

**Q25: Why AFTER INSERT and not BEFORE INSERT?**
> "Because we need the NEW row to be already committed to the table before we can compare it against other drugs in the same prescription. A BEFORE trigger would fire before the row is inserted, so the new drug wouldn't be in the table yet for the JOIN to find."

**Q26: Can a trigger call a stored procedure?**
> "Yes. In fact, our trigger effectively performs the same logic as `sp_check_prescription_safety` but automatically. However, direct `CALL` inside triggers can cause issues with result sets, so we inline the logic using INSERT...SELECT."

**Q27: What is the difference between a trigger and a stored procedure?**
> "A **trigger** fires automatically on data events — you don't call it. A **stored procedure** must be explicitly called with `CALL`. Triggers are for enforcing business rules on every data change; procedures are for complex operations invoked on demand."

---

## B.9 — CURSORS

**Q28: What is a cursor? Why use one?**
> "A cursor is a database object for **row-by-row processing** of query results. Normal SQL operates on sets (all rows at once), but sometimes you need row-level logic. Our `sp_scan_all_prescriptions_for_interactions` uses a cursor to iterate through each approved prescription individually."

**Q29: What are the four steps of the cursor lifecycle?**
> "1. **DECLARE** — Define the cursor with a SELECT query
> 2. **OPEN** — Execute the query, populate the result set
> 3. **FETCH** — Retrieve rows one at a time in a LOOP
> 4. **CLOSE** — Release memory and resources"

**Q30: Why not just use a JOIN instead of a cursor?**
> "For our specific case, a JOIN would actually work. Cursors are demonstrated here for academic purposes. In practice, set-based operations (JOINs) are almost always faster than cursors. Use cursors only when row-level conditional logic can't be expressed in a single query."

---

## B.10 — EXCEPTION HANDLING

**Q31: How does MySQL handle exceptions in stored procedures?**
> "Using `DECLARE ... HANDLER` syntax. We have three handlers:
> ```sql
> DECLARE EXIT HANDLER FOR 1062  -- Duplicate entry
> DECLARE EXIT HANDLER FOR 1452  -- FK violation
> DECLARE EXIT HANDLER FOR SQLEXCEPTION  -- Any other error
> ```
> When an error occurs, the matching handler executes instead of crashing."

**Q32: What is the difference between EXIT and CONTINUE handlers?**
> "An **EXIT** handler terminates the procedure after handling the error. A **CONTINUE** handler handles the error and lets the procedure continue executing. We use EXIT because after a failed INSERT, there's nothing more to do."

**Q33: How is exception handling different from triggers?**
> "**Triggers** react to **data events** (INSERT/UPDATE/DELETE on tables). **Exception handlers** react to **runtime errors** during procedure execution. Use triggers for business rules; handlers for error recovery."

---

## B.11 — RELATIONAL ALGEBRA & TRC (Bonus)

**Q34: What is Selection (σ) in relational algebra?**
> "Selection filters rows by a condition. `σ_{severity='severe'}(ingredient_interactions)` is equivalent to `SELECT * FROM ingredient_interactions WHERE severity = 'severe'`."

**Q35: What is Projection (π)?**
> "Projection selects specific columns. `π_{brand_name, drug_class}(drugs)` is equivalent to `SELECT DISTINCT brand_name, drug_class FROM drugs`."

**Q36: What is Division (÷)?**
> "Division finds tuples associated with ALL tuples in another set. 'Find patients prescribed ALL of {Warfarin, Aspirin}' uses `NOT EXISTS` in SQL — we check that no required drug is missing from the patient's prescriptions."

**Q37: What is Tuple Relational Calculus?**
> "TRC is a **declarative** query language — it specifies **WHAT** to retrieve, not HOW. Notation: `{ t | P(t) }` — 'the set of tuples t where predicate P is true.' The SQL equivalent uses `EXISTS`. For example: `{ t | t ∈ patients ∧ ∃p ∈ prescriptions(p.patient_id = t.patient_id) }` becomes `SELECT * FROM patients WHERE EXISTS (SELECT 1 FROM prescriptions ...)`."

---

## B.12 — PROJECT-SPECIFIC QUESTIONS

**Q38: How does your system detect drug interactions?**
> "When a drug is added to a prescription via `INSERT INTO prescription_drugs`, an AFTER INSERT trigger fires. The trigger:
> 1. Finds all ingredients of the new drug (via `drug_ingredients`)
> 2. Finds all ingredients of existing drugs in the same prescription
> 3. Checks every ingredient pair against `ingredient_interactions`
> 4. Inserts an alert into `interaction_alerts` for each match
> This happens at the database level — zero application code needed."

**Q39: What happens if the same interaction is detected twice?**
> "We prevent duplicates using the `UNIQUE(prescription_id, drug_id)` constraint on `prescription_drugs`, so you can't add the same drug twice. Additionally, the trigger's INSERT uses deduplication logic to avoid duplicate alerts for the same interaction."

**Q40: Why four severity levels?**
> "They map to clinical urgency:
> - **Mild** — Informational, monitor the patient
> - **Moderate** — Clinically significant, may need dose adjustment
> - **Severe** — Dangerous, avoid unless essential, close monitoring
> - **Contraindicated** — NEVER co-prescribe, life-threatening risk"

**Q41: How many tables does your system have and what are they?**
> "9 tables: `patients`, `doctors`, `drugs`, `ingredients`, `drug_ingredients`, `ingredient_interactions`, `prescriptions`, `prescription_drugs`, `interaction_alerts`."

**Q42: What is the most important query in your system?**
> "The multi-table JOIN in the trigger — it joins `prescription_drugs → drug_ingredients → ingredient_interactions → drugs` to detect all dangerous combinations. This single query IS the safety mechanism."

---

# PART C: QUICK-REFERENCE CHEAT SHEET

> 📋 **Print this page** and keep it handy during your review. Glance at it if you blank on a concept.

| Concept | Key Point | Our Example |
|---------|-----------|-------------|
| **1NF** | Atomic values, no repeating groups | Each drug is a separate row in `prescription_drugs` |
| **2NF** | No partial dependencies | Drug name is in `drugs` table, not in `prescription_drugs` |
| **3NF** | No transitive dependencies | Patient name is not stored in `prescriptions` — only `patient_id` |
| **INNER JOIN** | Only matching rows | Prescriptions ⋈ Patients ⋈ Doctors |
| **LEFT JOIN** | All left + matching right | All drugs, even those never prescribed |
| **RIGHT JOIN** | All right + matching left | All patients, even those without prescriptions |
| **Subquery (IN)** | Value-list filter | Drugs containing dangerous ingredients |
| **Subquery (EXISTS)** | Existence check | Patients with active severe alerts |
| **Correlated** | References outer query | Drug count per prescription |
| **View** | Virtual table from SELECT | `Dangerous_Prescriptions` (6-table JOIN) |
| **Stored Procedure** | Precompiled SQL block | `sp_check_prescription_safety(rx_id)` |
| **IN / OUT params** | Input / return values | `sp_add_prescription(IN..., OUT rx_id)` |
| **AFTER INSERT trigger** | Fires on data insert | `trg_check_drug_interactions` |
| **Cursor** | Row-by-row processing | Scan all prescriptions one by one |
| **Cursor lifecycle** | DECLARE → OPEN → FETCH → CLOSE | `sp_scan_all_prescriptions_for_interactions` |
| **EXIT HANDLER** | Catches errors, stops proc | 1062 = duplicate, 1452 = bad FK |
| **CONTINUE HANDLER** | Catches errors, continues | Used for NOT FOUND in cursors |
| **UNION** | Combine + deduplicate | All ingredients from both sides of interactions |
| **CASCADE** | Delete children with parent | Prescription → prescription_drugs |
| **RESTRICT** | Block parent deletion | Can't delete a drug used in prescriptions |
| **CHECK** | Domain validation | `date_of_birth < CURDATE()` |

---

> 🎯 **Final Tip**: When answering viva questions, always relate back to YOUR project. Don't give generic textbook answers — say "In our project, we used this for..." The examiner is testing whether you UNDERSTAND what you built, not whether you memorized definitions.
