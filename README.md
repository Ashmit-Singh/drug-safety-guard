# 🛡️ Drug Interaction Safety & Prescription Validation System

A production-grade clinical decision support system that detects harmful drug combinations at the **ingredient level** and generates real-time safety alerts before prescriptions reach patients.

---

## 🏗 Architecture

```
┌────────────┐     ┌──────────────┐     ┌────────────────┐
│  Flutter 3  │────▶│  Node.js +   │────▶│   Supabase     │
│  (Frontend) │◀────│  Express API │◀────│  (PostgreSQL)  │
└────────────┘     └──────┬───────┘     └────────────────┘
                          │
                   ┌──────┴───────┐
                   │              │
              ┌────▼────┐   ┌────▼────┐
              │  Redis   │   │Cassandra│
              │ (Cache)  │   │(Events) │
              └──────────┘   └─────────┘
```

## 📂 Project Structure

```
Drug Interaction/
├── database/
│   ├── postgresql/         # Supabase PostgreSQL DDL (14 tables, RLS, triggers)
│   │   └── schema.sql
│   └── cassandra/          # Cassandra event-store schemas
│       ├── schema.cql
│       └── analytics_queries.cql
├── backend/                # Node.js + Express REST API
│   ├── src/
│   │   ├── middleware/     # auth, rbac, rateLimiter, logger, errorHandler
│   │   ├── routes/         # patients, doctors, drugs, ingredients,
│   │   │                   # prescriptions, alerts, interactions, analytics
│   │   ├── services/       # interactionEngine, cassandraService, redisService
│   │   ├── app.js          # Express app setup
│   │   └── server.js       # Server entry + graceful shutdown
│   ├── Dockerfile
│   └── package.json
├── flutter_app/            # Flutter 3+ (Material 3, Riverpod)
│   ├── lib/
│   │   ├── core/           # Theme, colors, strings
│   │   ├── features/       # auth, dashboard, prescriptions,
│   │   │                   # patients, drugs, alerts, analytics
│   │   ├── services/       # api_service, supabase_service
│   │   ├── state/          # Riverpod providers
│   │   ├── widgets/        # Shared components
│   │   └── main.dart
│   └── pubspec.yaml
├── docs/
│   ├── architecture.md     # System diagrams (Mermaid)
│   └── security.md         # Security & HIPAA compliance
├── k8s/                    # Kubernetes manifests
│   └── api-deployment.yaml
├── .github/workflows/
│   └── ci.yml              # CI/CD (test, build, Docker, Trivy)
└── docker-compose.yml      # Full stack orchestration
```

## 🚀 Quick Start

### Prerequisites
- Node.js 20+, Flutter 3+, Docker & Docker Compose
- Supabase project (with schema.sql applied)

### 1. Backend Setup
```bash
cd backend
cp .env.example .env            # Configure Supabase, Redis, Cassandra
npm install
npm run dev                     # Starts on http://localhost:3000
```

### 2. Docker Compose (Full Stack)
```bash
docker-compose up -d            # Starts API + Redis + Cassandra
```

### 3. Flutter App
```bash
cd flutter_app
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

## 🔑 Key Features

| Feature | Description |
|---------|-------------|
| **Ingredient-Level Detection** | O(n²·m²) algorithm checks every ingredient pair across all drugs |
| **Real-Time Alerts** | PostgreSQL triggers + Supabase Realtime push alerts instantly |
| **Severity Classification** | 4 levels: Mild → Moderate → Severe → Contraindicated |
| **Prescription Builder** | Add drugs, see warnings live, acknowledge or override |
| **Redis Caching** | 24h TTL on ingredient interaction lookups for sub-ms response |
| **HIPAA Audit Trail** | Every action logged to Cassandra with 2-year retention |
| **Analytics Dashboard** | fl_chart visualizations — trends, severity distribution, top pairs |
| **Role-Based Access** | Patient, Doctor, Admin, Pharmacist roles with middleware guards |

## 🔒 Security

- **Supabase RLS** — Row-level security on all 14 tables
- **JWT Auth** — Automatic token refresh, Supabase PKCE flow
- **Rate Limiting** — 100 req/min general, 10/min interaction checks, 5/min auth
- **Input Validation** — Zod schemas on every endpoint
- **HIPAA Audit** — Cassandra audit log with 730-day TTL
- **Container Security** — Non-root Docker user, Trivy scanning in CI

## 📊 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/health` | Health check |
| `POST` | `/api/v1/prescriptions` | Create prescription |
| `POST` | `/api/v1/prescriptions/:id/drugs` | Add drug (triggers interaction check) |
| `GET` | `/api/v1/prescriptions/:id/safety-check` | Full safety analysis |
| `POST` | `/api/v1/interactions/check` | Ad-hoc interaction check |
| `GET` | `/api/v1/alerts` | List alerts (filterable) |
| `POST` | `/api/v1/alerts/:id/acknowledge` | Acknowledge alert |
| `POST` | `/api/v1/alerts/batch-acknowledge` | Batch acknowledge |
| `GET` | `/api/v1/analytics/dashboard-stats` | Dashboard summary |
| `GET` | `/api/v1/analytics/top-interactions` | Top dangerous pairs |
| `GET` | `/api/v1/analytics/alert-trends` | Alert volume over time |
| `GET` | `/api/v1/drugs/search?q=` | Search drugs |
| `GET` | `/api/v1/patients/:id/prescriptions` | Patient history |

## 🧪 Testing

```bash
# Backend
cd backend && npm test

# Flutter
cd flutter_app && flutter test
```

## 📜 License

MIT
