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

For a physical Android device on the same Wi-Fi as your dev machine, replace
`API_BASE_URL_ANDROID` with your computer's LAN IP:

```env
API_BASE_URL_ANDROID=http://192.168.1.42:3000/api
```

Resolution order:

1. `--dart-define=API_BASE_URL=...`
2. `--dart-define=API_BASE_URL_ANDROID=...` on Android only
3. values from `assets/env/.env`
4. built-in default `https://server-snowy-nine-48.vercel.app/api`

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

Android physical device:

1. Start the server so it listens on your LAN interface.
2. Set `API_BASE_URL_ANDROID` to `http://<your-computer-lan-ip>:3000/api`.
3. Make sure your phone and computer are on the same network.
4. Run the app on the device.
