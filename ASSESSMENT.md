# BookieAI Assessment

## Executive summary

BookieAI is a **strong MVP scaffold, not a production-ready app yet**.

The repo already has:
- a fairly complete **NestJS backend structure**
- a substantial **Prisma data model** aligned with the evolving spec
- a polished **Flutter UI shell** for the main user journeys
- local infra for **Postgres + Redis**
- demo seed data

But the biggest issue is this:

> **the backend and mobile app are not wired together cleanly enough to work end-to-end yet.**

There are multiple API contract mismatches, several “AI” features are still mock implementations, and the hardest product requirements (real SMS ingestion, email/statement import, learning, notifications flow, production security/deployment) are still unfinished.

---

## 1. What the spec requires

From `SPEC.md`, `SPEC_update_1.md`, and `SPEC_update_2.md`, the intended MVP is:

- voice-first AI budgeting app
- Android-first transaction ingestion from SMS
- optional email ingestion architecture
- accounts + balances + reconciliation
- multi-currency support and FX conversion
- transaction clarification flow
- budgets, goals, dashboard, summaries, assistant
- notifications and nudges
- secure auth, backend APIs, Dockerized local setup

The updates also made these first-class systems:
- **accounts + balance reconciliation**
- **statement import / drift correction**
- **scenario simulation**
- **multi-currency + FX**

---

## 2. Backend assessment (`server/src/`)

### Implemented backend modules

`AppModule` wires these modules:
- `auth`
- `users`
- `accounts`
- `categories`
- `transactions`
- `fx-rates`
- `clarifications`
- `budgets`
- `goals`
- `ai`
- `ingestion`
- `insights`
- `assistant`
- `notifications`
- `prisma`

### What is actually implemented in code

#### Auth
Implemented:
- register
- login
- refresh token flow
- logout
- `/auth/me`
- JWT guard + local strategy
- bcrypt password hashing
- refresh token persistence in DB

Not fully implemented:
- Google auth is placeholder only
- password reset is placeholder only
- email verification is absent
- Apple sign-in is absent

#### Users
Implemented:
- get current profile
- update profile
- update preferences

Issue:
- backend route is `PATCH /users/preferences`, but mobile expects `/users/me/preferences`

#### Accounts
Implemented:
- CRUD for accounts
- soft-delete via `isActive`
- account balance lookup with confidence level
- manual reconciliation
- reconciliation history endpoint
- converted balance lookup using stored FX rates

Good:
- account system matches the updated spec reasonably well

Limitations:
- reconciliation is basic only
- no automated drift workflow beyond simple adjustment
- no statement import linkage yet in services

#### Transactions
Implemented:
- create/list/get/update/delete
- filters for type/account/category/date/amount/search
- monthly stats
- category breakdown
- account balance updates when transactions change

Limitations:
- transaction balance adjustment logic is basic
- no real recurring detection
- no learning system tied to edits
- converted amount / fx fields exist in schema but are not really maintained in service flows

#### Ingestion
Implemented:
- `POST /ingestion/sms/parse`
- `POST /ingestion/email/parse`
- `POST /ingestion/voice-log`
- `POST /ingestion/manual-entry`

Reality:
- these endpoints exist, but parsing is driven by the mock AI service
- no real Android SMS listener/scanner here
- no Gmail OAuth/email connector flow
- no statement parser/import pipeline

#### Clarifications
Implemented:
- list clarifications
- respond to clarification
- dismiss clarification
- transaction status updates after answer

Good:
- this is one of the more complete backend flows

Limitation:
- response logic is still simple; it does not meaningfully “learn” from corrections

#### Categories
Implemented:
- CRUD module exists

Likely usable for MVP basics.

#### Budgets
Implemented:
- CRUD
- progress calculation
- overspend/projected overspend calculation

Limitations:
- no scheduled alerts / nudges
- no cross-currency budget normalization logic in practice

#### Goals
Implemented:
- CRUD
- add contributions
- projection endpoint
- status calculation (`ON_TRACK`, `AT_RISK`, etc.)

Good:
- goal projection logic is present and reasonably useful

Limitations:
- contributions are simple
- multi-currency aggregation is only partially represented in schema, not fully enforced in service logic
- no income target workflow in APIs/UI despite schema support

#### FX rates
Implemented:
- fetch latest rates from configured API
- cache FX rates in DB
- convert endpoint

Good:
- this aligns with the multi-currency spec foundation

Limitations:
- historical FX insight logic is not implemented
- no scheduler/worker refreshing rates periodically

#### Insights
Implemented:
- dashboard summary
- weekly summary
- monthly summary
- generated insights persisted to DB

Reality:
- summaries depend on the mock AI service for text generation
- logic is mostly deterministic + mocked narrative

#### Assistant
Implemented:
- chat
- voice query endpoint
- clarify transaction endpoint
- goal planning
- scenario simulation
- FX simulation

Reality:
- backend endpoints exist, but responses come from mocked AI behavior
- no true voice pipeline

#### Notifications
Implemented:
- list notifications
- unread count
- mark one read
- mark all read
- notification create service exists

Limitations:
- no actual dispatch system
- no push notification integration
- no proactive worker pipeline

#### AI module
Critical finding:
- **AI is entirely mocked right now**
- `AiService` explicitly returns structured mock responses
- `OPENAI_API_KEY` exists in env example, but no real LLM API integration is wired

This means:
- parsing
- categorization fallback
- clarification generation
- assistant answers
- summaries
- goal planning
- scenario simulation
- FX simulation

are all currently **simulated**, not real AI features.

---

## 3. Data model assessment (`server/prisma/schema.prisma`)

### Strong points

The schema is one of the best parts of the repo. It covers most of the spec well.

Implemented models include:
- `User`
- `Account`
- `ConnectedAccount`
- `Transaction`
- `Category`
- `Clarification`
- `Budget`
- `Goal`
- `GoalContribution`
- `Insight`
- `Notification`
- `MerchantAlias`
- `IncomeTarget`
- `AccountReconciliation`
- `StatementImport`
- `ScenarioSimulation`
- `FxRate`
- `RefreshToken`

### What the schema gets right

It captures:
- accounts per user
- multi-currency preferences
- reconciliation history
- statement import records
- scenario simulation records
- transactions tied to accounts
- clarification state
- goals + contributions
- notifications + insights
- merchant alias / learning rule foundation

### Important schema gap / blocker

The datasource is declared as:

```prisma
datasource db {
  provider = "postgresql"
}
```

There is **no `url = env("DATABASE_URL")`** in the schema.

That is a serious runnable-state blocker. As written, Prisma schema configuration looks incomplete for normal local/prod usage.

### Other practical gaps

- no migrations directory present
- schema is ambitious, but several models are not yet backed by business logic
  - `ConnectedAccount`
  - `StatementImport`
  - `MerchantAlias`
  - `IncomeTarget`
  - `ScenarioSimulation` is only lightly used

---

## 4. Mobile assessment (`mobile/lib/`)

### Screens/features that are built

Implemented screens:
- splash
- onboarding
- login
- register
- dashboard/home
- accounts list
- account detail
- transactions list
- transaction detail
- assistant/chat screen
- budgets screen
- goals screen
- goal detail
- settings screen

Also implemented:
- Riverpod state setup
- Dio API client
- secure token storage
- Hive-based local cache
- models for accounts/transactions/budgets/goals/notifications/etc.
- polished theme and reusable widgets

### UI quality

The Flutter app looks like a **real product shell**, not a throwaway scaffold.

Strengths:
- polished dark theme
- usable navigation structure
- decent dashboard composition
- decent detail screens
- bottom navigation
- create sheets for accounts/budgets/goals/transactions

### What is only partially real on mobile

#### Onboarding
Built:
- intro slides
- currency/income style/personality local selection

Missing:
- actual permission education + permission requests
- SMS permission flow
- microphone/speech permission flow
- syncing onboarding preferences to backend

#### Auth UI
Built:
- email/password login/register flows

Missing:
- Google sign-in UI flow
- forgot password flow
- reset password flow
- Apple sign-in placeholder

#### Dashboard
Built:
- totals
- recent transactions
- budget cards
- goals cards
- clarification banner

Missing:
- insights screen from spec
- charts-heavy polished insight flow
- monthly comparisons UI
- notification center

#### Accounts
Built:
- accounts list
- account detail
- reconciliation sheet UI
- confidence badge UI

Issues:
- total balance card hardcodes USD display
- converted balance display is hardcoded to USD in places
- reconcile request payload does not match backend contract

#### Transactions
Built:
- list
- search
- grouped by date
- add transaction sheet
- transaction detail
- delete action

Missing:
- full filter support from spec
- edit flow UI
- clarification inbox screen
- raw message review/editing workflow beyond detail display

#### Assistant
Built:
- chat UI
- suggestion chips
- mic button animation

Reality:
- voice mode is not real speech capture
- assistant response parsing likely does not match backend response shape cleanly
- no TTS playback

#### Budgets
Built:
- list screen
- create sheet
- progress cards

Missing:
- edit/delete UI polish
- alert center / warning workflow
- weekly cap UX beyond backend enum support

#### Goals
Built:
- goals list
- goal detail
- contribution add sheet
- projection display

Issues:
- contribution payload from mobile omits required backend `sourceType`
- totals are sometimes hardcoded/displayed in USD assumptions

#### Settings
Built:
- basic settings screen
- logout

Missing:
- real preference update actions
- privacy controls
- email connection
- preferred voice
- export data
- delete data

---

## 5. Infrastructure assessment (`docker-compose.yml`)

Implemented locally:
- PostgreSQL 16
- Redis 7
- named volumes
- shared bridge network

This is enough for local backend development.

Missing for production:
- backend service in compose
- worker service
- reverse proxy
- health checks
- monitoring/logging
- secrets handling
- staging/prod deployment manifests

Also note:
- root has `docker-compose.yml`, but README says run `docker-compose up -d` from `server/`, which is misleading unless copied there manually.

---

## 6. Environment variables (`server/.env.example`)

Defined env vars:
- `DATABASE_URL`
- `JWT_SECRET`
- `JWT_EXPIRATION_SECONDS`
- `JWT_REFRESH_EXPIRATION_DAYS`
- `REDIS_URL`
- `OPENAI_API_KEY`
- `OPENAI_MODEL`
- `FX_API_URL`
- `CORS_ORIGINS`
- `CORS_CREDENTIALS`
- `PORT`

What is missing for real production:
- Google OAuth client secrets
- Apple auth config
- email provider / SMTP / resend provider config
- push notification credentials
- error tracking config (Sentry, etc.)
- analytics config (PostHog, etc.)
- encryption key for stored provider tokens
- statement import / object storage config if attachments are added

---

## 7. What is DONE

These are meaningfully implemented in the repo:

### Backend
- NestJS modular backend scaffold
- JWT auth with refresh tokens
- user profile/preferences endpoints
- accounts CRUD + manual reconciliation
- categories CRUD
- transactions CRUD + filters + stats
- clarification lifecycle endpoints
- budgets CRUD + progress calculations
- goals CRUD + contribution + projection logic
- FX rate fetch/cache/convert service
- dashboard/weekly/monthly insight endpoints
- assistant/scenario/fx/goal-planning endpoints
- notifications CRUD-ish endpoints
- demo seed script

### Data model
- comprehensive Prisma schema covering accounts, balances, reconciliation, goals, FX, notifications, clarifications, statement imports, and simulations

### Mobile
- polished app shell and navigation
- onboarding flow UI
- login/register screens
- dashboard UI
- accounts UI
- transactions UI
- assistant chat UI
- budgets UI
- goals UI + goal detail
- settings UI
- local storage + token handling scaffolding

### Dev infrastructure
- Postgres + Redis compose setup
- Swagger enabled
- seed data script exists

---

## 8. What is PARTIALLY done

### Real AI
- all AI endpoints/services are currently mock implementations
- architecture exists, real intelligence does not

### SMS/email/voice ingestion
- ingestion endpoints exist
- parsing path exists
- but actual platform/email integrations are missing

### Multi-currency
- schema and FX service support it
- some account conversion logic exists
- mobile/backend calculations and displays are still inconsistent

### Reconciliation
- manual reconciliation exists
- no robust discrepancy workflow, no statement reconciliation engine

### Assistant
- screen and endpoints exist
- but real conversational intelligence, voice I/O, and action execution are incomplete

### Summaries and insights
- endpoints exist
- some summary generation exists
- UI coverage is incomplete and AI text is mocked

### Notifications
- DB model + endpoints exist
- no actual push delivery or proactive automation pipeline

### Learning system
- `MerchantAlias` / rule structures exist in schema
- no real learning engine implemented

### Offline support
- there is basic local caching for user/dashboard
- true queued offline sync is not implemented

### Testing
- minimal Nest starter tests exist
- no meaningful feature coverage
- no mobile tests present

---

## 9. What is NOT started or effectively missing

From the spec, these are still absent or close to absent:

- Android native SMS listener / inbox scanning / permission flow
- Gmail OAuth connection flow
- connected email account management UI/backend flow
- bank statement CSV/PDF import pipeline
- statement conflict diff/review UI
- recurring detection
- user correction learning engine
- analytics/PostHog events
- notification dispatch system
- notification center screen
- dedicated clarifications inbox screen
- insights screen from spec
- profile screen from spec
- privacy controls page
- export/delete data flow
- TTS playback for summaries
- real speech-to-text capture flow
- Apple sign-in placeholder flow in mobile/backend
- email verification
- password reset implementation
- business vs personal classification workflow
- income target APIs/UI despite schema support
- admin module from architecture spec
- queue workers/background job processing in practice
- CI/CD workflows
- production deployment config
- Sentry/error monitoring
- comprehensive docs for platform limitations and ops

---

## 10. Critical integration problems blocking a real demo

This is the most important section.

Even though both backend and mobile are substantial, there are several **contract mismatches** that likely prevent smooth end-to-end operation right now.

### A. Mobile uses `/api` prefix, backend does not set one
Mobile base URL defaults to:
- `http://10.0.2.2:3000/api`

Backend:
- enables Swagger at `/api`
- but does **not** call `app.setGlobalPrefix('api')`

Result:
- mobile likely calls `/api/auth/login`
- backend likely serves `/auth/login`

That breaks requests immediately.

### B. Mobile expects wrapped responses like `response.data['data']`
Most mobile providers/services read backend responses like:
- `response.data['data']`

Backend controllers mostly return raw objects/arrays directly.

Result:
- many mobile screens/providers will fail parsing even if the HTTP route is correct.

### C. Logout contract mismatch
Backend logout expects:
- authenticated request
- body containing `refreshToken`

Mobile logout sends:
- `POST /auth/logout`
- no refresh token body

### D. Reconcile account contract mismatch
Backend expects:
```json
{ "balance": 1234, "source": "MANUAL" }
```

Mobile sends:
```json
{ "actualBalance": 1234 }
```

### E. Goal contribution contract mismatch
Backend requires `sourceType`.
Mobile contribution sheet sends amount/currency/date only.

### F. Users preferences route mismatch
Backend route:
- `PATCH /users/preferences`

Mobile constant:
- `/users/me/preferences`

### G. Some mobile views assume returned objects differ from backend responses
Example areas:
- assistant response shape
- reconcile return shape
- add contribution return shape

Bottom line:

> **The repo is not yet integrated enough for a reliable full demo without fixing the API contract layer first.**

---

## 11. What is needed to get this to production

### Must-fix engineering work
1. **Fix backend/mobile API contract alignment**
   - route prefixes
   - response envelope shape
   - request payloads
   - DTO/field names

2. **Make Prisma schema runnable**
   - add datasource URL config
   - generate migrations
   - verify seed + app boot

3. **Implement real AI provider integration**
   - actual OpenAI-compatible client
   - schema-validated JSON outputs
   - retries/timeouts/fallbacks

4. **Implement real ingestion paths**
   - Android SMS integration for MVP
   - at minimum robust manual/voice fallback
   - defer email import if needed, but document it honestly

5. **Complete auth flows**
   - working logout
   - forgot/reset password
   - optional Google sign-in
   - production token/session security review

6. **Finish mobile/backend end-to-end happy path**
   - register/login
   - create account
   - add transaction
   - clarification
   - budget
   - goal
   - dashboard refresh

7. **Add production ops basics**
   - environment separation
   - deployment target config
   - HTTPS/reverse proxy
   - secrets management
   - monitoring/logging
   - DB backup strategy

8. **Add tests for critical flows**
   - auth
   - transaction creation/update/delete
   - reconciliation
   - budget progress
   - goal projection
   - contract tests for mobile-facing APIs

### Required env vars / secrets / external services
At minimum for production:
- Postgres database
- Redis
- JWT secret
- real AI provider key
- FX provider endpoint/key if moving off free endpoint
- Google OAuth credentials if Google sign-in/email integration is enabled
- mail delivery provider for password reset
- push notification credentials
- optional Sentry DSN
- optional PostHog key

### Product-level decisions still needed
- Is email ingestion in MVP or phase 2?
- Is statement import MVP or post-MVP?
- How much of voice is truly native in v1 vs simulated text input?
- Will reconciliation use synthetic adjustment transactions or hidden offsets consistently?

---

## 12. Estimated effort to finish

These are rough estimates assuming one experienced full-stack engineer familiar with NestJS + Flutter.

### A. Get the current repo actually working end-to-end
- fix API contracts
- fix route prefixes / response formats
- fix mobile payload mismatches
- fix Prisma runnable issues
- verify core auth/account/transaction/budget/goal flows

**Estimate: 24–40 hours**

### B. Finish a believable MVP matching the current spec intent
Add/finish:
- real AI provider integration
- real Android SMS MVP ingestion
- clarification polish
- notification plumbing
- better multi-currency handling
- settings/preferences sync
- basic summaries + assistant polish
- core testing

**Estimate: 80–140 hours**

### C. Production hardening
Add:
- deployment pipeline
- monitoring
- secrets handling
- background jobs/workers
- stronger tests
- security/privacy polish
- failure handling
- docs/runbooks

**Estimate: 40–70 hours**

### Practical total
- **Local/demo-ready MVP:** ~100–160 hours
- **Production-ready v1:** ~140–230 hours

If email ingestion + statement import are required in MVP, add roughly:
- **+30–60 hours**

---

## 13. Final verdict

### The good
This repo is not empty fluff. There is real thought here.
- solid architecture direction
- strong schema
- decent backend coverage
- polished Flutter UI shell
- clear product vision aligned with the spec

### The bad
It is still **closer to a high-quality prototype scaffold than a true working product**.
The hardest parts are unfinished:
- real AI
- real ingestion
- API contract stability
- production security/ops
- test coverage

### Plain answer
If you asked, “Is this mostly built?”
- **UI shell:** yes
- **backend scaffold:** yes
- **true MVP functionality:** partially
- **production readiness:** no

### Best next move
Do this first, before any new features:
1. fix backend/mobile API contract mismatches
2. make Prisma fully runnable with migrations
3. verify the full happy path end-to-end
4. then implement real AI + real SMS ingestion

That’s the shortest path to turning this from a nice scaffold into an actual product.
