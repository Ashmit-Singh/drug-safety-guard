<div align="center">

<img src="https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge" />
<img src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge" />
<img src="https://img.shields.io/badge/HIPAA-Compliant-red?style=for-the-badge" />
<img src="https://img.shields.io/badge/Node.js-20+-339933?style=for-the-badge&logo=node.js&logoColor=white" />
<img src="https://img.shields.io/badge/Flutter-3+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/PostgreSQL-Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />

<br /><br />

# 💊 RxGuard
### Clinical Drug Interaction Safety & Prescription Validation System

**Catch dangerous drug combinations before they reach patients.**  
RxGuard performs ingredient-level interaction detection in real time — surfacing severity-graded alerts the moment a prescription is being written, not after.

<br />

[🚀 Quick Start](#-quick-start) · [📐 Architecture](#-architecture) · [📡 API Reference](#-api-reference) · [🔒 Security](#-security--compliance) · [🧪 Testing](#-testing)

<br />

</div>

---

## 🩺 What is RxGuard?

Most drug interaction systems check at the **drug name level**. RxGuard goes deeper — it decomposes every drug into its constituent **active ingredients** and checks every ingredient pair across the entire prescription. This catches interactions that brand-name matching misses entirely.

**The result:** A prescriber adding a drug to an active prescription sees live warnings, severity classifications, and override audit trails — before anything is finalized.

```
Doctor adds Drug B to a prescription containing Drug A
         │
         ▼
  Decompose both drugs into ingredients
         │
         ▼
  Check every ingredient pair (O(n²·m²))
         │
         ├─ No interaction → ✅ Prescription proceeds
         │
         └─ Interaction found
                │
                ├─ MILD          → 🟡 Advisory shown
                ├─ MODERATE      → 🟠 Warning + confirm
                ├─ SEVERE        → 🔴 Alert + justification required
                └─ CONTRAINDICATED → 🚫 Blocked (override needs admin)
```

---

## ✨ Features at a Glance

| | Feature | Details |
|---|---|---|
| 🔬 | **Ingredient-Level Detection** | O(n²·m²) algorithm; catches what drug-name checks miss |
| ⚡ | **Real-Time Alerts** | PostgreSQL triggers + Supabase Realtime — no polling |
| 🎯 | **4-Tier Severity System** | Mild → Moderate → Severe → Contraindicated |
| 📝 | **Live Prescription Builder** | Warnings appear as drugs are added, not on submit |
| 🔴 | **Redis Interaction Cache** | 24h TTL; sub-millisecond repeat lookups |
| 📋 | **HIPAA Audit Trail** | Cassandra event log with 730-day retention |
| 📊 | **Analytics Dashboard** | Trend charts, top dangerous pairs, severity distribution |
| 👥 | **Role-Based Access** | Patient · Doctor · Pharmacist · Admin — enforced in middleware |
| 🏥 | **Batch Acknowledgement** | Pharmacists can triage multiple alerts in one action |
| 🔐 | **PKCE Auth Flow** | Supabase JWT + automatic token refresh |

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter 3 Frontend                      │
│          (Material 3 · Riverpod · fl_chart)                     │
└────────────────────────┬────────────────────────────────────────┘
                         │  HTTPS + JWT
┌────────────────────────▼────────────────────────────────────────┐
│                    Node.js + Express API                        │
│   ┌─────────────┐  ┌──────────────┐  ┌───────────────────────┐ │
│   │  Auth +     │  │  Interaction │  │   Zod Validation +    │ │
│   │  RBAC MW    │  │  Engine      │  │   Rate Limiter        │ │
│   └─────────────┘  └──────┬───────┘  └───────────────────────┘ │
└──────────────────────────┼─────────────────────────────────────┘
              ┌────────────┼──────────────┐
              │            │              │
   ┌──────────▼──┐  ┌──────▼──────┐  ┌───▼──────────┐
   │  Supabase   │  │    Redis    │  │  Cassandra   │
   │ PostgreSQL  │  │   Cache     │  │  Event Store │
   │  (14 tables │  │  (24h TTL) │  │  (Audit Log) │
   │   + RLS)    │  └─────────────┘  └──────────────┘
   └─────────────┘
```

### Technology Choices

| Layer | Technology | Why |
|---|---|---|
| Frontend | Flutter 3 + Riverpod | Cross-platform, reactive state, Material 3 |
| Backend | Node.js 20 + Express | Fast I/O, rich ecosystem, async interaction engine |
| Primary DB | Supabase (PostgreSQL) | RLS, Realtime subscriptions, managed auth |
| Cache | Redis | Sub-ms interaction lookups; 24h TTL per ingredient pair |
| Event Store | Cassandra | Time-series audit log; high-write throughput at scale |
| Container | Docker + Kubernetes | Reproducible deploys, horizontal scaling |
| CI/CD | GitHub Actions + Trivy | Automated test, build, Docker publish, vuln scan |

---

## 📂 Project Structure

```
rxguard/
├── backend/                    # Node.js + Express REST API
│   ├── src/
│   │   ├── middleware/         # auth, rbac, rateLimiter, logger, errorHandler
│   │   ├── routes/             # patients, doctors, drugs, ingredients,
│   │   │                       # prescriptions, alerts, interactions, analytics
│   │   ├── services/
│   │   │   ├── interactionEngine.js   # Core O(n²·m²) detection algorithm
│   │   │   ├── cassandraService.js    # Audit log writes/reads
│   │   │   └── redisService.js        # Interaction result caching
│   │   ├── app.js              # Express app + middleware chain
│   │   └── server.js           # Entrypoint + graceful shutdown
│   ├── Dockerfile
│   └── package.json
│
├── flutter_app/                # Flutter 3+ frontend
│   ├── lib/
│   │   ├── core/               # Theme, color tokens, string constants
│   │   ├── features/
│   │   │   ├── auth/           # Login, PKCE flow, session management
│   │   │   ├── dashboard/      # Overview + stat cards
│   │   │   ├── prescriptions/  # Builder UI with live interaction warnings
│   │   │   ├── patients/       # Patient records + prescription history
│   │   │   ├── drugs/          # Drug search + ingredient viewer
│   │   │   ├── alerts/         # Alert inbox, acknowledge, batch actions
│   │   │   └── analytics/      # fl_chart dashboards
│   │   ├── services/           # api_service.dart, supabase_service.dart
│   │   ├── state/              # Riverpod providers
│   │   ├── widgets/            # Shared components (severity badge, etc.)
│   │   └── main.dart
│   └── pubspec.yaml
│
├── database/
│   ├── postgresql/
│   │   └── schema.sql          # 14 tables, RLS policies, triggers, indexes
│   └── cassandra/
│       ├── schema.cql          # Keyspace + event table definitions
│       └── analytics_queries.cql
│
├── docs/
│   ├── architecture.md         # System diagrams (Mermaid)
│   └── security.md             # Security model + HIPAA controls
│
├── k8s/
│   └── api-deployment.yaml     # Kubernetes manifests
├── .github/workflows/
│   └── ci.yml                  # Test → Build → Docker → Trivy scan
└── docker-compose.yml          # Full local stack
```

---

## 🚀 Quick Start

### Prerequisites

- **Node.js** 20+
- **Flutter** 3+
- **Docker** & Docker Compose
- A **Supabase** project (free tier works)

---

### 1 — Database Setup

Apply the PostgreSQL schema to your Supabase project:

```bash
# In the Supabase SQL editor, run:
database/postgresql/schema.sql
```

This creates 14 tables with RLS policies, triggers for real-time alert generation, and all required indexes.

---

### 2 — Backend

```bash
cd backend
cp .env.example .env
```

Edit `.env` with your credentials:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key
REDIS_URL=redis://localhost:6379
CASSANDRA_HOSTS=localhost
JWT_SECRET=your-jwt-secret
```

```bash
npm install
npm run dev         # API starts at http://localhost:3000
```

---

### 3 — Docker Compose (Recommended)

Spins up the API, Redis, and Cassandra together:

```bash
docker-compose up -d
```

```
Services started:
  ✔ api        → http://localhost:3000
  ✔ redis      → localhost:6379
  ✔ cassandra  → localhost:9042
```

---

### 4 — Flutter App

```bash
cd flutter_app
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

---

## 📡 API Reference

All endpoints are prefixed with `/api/v1`. Authentication via `Authorization: Bearer <jwt>` is required on all endpoints except `/health`.

### Prescriptions

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/prescriptions` | Create a new prescription |
| `GET` | `/prescriptions/:id` | Get prescription details |
| `POST` | `/prescriptions/:id/drugs` | Add a drug — triggers interaction check |
| `GET` | `/prescriptions/:id/safety-check` | Full ingredient-level safety analysis |
| `GET` | `/patients/:id/prescriptions` | Full prescription history for a patient |

### Interactions & Alerts

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/interactions/check` | Ad-hoc ingredient interaction check |
| `GET` | `/alerts` | List alerts (filter by severity, status, date) |
| `POST` | `/alerts/:id/acknowledge` | Acknowledge a single alert |
| `POST` | `/alerts/batch-acknowledge` | Batch acknowledge multiple alerts |

### Drugs & Search

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/drugs/search?q=` | Fuzzy drug search |
| `GET` | `/drugs/:id/ingredients` | List active ingredients for a drug |

### Analytics

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/analytics/dashboard-stats` | Summary counts + severity breakdown |
| `GET` | `/analytics/top-interactions` | Most frequently flagged dangerous pairs |
| `GET` | `/analytics/alert-trends` | Alert volume over time (daily/weekly) |

### System

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Health check — returns service + DB status |

---

### Example: Add a Drug to a Prescription

**Request**
```http
POST /api/v1/prescriptions/prx_123/drugs
Authorization: Bearer eyJhbGci...
Content-Type: application/json

{
  "drug_id": "drg_warfarin",
  "dosage": "5mg",
  "frequency": "once_daily"
}
```

**Response — Interaction Detected**
```json
{
  "status": "warning",
  "drug_added": true,
  "alerts": [
    {
      "id": "alt_789",
      "severity": "SEVERE",
      "ingredient_a": "Warfarin",
      "ingredient_b": "Aspirin",
      "description": "Concurrent use significantly increases bleeding risk.",
      "requires_acknowledgement": true,
      "created_at": "2025-11-15T09:41:22Z"
    }
  ]
}
```

---

## 🔒 Security & Compliance

### Defense in Depth

```
Request
  │
  ├─ Rate Limiter       100 req/min (general)
  │                      10 req/min (interaction checks)
  │                       5 req/min (auth endpoints)
  │
  ├─ JWT Verification   Supabase PKCE flow · auto-refresh
  │
  ├─ RBAC Middleware    Role checked per route
  │                     (Patient / Doctor / Pharmacist / Admin)
  │
  ├─ Zod Validation     Schema-validated on every endpoint
  │
  ├─ PostgreSQL RLS     Row-level security on all 14 tables —
  │                     users only see data they're authorized for
  │
  └─ Cassandra Audit    Every action logged with actor, timestamp,
                        and payload — 730-day retention (HIPAA)
```

### HIPAA Controls

| Control | Implementation |
|---|---|
| Access Control | RBAC with middleware + Supabase RLS |
| Audit Log | Cassandra event store, 730-day TTL |
| Data in Transit | TLS enforced on all connections |
| Data at Rest | Supabase managed encryption |
| Minimum Necessary | RLS restricts data by role and relationship |
| Override Accountability | Every alert override logged with justification |

### Container Security

- Non-root Docker user in all containers
- Trivy vulnerability scanning in CI on every push
- Dependencies pinned with lockfiles (`package-lock.json`, `pubspec.lock`)

---

## 🧪 Testing

### Backend

```bash
cd backend
npm test                    # Unit + integration tests
npm run test:coverage       # Coverage report
```

### Flutter

```bash
cd flutter_app
flutter test                # Widget + unit tests
flutter test --coverage     # Coverage report
```

### CI Pipeline

Every pull request runs:

```
1. npm test (backend)
2. flutter test (frontend)
3. docker build (both images)
4. trivy scan (vulnerability check)
```

See `.github/workflows/ci.yml` for the full pipeline definition.

---

## 🗄 Database Schema Overview

The PostgreSQL schema (14 tables) covers:

- `users` · `roles` · `user_roles` — Identity and access
- `patients` · `doctors` · `pharmacists` — Clinical actors
- `drugs` · `ingredients` · `drug_ingredients` — Drug catalog + composition
- `interaction_rules` — Known interaction pairs with severity + evidence
- `prescriptions` · `prescription_drugs` — Active prescriptions
- `alerts` · `alert_acknowledgements` — Generated warnings + responses
- `audit_log` (Cassandra) — Immutable action trail

All tables have RLS enabled. Triggers on `prescription_drugs` automatically invoke the interaction engine and emit alerts via Supabase Realtime.

---

## 🛣 Roadmap

- [ ] FHIR R4 export for EHR integration
- [ ] NLP drug name disambiguation (handle misspellings + brand/generic synonyms)
- [ ] Mobile app (iOS + Android) via Flutter
- [ ] Pharmacogenomics layer (CYP450 interaction awareness)
- [ ] Multi-tenant / clinic workspace support

---

## 🤝 Contributing

Contributions are welcome. Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/your-feature`)
3. Commit with conventional commits (`feat:`, `fix:`, `docs:`)
4. Open a pull request against `main`

For major changes, open an issue first to discuss the approach.

---

## 📜 License

MIT © 2025 — See [LICENSE](./LICENSE) for details.

---

<div align="center">

**Built for clinicians. Designed for safety. Engineered for scale.**

If RxGuard prevents even one adverse drug event, it has done its job.

</div>
