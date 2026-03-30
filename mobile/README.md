# bookie_ai mobile

## Environment configuration

This app now loads API configuration from `assets/env/.env` via `flutter_dotenv`.

Default values:

- `API_BASE_URL=http://localhost:3000/api`
- `API_BASE_URL_ANDROID=http://10.0.2.2:3000/api`

Resolution order:

1. `--dart-define=API_BASE_URL=...`
2. `--dart-define=API_BASE_URL_ANDROID=...` on Android only
3. Values from `assets/env/.env`
4. Built-in defaults

## Run examples

Web server:

```bash
flutter run -d web-server
```

Web server with explicit override:

```bash
flutter run -d web-server --dart-define=API_BASE_URL=http://localhost:3000/api
```

Android emulator:

```bash
flutter run --dart-define=API_BASE_URL_ANDROID=http://10.0.2.2:3000/api
```