# Firebase App Check — Phase 1 (Firebase AI) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Initialize Firebase App Check at app launch so only the genuine,
untampered Lorescape app can call Firebase AI (Gemini).

**Architecture:** Add the `firebase_app_check` package and activate it in
`main.dart` immediately after `Firebase.initializeApp(...)`. Once activated, the
`firebase_ai` SDK automatically attaches an App Check token to every Gemini
request, so no call-site code changes. Provider is chosen at runtime by build
mode: debug provider for local dev, Play Integrity (Android) / App Attest (iOS)
for release.

**Tech Stack:** Flutter, Dart, `firebase_core`, `firebase_app_check`,
`firebase_ai`, `logging`. Commands run via `fvm`.

## Global Constraints

- Run `fvm` in front of every `flutter` / `dart` command.
- Lines 80 characters or fewer; functions short and single-purpose.
- Use the `logging` package, never `print`. A `final _log = Logger('bootstrap')`
  already exists in `frontend/lib/main.dart`.
- App Check activation MUST be non-fatal: a failure must not block app launch
  (mirror the existing `_ensureSignedIn` / `_identifyRevenueCat` try/catch style).
- `kDebugMode` is available via the existing `package:flutter/material.dart`
  import (it re-exports `foundation.dart`).
- After every code change run `fvm flutter analyze --fatal-infos`; it must report
  no issues before a task is considered complete.
- Out of scope: FastAPI backend verification, Analytics enforcement, flipping
  Firebase AI enforcement to "Enforced".

---

### Task 1: Add the `firebase_app_check` dependency

**Files:**
- Modify: `frontend/pubspec.yaml` (dependencies block)
- Modify: `frontend/pubspec.lock` (generated)

**Interfaces:**
- Consumes: nothing.
- Produces: the `package:firebase_app_check/firebase_app_check.dart` library,
  exposing `FirebaseAppCheck.instance.activate(...)`, `AndroidProvider`,
  `AppleProvider`. Task 2 relies on these symbols.

- [ ] **Step 1: Add the package**

`pub add` resolves a version compatible with the existing `firebase_core ^4.x`.

Run (from the `frontend/` directory):
```bash
cd frontend && fvm flutter pub add firebase_app_check
```
Expected: a `firebase_app_check:` line is added under `dependencies:` in
`pubspec.yaml` and resolution succeeds ("Changed N dependencies!").

- [ ] **Step 2: Verify the dependency resolves and analyze is clean**

Run:
```bash
cd frontend && fvm flutter pub get && fvm flutter analyze --fatal-infos
```
Expected: `pub get` succeeds; analyze reports "No issues found!".

- [ ] **Step 3: Commit**

```bash
git add frontend/pubspec.yaml frontend/pubspec.lock
git commit -m "build(security): add firebase_app_check dependency

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Activate App Check in `main.dart`

**Files:**
- Modify: `frontend/lib/main.dart` (add import; add `_initializeAppCheck`;
  call it right after `Firebase.initializeApp(...)`)

**Interfaces:**
- Consumes: `FirebaseAppCheck`, `AndroidProvider`, `AppleProvider` from Task 1;
  the existing `_log` (`Logger('bootstrap')`); `kDebugMode`.
- Produces: a private `Future<void> _initializeAppCheck()` bootstrap step. No
  later task depends on its return value.

> **Note on testing:** This is platform-channel bootstrap glue on the
> `FirebaseAppCheck.instance` singleton; it has no pure logic to unit-test.
> Verification is a clean analyze plus a manual debug run (Step 4), matching the
> spec's verification section. Do not fabricate a unit test that asserts nothing.

- [ ] **Step 1: Add the import**

In `frontend/lib/main.dart`, add alongside the other `firebase_*` imports
(after the `firebase_core` import on line 7):

```dart
import 'package:firebase_app_check/firebase_app_check.dart';
```

- [ ] **Step 2: Add the `_initializeAppCheck` function**

Add this private function near the other bootstrap helpers
(e.g. next to `_ensureSignedIn`):

```dart
/// Activates Firebase App Check so only the genuine app binary can call
/// Firebase AI. Debug builds use the debug provider so local development and
/// simulators are not blocked. Activation failure is non-fatal: the app still
/// launches and unverified requests are simply rejected once enforcement is on.
Future<void> _initializeAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
  } catch (e, stack) {
    _log.warning('Firebase App Check activation failed at startup', e, stack);
  }
}
```

- [ ] **Step 3: Call it right after Firebase init**

In `init()`, immediately after the existing
`await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`
line, add:

```dart
  // Activate App Check before any Firebase AI call so Gemini requests carry
  // a valid attestation token. Non-fatal on failure.
  await _initializeAppCheck();
```

- [ ] **Step 4: Verify analyze is clean and the debug build works**

Run:
```bash
cd frontend && fvm flutter analyze --fatal-infos
```
Expected: "No issues found!".

Then run the app in debug on a device/emulator:
```bash
cd frontend && fvm flutter run --debug
```
Expected: app launches normally; the console log prints a Firebase App Check
**debug token** line (e.g. `App Check debug token: <UUID>` / `Enter this debug
secret into the allow list...`). Copy that token — Task 3 registers it. Confirm
camera image analysis and narration grounding still work (they will, because the
console default is Unenforced until Task 3's rollout step).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/main.dart
git commit -m "feat(security): activate Firebase App Check at app launch

Initializes firebase_app_check after Firebase init so firebase_ai
attaches an App Check token to every Gemini call. Debug builds use the
debug provider; release uses Play Integrity (Android) / App Attest (iOS).
Activation is non-fatal.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Firebase Console configuration (operator, via browser)

**Files:** none (Firebase Console actions).

**Interfaces:**
- Consumes: the debug token printed in Task 2, Step 4.
- Produces: registered App Check providers + an allow-listed debug token, with
  Firebase AI kept Unenforced (Monitoring).

> Performed in the Firebase Console using the Chrome browser automation tools
> (the user has authorized opening the web console). These are config actions,
> not code, so there is no test/commit cycle — verification is the App Check
> metrics dashboard.

- [ ] **Step 1: Register providers**

In Firebase Console → **App Check** → Apps: register the Android app with
**Play Integrity** and the iOS app with **App Attest**.

- [ ] **Step 2: Register the debug token**

In App Check → **Manage debug tokens**, add the debug token copied from Task 2,
Step 4. Give it a descriptive name (e.g. "<dev> local debug").

- [ ] **Step 3: Keep Firebase AI Unenforced (monitoring)**

Leave the Firebase AI (and any other) App Check enforcement set to
**Unenforced / Monitoring**. Do NOT enable enforcement in this phase.

- [ ] **Step 4: Verify metrics**

Exercise camera image analysis / narration grounding from a debug build, then in
App Check → **Metrics** confirm verified requests appear for the Firebase AI
(Gemini) API. This confirms tokens are being minted and accepted.

- [ ] **Step 5: Hand off the enforcement decision**

Report metrics back to the user. Enabling enforcement is deferred until the user
confirms real-device verification rates look healthy.
