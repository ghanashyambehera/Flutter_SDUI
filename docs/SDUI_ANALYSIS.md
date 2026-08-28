# Server-Driven UI (SDUI) — Analysis (No Implementation)

**Status:** Analysis only. Do not implement from this document until a follow-up explicitly asks for code.

**Audience:** Flutter client + backend that will own screen JSON.

**Goal:** Define a reusable JSON contract, a real-time delivery model, and the class/method shapes a Flutter SDUI engine should expose so login, signup, and OTP can be rendered without shipping a new app build for layout or copy changes.

**Related:** Detailed folder layout, Dio wiring, connectivity, and class APIs live in [`SDUI_DESIGN.md`](./SDUI_DESIGN.md). This file stays the product/contract analysis; the design file is the engineering blueprint.

**Client stack (decided):**

| Concern | Choice |
|---------|--------|
| Architecture | **Core** (global: Dio, interceptors, SDUI engine) + **feature** clean architecture: `login`, `signup`, `otp` each with data / domain / presentation |
| HTTP | **Dio** in `core/network`; interceptors on that client only — not inside feature `data` |
| Connectivity | Core `NetworkInfo`; check before every request; watch while a feature page is open; cache GET; never offline-submit auth |

---

## 1. What SDUI changes

In a classic Flutter app, screens are compiled widgets:

```
Backend → API data (strings, flags)
Client  → hardcoded Scaffold / Form / Buttons
```

SDUI inverts layout ownership:

```
Backend → Screen JSON (widgets + data + actions)
Client  → generic renderer that maps JSON → Flutter widgets
```

The client still owns:

- Widget catalog (what types exist and how they look)
- Navigation shell (route names, back stack)
- Native capabilities (secure storage, SMS autofill, biometrics)
- Safety (unknown types, schema version, timeouts)

The server owns:

- Which widgets appear, in which order
- Copy, colors (within theme tokens), visibility, validation rules
- Which API to call on submit and what happens next (navigate / show toast / replace screen)

**What SDUI is not:** a full Flutter DSL over the network. Keep the catalog small and opinionated. If a screen needs a one-off animation or a new native API, ship a client update and add a new `type` to the catalog.

---

## 2. Real-time working model

“Real-time” here means: the user sees the current server layout without waiting for an app store release, and the client can refresh or patch a screen while it is open.

### 2.1 Sources of truth

| Source | When to use | Latency | Notes |
|--------|-------------|---------|--------|
| **HTTP GET screen** | First paint, cold start, deep link | One round trip | Cache by `screenId` + `schemaVersion` |
| **HTTP POST actions** | Login / signup / verify OTP | Request/response | Server returns next screen JSON or a navigation command |
| **WebSocket / SSE** | Live copy, A/B, force-logout layout, OTP resend countdown from server | Push | Optional for v1; HTTP is enough for auth screens |
| **Local cache** | Offline / slow network | Instant | Stale-while-revalidate; never cache secrets |

Recommended v1 for login / signup / OTP:

1. App starts → fetch `GET /sdui/screens/{screenId}` (or a bundle of auth screens).
2. Renderer builds the tree from JSON.
3. User submits → `POST /sdui/actions/{actionId}` with form values.
4. Server responds with an **action result** (success + next screen, or field errors).
5. Client applies the result without a hardcoded “if login then go home” path, except for a small set of **allowed navigation targets**.

WebSocket can come later for: “this OTP screen is now disabled”, campaign banners, or session-killed overlays.

### 2.2 Sequence (login as example)

```
App
  → GET /sdui/screens/login?locale=en&appVersion=1.0.0
  ← { schemaVersion, screenId, root, theme? }

User types email/password
  → local validators from JSON (instant)

User taps PrimaryButton actionId=submit_login
  → POST /sdui/actions/submit_login
     { screenId, formId, values: { email, password }, client: {...} }
  ← {
       status: "ok" | "field_errors" | "navigate" | "replace_screen",
       fieldErrors?: { email: "..." },
       next?: ScreenDocument,          // inline next UI (OTP)
       navigation?: { type, route, params }
     }
```

OTP after signup follows the same loop: submit → server decides “show OTP” vs “show home”.

### 2.3 Cache and invalidation

- Cache key: `(screenId, locale, appVersion, schemaVersion)`.
- `ETag` / `If-None-Match` on GET (Dio interceptor or datasource sets headers).
- After a successful action, prefer **server-returned next screen** over refetch.
- If `schemaVersion` from server is **newer than the client catalog**, show a fallback screen (“Please update the app”) — never crash on unknown `type`.
- Offline: **GET screen** may serve last successful cache. **POST action** (login / signup / OTP) must **not** run offline — show a connectivity error; credentials must not sit in a retry queue on disk.

### 2.3.1 Connectivity (required for every network path)

“Connected” for SDUI means: the device has a usable path to the API, not merely Wi‑Fi/cellular attached.

| Check | When | Outcome |
|-------|------|---------|
| Pre-flight | Before `GET` screen and before `POST` action | If down: do not call Dio; map to domain `NoConnectivityFailure` |
| Transport | Dio error `connectionTimeout` / `connectionError` / `unknown` with no response | Same failure type; presentation shows retry |
| Live | Subscribe while `SduiPage` is visible | Banner: “You’re offline”; disable submit; optional cache render for GET |
| Recovery | Transition offline → online | Auto-refetch current `screenId` if the last load was cache-only or failed |

Rules:

- Auth **submit/resend** requires connectivity. No silent queue.
- Screen **load** may fall back to cache when offline, with an explicit “offline / cached” flag in presentation state.
- Connectivity is a **domain capability** (`CheckConnectivity`, `WatchConnectivity`). Dio and `connectivity_plus` live in **data**. Presentation never imports Dio or the plugin.

### 2.4 Safety in real time

- Unknown `type` → skip node or render a placeholder; log telemetry.
- Actions must be **allowlisted** (`submit_login`, `resend_otp`, `navigate_signup`). Arbitrary URLs from JSON should still go through a client policy (https only, host allowlist).
- Secrets (password, OTP) never written to disk cache; only in-memory form state.
- Max JSON size and max tree depth (e.g. 32) to avoid parser bombs.

---

## 3. JSON contract (reusable format)

Every screen is a **Screen Document**. Every visual node is a **Widget Node**. Behavior is **Action** + **Binding**.

### 3.1 Screen document

```json
{
  "schemaVersion": 1,
  "screenId": "login",
  "title": "Sign in",
  "safeArea": true,
  "theme": {
    "primaryColor": "brand.primary",
    "backgroundColor": "neutral.background"
  },
  "root": { "type": "column", "children": [] },
  "forms": {
    "login_form": {
      "fields": ["email", "password"]
    }
  }
}
```

### 3.2 Widget node (common fields)

Every node should support a stable subset so the renderer stays generic:

| Field | Purpose |
|-------|---------|
| `id` | Unique in the screen; used for focus, errors, analytics |
| `type` | Catalog key (`text`, `textField`, `button`, `column`, …) |
| `visibleWhen` | Optional condition on form/state |
| `padding` / `margin` | Spacing (numbers or token names) |
| `flex` | For row/column children |
| `props` | Type-specific properties |
| `children` | Nested nodes (layout types only) |
| `actions` | Event → action map (`onTap`, `onSubmit`, `onChanged`) |
| `bind` | Two-way bind to form key (`email`, `otp`) |

**Do not** put Flutter-specific class names in JSON (`TextField`, `ElevatedButton`). Use catalog names the server and client both understand.

### 3.3 Suggested widget catalog (auth-sized)

Keep v1 small; everything else is composition of these:

| `type` | Role | Typical props |
|--------|------|----------------|
| `scaffold` | Page chrome | `backgroundColor`, `appBar` |
| `appBar` | Title bar | `title`, `showBack` |
| `column` / `row` / `stack` | Layout | `gap`, `alignment`, `mainAxisAlignment` |
| `scroll` | Overflow | `physics` token |
| `spacer` | Flex gap | `flex` or `height` |
| `text` | Copy | `value`, `style` (`headline`, `body`, `caption`, `link`) |
| `image` | Logo | `url` or `assetKey`, `height` |
| `textField` | Input | `bind`, `keyboard`, `obscure`, `maxLength`, `placeholder` |
| `otpField` | Digit boxes | `bind`, `length`, `autofill` |
| `button` | CTA | `label`, `variant` (`primary`/`text`/`outline`), `fullWidth` |
| `textButton` | Secondary | `label` |
| `checkbox` | T&C | `bind`, `label` (rich text optional later) |
| `banner` | Error/info | `bind` or static `message`, `severity` |

### 3.4 Actions (server-driven behavior)

```json
{
  "type": "submit_form",
  "formId": "login_form",
  "actionId": "submit_login"
}
```

Action types the **client** should implement as methods (not as free-form scripts):

| `type` | Client behavior |
|--------|-----------------|
| `submit_form` | Collect bound fields → POST `actionId` |
| `navigate` | Push/replace a **named** route or `screenId` |
| `open_url` | External / in-app browser (allowlisted) |
| `validate_only` | Run local validators, no network |
| `resend_otp` | POST resend; start local cooldown from response |
| `set_state` | Patch local UI state (`resendEnabled: true`) |
| `pop` | Back |

Chaining: an action can include `then` for client-only follow-ups (e.g. start cooldown timer after resend succeeds). Network success/failure still comes from the action response.

### 3.5 Validation (local + server)

Local rules live on the field so the UI can show errors before a round trip:

```json
{
  "bind": "email",
  "validators": [
    { "type": "required", "message": "Email is required" },
    { "type": "email", "message": "Enter a valid email" }
  ]
}
```

Server `fieldErrors` map to the same `bind` keys and **override** local messages after submit.

### 3.6 Tokens vs raw values

Prefer tokens (`brand.primary`, `spacing.md`, `radius.lg`) so dark mode and brand stay in the client theme. Raw hex is an escape hatch, not the default.

### 3.7 Conditions

```json
{
  "visibleWhen": {
    "all": [
      { "field": "termsAccepted", "op": "eq", "value": true }
    ]
  }
}
```

Keep operators tiny: `eq`, `neq`, `empty`, `notEmpty`. No arbitrary expressions.

---

## 4. Sample screens

Full JSON lives next to this doc:

- [`../samples/sdui/login.json`](../samples/sdui/login.json)
- [`../samples/sdui/signup.json`](../samples/sdui/signup.json)
- [`../samples/sdui/otp.json`](../samples/sdui/otp.json)

Shared ideas across the three:

- Same `schemaVersion`.
- Same form `bind` keys the actions will POST.
- Navigation between them is `screenId`, not hardcoded Flutter routes in JSON (the client maps `screenId` → fetch-or-cache).
- OTP is a **generic** screen parameterized by `props.context` (`signup` vs `login`) so one renderer path serves both.

### 4.1 Login — intent

- Logo + title + email + password + primary submit + link to signup.
- Optional “forgot password” as `navigate` to another screen later.
- Submit action: `submit_login`. Success typically `replace_screen` home or OTP if 2FA.

### 4.2 Signup — intent

- Name, email, password, confirm password, terms checkbox.
- Confirm password validator: `matchField: password`.
- Submit: `submit_signup` → usually `replace_screen` OTP with `params: { destination, flow: "signup" }`.

### 4.3 OTP — intent

- Title/subtitle bound to `params.destination` (masked email/phone) from previous action.
- `otpField` length 6, numeric, SMS autofill hint on Android.
- Primary: `submit_otp`.
- Secondary: `resend_otp` disabled while `state.resendSecondsLeft > 0`.
- Server returns remaining cooldown in the action result; client only ticks the clock.

---

## 5. Reusable classes and methods (Clean Architecture)

This is a **map of responsibilities**, not code. Folder tree, interceptors-in-core, and per-feature APIs: [`SDUI_DESIGN.md`](./SDUI_DESIGN.md).

Layout JSON is still server-driven. **Features** are still `LoginPage` / `SignupPage` / `OtpPage`, but each page hosts the **core** renderer — no hardcoded email/password widgets in the feature.

### 5.1 Layering (core + features)

```
lib/core          global: Dio, interceptors, Failure, connectivity, SDUI engine
lib/features/login | signup | otp
                  each: presentation → domain ← data
```

- **Core** is imported by all features. Core never imports features.
- Feature **domain** has no Flutter/Dio. Feature **data** uses the **shared** Dio (interceptors already attached). Feature **presentation** uses core `SduiHost` + that feature’s Cubit.
- Interceptors are **not** feature data. They configure the app HTTP client. See design §2.

| Location | Owns | Must not own |
|----------|------|----------------|
| `core/network` | Dio, interceptors, `DioErrorMapper` | Login/signup/otp use cases |
| `core/sdui` | Entities, parser, mapper, catalog, `SduiHost` | Feature routes / submit_login |
| Feature domain | `GetLoginScreen`, `SubmitLogin`, `LoginRepository`, … | Dio, interceptors, Widgets |
| Feature data | Remote datasource for **that** screen/action path, repo impl | Interceptor classes |
| Feature presentation | `LoginPage` / Cubit / navigate to signup or otp | Dio, JSON parser |

### 5.2 Models (immutable)

| Class | Responsibility |
|-------|----------------|
| `SduiScreenDocument` | `schemaVersion`, `screenId`, `root`, `forms`, optional `theme` |
| `SduiNode` | `id`, `type`, `props`, `children`, `actions`, `bind`, `validators`, `visibleWhen` |
| `SduiAction` | `type`, `actionId`, `formId`, `payload` |
| `SduiValidator` | `type`, `message`, extra args (`minLength`, `matchField`) |
| `SduiActionResult` | `status`, `fieldErrors`, `nextScreen`, `navigation`, `statePatch` |
| `SduiThemeTokens` | Resolve token string → `Color` / `TextStyle` / `EdgeInsets` |

**Data mapping:** `SduiScreenDto.fromJson` / `SduiNodeDto.fromJson` in data; map to domain `SduiScreen` / `SduiNode`. Fail soft: unknown keys ignored; unknown `type` kept so telemetry can report it. Presentation never parses the HTTP body.

### 5.3 Parsing

| Method | Responsibility |
|--------|----------------|
| `SduiScreenParser.parse(Map json)` | Validate `schemaVersion` in supported range; return document or `SduiParseFailure` |
| `SduiSchemaGuard.assertSupported(int version)` | Client min/max schema |
| `SduiNode.walk(visitor)` | Analytics, max-depth check, collect all `bind` keys |

### 5.4 Runtime state (one controller per screen instance)

| Class | Responsibility |
|-------|----------------|
| `SduiController` | Holds `Map<String, dynamic> values`, `Map<String, String> errors`, `bool submitting`, `Map extraState` (cooldown) |

Suggested methods on `SduiController`:

| Method | Why it is reusable |
|--------|---------------------|
| `setValue(String bind, dynamic value)` | All fields |
| `value(String bind)` | Read for submit + conditions |
| `setFieldError` / `clearErrors` | Local + server errors |
| `valuesForForm(String formId)` | Subset for POST |
| `patchState(Map)` | Resend timer, banners |
| `dispose()` | Cancel timers |

Do **not** put Dio or HTTP inside the Cubit/controller. Inject **use cases**. The repository implementation is the only type that talks to Dio.

### 5.5 Validation

| Class | Methods |
|-------|---------|
| `SduiValidatorRunner` | `String? validateField(bind, value, List<SduiValidator>, SduiController)` |
| | `Map<String, String> validateForm(formId, document, controller)` |

Validator **types** as small functions or a map:

- `required`, `email`, `minLength`, `maxLength`, `regex`, `matchField`, `otpLength`

Adding a new rule is one registry entry, not a new screen class.

### 5.6 Conditions

| Class | Method |
|-------|--------|
| `SduiConditionEvaluator` | `bool eval(condition, SduiController)` |

Used by renderer: if `visibleWhen` is false, skip building that node (and do not include hidden fields in submit unless marked `submitWhenHidden`).

### 5.7 Renderer and factory (the reuse core)

| Class | Methods |
|-------|---------|
| `SduiRenderer` | `Widget build(SduiScreenDocument, SduiController)` → builds `root` |
| `SduiWidgetFactory` | `Widget? build(SduiNode, SduiBuildContext)` |
| `SduiBuildContext` | document, controller, dispatcher, token resolver, `onChanged` |

`SduiWidgetFactory` holds a `Map<String, SduiWidgetBuilder>`. Each builder:

```
abstract class SduiWidgetBuilder {
  Widget build(SduiNode node, SduiBuildContext ctx);
}
```

Concrete builders (one each): `ColumnBuilder`, `RowBuilder`, `TextBuilder`, `TextFieldBuilder`, `OtpFieldBuilder`, `ButtonBuilder`, `ImageBuilder`, `CheckboxBuilder`, `ScrollBuilder`, `AppBarBuilder`, `BannerBuilder`, `SpacerBuilder`.

**Reuse rule:** a new screen JSON that only uses existing `type`s needs **zero** new Dart classes. A new `type` needs **one** builder + catalog registration + schema docs.

Recursive children: layout builders call `factory.build(child, ctx)` — same path as the root.

### 5.8 Actions

| Class | Methods |
|-------|---------|
| `SduiActionDispatcher` | `Future<void> dispatch(SduiAction, SduiController)` |

Internal handlers (private methods or strategy map):

| Handler | Maps to action `type` |
|---------|------------------------|
| `_submitForm` | `submit_form` |
| `_navigate` | `navigate` |
| `_pop` | `pop` |
| `_resendOtp` | `resend_otp` |
| `_setState` | `set_state` |
| `_openUrl` | `open_url` |

`_submitForm` algorithm (all screens):

1. Run `SduiValidatorRunner.validateForm`.
2. If errors, `controller.setFieldError` and return.
3. `controller.submitting = true`.
4. Presentation calls **that feature’s** submit use case (`SubmitLogin` / `SubmitSignup` / `SubmitOtp`). Use case: `CheckConnectivity` (core) → feature repository.
5. Feature data: Dio `POST` (core interceptors already on the client); map errors via `DioErrorMapper`.
6. Feature action handler: field errors stay; success **navigates to another feature route** (login → otp), not a second screen inside the same Cubit.
7. `submitting = false`. On `NoConnectivityFailure`, keep form values; show retry.

### 5.9 Navigation

| Class | Methods |
|-------|---------|
| `SduiNavigator` | `openScreenId(String id, {replace, params})`, `openNamedRoute` (allowlist), `pop` |

`openScreenId` either uses inlined `next` JSON from the action result or `repository.fetchScreen(id)`. Params (masked email) merge into controller state for bindings like `{{destination}}`.

String interpolation: a tiny `SduiStringResolver.resolve(template, controller)` for `"Enter the code sent to {{destination}}"`.

### 5.10 Network (Dio) and connectivity

| Location | Type | Role |
|----------|------|------|
| Core domain | `ConnectivityRepository` | `isOnline()`, `onChange()` |
| Core domain | `CheckConnectivity`, `WatchConnectivity` | Shared use cases |
| Core network | `Dio` + interceptors | Global client; connectivity/headers/ETag/logging |
| Core | `DioErrorMapper`, `SduiScreenCache` | Shared errors and GET cache |
| Feature domain | `GetLoginScreen` / `SubmitLogin` (and signup/otp equivalents) | Policy: cache GET if offline; never POST offline |
| Feature data | `LoginRemoteDataSource` using **injected** Dio | `GET .../login`, `POST .../submit_login` only |

Dio is constructed **once** in core. Features never add interceptors. Presentation never calls `dio.get`.

Dio is the **only** HTTP client for SDUI. Use interceptors for: logging (no secrets), auth token later, `If-None-Match`, correlation id. Timeouts: connect and receive must be set so a hung network becomes `TimeoutFailure`, not a frozen button.

HTTP DTOs and `fromJson` live in **data**. Domain entities are mapped from DTOs. Presentation never calls `dio.get`.

### 5.11 What not to abstract

- Do not generate Dart from JSON at runtime.
- Do not expose a JS engine for actions.
- Do not let JSON set arbitrary `BoxDecoration` trees; tokens + a few variants are enough.
- Do not create `LoginSduiController` subclasses; use `extraState` and `screenId`.

---

## 6. Backend responsibilities (for the same contract)

| Endpoint (illustrative) | Role |
|-------------------------|------|
| `GET /sdui/screens/:id` | Return screen document; vary by locale, app version, experiment |
| `POST /sdui/actions/:actionId` | Validate credentials / create user / verify OTP; return result |
| (optional) `GET /sdui/bundle/auth` | Login + signup + OTP in one payload for faster first auth |

Action handlers return **UI decisions**:

- Invalid password → `field_errors` on `password` (or a `banner` via `statePatch`).
- Signup OK → `replace_screen` with OTP document + `params.destination`.
- OTP OK → `navigation: { type: "replace_all", route: "home" }` (route must be allowlisted).

The backend can A/B test button copy or extra fields by serving different JSON for the same `screenId`.

---

## 7. Client vs server ownership (decision table)

| Concern | Owner | Reason |
|---------|--------|--------|
| Pixel-perfect Material/Cupertino look | Client catalog | Consistency, a11y, platform |
| Field order, labels, extra marketing text | Server JSON | No store release |
| Password hashing / OTP generation | Server | Security |
| Keyboard type, obscure text, autofill hints | JSON props + client mapping | UX + platform APIs |
| “Go to home after login” | Server action result + client allowlist | Server chooses; client enforces |
| New widget (e.g. social login row) | Client release + new `type` | Native SDKs |

---

## 8. Testing strategy (when implementation starts)

Not implementing now; when it does:

- **Parser tests:** login/signup/otp fixtures round-trip; unknown `type` does not throw.
- **Validator tests:** email, matchField, otp length — no widget tests required.
- **Dispatcher tests:** mock `PerformSduiAction` / repository; assert POST body keys match `bind`s.
- **Data tests:** mock Dio `Adapter` (`http_mock_adapter` or `DioMixin` adapter); assert paths, ETag, error mapping.
- **Connectivity tests:** fake `ConnectivityRepository` — offline GET uses cache; offline POST returns `NoConnectivityFailure`.
- **Golden/widget tests:** one per catalog `type`, not per screen.
- **Contract tests:** shared JSON Schema (optional file) validated in CI for both backend and `samples/`.

---

## 9. Suggested delivery order (later)

1. Core: schema samples, Dio, interceptors, connectivity, parser, catalog.
2. Login feature (domain → data → page) against mock Dio.
3. Signup feature.
4. OTP feature (otpField, resend).
5. Routes between the three pages.
6. Cache, ETag, schema mismatch fallback.

---

## 10. Open questions (product / engineering)

- Phone vs email as login identifier — one field `identifier` vs two screens.
- OTP channel (SMS vs email) — `otpField` autofill only helps SMS.
- Social login — new catalog types (`googleButton`) vs `open_url` OAuth.
- Whether signup and login share one `auth` bundle fetch.
- Minimum supported app version vs `schemaVersion` matrix.

---

## 11. File map (this analysis drop)

```
docs/SDUI_ANALYSIS.md
docs/SDUI_DESIGN.md            ← core vs features, interceptors, per-feature CA
samples/sdui/login.json | signup.json | otp.json
```

No Dart, no pubspec, no widgets. Implementation is explicitly out of scope until requested.
