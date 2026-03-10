# Security Documentation

## Supabase Service Key Usage (S-02)

### Principle
The `SUPABASE_SERVICE_KEY` bypasses ALL Row-Level Security (RLS) policies. It must be used **only** for operations that cannot be performed with the anon key + RLS.

### Authorized Uses
| Use Case | File | Justification |
|----------|------|---------------|
| Admin user lookup during auth | `middleware/auth.js` | `auth.admin.getUserById()` requires service key |
| Initial user profile fetch | `middleware/auth.js` | Runs before RLS context is established |

### Prohibited Uses
- ❌ Any data query that can use RLS (prescriptions, alerts, etc.)
- ❌ Client-side code (Flutter app)
- ❌ Analytics/reporting queries
- ❌ Passing to frontend via environment variables

### Mitigation
- Service key is loaded from env (`SUPABASE_SERVICE_KEY`)
- `supabaseAnon` client is available for RLS-scoped queries
- All data-layer repositories use RLS-scoped queries
- Key rotation: rotate via Supabase dashboard → Settings → API keys

---

## JWT Key Rotation (S-01)

### Current State
JWT tokens are signed with a static `JWT_SECRET` env variable.

### Target Architecture
1. Store signing keys in a `jwt_keys` table
2. Sign new tokens with the current active key, embedding `kid` in the JWT header
3. Verify against any non-expired key (supports rotation window)
4. Rotate keys every 90 days via scheduled function

---

## Rate Limiting (S-04)

- Redis-backed via `rate-limit-redis` package
- Shared store for multi-instance deployments
- Key generator uses authenticated `user.id`, falls back to IP

| Endpoint | Window | Max Requests |
|----------|--------|-------------|
| General | 1 min | 100 |
| Interaction check | 1 min | 10 |
| Authentication | 15 min | 5 |

---

## RBAC Error Messages (S-05)

Information about available roles and the user's current role is never exposed in error responses. The generic message "You do not have sufficient permissions to access this resource." is returned for all 403 responses.
