# Bookie-AI Deployment

Never put secret values (passwords, keys, connection strings) in this file:
the repo is public. Secrets live only in Vercel project env vars.

## API (`server/`)
- **Hosting:** Vercel project `bookie-ai-api` (scope `tonyenehs-projects`),
  Root Directory `server`, framework preset NestJS. Connected to this GitHub
  repo: pushes to `main` deploy production, other branches get previews.
- **Public URL:** https://bookie-ai-api.vercel.app/api
- **API docs (Swagger):** https://bookie-ai-api.vercel.app/api/docs
- The older `server` Vercel project (`server-snowy-nine-48.vercel.app`) is
  superseded and can be deleted.

## Database
- **Provider:** Neon, via the Vercel Marketplace integration. Connection
  details are injected into the `bookie-ai-api` env (`DATABASE_URL` and the
  `NEON_*` variables).
- **Migrations:** `server/prisma/migrations/`. Apply with
  `npx prisma migrate deploy` using the production `DATABASE_URL`.
- **Default categories:** created by the API on startup if missing (idempotent).
  `prisma/seed.ts` is for local development only: it wipes every table.

## Runtime env vars (names only)
Required: `DATABASE_URL`, `JWT_SECRET`, `JWT_EXPIRATION_SECONDS`,
`JWT_REFRESH_EXPIRATION_DAYS`.

Optional:
- `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`: real AI. Leave
  `OPENAI_API_KEY` unset for mock mode.
- `REDIS_URL`: queue for outgoing email. When unset or unreachable, email is
  sent inline.
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`,
  `SMTP_FROM`: password reset email. Without SMTP the reset link is only logged.
- `PASSWORD_RESET_URL`: optional. The reset email links to a page the API
  serves itself (`/api/auth/reset-password`), built from the request host;
  set this only to send users somewhere else. (`APP_URL` is no longer used.)
- `GOOGLE_CLIENT_ID`: Google sign-in.
- `FX_API_URL`: exchange rate source.
- `CORS_MODE`, `CORS_ORIGINS`, `CORS_CREDENTIALS`: see `server/src/main.ts`.
- `RESET_PASSWORD_EXPIRATION_MINUTES`.
- `TOKEN_ENCRYPTION_KEY`: optional 32-byte base64 key for encrypting stored
  OAuth tokens (connected accounts). Defaults to a key derived from
  `JWT_SECRET`; changing either makes stored tokens unreadable.

## Quick verification
```bash
curl -sS https://bookie-ai-api.vercel.app/api/health

curl -sS https://bookie-ai-api.vercel.app/api/auth/login   -H 'content-type: application/json'   -d '{"email":"you@example.com","password":"..."}'
```

## Landing page (`landing/`)
Live at https://bookie-ai.joypinness.com (Vercel project `bookie-ai-landing`,
scope `tonyenehs-projects`; DNS is on Vercel). Static HTML/CSS, no build step.
The project is connected to this GitHub repo with Root Directory `landing`,
so every push to `main` redeploys it automatically. The Android download link
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
