---
name: flutter-widget-tests
description: Use when writing or modifying Flutter widget tests under frontend/test/ in this project - covers BDD naming, pump helpers, fake-over-mock, interaction-over-static-render, router testing, i18n handling, and when to prefer a widget test over a controller/notifier test.
---

# Flutter Widget Tests (this project)

How this project writes widget tests. Follow these when adding or changing tests under `frontend/test/`.

## Core principle

**Test behavior through the UI, not controller internals.** A widget test that taps "delete" and asserts the repo no longer contains the item is worth more than a controller test asserting the same state transition — and it covers the same lines of controller code for free.

## BDD naming

Every test name reads `given X, when Y, then Z`. Helpers mirror the structure:

```dart
testWidgets(
  'given a trip with entries, when the detail screen loads, '
  'then the trip name and each timeline entry are rendered',
  (tester) async {
    await _givenTripDetailScreen(tester, ...);
    _thenTripNameIsVisible('Kyoto');
    _thenAtLeastOneTimelineEntryIsShown();
  },
);
```

Private helpers: `_givenXScreen()`, `_whenUserTapsY()`, `_thenZIsVisible()`.

## Merge tests sharing same Given/When

If two sibling tests have identical Given and When and only differ in Then, merge them into one test with multiple assertions. Three static-render tests that all skip interaction and check different parts of the initial view should be one test.

## Use project helpers, not raw pumpWidget

- `pumpScreen(tester, child: ..., overrides: [...])` — simple screen, no routing
- `pumpRouterApp(tester, routes: [...], overrides: [...])` — whenever the screen calls `context.push` / `pushNamed` / `context.pop`

Both live in `test/helpers/pump_app.dart` and already bootstrap EasyLocalization, SharedPreferences mocks, and ProviderScope.

## Fakes, not mocks

Never use `mocktail` for repositories or services. Use the existing fakes under `test/fakes/`:

- In-memory repos: `InMemoryJourneyRepository`, `InMemoryTripRepository`, `InMemoryUsageRepository`, `InMemoryQuickGuideRepository`, `InMemorySavedLocationsRepository`, ...
- Fake services: `FakeImagePickerService`, `FakeNarrationService`, `FakeQuickGuideAiService`, `FakeImageAnalysisService`, `FakeLocationService`, `FakePlacesRepository`, `FakeRewardedAdService`

If you need to assert "was this called?" — extend the fake with a counter or captured-args field (see `FakePlacesRepository.nearbyCallCount`, `FakeImagePickerService.pickCount`). Don't reach for a mock.

## Cover interactions, not just static render

Interaction paths that screen tests commonly miss:
- Dialogs and bottom sheets (default hidden, need user action to open)
- FloatingActionButton callbacks (rendered but `onPressed` never fires)
- Multi-select / edit mode entry + batch actions
- Error / retry / empty / loading states
- Off-screen-render widgets used by services (capture/export flows)

Checklist for a screen test: `tap`, `onPressed`, `onTap`, `showDialog`, `showModalBottomSheet`, error state, empty state. If none appear in the file, interaction coverage is missing.

## Prefer widget test over controller/notifier test

Controller tests usually cover the same lines widget tests already hit via the UI. Delete the controller test unless it covers one of these non-UI contracts:

- SharedPreferences or other persistence
- Error-type mapping branches with no visible difference
- State machine transitions the UI can't observe

For everything else, cover the behavior with a widget test that asserts the **UI outcome** (or the underlying repo's state after the interaction).

## Router tests

Replace destination routes with stub `Scaffold`s that capture `state.extra` — assert on what was pushed rather than navigating through real screens:

```dart
final extras = <Object?>[];
await pumpRouterApp(tester, routes: [
  GoRoute(path: '/', builder: (_, __) => const MyScreen()),
  GoRoute(name: 'player', path: '/player', builder: (_, state) {
    extras.add(state.extra);
    return const Scaffold(key: Key('player-screen'));
  }),
], overrides: [...]);
// ... trigger action ...
expect(extras.single, isA<Map<String, dynamic>>());
```

If the test exercises `context.pop()`, start at `/` and push to the screen under test — popping from the `initialLocation` leaves an empty stack.

## i18n inside tests

`pumpScreen` wires `_EmptyAssetLoader`, so `tr()` returns the raw key — assert on `'passport.title'`, `'camera.take_photo'`, etc. If the raw key causes a `RenderFlex overflowed` error in a fixed-width widget, write a local `_MapAssetLoader` that returns short Chinese/English strings (see `journey_sharing_card_test.dart`).

## Image.memory needs valid bytes

Invalid bytes trigger a codec exception that marks the test failed even if assertions pass. Copy the 1x1 transparent PNG helper from `journey_sharing_card_test.dart` / `select_narration_aspect_screen_test.dart` when seeding `imageBytes`.

## Common gotchas

- **Chips in `SingleChildScrollView`**: call `tester.ensureVisible(chipFinder)` before `tap` — they may be clipped off-screen on the default 800×600 test surface.
- **`pump` vs `pumpAndSettle`**: use `pumpAndSettle()` after interactions that chain async work (provider invalidation, navigation, dialog animations). Use `pump(Duration)` to step through controlled animations.
- **Static test state**: if a test uses static capture fields (`_Host.lastSelection`), reset them in `setUp()` — not just at the end of the test body.
- **Search-field clear suffix**: on fields where the suffix appears conditionally on `controller.text.isNotEmpty`, the widget only rebuilds on `onChanged` / submit. You may need to submit once before the clear icon exists.
- **Current-trip / prefs tests**: `SharedPreferences.setMockInitialValues({...})` BEFORE `pumpScreen` to seed persisted state, then don't override the notifier — test the real hydration path.

## When in doubt

Look at an existing test in the same feature. The patterns above were extracted from the actual test corpus; consistency with neighbors is usually the right call.
