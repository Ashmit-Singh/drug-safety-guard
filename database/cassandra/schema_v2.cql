-- ╔══════════════════════════════════════════════════════════════╗
-- ║  DRUG INTERACTION SYSTEM — CASSANDRA SCHEMA v2             ║
-- ║  Fixes C-01 through C-04 from architecture audit           ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE KEYSPACE IF NOT EXISTS drug_interaction_analytics
WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'dc1': 3
}
AND durable_writes = true;

USE drug_interaction_analytics;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 1: interaction_alert_logs (C-01 FIX)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FIX: Replaced hospital_id (never populated) with patient_id
--      (aligns with actual query: "alerts for this patient").
--      Added created_date TEXT bucketing to bound partition size.
--      Each partition = 1 patient × 1 day ≈ bounded to <10MB.

CREATE TABLE IF NOT EXISTS interaction_alert_logs (
    patient_id UUID,
    created_date TEXT,           -- YYYY-MM-DD bucketing key
    created_at TIMESTAMP,
    alert_id UUID,
    prescription_id UUID,
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
    PRIMARY KEY ((patient_id, created_date), created_at, alert_id)
) WITH CLUSTERING ORDER BY (created_at DESC, alert_id ASC)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 1,
    'compaction_window_unit': 'DAYS'
}
AND default_time_to_live = 31536000
AND gc_grace_seconds = 864000
AND comment = 'C-01: Alerts partitioned by patient+date (was hospital_id)';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 2: prescription_history (unchanged)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE IF NOT EXISTS prescription_history (
    patient_id UUID,
    prescribed_at TIMESTAMP,
    prescription_id UUID,
    doctor_id UUID,
    doctor_name TEXT,
    status TEXT,
    diagnosis TEXT,
    drugs LIST<FROZEN<TUPLE<TEXT, TEXT, TEXT>>>,
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
AND comment = 'Patient prescription timeline';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 3: system_audit_events (C-04 FIX)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FIX: Changed partition key from (event_date) to (event_date, hour_bucket).
--      Daily partitions could exceed 100MB for high-traffic systems.
--      Hourly bucketing: ~10MB/hour assuming 500 events/hour × 20KB avg.
--      hour_bucket is an INT (0-23) for the hour of the day.

CREATE TABLE IF NOT EXISTS system_audit_events (
    event_date TEXT,             -- YYYY-MM-DD
    hour_bucket INT,             -- 0-23, derived from EXTRACT(HOUR FROM timestamp)
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
    PRIMARY KEY ((event_date, hour_bucket), created_at, event_id)
) WITH CLUSTERING ORDER BY (created_at DESC, event_id ASC)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 1,
    'compaction_window_unit': 'HOURS'
}
AND default_time_to_live = 63072000
AND gc_grace_seconds = 864000
AND comment = 'C-04: HIPAA audit trail with hourly partition bucketing (~10MB/hour)';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 4: user_activity_logs (unchanged)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
AND comment = 'Per-user activity log';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 5: interaction_analytics (unchanged)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
-- TABLE 6a: drug_metadata (C-02 FIX — non-counter)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FIX: Counter tables cannot have non-counter columns.
-- Drug display names stored in a separate regular table.

CREATE TABLE IF NOT EXISTS drug_metadata (
    drug_id UUID PRIMARY KEY,
    drug_name TEXT,
    drug_class TEXT,
    updated_at TIMESTAMP
) WITH comment = 'C-02: Drug metadata separated from counter table';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TABLE 6b: drug_usage_analytics (C-02 FIX — counter only)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
AND comment = 'C-02: Counters only (metadata in drug_metadata table)';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MATERIALIZED VIEW (C-03)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Enables severity-filtered alert lookups without ALLOW FILTERING.

CREATE MATERIALIZED VIEW IF NOT EXISTS alert_logs_by_severity AS
    SELECT * FROM interaction_alert_logs
    WHERE severity IS NOT NULL
      AND patient_id IS NOT NULL
      AND created_date IS NOT NULL
      AND created_at IS NOT NULL
      AND alert_id IS NOT NULL
    PRIMARY KEY (severity, patient_id, created_date, created_at, alert_id)
WITH CLUSTERING ORDER BY (patient_id ASC, created_date DESC, created_at DESC, alert_id ASC)
AND comment = 'C-03: Severity-filtered alert lookups';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CONSISTENCY LEVEL NOTES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WRITES: QUORUM for audit events (RF=3 → 2 acks required)
-- READS:  LOCAL_ONE for analytics dashboards (eventual consistency OK)
-- READS:  LOCAL_QUORUM for audit reads (compliance requirement)
