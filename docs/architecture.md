# System Architecture — Drug Interaction Safety & Prescription Validation System

## High-Level Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        FW["Flutter Web App"]
        FM["Flutter Mobile App"]
    end

    subgraph "API Gateway"
        CORS["CORS Policy"]
        RL["Rate Limiter"]
        AUTH["JWT Auth Guard"]
        RBAC["RBAC Guard"]
    end

    subgraph "Application Layer"
        API["Node.js / Express API<br/>Port 3000"]
        IE["Interaction Detection Engine"]
        WS["Winston Logger"]
    end

    subgraph "Caching Layer"
        REDIS["Redis<br/>Port 6379<br/>Interaction Cache (TTL 24h)"]
    end

    subgraph "Primary Database"
        SUPA["Supabase (PostgreSQL)<br/>Tables: patients, doctors, drugs,<br/>ingredients, prescriptions, alerts"]
        RLS["Row Level Security"]
        TRIG["PL/pgSQL Triggers<br/>Auto Interaction Detection"]
    end

    subgraph "Analytics Database"
        CASS["Apache Cassandra<br/>Port 9042<br/>Event Logs, Audit Trail,<br/>Analytics Tables"]
    end

    subgraph "Auth Provider"
        SA["Supabase Auth<br/>JWT + Refresh Tokens"]
    end

    FW --> CORS
    FM --> CORS
    CORS --> RL --> AUTH --> RBAC --> API
    API --> IE
    IE --> REDIS
    IE --> SUPA
    API --> SUPA
    API --> CASS
    SUPA --> RLS
    SUPA --> TRIG
    API --> WS --> CASS
    FW --> SA
    FM --> SA
    SA --> SUPA
```

## Data Flow — Prescription Drug Addition

```mermaid
sequenceDiagram
    participant U as Flutter Client
    participant A as Express API
    participant R as Redis Cache
    participant P as PostgreSQL (Supabase)
    participant C as Cassandra

    U->>A: POST /prescriptions/:id/drugs
    A->>A: JWT Verify + RBAC Check
    A->>P: INSERT INTO prescription_drugs
    P->>P: TRIGGER: check_drug_interactions()
    P->>P: Cross-join ingredients, query interactions
    P->>P: INSERT INTO interaction_alerts
    P->>P: TRIGGER: audit_alert_insert()
    P->>P: INSERT INTO audit_log
    A->>P: SELECT alerts for prescription
    A->>R: Cache interaction lookups (TTL 24h)
    A-->>C: Async: Write audit event
    A-->>U: Response: { drug, alerts[] }
```

## Component Responsibilities

| Component | Responsibility |
|-----------|---------------|
| **Flutter App** | UI rendering, state management (Riverpod), auth flow, real-time subscriptions |
| **Express API** | Request routing, validation (Zod), business logic orchestration, auth enforcement |
| **Interaction Engine** | Core algorithm: ingredient pairing, interaction lookup, severity ranking |
| **PostgreSQL** | ACID transactions, referential integrity, triggers, RLS, stored procedures |
| **Cassandra** | High-volume event storage, time-series analytics, audit trail |
| **Redis** | Ingredient interaction cache, reducing DB load on repeated lookups |
| **Supabase Auth** | JWT issuance, refresh token rotation, user management |

## Deployment Architecture

```mermaid
graph LR
    subgraph "Kubernetes Cluster"
        subgraph "API Tier"
            API1["API Pod 1"]
            API2["API Pod 2"]
            APIN["API Pod N"]
            HPA["HPA: 2-10 pods<br/>CPU target: 60%"]
        end
        subgraph "Data Tier"
            C1["Cassandra Node 1"]
            C2["Cassandra Node 2"]
            C3["Cassandra Node 3"]
        end
        REDIS2["Redis Pod"]
        ING["Ingress Controller<br/>TLS Termination"]
    end

    subgraph "Managed Services"
        SUPA2["Supabase Cloud<br/>(PostgreSQL + Auth)"]
    end

    ING --> API1
    ING --> API2
    ING --> APIN
    API1 --> C1
    API1 --> REDIS2
    API1 --> SUPA2
```
