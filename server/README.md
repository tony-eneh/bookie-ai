# BookieAI Server

NestJS and Prisma backend for BookieAI, a voice-first personal finance API with multi-currency accounts, transaction ingestion, budget tracking, goals, clarifications, insights, and assistant endpoints.

## Stack

- NestJS 11
- Prisma ORM
- PostgreSQL
- Redis
- Swagger / OpenAPI

## Prerequisites

- Node.js 20+
- npm 10+
- Docker and Docker Compose

## Environment

Create `server/.env` from `server/.env.example` and set the required values.

```env
DATABASE_URL=postgresql://bookieai:bookieai@localhost:5432/bookieai
JWT_SECRET=replace-me
JWT_EXPIRATION_SECONDS=900
JWT_REFRESH_EXPIRATION_DAYS=7
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=replace-me
OPENAI_MODEL=gpt-4o-mini
FX_API_URL=https://api.exchangerate-api.com/v4/latest
CORS_ORIGINS=http://localhost:3000,http://localhost:5173
CORS_CREDENTIALS=false
PORT=3000
```

Notes:

- `JWT_SECRET` is required. The server now fails fast if it is missing.
- Refresh tokens are opaque UUIDs stored in the database, so there is no `JWT_REFRESH_SECRET` variable.
- CORS is restricted to the comma-separated origins in `CORS_ORIGINS`.

## Local Setup

```bash
npm install
docker compose up -d
npx prisma generate
npx prisma migrate dev
npx prisma db seed
npm run start:dev
```

The API listens on `http://localhost:3000` by default.

## Useful Commands

```bash
npm run build
npm run lint
npm run test
npm run test:e2e
npm run start:dev
```

## Seed Data

The seed script creates:

- one demo user
- three accounts
- default categories
- transactions with running `balanceAfterTransaction` snapshots
- clarifications, budgets, goals, notifications, FX rates, and an income target

Default categories are seeded through `npx prisma db seed`, not automatically on application startup. That avoids duplicate category races in multi-instance deployments.

Demo credentials:

- Email: `demo@bookieai.com`
- Password: `demo123456`

## API Surface

Swagger is available at:

```text
http://localhost:3000/api
```

Implemented modules include:

- `auth`
- `users`
- `accounts`
- `categories`
- `transactions`
- `clarifications`
- `budgets`
- `goals`
- `fx`
- `insights`
- `assistant`
- `notifications`
- `ingestion`

## Auth Readiness

Current auth behavior is intentionally conservative:

- email/password login is implemented through Passport local auth
- JWT access tokens and persisted refresh tokens are implemented
- forgot-password validates input and returns a generic response, but email delivery is not implemented yet
- reset-password currently returns `501 Not Implemented` until reset-token validation is added
- Google sign-in currently returns `501 Not Implemented` until ID token verification is added

Do not treat password reset or Google sign-in as production-ready until those flows are completed end to end.

## Testing Notes

Jest is configured with NodeNext-friendly `.js` import mapping so unit and e2e tests can resolve TypeScript source imports consistently.

## Production Notes

- restrict `CORS_ORIGINS` to trusted frontend origins
- use a strong `JWT_SECRET`
- run Prisma migrations before deploying
- provide a real FX API key/service if the configured endpoint requires one
- wire real email delivery and Google ID-token verification before enabling those auth features
