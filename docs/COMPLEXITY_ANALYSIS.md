# System Complexity Analysis & Reduction Plan

## Current Architecture Complexity Map

```
Component              Operational Overhead    Complexity Score
────────────────────   ────────────────────    ───────────────
Node.js API            Low (stateless)         3/10
Supabase PostgreSQL    Low (managed)           2/10
Redis                  Medium (state, tuning)  5/10
Cassandra              HIGH (ops-heavy)        9/10
Flutter Web + Mobile   Low (client-side)       3/10
CI Pipeline            Low (automated)         2/10
────────────────────   ────────────────────    ───────────────
TOTAL                                          24/60
```

---

## Proposal 1: Replace Cassandra with ClickHouse

### Why
Cassandra is the heaviest operational component (9/10 complexity). It requires:
- Tuning compaction strategies per table
- Managing RF=3 across 3 nodes minimum
- Monitoring partition sizes, tombstones, gc_grace
- Operating a separate analytics consumer worker

### ClickHouse Alternative
ClickHouse is a columnar analytics database that:
- Handles analytical queries orders of magnitude faster
- Has simpler operational model (single binary)
- Supports SQL (familiar to team)
- Managed options exist (ClickHouse Cloud, Altinity)

### Trade-offs
| Factor | Cassandra | ClickHouse |
|--------|-----------|------------|
| Write throughput | Excellent (designed for writes) | Good (batched inserts) |
| Query latency | Good for key lookups | Excellent for aggregations |
| Operational complexity | High (RF, compaction, repairs) | Low (single binary/managed) |
| Team expertise needed | High (CQL, data modeling) | Lower (SQL-based) |
| HIPAA compliance | Self-managed | ClickHouse Cloud has BAA |
| Cost (3 nodes) | ~$300/mo | ~$100/mo (managed) |

### Verdict
**Recommended for non-mission-critical analytics.** Keep Cassandra only if write throughput exceeds 50K events/sec. For a hospital system doing <10K events/day, ClickHouse is significantly simpler.

### Complexity reduction: **9/10 → 4/10** (saves ~5 points)

---

## Proposal 2: Use Supabase Edge Functions

### Why
The Node.js backend runs on a separate server, requiring:
- Container orchestration (Docker/K8s)
- Load balancer configuration
- Independent scaling
- SSL certificate management

### What Edge Functions Replace
Only **stateless, request-response** endpoints:
- Drug search
- Ingredient lookup
- Static data queries

### What They Cannot Replace
- WebSocket connections
- Long-running interaction checks
- Background workers (analytics consumer)
- Redis-dependent operations (rate limiting, caching)

### Trade-offs
| Factor | Node.js API | Supabase Edge Functions |
|--------|-------------|----------------------|
| Cold start | None (always running) | 50-200ms (Deno first req) |
| State (Redis, sessions) | Full access | No native Redis |
| Deployment | Docker + CI | supabase functions deploy |
| Cost | $50-200/mo server | Pay per invocation |
| Debugging | Full logs, tracing | Limited (dashboard only) |

### Verdict
**Partial adoption recommended.** Move read-only endpoints (drug search, ingredient list) to Edge Functions. Keep the core prescription/interaction/alert flow on Node.js.

### Complexity reduction: **3/10 → 2/10** (saves ~1 point, but reduces infra)

---

## Proposal 3: Merge Redis Cache + Queue

### Current State
Redis serves 3 roles:
1. **Cache**: Interaction lookup results
2. **Rate Limiter**: Redis-backed sliding window
3. **Queue**: Audit retry, analytics streams

### Simplification
These can remain in a single Redis instance but with better namespace isolation:
- `cache:interaction:*` (TTL: 1h)
- `rl:*` (TTL: per window)
- `audit:*` (persistent)
- `analytics:*` (persistent stream)

### Already Done
This is already the current design. No further simplification needed.

---

## Recommended Complexity Reduction Roadmap

| Priority | Change | Effort | Complexity Saved |
|----------|--------|--------|-----------------|
| 1 | Replace Cassandra with ClickHouse Cloud | 2 weeks | -5 points |
| 2 | Move read-only endpoints to Edge Functions | 1 week | -1 point |
| 3 | Remove legacy v1 routes after v2 GA | 3 days | -1 point |
| 4 | Auto-generate API docs with OpenAPI | 2 days | +0 (maintainability) |

**Net result: 24/60 → 17/60 complexity** (30% reduction)
