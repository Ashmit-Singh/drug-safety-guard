# HIPAA Compliance Checklist

## Drug Interaction Safety & Prescription Validation System

### 1. Business Associate Agreements (BAAs)
| Service | BAA Status | Notes |
|---------|-----------|-------|
| Supabase | ✅ Required | Available on Pro/Team plans |
| Cassandra Host (self-hosted) | ⚠️ N/A if self-hosted | Ensure host infrastructure is BAA-covered |
| Cassandra Host (managed) | ❌ Needed | Obtain BAA from DataStax/Astra/provider |
| Redis (self-hosted) | ⚠️ N/A if self-hosted | No PHI stored in Redis (cache only) |
| Cloud Provider (AWS/GCP) | ✅ Required | Standard BAA available |

### 2. Access Controls
- [x] Role-based access control (RBAC) on all endpoints
- [x] Row-Level Security (RLS) on PostgreSQL tables
- [x] JWT authentication with token expiration
- [ ] JWT key rotation (90-day cycle) — *migration provided*
- [x] Service key restricted to auth bootstrap only
- [x] Minimum necessary access principle (SECURITY INVOKER on RLS functions)

### 3. Encryption
- [x] **In Transit**: HTTPS/TLS enforced (Supabase default)
- [x] **In Transit**: Cassandra TLS configurable via `cassandra-driver`
- [ ] **At Rest**: pgsodium column-level encryption — *migration 004 provided*
- [x] **At Rest**: Supabase managed encryption at storage level

### 4. Audit Trail
- [x] PostgreSQL `audit_log` table with RLS restrictions
- [x] Cassandra `system_audit_events` with hourly bucketing
- [x] Reliable audit writes via Redis retry queue (no silent drops)
- [x] Dead-letter queue monitoring (alert at >1000 items)
- [x] Request ID (`X-Request-Id`) for end-to-end tracing

### 5. PHI Handling
- [x] No raw PHI in application logs (Winston configured)
- [x] Error responses never expose internal data
- [x] Cassandra indexes use patient_id (not names) as partition keys
- [x] XSS sanitization on text input fields
- [x] Input validation via Zod schemas

### 6. Data Retention
- [x] Soft-delete on all PHI tables (`deleted_at` column)
- [ ] Hard-delete retention policy: 7-year threshold — *migration 004 provided*
- [ ] pg_cron scheduling for weekly retention enforcement
- [x] Cassandra TTLs: audit (2yr), alerts (1yr), activity (90d)

### 7. Breach Notification
- [ ] Incident response plan documented
- [ ] Automated alerts on suspicious access patterns
- [x] Rate limiting on all endpoints (Redis-backed)
- [x] Failed auth attempt tracking

### 8. Minimum Necessary Standard
- [x] RLS policies scope data to user's role
- [x] Explicit column lists in queries (no `SELECT *`)
- [x] Pharmacist access limited to prescription read
- [x] Patient sees only own data

### 9. Compliance Score
| Area | Status |
|------|--------|
| Technical Safeguards | 85% |
| Administrative Safeguards | 60% |
| Physical Safeguards | Managed by cloud provider |
| **Overall** | **~75%** |

> **NOTE**: Full HIPAA compliance requires organizational policies, staff training, and incident response procedures beyond the technical implementation.
