-- ╔══════════════════════════════════════════════════════════════╗
-- ║  DRUG INTERACTION SYSTEM — CASSANDRA ANALYTICS QUERIES     ║
-- ╚══════════════════════════════════════════════════════════════╝

USE drug_interaction_analytics;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- QUERY 1: Top 10 Most Dangerous Drug Interaction Pairs (Last 30 Days)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Strategy: Since interaction_analytics is partitioned by drug_pair_key,
-- we cannot efficiently query across ALL pairs in Cassandra alone.
-- Two approaches:
--
-- APPROACH A: Application-side aggregation (recommended for <10K pairs)
-- 1. Maintain a materialized view or secondary lookup table
-- 2. Query known drug pairs and aggregate in the application layer

-- Step 1: Create a lookup table of all known drug pairs
CREATE TABLE IF NOT EXISTS known_drug_pairs (
    bucket INT,  -- fixed set of buckets (e.g., 0-9) for even distribution
    drug_pair_key TEXT,
    drug_a_name TEXT,
    drug_b_name TEXT,
    total_occurrences COUNTER,
    PRIMARY KEY ((bucket), drug_pair_key)
);

-- Step 2: Query each bucket and aggregate application-side
-- SELECT drug_pair_key, drug_a_name, drug_b_name, total_occurrences
-- FROM known_drug_pairs WHERE bucket = ?;
-- Repeat for all buckets (0-9), sort in application, take top 10.

-- APPROACH B: Spark connector for batch analytics
-- SELECT drug_pair_key, drug_a_name, drug_b_name, COUNT(*) as occurrence_count
-- FROM interaction_analytics
-- WHERE occurred_at >= '2026-02-09T00:00:00Z'
-- GROUP BY drug_pair_key
-- ORDER BY occurrence_count DESC
-- LIMIT 10;
-- NOTE: Run via Spark Cassandra Connector (spark.read.cassandraFormat)

-- For real-time dashboard, use the counter table approach:
-- Application queries all 10 buckets of known_drug_pairs,
-- merges results, sorts by total_occurrences DESC, returns top 10.

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- QUERY 2: Alert Volume Per Hospital Per Week
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Direct query on interaction_alert_logs with hospital_id partition
-- Application provides the date range for the week.

-- For a specific hospital and week:
SELECT COUNT(*) AS alert_count,
       severity,
       toDate(created_at) AS alert_date
FROM interaction_alert_logs
WHERE hospital_id = ?
  AND created_at >= '2026-03-04T00:00:00Z'
  AND created_at < '2026-03-11T00:00:00Z'
GROUP BY toDate(created_at);
-- Note: GROUP BY on clustering columns is supported in Cassandra 4.0+

-- Pre-aggregated weekly stats table for cross-hospital comparison:
CREATE TABLE IF NOT EXISTS weekly_hospital_alert_stats (
    year_week TEXT,          -- '2026-W10'
    hospital_id UUID,
    hospital_name TEXT STATIC,
    total_alerts COUNTER,
    severe_alerts COUNTER,
    contraindicated_alerts COUNTER,
    PRIMARY KEY ((year_week), hospital_id)
);

-- Query for a specific week across all hospitals:
-- SELECT hospital_id, hospital_name, total_alerts, severe_alerts
-- FROM weekly_hospital_alert_stats WHERE year_week = '2026-W10';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- QUERY 3: Patients With Most Active Alerts
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Strategy: Maintain a counter table tracking active alerts per patient

CREATE TABLE IF NOT EXISTS patient_alert_counts (
    bucket INT,
    patient_id UUID,
    patient_name TEXT,
    active_alert_count COUNTER,
    severe_alert_count COUNTER,
    PRIMARY KEY ((bucket), patient_id)
);

-- Increment on alert creation:
-- UPDATE patient_alert_counts
-- SET active_alert_count = active_alert_count + 1,
--     severe_alert_count = severe_alert_count + 1  -- if severity is severe/contraindicated
-- WHERE bucket = ? AND patient_id = ?;

-- Query and aggregate across buckets in application layer:
-- SELECT patient_id, patient_name, active_alert_count, severe_alert_count
-- FROM patient_alert_counts WHERE bucket = ?;
-- Merge, sort by active_alert_count DESC, take top N.

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- QUERY 4: Ingredient Pair Interaction Frequency Heatmap Data
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Strategy: Pre-aggregated table for heatmap visualization

CREATE TABLE IF NOT EXISTS ingredient_pair_heatmap (
    month TEXT,                     -- '2026-03'
    ingredient_a_name TEXT,
    ingredient_b_name TEXT,
    occurrence_count COUNTER,
    PRIMARY KEY ((month), ingredient_a_name, ingredient_b_name)
);

-- Increment on each interaction alert:
-- UPDATE ingredient_pair_heatmap
-- SET occurrence_count = occurrence_count + 1
-- WHERE month = '2026-03'
--   AND ingredient_a_name = 'Warfarin Sodium'
--   AND ingredient_b_name = 'Aspirin';

-- Query for heatmap (single month, returns all pairs):
-- SELECT ingredient_a_name, ingredient_b_name, occurrence_count
-- FROM ingredient_pair_heatmap WHERE month = '2026-03';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- QUERY 5: Alert Severity Breakdown by Drug Category
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Strategy: Pre-aggregated counter table

CREATE TABLE IF NOT EXISTS severity_by_drug_class (
    drug_class TEXT,
    severity TEXT,
    month TEXT,
    alert_count COUNTER,
    PRIMARY KEY ((drug_class), severity, month)
) WITH CLUSTERING ORDER BY (severity ASC, month DESC);

-- Increment:
-- UPDATE severity_by_drug_class
-- SET alert_count = alert_count + 1
-- WHERE drug_class = 'Anticoagulant' AND severity = 'severe' AND month = '2026-03';

-- Query for a specific drug class:
-- SELECT severity, month, alert_count
-- FROM severity_by_drug_class WHERE drug_class = 'Anticoagulant';

-- Query for all drug classes (requires iterating known classes):
-- Application maintains a list of drug classes and queries each partition.

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NOTES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ALLOW FILTERING WARNING:
-- None of the above queries require ALLOW FILTERING.
-- All queries are designed to hit partition keys directly,
-- with optional clustering column ranges.
-- ALLOW FILTERING should be avoided in production as it
-- causes full table scans.

-- MATERIALIZED VIEWS (Cassandra 3.0+):
-- Materialized views can be used as alternatives to the counter tables,
-- but come with known stability issues in Cassandra.
-- Recommendation: Use application-managed counter tables (above)
-- instead of materialized views for production workloads.

-- SPARK CONNECTOR FOR BATCH ANALYTICS:
-- For complex cross-partition analytics (e.g., global top-N queries,
-- cross-hospital comparisons, trend analysis):
-- 1. Use DataStax Spark Cassandra Connector
-- 2. Configure: spark.cassandra.connection.host
-- 3. Read tables as DataFrames: spark.read.cassandraFormat("table", "keyspace")
-- 4. Run SQL-like aggregations in Spark
-- 5. Write results back to pre-aggregated Cassandra tables
-- 6. Schedule via cron or Airflow (daily/hourly batch jobs)
--
-- Example Spark job (PySpark):
-- df = spark.read \
--     .format("org.apache.spark.sql.cassandra") \
--     .options(table="interaction_analytics", keyspace="drug_interaction_analytics") \
--     .load()
-- top_pairs = df.filter(df.occurred_at >= lit("2026-02-09")) \
--     .groupBy("drug_pair_key", "drug_a_name", "drug_b_name") \
--     .count() \
--     .orderBy(desc("count")) \
--     .limit(10)
