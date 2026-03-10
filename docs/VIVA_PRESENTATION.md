# Viva Presentation Script
## Drug Interaction Safety & Prescription Validation System
### 5-Minute Technical Demo

---

## Slide 1: The Problem (45 seconds)

> "Every year, adverse drug interactions cause over 125,000 deaths in the US alone. When a doctor prescribes multiple medications, dangerous combinations can slip through — especially when different specialists prescribe independently.
>
> Our system solves this by detecting harmful drug interactions at the **ingredient level** — not just the drug level — in real-time, before the prescription reaches the patient.
>
> This is a clinical decision support system: it doesn't replace the doctor's judgment, it **augments** it with data the human brain can't hold — over 50,000 known ingredient-level interactions."

---

## Slide 2: System Architecture (60 seconds)

> "The system follows a layered enterprise architecture:
>
> **Frontend**: Flutter for both web and mobile, using Material 3 and Riverpod for state management. The same codebase runs on web, iOS, and Android.
>
> **Backend**: Node.js with Express, organized as Controller → Service → Repository. Every request passes through 7 middleware layers: security headers, CORS, request tracing, JWT auth, role-based access control, input validation with Zod, and XSS sanitization.
>
> **Primary Database**: Supabase PostgreSQL with Row-Level Security — a doctor can only see their patients, a patient can only see their own data. This is HIPAA-critical.
>
> **Cache**: Redis for interaction lookups. We cache ingredient pair results to avoid hitting the database on every prescription check. A circuit breaker protects against Redis failures — if Redis goes down, we fall through to the database.
>
> **Analytics**: Cassandra for audit logs and interaction analytics. Writes go through a Redis Streams queue with a dead-letter mechanism — we never silently lose an audit event. This is a HIPAA requirement."

---

## Slide 3: Database Design (45 seconds)

> "The schema is normalized to 3NF with 12 tables. The key insight is the **ingredient_interactions** table — we don't store 'Drug A interacts with Drug B.' We store 'Ingredient X interacts with Ingredient Y.' This means:
>
> - If a new drug contains Aspirin's active ingredient, all its interactions are automatically known
> - We reduce data redundancy by orders of magnitude
> - Clinical accuracy improves because interactions happen at the molecular level
>
> Row-Level Security ensures data isolation. A patient sees only their prescriptions. A pharmacist can read by not modify. An admin has full access. These policies are enforced at the database level — even if the backend code has a bug, the data stays protected."

---

## Slide 4: Interaction Detection Algorithm (45 seconds)

> "Let me walk through the detection pipeline:
>
> 1. Doctor adds Drug C to a prescription that already has Drugs A and B
> 2. We resolve all ingredients for all three drugs — a single batch query
> 3. We generate every ingredient pair: if Drug A has 2 ingredients and Drug B has 3, that's up to 6 pairs
> 4. We look up all pairs in Redis using a pipeline — a single network round trip
> 5. Cache misses go to a batch PostgreSQL query
> 6. Results are deduplicated, sorted by severity, and returned
>
> The entire pipeline runs in under 50 milliseconds for typical prescriptions. A circuit breaker protects Redis lookups — if cache fails, we fall through to the database. The doctor never waits."

---

## Slide 5: Live Demo (90 seconds)

### Demo Steps:

> "Let me show you the system in action.

**Step 1: Login as Doctor**
> "I'm logging in as Dr. Sarah Smith, a cardiologist. Notice the JWT token is issued with her role — this determines what she can see and do."

**Step 2: Create Prescription**
> "I'll create a new prescription for patient John Doe. Diagnosis: Atrial Fibrillation."

**Step 3: Add First Drug — Warfarin**
> "Adding Warfarin 5mg, once daily. No alerts — this is the only drug."

**Step 4: Add Second Drug — Aspirin**
> "Now I add Aspirin 325mg. Immediately, the system detects a **severe** interaction: Warfarin + Aspirin increases bleeding risk through anticoagulant-antiplatelet synergy."

**Step 5: View Alert**
> "The alert shows the clinical effect, the mechanism, the evidence level, and a recommendation. The doctor can acknowledge or override with a reason — both actions are audit-logged."

**Step 6: Analytics Dashboard**
> "The dashboard shows interaction frequency trends, most common dangerous pairs, and alert response times. All powered by real-time Cassandra analytics."

---

## Slide 6: Enterprise Features (45 seconds)

> "Beyond the core functionality:
>
> - **HIPAA Compliance**: Column-level encryption for PHI, audit trails with guaranteed delivery, 7-year data retention policy
> - **Security**: JWT key rotation, CSRF protection, Redis-backed rate limiting, XSS sanitization
> - **Fault Tolerance**: Circuit breakers on all external services, graceful degradation, dead-letter queues
> - **CI/CD**: GitHub Actions pipeline running backend tests, Flutter analysis, and SQL migration validation on every PR
> - **TypeScript Migration**: Incremental migration from JavaScript with strict type checking — we maintain both during transition
>
> The system scored **95 out of 100** on our enterprise readiness assessment."

---

## Q&A Preparation

### Expected Questions:

**Q: Why ingredient-level instead of drug-level interactions?**
> "Drug-level interactions are lossy. If Drug X and Drug Y both contain the same active ingredient, drug-level matching would miss the interaction with a third drug. Ingredient-level matching catches everything and reduces the database from millions of drug pairs to thousands of ingredient pairs."

**Q: How does this scale?**
> "The API is stateless — scale horizontally behind a load balancer. Redis handles distributed rate limiting and caching. Cassandra scales linearly with write throughput. The bottleneck is PostgreSQL, managed by Supabase with connection pooling."

**Q: How do you handle false positives?**
> "The system provides severity levels and evidence levels. A 'mild' interaction is informational. A 'contraindicated' interaction is a hard warning. The doctor can override any alert with a documented reason — this becomes part of the audit trail."

**Q: What about real-time updates to the interaction database?**
> "New interactions are added to the ingredient_interactions table. The Redis cache has a 1-hour TTL, so new interactions are picked up within an hour. For critical updates, we can flush the cache instantly."
