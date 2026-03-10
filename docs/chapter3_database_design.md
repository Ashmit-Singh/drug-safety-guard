# Chapter 3: Database Design and Implementation

## 3.1 System Overview

The Drug Interaction Safety & Prescription Validation System is a clinical decision support tool that detects dangerous drug combinations by analyzing ingredient-level interactions. When a physician builds a prescription, the system automatically cross-references all prescribed drugs' active ingredients against a knowledge base of known interactions and generates real-time safety alerts.

## 3.2 Database Design

### 3.2.1 Entity-Relationship Model

The database follows a normalized relational design (3NF) with 9 interconnected tables organized in three logical layers:

**Core Entities:**
- **PATIENTS** — Demographic and medical profile data
- **DOCTORS** — Prescribing physician credentials
- **DRUGS** — Master drug catalog (brand/generic names, NDC codes)
- **INGREDIENTS** — Active pharmaceutical ingredients (APIs)

**Transactional Entities:**
- **PRESCRIPTIONS** — Prescription records linking patients to doctors
- **PRESCRIPTION_DRUGS** — Junction table mapping drugs to prescriptions

**Knowledge & Safety Layer:**
- **DRUG_INGREDIENTS** — Junction table mapping drugs to their ingredient compositions
- **INGREDIENT_INTERACTIONS** — Known dangerous interactions between ingredient pairs
- **INTERACTION_ALERTS** — System-generated safety alerts for prescriptions

### 3.2.2 ER Diagram Relationships

```
PATIENTS (1) ──────────< (M) PRESCRIPTIONS (M) >────────── (1) DOCTORS
                                    |
                                    | 1
                                    |
                                    M
                            PRESCRIPTION_DRUGS
                                    |
                                    | M
                                    |
                                    1
                                  DRUGS
                                    |
                                    | 1
                                    |
                                    M
                             DRUG_INGREDIENTS
                                    |
                                    | M
                                    |
                                    1
                               INGREDIENTS
                                   / \
                                  /   \
                                 M     M
                        INGREDIENT_INTERACTIONS
                                    |
                                    | 1
                                    |
                                    M
                            INTERACTION_ALERTS
```

### 3.2.3 Key Design Decisions

1. **Ingredient-Level Analysis**: Interactions are defined at the ingredient level (not drug level), allowing the system to detect interactions even across different brand-name products containing the same active ingredients.

2. **Bidirectional Interaction Lookup**: The `ingredient_interactions` table stores each pair once (ingredient_a_id < ingredient_b_id) with a CHECK constraint, and queries check both orderings via OR conditions in joins.

3. **Soft Delete Support**: The system uses status-based workflows (draft → approved → dispensed → cancelled) rather than hard deletes, preserving audit trails.

## 3.3 Constraints Used

| Constraint Type | Table | Example |
|-----------------|-------|---------|
| **PRIMARY KEY** | All tables | `patient_id INT AUTO_INCREMENT PRIMARY KEY` |
| **FOREIGN KEY** | PRESCRIPTIONS | `FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE` |
| **NOT NULL** | PATIENTS | `first_name VARCHAR(100) NOT NULL` |
| **UNIQUE** | PATIENTS | `email VARCHAR(255) UNIQUE` |
| **CHECK** | PATIENTS | `CHECK (date_of_birth < CURDATE())` |
| **CHECK** | INGREDIENT_INTERACTIONS | `CHECK (ingredient_a_id <> ingredient_b_id)` — prevents self-interactions |
| **ENUM** | INTERACTION_ALERTS | `severity ENUM('mild', 'moderate', 'severe', 'contraindicated')` |
| **ON DELETE CASCADE** | PRESCRIPTION_DRUGS | Automatically removes drugs when a prescription is deleted |
| **ON DELETE RESTRICT** | PRESCRIPTION_DRUGS → DRUGS | Prevents deletion of drugs that are referenced in prescriptions |
| **COMPOSITE KEY** | DRUG_INGREDIENTS | `PRIMARY KEY (drug_id, ingredient_id)` — ensures no duplicate mappings |

## 3.4 SQL Queries Implemented

### 3.4.1 JOIN Queries
1. **INNER JOIN**: Prescriptions with patient and doctor names (3-table join)
2. **LEFT JOIN**: All drugs with their ingredients (including drugs with no mapped ingredients)
3. **RIGHT JOIN**: All patients with their prescriptions (including patients without prescriptions)
4. **Multi-Table JOIN**: Complete alert details joining 6 tables (alerts → prescriptions → patients → doctors → drug_a → drug_b)

### 3.4.2 Subqueries
1. Drugs containing ingredients involved in severe interactions (nested IN with UNION)
2. Patients with active danger alerts (correlated EXISTS subquery)
3. Drugs appearing in more than one prescription (HAVING clause with correlated scalar subquery)

### 3.4.3 Views
1. **Dangerous_Prescriptions** — Aggregates all severe/contraindicated alerts with patient, doctor, and drug details
2. **Drug_Ingredient_List** — Complete drug composition reference showing brand name, ingredient, and concentration

## 3.5 Stored Procedures

| Procedure | Purpose | Parameters |
|-----------|---------|------------|
| `sp_add_prescription` | Creates a new prescription record | IN: patient_id, doctor_id, diagnosis; OUT: prescription_id |
| `sp_check_prescription_safety` | Analyzes all drug pairs in a prescription for known interactions | IN: prescription_id |
| `sp_patient_history` | Returns complete prescription history with drug lists and alert counts | IN: patient_id |
| `sp_scan_all_prescriptions_for_interactions` | Cursor-based scan of all approved prescriptions | None |
| `sp_safe_add_drug_to_prescription` | Exception-safe drug addition with automatic interaction checking | IN: prescription_id, drug_id, dosage, frequency, duration |

## 3.6 Trigger Implementation

A critical `AFTER INSERT` trigger on `prescription_drugs` implements the system's core safety mechanism:

```sql
TRIGGER trg_check_drug_interactions
AFTER INSERT ON prescription_drugs
FOR EACH ROW
```

**Behavior**: When a drug is added to a prescription, the trigger:
1. Joins the new drug's ingredients with all existing drugs' ingredients in the same prescription
2. Cross-references against the `ingredient_interactions` knowledge base
3. Automatically inserts an `INTERACTION_ALERT` record for every dangerous combination found

This ensures that no interaction can go undetected — the safety check is enforced at the database level, independent of application logic.

## 3.7 Exception Handling

The `sp_safe_add_drug_to_prescription` procedure demonstrates MySQL exception handling using `DECLARE HANDLER`:

- **Error 1062** (Duplicate Entry): Catches attempts to add the same drug twice to a prescription
- **Error 1452** (FK Violation): Catches invalid prescription or drug IDs
- **SQLEXCEPTION** (General): Catches all other database errors with diagnostic messages

This ensures the procedure never crashes unexpectedly and always returns a meaningful error message.

## 3.8 Conclusion

The database design successfully implements a normalized, constraint-enforced schema that enables automated drug interaction detection. The combination of triggers for real-time safety checks, stored procedures for complex business logic, views for simplified reporting, and exception handling for robustness creates a reliable clinical decision support system suitable for real-world prescription validation.
