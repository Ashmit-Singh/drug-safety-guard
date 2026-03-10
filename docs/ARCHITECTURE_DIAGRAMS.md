# Drug Interaction Safety System — Architecture Diagrams

> These diagrams are suitable for final-year project reports, technical theses, and startup engineering documentation.

---

## 1. System Architecture Diagram

```mermaid
graph TB
    subgraph Client["Flutter Client Layer"]
        FW["Flutter Web<br/>Material 3 + Riverpod"]
        FM["Flutter Mobile<br/>iOS / Android"]
    end

    subgraph Gateway["API Gateway"]
        LB["Load Balancer<br/>Nginx / K8s Ingress"]
    end

    subgraph Backend["Node.js Backend Cluster"]
        API1["API Server 1<br/>Express + TypeScript"]
        API2["API Server 2<br/>Express + TypeScript"]
        API3["API Server N<br/>Express + TypeScript"]
    end

    subgraph Middleware["Middleware Pipeline"]
        MW1["Helmet + CORS"]
        MW2["Request ID<br/>X-Request-Id"]
        MW3["JWT Auth Guard"]
        MW4["RBAC Guard"]
        MW5["Rate Limiter<br/>Redis-backed"]
        MW6["Zod Validation"]
        MW7["XSS Sanitization"]
    end

    subgraph Services["Service Layer"]
        PS["Prescription<br/>Service"]
        IE["Interaction<br/>Engine"]
        AS["Alert<br/>Service"]
        AU["Audit<br/>Service"]
    end

    subgraph Data["Data Layer"]
        direction LR
        PG["Supabase PostgreSQL<br/>Primary Database<br/>RLS + pgAudit"]
        RD["Redis 7<br/>Cache + Streams<br/>Rate Limiting"]
        CS["Apache Cassandra<br/>Analytics + Audit<br/>RF=3"]
    end

    subgraph Workers["Background Workers"]
        AW["Analytics Consumer<br/>Redis Streams → Cassandra"]
        RQ["Audit Retry<br/>Dead-Letter Queue"]
    end

    FW & FM --> LB
    LB --> API1 & API2 & API3
    API1 & API2 & API3 --> MW1 --> MW2 --> MW3 --> MW4 --> MW5 --> MW6 --> MW7
    MW7 --> PS & IE & AS & AU
    PS & IE & AS --> PG
    IE --> RD
    AU --> RD
    AU --> CS
    AW --> RD
    AW --> CS
    RQ --> RD
    RQ --> CS

    style Client fill:#E3F2FD,stroke:#1565C0,stroke-width:2px
    style Gateway fill:#FFF3E0,stroke:#E65100,stroke-width:2px
    style Backend fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px
    style Data fill:#FCE4EC,stroke:#C62828,stroke-width:2px
    style Workers fill:#F3E5F5,stroke:#6A1B9A,stroke-width:2px
```

### ASCII Version

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                                     │
│   ┌──────────────────┐          ┌──────────────────┐                    │
│   │  Flutter Web     │          │  Flutter Mobile   │                   │
│   │  Material 3      │          │  iOS / Android    │                   │
│   │  Riverpod + Dio  │          │  Riverpod + Dio   │                   │
│   └────────┬─────────┘          └────────┬──────────┘                   │
└────────────┼─────────────────────────────┼──────────────────────────────┘
             │           HTTPS             │
             └─────────────┬───────────────┘
                           ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                     API GATEWAY (Nginx / K8s Ingress)                    │
└──────────────────────────────┬───────────────────────────────────────────┘
                               │  Round Robin
                ┌──────────────┼──────────────┐
                ▼              ▼              ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                    NODE.JS BACKEND CLUSTER                               │
│                                                                          │
│  ┌────────────────────── MIDDLEWARE PIPELINE ──────────────────────────┐ │
│  │ Helmet → CORS → RequestID → JWT Auth → RBAC → Rate Limit → Zod    │ │
│  │ → XSS Sanitize                                                     │ │
│  └────────────────────────────┬───────────────────────────────────────┘ │
│                               │                                          │
│  ┌────────────────────── CONTROLLER LAYER ────────────────────────────┐ │
│  │  PrescriptionCtrl  │  AlertCtrl  │  DrugCtrl  │  PatientCtrl      │ │
│  └────────────┬───────┴──────┬──────┴─────┬──────┴───────────────────┘ │
│               │              │            │                              │
│  ┌────────────────────── SERVICE LAYER ───────────────────────────────┐ │
│  │  PrescriptionSvc  │  AlertSvc  │  InteractionEngine │  AuditSvc   │ │
│  └────────────┬───────┴──────┬──────┴─────┬──────┬───────────────────┘ │
│               │              │            │      │                       │
│  ┌────────────────────── REPOSITORY LAYER ───────────────────────────┐ │
│  │  PrescriptionRepo  │  AlertRepo  │  DrugRepo  │  PatientRepo     │ │
│  └────────────────────┴─────────────┴────────────┴───────────────────┘ │
└───────────┬──────────────────┬────────────────────┬──────────────────────┘
            │                  │                    │
            ▼                  ▼                    ▼
┌───────────────────┐ ┌────────────────┐ ┌──────────────────┐
│  Supabase         │ │  Redis 7       │ │  Cassandra       │
│  PostgreSQL       │ │                │ │  Cluster         │
│  ──────────────── │ │  ──────────────│ │  ────────────────│
│  • Tables + RLS   │ │  • Interaction │ │  • Alert logs    │
│  • Triggers       │ │    cache       │ │  • Audit events  │
│  • pgAudit        │ │  • Rate limits │ │  • Analytics     │
│  • Severity rank  │ │  • Streams     │ │  • Mat. views    │
│  • Retention pol. │ │  • Dead-letter │ │  • TTL: 1-2 yr   │
└───────────────────┘ └────────────────┘ └──────────────────┘
```

---

## 2. Layered Architecture Diagram

```mermaid
graph TB
    subgraph HTTP["HTTP Layer"]
        REQ["Incoming Request"]
    end

    subgraph MW["Middleware Stack"]
        M1["helmet()"]
        M2["cors()"]
        M3["requestId()"]
        M4["requestLogger()"]
        M5["rateLimiter()"]
        M6["authGuard()"]
        M7["rbacGuard()"]
        M8["validate(schema)"]
        M9["sanitize(fields)"]
    end

    subgraph CTRL["Controllers"]
        C1["prescriptionController"]
        C2["alertController"]
        C3["drugController"]
        C4["patientController"]
    end

    subgraph SVC["Services"]
        S1["prescriptionService"]
        S2["alertService"]
        S3["interactionEngine"]
        S4["auditService"]
    end

    subgraph REPO["Repositories"]
        R1["prescriptionRepo"]
        R2["alertRepo"]
        R3["drugRepo"]
        R4["patientRepo"]
    end

    subgraph INFRA["Infrastructure"]
        I1["Supabase Client"]
        I2["Redis Client + Circuit Breaker"]
        I3["Cassandra Client"]
        I4["Winston Logger"]
    end

    REQ --> M1 --> M2 --> M3 --> M4 --> M5 --> M6 --> M7 --> M8 --> M9
    M9 --> C1 & C2 & C3 & C4
    C1 --> S1
    C2 --> S2
    C3 --> R3
    C4 --> R4
    S1 --> S3
    S1 --> S4
    S1 --> R1
    S2 --> R2
    S2 --> S4
    S3 --> I2
    S3 --> I1
    S4 --> I3
    S4 --> I2
    R1 & R2 & R3 & R4 --> I1

    style HTTP fill:#E3F2FD,stroke:#1565C0
    style MW fill:#FFF8E1,stroke:#F57F17
    style CTRL fill:#E8F5E9,stroke:#2E7D32
    style SVC fill:#F3E5F5,stroke:#7B1FA2
    style REPO fill:#FBE9E7,stroke:#D84315
    style INFRA fill:#ECEFF1,stroke:#37474F
```

---

## 3. Data Flow Diagram

```mermaid
sequenceDiagram
    participant D as Doctor (Client)
    participant API as API Server
    participant AUTH as JWT Auth
    participant VAL as Validator
    participant PS as PrescriptionService
    participant IE as InteractionEngine
    participant RD as Redis Cache
    participant PG as PostgreSQL
    participant AU as AuditService
    participant CS as Cassandra
    participant WK as Analytics Worker

    D->>API: POST /prescriptions/:id/drugs
    API->>AUTH: Verify JWT Token
    AUTH-->>API: User { id, role: doctor }
    API->>VAL: validate(addDrugSchema)
    VAL-->>API: req.validated

    API->>PS: addDrug(prescriptionId, drugData, user)
    PS->>PG: findById(prescriptionId)
    PG-->>PS: prescription

    PS->>PG: insertDrug(prescriptionId, drug)
    PG-->>PS: prescriptionDrug

    PS->>PG: getDrugIds(prescriptionId)
    PG-->>PS: [drugId1, drugId2, ...]

    PS->>IE: detectInteractions(drugIds)
    IE->>PG: fetch drug_ingredients (batch)
    PG-->>IE: ingredients[]

    IE->>RD: batchGetCachedInteractions(pairs)
    RD-->>IE: cachedResults (Map)

    IE->>PG: batch query cache misses
    PG-->>IE: dbInteractions[]

    IE->>RD: cache new results (parallel)
    IE-->>PS: alerts[]

    PS->>PG: getAlerts(prescriptionId)
    PS->>PG: insertEvent("drug_added")

    PS->>AU: logDrugUsage(event)
    AU->>CS: writeDrugUsage()
    alt Cassandra Down
        AU->>RD: LPUSH audit:retry_queue
        WK->>RD: RPOP audit:retry_queue
        WK->>CS: retry write
    end

    PS-->>API: { prescriptionDrug, alerts, interactions }
    API-->>D: 201 Created { success: true, data: {...} }
```

---

## 4. Interaction Detection Pipeline

```mermaid
graph LR
    subgraph Input["Input"]
        D1["Drug A<br/>Aspirin"]
        D2["Drug B<br/>Warfarin"]
        D3["Drug C<br/>Ibuprofen"]
    end

    subgraph Step1["Step 1: Ingredient Resolution"]
        I1["Acetylsalicylic Acid"]
        I2["Warfarin Sodium"]
        I3["Ibuprofen"]
    end

    subgraph Step2["Step 2: Pair Generation"]
        P1["ASA ↔ Warfarin"]
        P2["ASA ↔ Ibuprofen"]
        P3["Warfarin ↔ Ibuprofen"]
    end

    subgraph Step3["Step 3: Cache Lookup"]
        CB["Circuit Breaker"]
        RL["Redis Pipeline<br/>MGET"]
        HIT["Cache Hits"]
        MISS["Cache Misses"]
    end

    subgraph Step4["Step 4: DB Lookup"]
        SQ["Supabase Batch Query<br/>WHERE (a,b) IN (...)"]
    end

    subgraph Step5["Step 5: Alert Generation"]
        A1["🔴 Contraindicated<br/>ASA + Warfarin"]
        A2["🟠 Severe<br/>Warfarin + Ibuprofen"]
        A3["🟡 Moderate<br/>ASA + Ibuprofen"]
    end

    D1 --> I1
    D2 --> I2
    D3 --> I3
    I1 & I2 & I3 --> P1 & P2 & P3
    P1 & P2 & P3 --> CB --> RL
    RL --> HIT
    RL --> MISS
    MISS --> SQ
    HIT & SQ --> A1 & A2 & A3

    style Input fill:#E3F2FD,stroke:#1565C0
    style Step1 fill:#E8F5E9,stroke:#2E7D32
    style Step2 fill:#FFF3E0,stroke:#E65100
    style Step3 fill:#F3E5F5,stroke:#7B1FA2
    style Step4 fill:#FCE4EC,stroke:#C62828
    style Step5 fill:#FFF9C4,stroke:#F57F17
```

### ASCII Version

```
                    INTERACTION DETECTION PIPELINE
    ┌──────────────────────────────────────────────────────────┐
    │                                                          │
    │  ┌─────────┐  ┌─────────┐  ┌─────────┐                 │
    │  │ Drug A  │  │ Drug B  │  │ Drug C  │   INPUT          │
    │  │ Aspirin │  │Warfarin │  │Ibuprofen│                  │
    │  └────┬────┘  └────┬────┘  └────┬────┘                  │
    │       │            │            │                        │
    │       ▼            ▼            ▼                        │
    │  ┌─────────────────────────────────────┐                │
    │  │ STEP 1: Resolve Ingredients         │                │
    │  │ Acetylsalicylic Acid, Warfarin      │                │
    │  │ Sodium, Ibuprofen                   │                │
    │  └──────────────────┬──────────────────┘                │
    │                     │                                    │
    │                     ▼                                    │
    │  ┌─────────────────────────────────────┐                │
    │  │ STEP 2: Generate Canonical Pairs    │                │
    │  │ (ASA,Warfarin) (ASA,Ibu) (War,Ibu) │                │
    │  │ Total pairs: n(n-1)/2 × m²         │                │
    │  └──────────────────┬──────────────────┘                │
    │                     │                                    │
    │           ┌─────────┴──────────┐                        │
    │           ▼                    ▼                         │
    │  ┌────────────────┐  ┌─────────────────┐               │
    │  │ STEP 3: Redis  │  │ Circuit Breaker │               │
    │  │ Pipeline MGET  │  │ (opossum)       │               │
    │  │ Single RTT     │  │ Fallback: DB    │               │
    │  └───┬────────┬───┘  └─────────────────┘               │
    │      │        │                                          │
    │   Hits     Misses                                        │
    │      │        │                                          │
    │      │        ▼                                          │
    │      │  ┌─────────────────┐                             │
    │      │  │ STEP 4: Supabase│                             │
    │      │  │ Batch Query     │                             │
    │      │  │ WHERE (a,b) IN  │                             │
    │      │  └────────┬────────┘                             │
    │      │           │                                       │
    │      └─────┬─────┘                                      │
    │            ▼                                             │
    │  ┌─────────────────────────────────────┐                │
    │  │ STEP 5: Deduplicate + Sort          │                │
    │  │ 🔴 contraindicated (rank 1)         │                │
    │  │ 🟠 severe          (rank 2)         │                │
    │  │ 🟡 moderate        (rank 3)         │                │
    │  │ 🟢 mild            (rank 4)         │                │
    │  └─────────────────────────────────────┘                │
    └──────────────────────────────────────────────────────────┘
```

---

## 5. Deployment Architecture

```mermaid
graph TB
    subgraph K8S["Kubernetes Cluster"]
        subgraph NS1["Namespace: drug-interaction"]
            ING["Ingress Controller<br/>TLS Termination"]
            
            subgraph API["API Deployment (3 replicas)"]
                P1["Pod 1<br/>Node.js API"]
                P2["Pod 2<br/>Node.js API"]
                P3["Pod 3<br/>Node.js API"]
            end
            
            subgraph WRK["Worker Deployment (2 replicas)"]
                W1["Pod: Analytics<br/>Consumer"]
                W2["Pod: Audit<br/>Retry Worker"]
            end
            
            SVC1["Service: api-svc<br/>ClusterIP :3000"]
            HPA["HPA<br/>CPU > 70% → scale"]
        end

        subgraph NS2["Namespace: data"]
            subgraph REDIS["Redis Cluster"]
                RM["Redis Master"]
                RS1["Redis Replica 1"]
                RS2["Redis Replica 2"]
            end
            
            subgraph CASS["Cassandra StatefulSet"]
                CN1["cassandra-0"]
                CN2["cassandra-1"]
                CN3["cassandra-2"]
            end
        end
    end

    subgraph EXT["External Services"]
        SB["Supabase Cloud<br/>PostgreSQL + Auth<br/>+ Realtime"]
        CDN["CDN<br/>Flutter Web<br/>Static Assets"]
    end

    subgraph MON["Monitoring"]
        PROM["Prometheus"]
        GRAF["Grafana"]
        ALERT["AlertManager"]
    end

    CDN --> ING
    ING --> SVC1
    SVC1 --> P1 & P2 & P3
    P1 & P2 & P3 --> RM
    P1 & P2 & P3 --> SB
    W1 & W2 --> RM
    W1 & W2 --> CN1
    HPA --> API
    PROM --> API & REDIS & CASS
    PROM --> GRAF --> ALERT

    style K8S fill:#E3F2FD,stroke:#1565C0,stroke-width:2px
    style EXT fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px
    style MON fill:#FFF3E0,stroke:#E65100,stroke-width:2px
```

### ASCII Version

```
┌──────────────────── KUBERNETES CLUSTER ──────────────────────────────┐
│                                                                       │
│  ┌─────────────── namespace: drug-interaction ─────────────────────┐ │
│  │                                                                  │ │
│  │  ┌──────────────────────────────────────────────┐               │ │
│  │  │          INGRESS CONTROLLER                   │               │ │
│  │  │          TLS + Rate Limiting                  │               │ │
│  │  └──────────────────┬───────────────────────────┘               │ │
│  │                     │                                            │ │
│  │     ┌───────────────┼───────────────┐                           │ │
│  │     ▼               ▼               ▼                           │ │
│  │  ┌──────┐       ┌──────┐       ┌──────┐                        │ │
│  │  │Pod 1 │       │Pod 2 │       │Pod 3 │  API (HPA: 3-10)      │ │
│  │  │API   │       │API   │       │API   │                        │ │
│  │  └──┬───┘       └──┬───┘       └──┬───┘                        │ │
│  │     │               │               │                            │ │
│  │  ┌──────┐       ┌──────┐                                        │ │
│  │  │Worker│       │Worker│    Workers (2 replicas)                │ │
│  │  │Analyt│       │Audit │                                        │ │
│  │  └──┬───┘       └──┬───┘                                        │ │
│  └─────┼───────────────┼────────────────────────────────────────────┘ │
│        │               │                                               │
│  ┌─────┼───── namespace: data ──────────────────────────────────────┐ │
│  │     │               │                                             │ │
│  │  ┌──▼───────────────▼──┐    ┌──────────────────────────────┐    │ │
│  │  │   REDIS CLUSTER     │    │   CASSANDRA STATEFULSET      │    │ │
│  │  │   Master + 2 Repl.  │    │   3 nodes, RF=3              │    │ │
│  │  │   Cache + Streams   │    │   Analytics + Audit          │    │ │
│  │  └─────────────────────┘    └──────────────────────────────┘    │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
         │                            │
         ▼                            ▼
┌─────────────────┐          ┌─────────────────┐
│ Supabase Cloud  │          │  CDN / Vercel   │
│ PostgreSQL+Auth │          │  Flutter Web    │
│ RLS + Realtime  │          │  Static Assets  │
└─────────────────┘          └─────────────────┘
```
