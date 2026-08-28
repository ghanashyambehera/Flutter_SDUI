# SDUI — Detailed Design

**Status:** Design only. No implementation in this drop.

**Depends on:** [`SDUI_ANALYSIS.md`](./SDUI_ANALYSIS.md) (JSON contract, widget catalog, action types, sample screens).

**Architecture (corrected):**

| Piece | Where | Why |
|-------|--------|-----|
| Shared / global | `lib/core` | One Dio, interceptors, failures, connectivity, SDUI engine |
| Product features | `lib/features/login`, `signup`, `otp` | Each has **data / domain / presentation** |

HTTP via **Dio** only. Connectivity checked before feature API calls and watched while a feature page is open.

---

## 1. What was wrong in the previous design

The last draft put **everything** under `features/sdui` (Dio, interceptors, connectivity, renderer, and all three screens). That is not feature-based clean architecture.

| Problem | Fix |
|---------|-----|
| Login, signup, OTP were one generic `SduiPage` with no feature modules | Each is a **feature** with its own layers |
| Interceptors lived in `features/sdui/data` | Interceptors belong in **`core/network`** (they wrap the **app** Dio) |
| `Failure`, `NetworkInfo`, cache helpers duplicated the idea of “core” but stayed in the feature | Move all **global** types to `core` |
| A future Home feature would re-copy Dio/interceptors | Features only **use** core Dio; they never register interceptors |

SDUI does **not** disappear. The **engine** (parse JSON → widgets) is **core infrastructure**. Each feature **loads its own screen**, **submits its own actions**, and **owns navigation to the next feature** (login → signup / otp).

---

## 2. Why interceptors are not in a feature `data` layer

Interceptors are **not** login/signup/otp business rules. They run on **every** HTTP call attached to the shared client.

| Interceptor | Scope | If it lived in `features/login/data` |
|-------------|--------|--------------------------------------|
| Connectivity | All APIs | Signup/OTP would need copies, or login would “own” the app client |
| Headers (`Accept`, app version, later `Authorization`) | All APIs | Token refresh is not a login-screen concern |
| Logging + secret redaction | All APIs | Must apply to OTP POST as well |
| ETag (optional) | Shared GET cache policy | Screen cache is a **core** helper; feature datasources pass `screenId` |

**Clean Architecture mapping:**

- **Core `data` (infrastructure):** create `Dio`, **attach interceptors**, map `DioException` → core `Failure`.
- **Feature `data`:** `dio.get('/sdui/screens/login')` / `dio.post('/sdui/actions/submit_login')`. No interceptor classes here.
- **Feature `domain`:** never sees `Dio`, `Interceptor`, or plugins.

Feature `data` may still **catch** `DioException` and map to `Failure` (or call a **core** `DioErrorMapper`). That mapping is datasource work, not interceptor work.

**ETag:** the interceptor in core can attach `If-None-Match` using a **core** ETag store keyed by URL. Login/signup/otp datasources do not implement HTTP cache headers themselves.

---

## 3. Goals and non-goals

**Goals**

- Feature-wise clean architecture: **login**, **signup**, **otp**.
- Global access for shared types via **`core`**.
- Fetch each feature’s screen JSON and submit that feature’s actions through that feature’s repository.
- Survive unknown widget `type`s (core renderer).
- Offline: cached **GET** per feature; **block** POST when offline.
- Feature domain testable without Flutter, Dio, or plugins.

**Non-goals (v1)**

- WebSocket/SSE.
- Offline retry queue for credentials.
- Three copies of the widget catalog (catalog is core).
- Hardcoded Form widgets in `LoginPage` (page hosts the **core renderer**).

---

## 4. High-level architecture

```
                    ┌──────────────────────────────────────────┐
                    │                 CORE                      │
                    │  network: Dio + interceptors + ErrorMapper│
                    │  connectivity: NetworkInfo + repo impl    │
                    │  error: Failure                           │
                    │  sdui: entities, parser, mapper,          │
                    │        renderer, catalog, SduiHost        │
                    │  cache: screen JSON store (by screenId)   │
                    └────────────▲──────────────▲───────────────┘
                                 │ uses         │ uses
              ┌──────────────────┼──────────────┼──────────────────┐
              │                  │              │                  │
     ┌────────┴────────┐ ┌───────┴──────┐ ┌─────┴────────┐
     │ features/login  │ │features/signup│ │ features/otp │
     │  presentation   │ │ presentation  │ │ presentation │
     │  domain         │ │ domain        │ │ domain       │
     │  data           │ │ data          │ │ data         │
     └─────────────────┘ └───────────────┘ └──────────────┘
```

**Dependency rule**

- `core` does not import `features/*`.
- Feature **domain** imports only Dart + core **domain** types (`Failure`, `SduiScreen`, `ConnectivityRepository`). No Dio, no Flutter.
- Feature **data** imports feature domain + core Dio / cache / mapper.
- Feature **presentation** imports feature domain + core SDUI **presentation** (renderer) + Flutter.
- Features do not import each other’s `data` or `domain`. Navigation is **routes** / callbacks (`LoginNavigator` → signup route).

---

## 5. Folder layout

```
lib/
  core/
    error/
      failures.dart
    network/
      dio_client.dart                 # singleton Dio, timeouts, baseUrl
      dio_error_mapper.dart           # DioException → Failure
      interceptors/
        connectivity_interceptor.dart
        header_interceptor.dart
        logging_interceptor.dart      # redact password, otp
        etag_interceptor.dart         # optional, uses core cache keys
    connectivity/
      network_info.dart               # abstract in domain style, impl here
      connectivity_repository_impl.dart
    cache/
      sdui_screen_cache.dart          # save/read JSON + ETag by screenId
    constants/
      api_paths.dart                  # /sdui/screens, /sdui/actions
      sdui_schema.dart                # min/max schemaVersion
    di/
      injection.dart                  # register core + all features
    sdui/
      domain/
        entities/
          sdui_screen.dart
          sdui_node.dart
          sdui_action.dart
          sdui_validator.dart
          sdui_action_result.dart
          sdui_navigation.dart
        repositories/
          connectivity_repository.dart
      data/
        models/                       # DTOs + fromJson
        mappers/
          sdui_mapper.dart
        parsers/
          sdui_screen_parser.dart
      presentation/
        engine/                       # controller, validators, conditions
        renderer/                     # factory + catalog builders
        widgets/                      # SduiHost, offline banner, error/loading
        navigation/
          sdui_navigator.dart         # push named feature routes (allowlist)

  features/
    login/
      domain/
        repositories/
          login_repository.dart
        usecases/
          get_login_screen.dart
          submit_login.dart
      data/
        datasources/
          login_remote_data_source.dart
        repositories/
          login_repository_impl.dart
      presentation/
        cubit/
          login_cubit.dart
          login_state.dart
        pages/
          login_page.dart
        login_action_handler.dart     # feature-specific result → navigate

    signup/
      domain/
        repositories/
          signup_repository.dart
        usecases/
          get_signup_screen.dart
          submit_signup.dart
      data/
        datasources/
          signup_remote_data_source.dart
        repositories/
          signup_repository_impl.dart
      presentation/
        cubit/
          signup_cubit.dart
          signup_state.dart
        pages/
          signup_page.dart
        signup_action_handler.dart

    otp/
      domain/
        entities/
          otp_params.dart             # destination, flow (signup | login)
        repositories/
          otp_repository.dart
        usecases/
          get_otp_screen.dart
          submit_otp.dart
          resend_otp.dart
      data/
        datasources/
          otp_remote_data_source.dart
        repositories/
          otp_repository_impl.dart
      presentation/
        cubit/
          otp_cubit.dart
          otp_state.dart
        pages/
          otp_page.dart
        otp_action_handler.dart
```

Shared fixtures: `samples/sdui/login.json`, `signup.json`, `otp.json`.

**What stays out of features:** Dio construction, interceptors, `Failure`, `NetworkInfo`, JSON parser/mapper, widget catalog, `SduiHost`.

**What stays in features:** screen id + action ids, repository contracts, use cases, remote paths for that screen, Cubit, Page, navigation after success.

---

## 6. Core design (global)

### 6.1 Failures (`core/error`)

Used by every feature. Presentation maps these to UI; never show raw `DioException`.

| Type | When |
|------|------|
| `NoConnectivityFailure` | Pre-flight or connectivity interceptor |
| `TimeoutFailure` | Dio timeouts |
| `ServerFailure` | HTTP 5xx / bad envelope |
| `ClientFailure` | HTTP 4xx that is not field-errors body |
| `UnauthorizedFailure` | HTTP 401 |
| `ParseFailure` | JSON missing `root` |
| `UnsupportedSchemaFailure` | schemaVersion > client max |
| `CacheMissFailure` | Offline and no cache |
| `UnknownFailure` | Fallback |

HTTP **200** with `status: field_errors` is **not** a Failure. It is `SduiActionResult` applied by the **feature** Cubit.

### 6.2 Dio client (`core/network`)

One app-wide `Dio` registered in DI.

| Setting | v1 |
|---------|-----|
| `baseUrl` | env / `--dart-define` |
| `connectTimeout` | 10s |
| `receiveTimeout` | 20s |
| `sendTimeout` | 20s |
| `headers` | `Accept: application/json` (rest via HeaderInterceptor) |
| `validateStatus` | 200–299 success; 304 success-with-cache |

**Interceptor order (core only):**

1. `ConnectivityInterceptor` — if `NetworkInfo.isOnline == false`, throw `NoNetworkException`. Features never hang on a socket.
2. `HeaderInterceptor` — locale, `X-App-Version`, `X-Schema-Max`, later `Authorization`.
3. `ETagInterceptor` — GET: `If-None-Match` from `SduiScreenCache`.
4. `LoggingInterceptor` — debug; **redact** `password`, `confirmPassword`, `otp`.

No retry on auth POST. Optional single retry on GET timeout if still online (core policy, not per feature).

### 6.3 Connectivity (`core/connectivity`)

`connectivity_plus` alone is not enough (Wi‑Fi without internet).

`NetworkInfo.isOnline()`:

1. `ConnectivityResult.none` → `false`.
2. Reachability: `internet_connection_checker_plus` **or** short `HEAD` `{baseUrl}/health`.

`ConnectivityRepository` (interface in `core/sdui/domain`, **impl in core**):

- `Future<bool> isOnline()`
- `Stream<bool> onStatusChange()` (debounce 300–500ms, then re-check reachability)

Every feature Cubit **injects** `WatchConnectivity` / `CheckConnectivity` from **core domain use cases** (or the repository). Do not copy connectivity into login/signup/otp.

Core use cases (global, not feature):

| Use case | Location |
|----------|----------|
| `CheckConnectivity` | `core/sdui/domain/usecases/` |
| `WatchConnectivity` | same |

### 6.4 Screen cache (`core/cache`)

```
SduiScreenCache
  save(screenId, locale, appVersion, json, etag?)
  read(...)
  readEtag(...)
```

Key: `sdui:{screenId}:{locale}:{appVersion}`. Never persist passwords/OTP/POST bodies.

Features call cache through **their repository impl** (data layer), not from Cubit.

### 6.5 SDUI engine (`core/sdui`)

**Domain entities** (no `fromJson`): `SduiScreen`, `SduiNode`, `SduiAction`, `SduiValidator`, `SduiActionResult`, `SduiNavigation`.

**Data:** DTOs, `SduiScreenParser`, `SduiMapper.toDomain`.

**Presentation:**

| Type | Role |
|------|------|
| `SduiController` | Form values, errors, extraState, submitting, OTP timer |
| `SduiValidatorRunner` | Local validators |
| `SduiConditionEvaluator` | `visibleWhen` |
| `SduiStringResolver` | `{{destination}}` |
| `SduiWidgetFactory` | Catalog builders |
| `SduiRenderer` | Builds `root` |
| `SduiHost` | Loading / error / offline banner + renderer (used **inside** feature pages) |

Feature pages compose `SduiHost`; they do not reimplement the catalog.

---

## 7. Feature design (login, signup, otp)

Each feature follows the same shape. Only screen id, actions, and navigation differ.

### 7.1 Layer responsibilities

| Layer | Owns | Must not own |
|-------|------|----------------|
| Domain | Feature repository **interface**, use cases, optional `OtpParams` | Dio, interceptors, Widgets, JSON `fromJson` |
| Data | Remote datasource using **core Dio**, repository **impl**, map DTO via **core mapper** | Interceptors, other features’ repos |
| Presentation | `XxxPage`, `XxxCubit`, action handler (navigate) | Dio, parser |

### 7.2 Login

**Constants (domain or `login/domain/login_ids.dart`):**

- `screenId = login`
- `formId = login_form`
- `submitActionId = submit_login`

**Repository**

```
abstract class LoginRepository {
  Future<Either<Failure, GetScreenOutcome>> getScreen({String? locale, String? appVersion});
  Future<Either<Failure, SduiActionResult>> submitLogin({
    required String formId,
    required Map<String, dynamic> values,
  });
}
```

**Use cases**

| Use case | Policy |
|----------|--------|
| `GetLoginScreen` | `CheckConnectivity` → remote GET `/sdui/screens/login` → core cache; if offline, cache or `CacheMissFailure` |
| `SubmitLogin` | If offline → `NoConnectivityFailure` (no Dio). Else POST `/sdui/actions/submit_login` |

**Data**

- `LoginRemoteDataSource`: `fetchScreen()`, `submit(body)` — only login paths.
- `LoginRepositoryImpl`: uses remote + `SduiScreenCache` + core mapper. Policy can live in the use case (preferred): repo exposes `fetchRemote`, `readCache`, `writeCache`, `submitRemote`.

**Presentation**

- `LoginPage` → `LoginCubit` → `SduiHost`.
- `LoginActionHandler`: on `navigate` / success → `Signup` route or `Otp` route with params; `field_errors` stay on login.
- JSON `navigate.screenId: signup` maps to **app route** `signup`, not to swapping JSON inside login Cubit.

Do **not** replace the login Cubit’s document with the OTP tree on the same page. **Cross-feature navigation** is a first-class route so each feature keeps its own lifecycle (back stack: OTP pops to signup/login).

### 7.3 Signup

Same pattern:

- `screenId = signup`, `submit_signup`
- `GetSignupScreen`, `SubmitSignup`
- `SignupPage` / `SignupCubit`
- Success → push **otp** with `OtpParams(destination, flow: signup)`
- Link “Sign in” → pop or replace **login** route

### 7.4 OTP

- `screenId = otp`, `submit_otp`, `resend_otp`
- `GetOtpScreen` (may merge `OtpParams` into `SduiScreen.params` / controller)
- `SubmitOtp`, `ResendOtp`
- `OtpPage` / `OtpCubit`
- Success → allowlisted `replace_all` **home** (home is a future feature; route name only in v1)
- Resend cooldown: `SduiController.patchState` in **otp** Cubit (timer is feature presentation using core controller)

### 7.5 Shared outcome type

`GetScreenOutcome` lives in **core** (used by all three):

```
class GetScreenOutcome {
  final SduiScreen screen;
  final bool fromCache;
  final bool isOffline;
}
```

### 7.6 What is duplicated vs shared

| Duplicated per feature (intentional) | Shared in core |
|--------------------------------------|----------------|
| Repository interface + impl | Dio, interceptors |
| Get/Submit use cases | Parser, mapper, cache API |
| Cubit + Page | Renderer, catalog, SduiHost |
| Action handler / navigator glue | Failure, connectivity |
| Remote paths for that screen | — |

Do **not** duplicate `ColumnBuilder` or Dio setup.

---

## 8. Feature data sources (Dio usage)

Features receive the **already configured** `Dio` from DI.

```
LoginRemoteDataSource(this._dio, this._mapper)

fetchScreen() => _dio.get('${ApiPaths.sduiScreens}/login', queryParameters: ...)
submit(body)  => _dio.post('${ApiPaths.sduiActions}/submit_login', data: body)
```

Catch `DioException` → `core/DioErrorMapper.toFailure`. Parse body with **core** parser.

**POST body:** `screenId`, `formId`, `values` (form keys only), `client` meta. Never send `resendSecondsLeft`.

---

## 9. Presentation (per feature)

### 9.1 Cubit state (same shape, three types)

`LoginState` / `SignupState` / `OtpState`: Initial, Loading, Ready, LoadError, UnsupportedSchema.

`Ready`: screen, controller snapshot, `isOffline`, `fromCache`, `submitting`.

Methods: `started`, `valueChanged`, `actionRequested`, `retryLoad`, `connectivityChanged`.

Cubit injects **that feature’s use cases** + core `WatchConnectivity`. **No Dio.**

### 9.2 Action handling

Core can provide a small `SduiFormDispatcher` (validate + call a `Future<Either<Failure, SduiActionResult>> submit(...)` callback). Each feature passes its `SubmitLogin` / `SubmitSignup` / `SubmitOtp`.

| JSON `type` | Who handles |
|-------------|-------------|
| `submit_form` | Feature submit use case |
| `resend_otp` | **Otp** `ResendOtp` only; ignore on login |
| `navigate` | Feature handler → named route (`signup`, `login`, `otp`, `forgot_password`) |
| `pop` | `Navigator.pop` |
| `set_state` | Feature Cubit + core controller |
| `open_url` | Core allowlist helper |

If login JSON includes `navigate.screenId: signup`, **LoginActionHandler** pushes `SignupPage`. Signup does not load inside `LoginCubit`.

### 9.3 Connectivity UI

`SduiHost` (core) shows the offline banner from Cubit flags. Feature Cubits subscribe to `WatchConnectivity`. Submit still calls the use case; offline → snackbar, fields kept.

---

## 10. Sequences

### 10.1 Open login (online)

```
LoginPage
  → LoginCubit.started
  → GetLoginScreen
  → CheckConnectivity (core)
  → LoginRepository.fetchRemote
  → Dio GET /sdui/screens/login   // interceptors in core already on Dio
  → core parser/mapper
  → SduiScreenCache.save
  → Ready → SduiHost → SduiRenderer
```

### 10.2 Submit login → OTP feature

```
submit_form
  → SubmitLogin
  → POST /sdui/actions/submit_login
  → SduiActionResult.navigation or explicit contract: go to otp + params
  → LoginActionHandler → Navigator push OtpPage(OtpParams)
  → OtpCubit.started → GetOtpScreen
```

Prefer **navigation to `OtpPage`**, not inlining OTP JSON on `LoginPage`. If the server sends `next` OTP document, OTP feature may **skip GET** and `started(preloaded: screen)` — still **OtpCubit**, not LoginCubit.

### 10.3 Offline submit

```
SubmitLogin → CheckConnectivity false → NoConnectivityFailure
→ Dio not called
```

---

## 11. Security and privacy

- Redact secrets in **core** logging interceptor (covers all features).
- HTTPS only; pinning later on **core** `Dio` adapter.
- `open_url` host allowlist in core.
- Route allowlist: `login`, `signup`, `otp`, `home`.
- Parser max size / depth in **core**.
- No credential cache.

---

## 12. DI graph

```
CORE
  NetworkInfo
  ConnectivityRepositoryImpl → ConnectivityRepository
  CheckConnectivity, WatchConnectivity
  Dio (+ interceptors)
  DioErrorMapper
  SduiScreenCache
  SduiScreenParser, SduiMapper
  SduiWidgetFactory, SduiHost

LOGIN
  LoginRemoteDataSource(Dio)
  LoginRepositoryImpl
  GetLoginScreen, SubmitLogin
  LoginCubit
  LoginPage

SIGNUP  (same pattern)
OTP     (same pattern + ResendOtp, OtpParams)
```

Feature constructors take use cases + `SduiHost` dependencies, never `Dio`.

---

## 13. Testing

| Layer | Mock | Assert |
|-------|------|--------|
| Core interceptors | Fake `NetworkInfo` | Offline request never sent |
| Core parser | `samples/sdui/*.json` | Unknown `type` retained |
| Login domain | Fake `LoginRepository` | Offline submit does not call repo.submit |
| Login data | Dio adapter | Path is `/sdui/screens/login` |
| Login Cubit | Fake use cases | Navigation intent to otp/signup |
| Signup / otp | Same pattern | Feature isolation |
| Catalog goldens | Core builders | One per `type`, not per feature |

---

## 14. Implementation order (when requested)

1. **Core:** Failures, Dio, interceptors, connectivity, parser, mapper, cache, renderer catalog (text/field/button/column).
2. **Login** feature: domain → data → Cubit/Page; mock adapter + `login.json`.
3. **Signup** feature.
4. **Otp** feature (otpField, resend, params).
5. App routes wiring the three pages.
6. ETag + schema mismatch UI in core host.

---

## 15. Traceability

| Topic | Where |
|-------|--------|
| JSON contract / catalog | Analysis §§3–4; samples |
| Interceptors in core | Design §2, §6.2 |
| Feature CA | Design §5, §7 |
| Connectivity | Analysis §2.3.1; Design §6.3 |
| Cross-feature navigation | Design §7.2, §10.2 |

---

## 16. Open choices

| Topic | Options | Lean |
|-------|---------|------|
| `Either` vs `Result` | dartz vs sealed | Sealed `Result` if greenfield |
| Core SDUI `data` vs only DTOs beside parser | — | Keep parser/mapper under `core/sdui/data` |
| Preload OTP from `next` JSON | Skip GET vs always GET | Allow preload to save a round trip |
| Forgot password | Fourth feature later | Route stub only |
