# Chapter 3: System Design

## 3.1 System Architecture

The Drug Safety Guard system follows a **two-tier architecture** consisting of a relational database layer (MySQL) and a query interface (MySQL Workbench). The database serves as the core engine for storing drug data, patient records, prescriptions, known drug interactions, and system-generated safety alerts.

The system operates as follows:

1. A **doctor** creates a prescription for a patient and adds drugs to it.
2. A **database trigger** automatically fires upon each drug insertion, cross-referencing the newly added drug against all other drugs in the same prescription using the `drug_interactions` knowledge base.
3. If a dangerous interaction is found, the trigger inserts a record into the `alerts` table, immediately notifying the prescriber.
4. **Stored procedures** provide additional functionality for interaction checking, alert generation, and patient history retrieval.

This architecture ensures that safety checks are enforced at the database level, independent of any front-end application, making the system reliable and tamper-resistant.

## 3.2 Database Design

The database follows **Third Normal Form (3NF)** to eliminate redundancy and ensure data integrity. The design consists of six core tables organized into three logical layers:

**Master Data Layer:**
- `patients` — Stores patient demographics, contact information, and known allergies
- `drugs` — Master catalog of pharmaceutical products with brand names, generic names, and classifications

**Transactional Layer:**
- `prescriptions` — Prescription records linking patients to prescribing doctors
- `prescription_drugs` — Junction table mapping specific drugs (with dosage, frequency, and duration) to prescriptions

**Safety Intelligence Layer:**
- `drug_interactions` — Knowledge base of known dangerous drug-pair interactions with severity classifications
- `alerts` — System-generated safety notifications triggered when dangerous combinations are detected

## 3.3 Entity-Relationship Model

The ER model captures the following relationships:

| Relationship | Type | Description |
|-------------|------|-------------|
| Patient → Prescription | One-to-Many | A patient can have multiple prescriptions |
| Prescription → Prescription_Drugs | One-to-Many | A prescription contains multiple drugs |
| Drug → Prescription_Drugs | One-to-Many | A drug can appear in multiple prescriptions |
| Drug → Drug_Interactions | Many-to-Many (self) | A drug can interact with multiple other drugs |
| Prescription → Alerts | One-to-Many | A prescription may generate multiple alerts |

```
PATIENTS (1) ──────< (M) PRESCRIPTIONS
                              |
                              | (1)
                              ↓
                         (M) PRESCRIPTION_DRUGS (M) >──── (1) DRUGS
                                                                |
                              ALERTS                           (M)
                                ↑                               |
                                |                        DRUG_INTERACTIONS
                          (auto-generated                  (self-referencing
                           by trigger)                      M:M on DRUGS)
```

## 3.4 Table Structure

### PATIENTS
| Column | Type | Constraints |
|--------|------|-------------|
| patient_id | INT AUTO_INCREMENT | PRIMARY KEY |
| first_name | VARCHAR(100) | NOT NULL |
| last_name | VARCHAR(100) | NOT NULL |
| date_of_birth | DATE | NOT NULL, CHECK (< CURDATE()) |
| gender | ENUM | NOT NULL |
| phone | VARCHAR(20) | UNIQUE |
| email | VARCHAR(255) | UNIQUE |

### DRUGS
| Column | Type | Constraints |
|--------|------|-------------|
| drug_id | INT AUTO_INCREMENT | PRIMARY KEY |
| brand_name | VARCHAR(255) | NOT NULL, CHECK (length ≥ 2) |
| generic_name | VARCHAR(255) | NOT NULL |
| drug_class | VARCHAR(200) | — |

### DRUG_INTERACTIONS
| Column | Type | Constraints |
|--------|------|-------------|
| interaction_id | INT AUTO_INCREMENT | PRIMARY KEY |
| drug_a_id | INT | FK → drugs, NOT NULL |
| drug_b_id | INT | FK → drugs, NOT NULL |
| severity | ENUM('mild','moderate','severe','contraindicated') | NOT NULL |
| description | TEXT | NOT NULL |
| — | — | CHECK (drug_a_id ≠ drug_b_id), UNIQUE(drug_a_id, drug_b_id) |

### PRESCRIPTIONS
| Column | Type | Constraints |
|--------|------|-------------|
| prescription_id | INT AUTO_INCREMENT | PRIMARY KEY |
| patient_id | INT | FK → patients (CASCADE) |
| doctor_name | VARCHAR(255) | NOT NULL |
| status | ENUM | DEFAULT 'draft' |

### PRESCRIPTION_DRUGS
| Column | Type | Constraints |
|--------|------|-------------|
| pd_id | INT AUTO_INCREMENT | PRIMARY KEY |
| prescription_id | INT | FK → prescriptions (CASCADE) |
| drug_id | INT | FK → drugs (RESTRICT) |
| dosage | VARCHAR(100) | NOT NULL |
| — | — | UNIQUE(prescription_id, drug_id) |

### ALERTS
| Column | Type | Constraints |
|--------|------|-------------|
| alert_id | INT AUTO_INCREMENT | PRIMARY KEY |
| prescription_id | INT | FK → prescriptions (CASCADE) |
| drug_a_id, drug_b_id | INT | FK → drugs (CASCADE) |
| severity | ENUM | NOT NULL |

## 3.5 Constraints

The schema employs the following integrity constraints:

- **Entity Integrity**: All tables have AUTO_INCREMENT primary keys ensuring unique identification.
- **Referential Integrity**: Foreign keys with CASCADE/RESTRICT policies maintain consistency across related tables.
- **Domain Integrity**: ENUM types restrict severity to valid values; CHECK constraints prevent invalid dates and self-referencing interactions.
- **User-Defined Integrity**: UNIQUE constraints on (prescription_id, drug_id) prevent duplicate drug entries per prescription; UNIQUE on (drug_a_id, drug_b_id) prevents duplicate interaction records.

## 3.6 SQL Implementation

The project demonstrates the following SQL capabilities:

- **Basic Queries**: SELECT, WHERE, ORDER BY, GROUP BY with aggregate functions
- **JOIN Operations**: INNER JOIN (prescriptions + patients), LEFT JOIN (all patients including those without prescriptions), RIGHT JOIN (all drugs including unprescribed ones), Multi-table JOIN (6 tables for complete alert details)
- **Subqueries**: Nested queries using IN, EXISTS, and correlated subqueries
- **Views**: `DangerousDrugPairs` (severe interactions) and `PatientPrescriptionSummary` (complete patient overview)
- **Set Operations**: UNION for combining drug IDs from both sides of interaction pairs

## 3.7 Stored Procedures

Three stored procedures implement the core business logic:

1. **`sp_check_interaction(drug_a, drug_b)`** — Checks whether two specific drugs have a known interaction and returns the severity and recommendation.
2. **`sp_generate_alerts(prescription_id)`** — Scans all drug pairs in a prescription against the interaction knowledge base and generates appropriate alerts.
3. **`sp_patient_history(patient_id)`** — Returns a comprehensive view of a patient's prescription history including drugs prescribed and alert counts.

Additionally, `sp_safe_add_drug()` demonstrates exception handling with DECLARE HANDLER for graceful error recovery during drug insertion.

## 3.8 Triggers

The system employs an `AFTER INSERT` trigger on `prescription_drugs`:

```
TRIGGER trg_auto_alert
AFTER INSERT ON prescription_drugs
FOR EACH ROW
```

When a drug is added to a prescription, this trigger automatically:
1. Compares the new drug against every existing drug in the same prescription
2. Checks each pair against the `drug_interactions` table
3. Inserts an alert record for every dangerous combination found

This ensures **zero-miss detection** — every interaction is caught at the database level, regardless of how the data is inserted.

## 3.9 Security Considerations

- **Cascading Deletes**: When a prescription is deleted, all associated drugs and alerts are automatically removed, preventing orphaned records.
- **Restricted Deletion**: Drugs referenced in prescriptions cannot be deleted (ON DELETE RESTRICT), preserving prescription integrity.
- **Input Validation**: CHECK constraints prevent invalid data (e.g., future birth dates, self-referencing interactions).
- **Exception Handling**: Stored procedures use DECLARE HANDLER to catch constraint violations gracefully, preventing system crashes and providing meaningful error messages.
- **Audit Trail**: All tables include `created_at` timestamps for temporal tracking.

---

# Section 15: Presentation Script

## Slide 1 — Introduction (30 seconds)

> "Good morning. Our project is **Drug Safety Guard** — a database system that detects dangerous drug interactions before a prescription reaches the patient. The problem is simple: when a patient takes multiple medications, some drug combinations can cause life-threatening reactions. Our system solves this by automating interaction detection at the database level."

## Slide 2 — Database Design (45 seconds)

> "The database has six tables in Third Normal Form. Patients and Drugs are our master data. Prescriptions link patients to their medications through the Prescription_Drugs junction table. The Drug_Interactions table stores 20 clinically accurate interaction pairs with severity levels: mild, moderate, severe, and contraindicated. Finally, the Alerts table stores system-generated warnings."

## Slide 3 — Live Demonstration (2 minutes)

> "Let me demonstrate the system live. I'll create a new patient, write a prescription, and add Warfarin — an anticoagulant. No alerts. Now watch what happens when I add Fluconazole — an antifungal."
>
> *(Run the trigger demo)*
>
> "The system automatically detected a **contraindicated** interaction. The trigger fired, checked the drug_interactions table, and inserted an alert. This happened instantly at the database level — no application code needed."

## Slide 4 — Advanced Features (1 minute)

> "We've also implemented stored procedures for interaction checking and patient history, a cursor-based scanner that reviews all prescriptions, exception handling for error recovery, and two views for reporting. All queries use proper JOINs, subqueries, and GROUP BY operations as required."

## Slide 5 — Conclusion (30 seconds)

> "Drug Safety Guard demonstrates how a well-designed relational database can enforce patient safety rules automatically. The trigger-based approach ensures zero-miss detection. This system could be extended with a web frontend, role-based access control, and integration with electronic health records. Thank you."
