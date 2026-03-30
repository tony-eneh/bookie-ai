# bookie_ai mobile

## Environment configuration

This app loads a local `assets/env/.env` file when present.

Tracked example:

- `assets/env/.env.example`

Ignored local file:

- `assets/env/.env`

Example contents:

```env
API_BASE_URL=http://localhost:3000/api
API_BASE_URL_ANDROID=http://10.0.2.2:3000/api
```

Resolution order:

1. `--dart-define=API_BASE_URL=...`
2. `--dart-define=API_BASE_URL_ANDROID=...` on Android only
3. values from `assets/env/.env`
4. built-in defaults

## Setup

Create your local env file from the example:

```bash
cp assets/env/.env.example assets/env/.env
```

## Run examples

Web server:

```bash
flutter run -d web-server
```

Android emulator:

```bash
flutter run
```