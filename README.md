# Flutter SDUI

Server-Driven UI sample for **Android** and **iOS**. The backend owns screen layout, copy, validation, and next-step actions. The Flutter app owns a reusable widget catalog, navigation, connectivity, and native input (keyboard, autofill, obscure text).

This repo includes analysis/design docs, sample JSON for **login**, **signup**, and **OTP**, and a working Flutter client that renders those screens without hardcoded forms.

---

## What SDUI does here

Classic app: Flutter widgets are compiled; the API only sends data.

This app: the server (or local JSON) sends a **screen document**. A generic renderer maps `type` fields (`textField`, `button`, `otpField`, …) to Flutter widgets. Changing labels, field order, or extra copy does not require a new app store build, as long as the widget `type` already exists in the catalog.

The client still owns:

- Widget look and accessibility
- Route allowlist (`/login`, `/signup`, `/otp`, `/home`)
- Secrets (passwords and OTP stay in memory; they are not cached)
- Unknown `type` handling (skip / empty box, no crash)

---

## Platforms

| Platform | Project |
|----------|---------|
| Android | `android/` (`com.sdui.flutter_sdui`) |
| iOS | `ios/` |

Internet and network-state permissions are declared on Android. iOS uses the default Flutter runner.

---

## Requirements

- Flutter **3.38.9** (or compatible) / Dart **3.10.8+** (`pubspec.yaml` SDK `^3.10.8`)
- Xcode (iOS) or Android Studio / SDK (Android)
- Optional: [FVM](https://fvm.app) if you pin a Flutter version locally

```bash
flutter doctor
flutter pub get
```

---

## Run the app

```bash
# List devices
flutter devices

# Android
flutter run -d android

# iOS simulator
flutter run -d ios
```

From an IDE, run `lib/main.dart`.

There is **no live backend** in this demo. `AppConfig.useLocalSduiMock` is `true`. Dio still calls:

- `GET /sdui/screens/{login|signup|otp}`
- `POST /sdui/actions/{submit_login|submit_signup|submit_otp|resend_otp}`

A **core** interceptor (`LocalSduiInterceptor`) answers those calls from `assets/sdui/*.json` and returns demo action results.

---

## Demo credentials

| Flow | Input | Result |
|------|--------|--------|
| Login | Any valid email + password **at least 8 characters** | Navigate to OTP |
| Login failure | Password `wrongpass` | Field error on password |
| Signup | Name, email, passwords, terms checked | Navigate to OTP |
| OTP success | Code **`123456`** | Replace stack with home |
| OTP failure | Any other 6-digit code | Field error on OTP |
| Resend | Tap when countdown is 0 | Cooldown resets to 30s |
| Forgot password | Link on login | Snackbar only (not implemented) |

Home is a **native** page (not SDUI). Sign out returns to login.

---

## Architecture

Clean architecture is **feature-wise**, with shared code in **core**.

```
core (global)
  Dio + interceptors
  Failure / Result
  connectivity
  screen cache
  SDUI parser + renderer + SduiHost

features/login    data | domain | presentation
features/signup   data | domain | presentation
features/otp      data | domain | presentation
features/home     presentation only (success landing)
```

**Rules**

- `core` does not import `features/*` (OTP route args live in core so navigation can stay global).
- Feature **domain** has no Dio and no Flutter widgets.
- Feature **data** uses the **shared** `Dio` instance. Interceptors are **not** registered per feature.
- Feature **presentation** (`LoginPage`, `SignupPage`, `OtpPage`) hosts `SduiHost`. Forms are not hardcoded in Dart.
- After submit, navigation goes to **another feature route** (login → OTP page), not a second JSON tree inside the same Cubit.

### Why interceptors are in `core/network`

They wrap every HTTP call (connectivity abort, headers, ETag, logging with redacted `password` / `otp`, local mock). Login must not own the app HTTP client.

---

## Project layout

```
docs/
  SDUI_ANALYSIS.md      JSON contract, real-time flow, connectivity policy
  SDUI_DESIGN.md        Detailed design (layers, Dio, class map)

samples/sdui/           Source JSON (login, signup, otp)
assets/sdui/            Same JSON bundled for the mock interceptor

lib/
  main.dart
  app.dart              MaterialApp routes
  core/
    cache/
    connectivity/
    constants/          ApiPaths, AppRoutes, AppConfig
    di/injection.dart   get_it
    error/              Failure, Result
    network/            Dio, interceptors, error mapper
    sdui/
      domain/           SduiScreen, nodes, actions, connectivity repo
      data/parsers/
      presentation/     controller, validators, renderer, SduiHost
  features/
    login | signup | otp
      domain/           repository + use cases
      data/             remote datasource + repository impl
      presentation/     Cubit + Page
    home/presentation/pages/home_page.dart

test/widget_test.dart   Login JSON renders “Welcome back”
```

---

## JSON contract (short)

Each screen is a document: `schemaVersion`, `screenId`, `forms`, `root` tree.

Common node fields: `id`, `type`, `props`, `children`, `bind`, `validators`, `actions`, `visibleWhen`.

**Catalog (v1):** `scaffold`, `appBar`, `scroll`, `column`, `row`, `text`, `image`, `textField`, `otpField`, `button`, `textButton`, `checkbox`, `banner`, `spacer`.

**Actions:** `submit_form`, `resend_otp`, `navigate`, `pop`, `set_state`.

Samples:

- [`samples/sdui/login.json`](samples/sdui/login.json)
- [`samples/sdui/signup.json`](samples/sdui/signup.json)
- [`samples/sdui/otp.json`](samples/sdui/otp.json)

If you edit samples, copy them into `assets/sdui/` as well (or keep both in sync). `pubspec.yaml` loads `assets/sdui/`.

---

## Networking and connectivity

| Piece | Role |
|-------|------|
| Dio | Only HTTP client (timeouts, base URL `https://sdui.local` in mock mode) |
| `ConnectivityInterceptor` | No request if offline |
| `HeaderInterceptor` | `Accept`, app version, schema max |
| `EtagInterceptor` | `If-None-Match` for screen GET |
| `LoggingInterceptor` | Debug logs; secrets redacted |
| `LocalSduiInterceptor` | Mock responses when `useLocalSduiMock` is true |

**Offline policy**

- **GET screen:** use last cached JSON if present; otherwise error.
- **POST** (login / signup / OTP / resend): **blocked**. No credential queue on disk.

In mock mode, “online” means the device has a network **interface** (Wi‑Fi/cellular). Reachability to a real host is skipped so the demo works without the internet. With mock off, `internet_connection_checker_plus` is used after a non-`none` interface.

Cache: `SharedPreferences`, key `sdui:{screenId}:{locale}:{appVersion}`. Passwords and OTP are never stored.

---

## Use cases (per feature)

| Feature | Load | Submit |
|---------|------|--------|
| Login | `GetLoginScreen` | `SubmitLogin` |
| Signup | `GetSignupScreen` | `SubmitSignup` |
| OTP | `GetOtpScreen` | `SubmitOtp`, `ResendOtp` |

Shared: `CheckConnectivity`, `WatchConnectivity` (core).

State: `flutter_bloc` Cubits. DI: `get_it` in `lib/core/di/injection.dart`.

---

## Point at a real API later

1. Set `AppConfig.useLocalSduiMock` to `false` in `lib/core/constants/api_paths.dart`.
2. Set `AppConfig.baseUrl` to your server.
3. Implement:

   - `GET {baseUrl}/sdui/screens/:id`
   - `POST {baseUrl}/sdui/actions/:actionId`

   Request/response shapes are in [`docs/SDUI_ANALYSIS.md`](docs/SDUI_ANALYSIS.md) and [`docs/SDUI_DESIGN.md`](docs/SDUI_DESIGN.md).

Action results used by the client: `field_errors`, `navigate` (`route` + `params`), `ok` + `statePatch`.

---

## Tests

```bash
dart analyze lib test
flutter test
```

The widget test fakes connectivity so plugins do not hang, then asserts the login screen title from JSON.

---

## Dependencies

| Package | Use |
|---------|-----|
| `dio` | HTTP |
| `flutter_bloc` | Cubits |
| `get_it` | DI |
| `connectivity_plus` | Interface type (wifi / mobile / none) |
| `internet_connection_checker_plus` | Reachability when mock is off |
| `shared_preferences` | Screen JSON cache |

---

## Design docs

| File | Content |
|------|---------|
| [docs/SDUI_ANALYSIS.md](docs/SDUI_ANALYSIS.md) | Product/contract: SDUI vs classic UI, JSON schema, catalog, connectivity, class map |
| [docs/SDUI_DESIGN.md](docs/SDUI_DESIGN.md) | Engineering: core vs features, interceptor placement, sequences, DI |

---

## Out of scope (v1)

- Live WebSocket/SSE layout updates
- Offline retry queue for credentials
- Forgot-password screen
- Social login
- Code generation of widgets from JSON
