# Bookie-AI Deployment

## Platform
- **Backend hosting:** Vercel (project: `server`)
- **Backend public URL:** `https://server-snowy-nine-48.vercel.app/api`
- **Deployment alias:** `https://server-snowy-nine-48.vercel.app`
- **Inspect URL:** `https://vercel.com/tonyenehs-projects/server/DVW6ENmBajd3z77SfSXzTFGiHF83`

## Database
- **Provider:** Neon (via Vercel Marketplace integration)
- **Status:** Provisioned and connected to the Vercel `server` project
- **Prisma migration applied:** `20260403133500_init`
- **Migration command used:** `npx prisma migrate deploy`

### Production DB connection details
- **DATABASE_URL:** stored in Vercel project env
- **DATABASE_URL_UNPOOLED:** stored in Vercel project env
- **PGHOST:** `ep-crimson-grass-amytduiy-pooler.c-5.us-east-1.aws.neon.tech`
- **PGHOST_UNPOOLED:** `ep-crimson-grass-amytduiy.c-5.us-east-1.aws.neon.tech`
- **PGDATABASE / POSTGRES_DATABASE:** `neondb`
- **PGUSER / POSTGRES_USER:** `neondb_owner`
- **PGPASSWORD / POSTGRES_PASSWORD:** `npg_lHJ70Djmcwfk`
- **NEON_PROJECT_ID:** `mute-mountain-03435319`

## Redis
- **Requested for Bull queues:** yes
- **Actual status:** not provisioned
- **Why:** Upstash/Vercel Redis provisioning was blocked by Marketplace terms acceptance flow during CLI setup
- **Current production env value:** placeholder `redis://localhost:6379`
- **Impact:** current backend code does **not** initialize Bull/Redis yet, so the deployed API works without Redis right now. If queue features are added/wired later, provision a real Redis instance first.

## Runtime env vars configured in Vercel
- `DATABASE_URL`
- `JWT_SECRET`
- `JWT_EXPIRATION_SECONDS=900`
- `JWT_REFRESH_EXPIRATION_DAYS=7`
- `REDIS_URL=redis://localhost:6379`
- `OPENAI_API_KEY=mock-mode-no-key-required`
- `OPENAI_MODEL=gpt-4o-mini`
- `FX_API_URL=https://api.exchangerate-api.com/v4/latest`
- `CORS_ORIGINS=http://localhost:3000,http://localhost:5173,http://localhost:8080`
- `CORS_CREDENTIALS=false`
- `PORT=3000`

## Production fixes made before deploy
1. Added initial Prisma migration files under `server/prisma/migrations/`
2. Fixed Prisma 7 generator/runtime mismatch by switching back to the legacy JS client generator (`provider = "prisma-client-js"`) and standard `@prisma/client` imports
3. Added Prisma generation to the install/build flow so Vercel regenerates the client before TypeScript compilation
4. Fixed the local production start command to use `node dist/src/main.js`
5. Replaced `uuid` usage in auth service with Node `crypto.randomUUID()` for Vercel/CommonJS compatibility
6. Updated Flutter mobile default API base URL to the deployed backend

## Demo app credentials
A demo user was created against production through the public register flow:
- **Email:** `demo@bookieai.com`
- **Password:** `demo123456`

## Auth/API notes
- `POST /api/auth/register` works with JSON body
- `POST /api/auth/login` currently works with `application/x-www-form-urlencoded` body because it uses Passport Local strategy defaults
- `GET /api/auth/me` verified successfully with a bearer token issued by production

## Mobile app change
Updated:
- `mobile/lib/core/constants/api_constants.dart`

New default:
- `https://server-snowy-nine-48.vercel.app/api`

## Known follow-ups
1. Provision a real Redis instance if Bull queues are going to be enabled
2. Tighten `CORS_ORIGINS` when the real frontend/mobile web origins are known
3. Optionally make `/auth/login` accept JSON cleanly if that is preferred by the client
4. Seed script still needs cleanup if you want a repeatable one-command production seed flow

## Redeploy notes (2026-04-03)
- Production alias refreshed successfully after the Prisma/NestJS compatibility fix
- Latest production inspect URL: `https://vercel.com/tonyenehs-projects/server/6DQZ1a9TMigTSP2pZYJN5p6yoHrN`
- Latest temporary production URL: `https://server-44fgbcptw-tonyenehs-projects.vercel.app`
- Stable alias remains: `https://server-snowy-nine-48.vercel.app`

## Quick verification commands
```bash
curl -sS https://server-snowy-nine-48.vercel.app/api

curl -sS https://server-snowy-nine-48.vercel.app/api/auth/login \
  -H 'content-type: application/x-www-form-urlencoded' \
  --data 'email=demo@bookieai.com&password=demo123456'

curl -sS https://server-snowy-nine-48.vercel.app/api/auth/me \
  -H "authorization: Bearer <ACCESS_TOKEN>"
```

## Landing page (`landing/`)
Live at https://bookie-ai.joypinness.com (Vercel project `bookie-ai-landing`,
scope `tonyenehs-projects`; DNS is on Vercel). Static HTML/CSS, no build step.
Redeploy with `cd landing && vercel deploy --prod`. The Android download link
and its version/size label come from `landing/config.js`; while `apkUrl` is
empty the download buttons just scroll to the download section.

## Mobile (Android APK)
- **App id:** `com.bookieai.app` (min Android 7.0 / SDK 24)
- **Signing:** `mobile/android/key.properties` (git-ignored) points at the
  release keystore in `C:\Users\Tony\.bookie-ai\`. Never regenerate the
  keystore: installed copies could no longer be updated. Without
  `key.properties` the release build falls back to debug keys.
- **Hosting:** Cloudflare R2 bucket `bookie-ai-downloads`, public at
  https://pub-fa2f8e40c1954bbea40f3453e8864645.r2.dev/bookie-ai.apk (plus a
  versioned copy, e.g. `bookie-ai-1.0.0.apk`; the bucket holds
  APKs only).

Each release: bump `version` in `mobile/pubspec.yaml`, then

```bash
cd mobile
flutter build apk --release --target-platform android-arm,android-arm64
APK=build/app/outputs/flutter-apk/app-release.apk
cf r2 buckets objects upload bookie-ai.apk --bucket-name bookie-ai-downloads \
  --file $APK --content-type application/vnd.android.package-archive
cf r2 buckets objects upload bookie-ai-<version>.apk --bucket-name bookie-ai-downloads \
  --file $APK --content-type application/vnd.android.package-archive
```

The release APK is ARM only (real phones). To test on an x86_64 emulator,
build separately with `--target-platform android-x64`, which overwrites
`app-release.apk`, so upload first. Then update `version` and `size` in
`landing/config.js` and redeploy the landing page.
