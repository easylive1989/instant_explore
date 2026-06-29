# Firebase App Check — Phase 1 (Firebase AI)

**Date:** 2026-06-29
**Status:** Approved design, ready for implementation plan
**Scope:** Frontend (Flutter) only. Phase 1 protects direct Firebase AI (Gemini)
calls. FastAPI backend verification and Analytics enforcement are explicitly
out of scope.

## Goal

Ensure that only the genuine, untampered Lorescape app can successfully call
Firebase AI (Gemini), blocking scripts/scrapers that abuse leaked credentials.

App Check attests that an incoming request originates from your authentic app
binary on a genuine device. Once `firebase_app_check` is initialized, the
`firebase_ai` SDK automatically attaches an App Check token to every Gemini
request — no changes are needed in the call sites
(`features/camera/data/image_analysis_service.dart`,
narration grounding).

## Architecture

```
App launch (main.dart)
  └─ Firebase.initializeApp(...)
       └─ _initializeAppCheck()        ← new, non-fatal
            └─ FirebaseAppCheck.instance.activate(provider per platform/build)
                 └─ firebase_ai auto-attaches App Check token to Gemini calls
```

### Attestation providers (standard per-platform defaults)

| Context              | Android         | iOS         |
|----------------------|-----------------|-------------|
| Release build        | Play Integrity  | App Attest  |
| Debug / local dev    | Debug provider  | Debug       |

Provider is selected at runtime via `kDebugMode` so debug builds on
simulators/local devices are not blocked, while release builds use the real
attestation providers.

## Code changes

### Dependency
- Add `firebase_app_check` (official Firebase family package, aligns with the
  existing `firebase_core` / `firebase_ai` / `firebase_analytics` deps).

### `main.dart`
Add `_initializeAppCheck()` invoked **after** `Firebase.initializeApp(...)` and
**before** other service initialization. Extracted into a small private function
(short, single-purpose, per project conventions).

```dart
Future<void> _initializeAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttest,
    );
  } catch (e) {
    // Non-fatal: App Check failing to activate must not block app launch.
    // Mirrors the existing non-fatal style of _ensureSignedIn().
    _log.warning('Firebase App Check activation failed: $e');
  }
}
```

- Error handling: wrapped in try/catch, logged via the `logging` package.
  App Check activation failure must **not** prevent the app from launching.

## Firebase Console configuration (operator steps, done via browser)

1. **Register providers** on the App Check page: Android → Play Integrity,
   iOS → App Attest.
2. **Register debug token**: on first debug-build launch, App Check prints a
   debug token to the console log; paste it into Console → App Check →
   "Manage debug tokens" so local development passes attestation.
3. **Enforcement (rollout decision)**: keep Firebase AI **Unenforced
   (Monitoring)** initially. Observe App Check metrics to confirm real-device
   token verification rates before manually enabling enforcement. Turning on
   enforcement immediately risks locking out legitimate users.

## Verification

- `fvm flutter analyze --fatal-infos` passes with no issues.
- Debug build runs; console prints the App Check debug token; camera image
  analysis and narration grounding continue to work normally.
- Firebase Console App Check metrics show verified requests increasing.

## Out of scope (this phase)

- FastAPI backend App Check token verification (firebase-admin server-side).
- Firebase Analytics enforcement.
- Flipping enforcement to "Enforced" — deferred until monitoring data confirms
  it is safe; the operator decides timing.
