-- ╔══════════════════════════════════════════════════════════════╗
-- ║  DRUG INTERACTION SYSTEM — CASSANDRA SCHEMA                ║
-- ║  Query-First Modeling for High-Volume Event Storage         ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KEYSPACE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Replication: NetworkTopologyStrategy for production (multi-DC),
-- SimpleStrategy for local dev. RF=3 ensures availability with one node down.

CREATE KEYSPACE IF NOT EXISTS drug_interaction_analytics
WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'dc1': 3
}
AND durable_writes = true;

USE drug_interaction_analytics;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 1: interaction_alert_logs
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Query: "Get all interaction alerts for a hospital, most recent first"
-- Partition Key: hospital_id — groups alerts by hospital for locality
-- Clustering: created_at DESC — natural time-series ordering
-- TTL: 365 days (alerts older than 1 year archived to cold storage)
-- Compaction: TimeWindowCompactionStrategy (ideal for time-series data)

CREATE TABLE IF NOT EXISTS interaction_alert_logs (
    hospital_id UUID,
    created_at TIMESTAMP,
    alert_id UUID,
    prescription_id UUID,
    patient_id UUID,
    patient_name TEXT,
    drug_a_name TEXT,
    drug_b_name TEXT,
    ingredient_a_name TEXT,
    ingredient_b_name TEXT,
    severity TEXT,
    clinical_effect TEXT,
    recommendation TEXT,
    status TEXT,
    acknowledged_by TEXT,
    acknowledged_at TIMESTAMP,
    doctor_name TEXT,
    PRIMARY KEY ((hospital_id), created_at, alert_id)
) WITH CLUSTERING ORDER BY (created_at DESC, alert_id ASC)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 1,
    'compaction_window_unit': 'DAYS'
}
AND default_time_to_live = 31536000
AND gc_grace_seconds = 864000
AND comment = 'Interaction alerts partitioned by hospital for dashboard queries';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 2: prescription_history
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Query: "Get all prescriptions for a patient, most recent first"
-- Partition Key: patient_id — each patient's history is co-located
-- Clustering: prescribed_at DESC — chronological timeline
-- TTL: None (medical records retained indefinitely)
-- Compaction: SizeTieredCompactionStrategy (good for append-heavy workloads)

CREATE TABLE IF NOT EXISTS prescription_history (
    patient_id UUID,
    prescribed_at TIMESTAMP,
    prescription_id UUID,
    doctor_id UUID,
    doctor_name TEXT,
    status TEXT,
    diagnosis TEXT,
    drugs LIST<FROZEN<TUPLE<TEXT, TEXT, TEXT>>>,  -- (drug_name, dosage, frequency)
    alert_count INT,
    max_severity TEXT,
    notes TEXT,
    PRIMARY KEY ((patient_id), prescribed_at, prescription_id)
) WITH CLUSTERING ORDER BY (prescribed_at DESC, prescription_id ASC)
AND compaction = {
    'class': 'SizeTieredCompactionStrategy',
    'min_threshold': 4,
    'max_threshold': 32
}
AND gc_grace_seconds = 864000
AND comment = 'Patient prescription timeline for profile views';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 3: system_audit_events
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Query: "Get all audit events for a given date, most recent first"
-- Partition Key: event_date (TEXT, format YYYY-MM-DD) — daily partitions prevent hot spots
-- Clustering: created_at DESC — time ordering within the day
-- TTL: 730 days (2 years for HIPAA compliance)
-- Compaction: TimeWindowCompactionStrategy

CREATE TABLE IF NOT EXISTS system_audit_events (
    event_date TEXT,
    created_at TIMESTAMP,
    event_id UUID,
    user_id UUID,
    user_email TEXT,
    user_role TEXT,
    action TEXT,
    resource_type TEXT,
    resource_id UUID,
    details TEXT,
    ip_address TEXT,
    user_agent TEXT,
    request_method TEXT,
    request_path TEXT,
    response_status INT,
    duration_ms INT,
    PRIMARY KEY ((event_date), created_at, event_id)
) WITH CLUSTERING ORDER BY (created_at DESC, event_id ASC)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 1,
    'compaction_window_unit': 'DAYS'
}
AND default_time_to_live = 63072000
AND gc_grace_seconds = 864000
AND comment = 'HIPAA-aligned audit trail for all system actions';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 4: user_activity_logs
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Query: "Get recent activity for a specific user"
-- Partition Key: user_id — per-user activity co-located
-- Clustering: created_at DESC — most recent first
-- TTL: 90 days (activity logs are ephemeral)
-- Compaction: TimeWindowCompactionStrategy

CREATE TABLE IF NOT EXISTS user_activity_logs (
    user_id UUID,
    created_at TIMESTAMP,
    activity_id UUID,
    action TEXT,
    resource_type TEXT,
    resource_id UUID,
    details TEXT,
    ip_address TEXT,
    session_id TEXT,
    PRIMARY KEY ((user_id), created_at, activity_id)
) WITH CLUSTERING ORDER BY (created_at DESC, activity_id ASC)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 7,
    'compaction_window_unit': 'DAYS'
}
AND default_time_to_live = 7776000
AND gc_grace_seconds = 864000
AND comment = 'Per-user activity log for session tracking';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 5: interaction_analytics
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Query: "How often does a specific drug pair interaction fire?"
-- Partition Key: drug_pair_key (TEXT, format: "{drug_a_id}:{drug_b_id}" canonical order)
-- Clustering: occurred_at DESC — time series of occurrences
-- TTL: 365 days
-- Compaction: TimeWindowCompactionStrategy

CREATE TABLE IF NOT EXISTS interaction_analytics (
    drug_pair_key TEXT,
    occurred_at TIMESTAMP,
    event_id UUID,
    prescription_id UUID,
    patient_id UUID,
    hospital_id UUID,
    severity TEXT,
    ingredient_a_name TEXT,
    ingredient_b_name TEXT,
    drug_a_name TEXT,
    drug_b_name TEXT,
    doctor_id UUID,
    PRIMARY KEY ((drug_pair_key), occurred_at, event_id)
) WITH CLUSTERING ORDER BY (occurred_at DESC, event_id ASC)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 7,
    'compaction_window_unit': 'DAYS'
}
AND default_time_to_live = 31536000
AND gc_grace_seconds = 864000
AND comment = 'Interaction frequency analytics per drug pair';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 6a: drug_metadata (non-counter reference)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Stores drug display names and class for joining with counter data.
-- Counter tables in Cassandra cannot have non-counter columns
-- (except primary key columns), so metadata is stored separately.

CREATE TABLE IF NOT EXISTS drug_metadata (
    drug_id UUID PRIMARY KEY,
    drug_name TEXT,
    drug_class TEXT,
    updated_at TIMESTAMP
) WITH comment = 'Drug display metadata for analytics lookups';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 6b: drug_usage_analytics (counter table)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Query: "How many times was a drug prescribed per month?"
-- Partition Key: drug_id — per-drug stats
-- Clustering: month (TEXT, format YYYY-MM) — allows range scans by month
-- TTL: None (aggregate stats retained)
-- Compaction: SizeTieredCompactionStrategy (counter-like pattern)
-- Uses counter columns for atomic increment from multiple API nodes.

CREATE TABLE IF NOT EXISTS drug_usage_analytics (
    drug_id UUID,
    month TEXT,
    prescription_count COUNTER,
    alert_count COUNTER,
    severe_alert_count COUNTER,
    unique_patient_count COUNTER,
    PRIMARY KEY ((drug_id), month)
) WITH CLUSTERING ORDER BY (month DESC)
AND compaction = {
    'class': 'SizeTieredCompactionStrategy'
}
AND gc_grace_seconds = 864000
AND comment = 'Monthly drug usage and alert counters';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CONSISTENCY LEVEL NOTES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WRITES: Use QUORUM consistency for audit events and alerts
--   → Ensures data durability: majority of replicas acknowledge
--   → CL QUORUM with RF=3 requires 2 nodes to acknowledge
--
-- READS:  Use LOCAL_ONE for analytics dashboards
--   → Low latency for non-critical reads
--   → Acceptable eventual consistency for dashboard aggregates
--
-- READS:  Use LOCAL_QUORUM for audit reads (compliance)
--   → Ensures read-your-own-writes semantics for audit logs

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PARTITION KEY DESIGN RATIONALE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- interaction_alert_logs:  hospital_id  → hospitals generate bounded alert volumes
-- prescription_history:    patient_id   → single patient's history fits in one partition
-- system_audit_events:     event_date   → daily bucketing prevents unbounded growth
-- user_activity_logs:      user_id      → per-user activity is naturally bounded
-- interaction_analytics:   drug_pair_key → finite number of drug pairs
-- drug_usage_analytics:    drug_id      → finite number of drugs
