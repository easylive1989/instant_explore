# Daily Story Share Loop — Phase 1 (App Share Card) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a share button to the daily-story detail screen that renders the story as a designed PNG card (warm paper aesthetic, Lorescape wordmark watermark, story URL) and opens the system share sheet.

**Architecture:** Mirror the existing `JourneySharingService` pattern (render an off-screen widget via `RepaintBoundary` → capture to PNG → `Share.shareXFiles`). A new `DailyStorySharingCard` widget provides the visual; a new `DailyStorySharingService` captures and shares it; the detail screen's AppBar gains a share action. The share text carries a `lorescape.app/<lang>/story/<date>` URL with UTM params (the Phase 2 web page and Phase 3 deep link resolve that URL later; in Phase 1 it is just a link).

**Tech Stack:** Flutter, `share_plus`, `path_provider`, `easy_localization`, `google_fonts`, `flutter_test`. Dev tooling via `fvm`.

## Global Constraints

- Run `fvm flutter analyze --fatal-infos` after every code change; resolve all issues before a task is complete.
- Lines ≤ 80 chars; `PascalCase` classes, `camelCase` members, `snake_case` files.
- Use the `logging` package, never `print`.
- Feature-first + Clean Architecture: widget in `presentation/widgets/`, service in `domain/services/`, pure helpers unit-tested.
- Share card colours are hardcoded from `CardReaderTheme` values (copied as literals) so the captured PNG looks identical across platforms/themes — do NOT read theme at capture time.
- Brand identifier (both platforms): `com.paulchwu.instantexplore`.
- Share URL shape (verbatim): `https://lorescape.app/<lang>/story/<date>?utm_source=story_share&utm_medium=app`, where `<lang>` is `zh` for language `zh-TW` and `en` for `en`, and `<date>` is `publishDate` formatted `yyyy-MM-dd`.
- Tests follow the project BDD convention: `group('<Unit>')` + `testWidgets('given… when… then…')`, `EasyLocalization` + `ProviderScope` + `MaterialApp` harness, a `_ShortTranslationsLoader` for fixed-width cards (see `test/features/journey/presentation/widgets/journey_sharing_card_test.dart`).

---

### Task 1: Share URL builder (pure function)

**Files:**
- Create: `frontend/lib/features/daily_story/domain/services/daily_story_share_url.dart`
- Test: `frontend/test/features/daily_story/domain/services/daily_story_share_url_test.dart`

**Interfaces:**
- Produces: `String buildDailyStoryShareUrl(DailyStory story)` — returns the canonical share URL for a story.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/services/daily_story_share_url.dart';
import 'package:flutter_test/flutter_test.dart';

DailyStory _story({required String language, required DateTime publishDate}) {
  return DailyStory(
    publishDate: publishDate,
    language: language,
    placeName: 'Colosseum',
    placeLocation: 'Rome, Italy',
    era: '70-80 CE',
    story: 'body',
    imageUrl: null,
    wikipediaUrl: 'https://en.wikipedia.org/wiki/Colosseum',
  );
}

void main() {
  group('buildDailyStoryShareUrl', () {
    test('given zh-TW story, when built, then uses zh locale segment and '
        'yyyy-MM-dd date with UTM params', () {
      final url = buildDailyStoryShareUrl(
        _story(language: 'zh-TW', publishDate: DateTime(2026, 7, 1)),
      );
      expect(
        url,
        'https://lorescape.app/zh/story/2026-07-01'
        '?utm_source=story_share&utm_medium=app',
      );
    });

    test('given en story with single-digit month/day, when built, then '
        'date is zero-padded and locale segment is en', () {
      final url = buildDailyStoryShareUrl(
        _story(language: 'en', publishDate: DateTime(2026, 3, 5)),
      );
      expect(
        url,
        'https://lorescape.app/en/story/2026-03-05'
        '?utm_source=story_share&utm_medium=app',
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/domain/services/daily_story_share_url_test.dart`
Expected: FAIL — `buildDailyStoryShareUrl` is undefined.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';

/// Builds the canonical shareable URL for a [DailyStory].
///
/// Shape: `https://lorescape.app/<lang>/story/<date>?utm_source=...`.
/// `<lang>` collapses the app language tag to its locale segment
/// (`zh-TW` → `zh`, `en` → `en`); `<date>` is `publishDate` as
/// `yyyy-MM-dd`. Phase 2 (web page) and Phase 3 (deep link) resolve
/// this URL; in Phase 1 it is a plain link carried in the share text.
String buildDailyStoryShareUrl(DailyStory story) {
  final lang = story.language.toLowerCase().startsWith('zh') ? 'zh' : 'en';
  final d = story.publishDate;
  final date = '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return 'https://lorescape.app/$lang/story/$date'
      '?utm_source=story_share&utm_medium=app';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && fvm flutter test test/features/daily_story/domain/services/daily_story_share_url_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Analyze**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/daily_story/domain/services/daily_story_share_url.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/daily_story/domain/services/daily_story_share_url.dart \
        frontend/test/features/daily_story/domain/services/daily_story_share_url_test.dart
git commit -m "feat(daily-story): share URL builder for story share loop"
```

---

### Task 2: Story share i18n keys

**Files:**
- Modify: `frontend/assets/translations/en.json` (extend the existing `share_card` block, ~line 329)
- Modify: `frontend/assets/translations/zh-TW.json` (extend the existing `share_card` block, ~line 329)
- Test: `frontend/test/features/daily_story/i18n/story_share_keys_test.dart`

**Interfaces:**
- Produces: translation keys `share_card.story_share_text` (both locales) used by Task 4's service.

The existing `share_card` block is:
`{ "share": ..., "visited": ..., "explore_more": ..., "share_text": ... }`.
Add one key `story_share_text` (the daily-story share caption). Keep `share_text` (journey) untouched.

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('story share i18n keys', () {
    for (final locale in const ['en', 'zh-TW']) {
      test('given $locale translations, then share_card.story_share_text '
          'is a non-empty string', () {
        final json = jsonDecode(
          File('assets/translations/$locale.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final shareCard = json['share_card'] as Map<String, dynamic>;
        final value = shareCard['story_share_text'];
        expect(value, isA<String>());
        expect((value as String).trim(), isNotEmpty);
      });
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/i18n/story_share_keys_test.dart`
Expected: FAIL — `story_share_text` is null (not a String).

- [ ] **Step 3: Add the key to `en.json`**

In the `"share_card"` block, add after `"share_text"` line:

```json
    "share_text": "I explored this place with Lorescape",
    "story_share_text": "A true story from Lorescape — hear it for yourself"
```

- [ ] **Step 4: Add the key to `zh-TW.json`**

In the `"share_card"` block, add after `"share_text"` line:

```json
    "share_text": "我用 Lorescape 探索了這個地方",
    "story_share_text": "來自 Lorescape 的一段真實故事，你也聽聽看"
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd frontend && fvm flutter test test/features/daily_story/i18n/story_share_keys_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add frontend/assets/translations/en.json frontend/assets/translations/zh-TW.json \
        frontend/test/features/daily_story/i18n/story_share_keys_test.dart
git commit -m "feat(daily-story): add story_share_text i18n keys"
```

---

### Task 3: `DailyStorySharingCard` widget

**Files:**
- Create: `frontend/lib/features/daily_story/presentation/widgets/daily_story_sharing_card.dart`
- Test: `frontend/test/features/daily_story/presentation/widgets/daily_story_sharing_card_test.dart`

**Interfaces:**
- Produces: `DailyStorySharingCard` — a fixed-width (`380`) `StatelessWidget` with constructor params `{required String placeName, required String placeLocation, required String era, required String title, required String hook, String? imageUrl, Uint8List? imageBytes}`. Renders header image (or a clay placeholder), title, hook, a meta row (place · era), and a footer with the `LORESCAPE` wordmark. Colours are `CardReaderTheme` literals.

**Design:** warm paper card. Header photo on top (16:9), paper body (`readBg` `0xFFF7F1E6`) below with `title` (serif, `readInk`), `hook` (max 3 lines, `readDim`), a hairline (`readLine`), a `place · era` caption (`readCap`), and a footer strip showing `LORESCAPE` wordmark (letter-spaced, `readCap`). Watermark = the wordmark, so no new asset is needed.

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:typed_data';

import 'package:context_app/features/daily_story/presentation/widgets/daily_story_sharing_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyStorySharingCard', () {
    testWidgets(
      'given a story with no image, when rendered, then title, hook, '
      'place-era caption and the LORESCAPE wordmark are visible',
      (tester) async {
        await _pumpCard(
          tester,
          title: 'A century of ruin and rebirth',
          hook: 'Pope Julius II tore down a thousand-year-old basilica.',
          placeName: "St. Peter's Basilica",
          placeLocation: 'Vatican',
          era: '1506-1626',
        );

        expect(find.text('A century of ruin and rebirth'), findsOneWidget);
        expect(
          find.text('Pope Julius II tore down a thousand-year-old basilica.'),
          findsOneWidget,
        );
        expect(find.textContaining("St. Peter's Basilica"), findsOneWidget);
        expect(find.text('LORESCAPE'), findsOneWidget);
      },
    );

    testWidgets(
      'given a long hook, when rendered, then the hook is capped at '
      'three lines with ellipsis',
      (tester) async {
        final longHook = List.filled(30, 'lorem ipsum').join(' ');
        await _pumpCard(
          tester,
          title: 'Long hook',
          hook: longHook,
          placeName: 'Anywhere',
          placeLocation: 'Nowhere',
          era: '2026',
        );

        final hook = tester.widget<Text>(find.text(longHook));
        expect(hook.maxLines, 3);
        expect(hook.overflow, TextOverflow.ellipsis);
      },
    );

    testWidgets(
      'given imageBytes, when rendered, then an Image.memory header '
      'replaces the placeholder',
      (tester) async {
        await _pumpCard(
          tester,
          title: 'With photo',
          hook: 'hook',
          placeName: 'Place',
          placeLocation: 'Loc',
          era: '2026',
          imageBytes: _transparentPngBytes(),
        );

        final memoryImages = find.byWidgetPredicate(
          (w) => w is Image && w.image is MemoryImage,
        );
        expect(memoryImages, findsOneWidget);
      },
    );
  });
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required String title,
  required String hook,
  required String placeName,
  required String placeLocation,
  required String era,
  Uint8List? imageBytes,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Material(
          color: Colors.transparent,
          child: Center(
            child: DailyStorySharingCard(
              title: title,
              hook: hook,
              placeName: placeName,
              placeLocation: placeLocation,
              era: era,
              imageBytes: imageBytes,
            ),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 3; i += 1) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Uint8List _transparentPngBytes() {
  return Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/widgets/daily_story_sharing_card_test.dart`
Expected: FAIL — `DailyStorySharingCard` is undefined.

- [ ] **Step 3: Write the widget**

```dart
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/presentation/widgets/card_reader_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A shareable card that renders a daily story in the warm "paper"
/// reader aesthetic, suitable for social sharing.
///
/// Rendered off-screen via [RepaintBoundary] and captured to PNG by
/// [DailyStorySharingService]. Colours are fixed [CardReaderTheme]
/// literals so the captured image looks identical across platforms and
/// appearance settings.
class DailyStorySharingCard extends StatelessWidget {
  final String title;
  final String hook;
  final String placeName;
  final String placeLocation;
  final String era;
  final String? imageUrl;
  final Uint8List? imageBytes;

  const DailyStorySharingCard({
    super.key,
    required this.title,
    required this.hook,
    required this.placeName,
    required this.placeLocation,
    required this.era,
    this.imageUrl,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      color: CardReaderTheme.readBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(imageUrl: imageUrl, imageBytes: imageBytes),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSerifTc(
                    color: CardReaderTheme.readInk,
                    fontSize: 24,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hook,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSerifTc(
                    color: CardReaderTheme.readDim,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const _Hairline(),
          _Footer(placeName: placeName, placeLocation: placeLocation, era: era),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  const _Header({this.imageUrl, this.imageBytes});

  bool get _hasImage =>
      imageBytes != null || (imageUrl != null && imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: _hasImage
          ? (imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _Placeholder(),
                  ))
          : const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CardReaderTheme.inkBg,
      alignment: Alignment.center,
      child: const Icon(
        Icons.auto_stories_outlined,
        color: CardReaderTheme.clay,
        size: 48,
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 1,
      color: CardReaderTheme.readLine,
    );
  }
}

class _Footer extends StatelessWidget {
  final String placeName;
  final String placeLocation;
  final String era;
  const _Footer({
    required this.placeName,
    required this.placeLocation,
    required this.era,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$placeName · $placeLocation · $era',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CardReaderTheme.readCap,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'LORESCAPE',
            style: GoogleFonts.notoSerifTc(
              color: CardReaderTheme.readCap,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/widgets/daily_story_sharing_card_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Analyze**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/daily_story/presentation/widgets/daily_story_sharing_card.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/daily_story/presentation/widgets/daily_story_sharing_card.dart \
        frontend/test/features/daily_story/presentation/widgets/daily_story_sharing_card_test.dart
git commit -m "feat(daily-story): DailyStorySharingCard share image widget"
```

---

### Task 4: `DailyStorySharingService`

**Files:**
- Create: `frontend/lib/features/daily_story/domain/services/daily_story_sharing_service.dart`

**Interfaces:**
- Consumes: `DailyStorySharingCard` (Task 3), `buildDailyStoryShareUrl` (Task 1), `share_card.story_share_text` (Task 2).
- Produces: `DailyStorySharingService.shareStoryCard({required BuildContext context, required DailyStory story, VoidCallback? onSheetPresented})` — renders the card off-screen, captures a PNG, and opens the share sheet with the story URL in the text.

**Note on testing:** the off-screen capture depends on `Overlay`/`BuildContext` and the OS share sheet, so it is verified by manual on-device test and by Task 5's button test, not a unit test. All pure logic (URL) is already tested in Task 1. This is consistent with the existing `JourneySharingService`, which has no service-level test.

The card's `title`/`hook` derive from the story: prefer the card fields, fall back to the legacy body — `title = story.cardTitle ?? story.placeName`; `hook = story.cardPullQuote ?? story.cardTitleSub ?? _firstSentence(story.story)`.

- [ ] **Step 1: Write the implementation** (mirrors `JourneySharingService`)

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/domain/services/daily_story_share_url.dart';
import 'package:context_app/features/daily_story/presentation/widgets/daily_story_sharing_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final _log = Logger('DailyStorySharingService');

/// Captures a [DailyStorySharingCard] as a PNG and shares it via the
/// platform share sheet, with the story's canonical URL in the text.
class DailyStorySharingService {
  DailyStorySharingService._();

  static Future<void> shareStoryCard({
    required BuildContext context,
    required DailyStory story,
    VoidCallback? onSheetPresented,
  }) async {
    try {
      final pngBytes = await _captureCardImage(context: context, story: story);
      if (pngBytes == null) {
        _log.warning('Failed to capture daily story card image');
        onSheetPresented?.call();
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/daily_story_card_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      final url = buildDailyStoryShareUrl(story);
      final shareText = '${'share_card.story_share_text'.tr()}\n$url';

      onSheetPresented?.call();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: shareText,
      );
    } catch (e, stack) {
      _log.severe('Error sharing daily story card', e, stack);
      onSheetPresented?.call();
    }
  }

  static String _titleFor(DailyStory story) =>
      story.cardTitle ?? story.placeName;

  static String _hookFor(DailyStory story) =>
      story.cardPullQuote ?? story.cardTitleSub ?? _firstSentence(story.story);

  static String _firstSentence(String text) {
    final trimmed = text.trim();
    final end = trimmed.indexOf(RegExp(r'[。.!?！？]'));
    if (end == -1) return trimmed;
    return trimmed.substring(0, end + 1);
  }

  static Future<Uint8List?> _captureCardImage({
    required BuildContext context,
    required DailyStory story,
  }) async {
    final key = GlobalKey();

    final widget = RepaintBoundary(
      key: key,
      child: MediaQuery(
        data: MediaQuery.of(context),
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Localizations.override(
            context: context,
            child: Material(
              color: Colors.transparent,
              child: DailyStorySharingCard(
                title: _titleFor(story),
                hook: _hookFor(story),
                placeName: story.placeName,
                placeLocation: story.placeLocation,
                era: story.era,
                imageUrl: story.imageUrl,
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = OverlayEntry(
      builder: (_) => Positioned(left: -1000, top: -1000, child: widget),
    );
    Overlay.of(context).insert(overlay);

    await Future<void>.delayed(const Duration(milliseconds: 500));

    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      overlay.remove();
    }
  }
}
```

- [ ] **Step 2: Analyze**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/daily_story/domain/services/daily_story_sharing_service.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/daily_story/domain/services/daily_story_sharing_service.dart
git commit -m "feat(daily-story): DailyStorySharingService capture-and-share"
```

---

### Task 5: Share button in `DailyStoryDetailScreen`

**Files:**
- Modify: `frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart`
- Test: `frontend/test/features/daily_story/presentation/screens/daily_story_share_button_test.dart`

**Interfaces:**
- Consumes: `DailyStorySharingService.shareStoryCard` (Task 4).
- Produces: a share `IconButton` (`Icons.ios_share`, `Key('daily_story_share_button')`) in both AppBar variants (card + legacy).

The screen is currently a `StatelessWidget` with two AppBar builders. Add the share action to both `AppBar`s. The tap calls `DailyStorySharingService.shareStoryCard(context: context, story: story)`. Because the capture opens the OS share sheet, the widget test asserts the button exists and is tappable (matching how the journey feature is covered); it does not assert the sheet opens.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/screens/daily_story_detail_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

DailyStory _legacyStory() => DailyStory(
  publishDate: DateTime(2026, 7, 1),
  language: 'en',
  placeName: 'Colosseum',
  placeLocation: 'Rome, Italy',
  era: '70-80 CE',
  story: 'A great amphitheatre.',
  imageUrl: null,
  wikipediaUrl: 'https://en.wikipedia.org/wiki/Colosseum',
);

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('DailyStoryDetailScreen share button', () {
    testWidgets(
      'given a story, when the detail screen renders, then a share '
      'button is present in the app bar',
      (tester) async {
        await tester.pumpWidget(
          _wrap(DailyStoryDetailScreen(story: _legacyStory())),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('daily_story_share_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'given the share button, when tapped, then no exception is thrown',
      (tester) async {
        await tester.pumpWidget(
          _wrap(DailyStoryDetailScreen(story: _legacyStory())),
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('daily_story_share_button')));
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });
}

Widget _wrap(Widget child) {
  const locale = Locale('en');
  return EasyLocalization(
    supportedLocales: const [locale, Locale('zh', 'TW')],
    path: 'assets/translations',
    fallbackLocale: locale,
    startLocale: locale,
    useOnlyLangCode: false,
    child: ProviderScope(
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: child,
        ),
      ),
    ),
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/screens/daily_story_share_button_test.dart`
Expected: FAIL — no widget with key `daily_story_share_button`.

- [ ] **Step 3: Add a shared actions helper and wire both AppBars**

Add this import near the top of `daily_story_detail_screen.dart`:

```dart
import 'package:context_app/features/daily_story/domain/services/daily_story_sharing_service.dart';
```

Add a private method to `DailyStoryDetailScreen`:

```dart
  List<Widget> _shareActions(BuildContext context, Color color) {
    return [
      IconButton(
        key: const Key('daily_story_share_button'),
        icon: Icon(Icons.ios_share, size: 20, color: color),
        onPressed: () => DailyStorySharingService.shareStoryCard(
          context: context,
          story: story,
        ),
      ),
    ];
  }
```

In `_buildDarkAppBar`, add to the `AppBar`:

```dart
      actions: _shareActions(context, CardReaderTheme.clay),
```

In `build`, change the legacy `AppBar` line to:

```dart
      appBar: isCard
          ? _buildDarkAppBar(context)
          : AppBar(
              title: Text(story.placeName),
              actions: _shareActions(
                context,
                Theme.of(context).colorScheme.onSurface,
              ),
            ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/screens/daily_story_share_button_test.dart`
Expected: PASS (2 tests). (The tap runs the async capture on a fake overlay; `takeException` is null because errors are caught and logged inside the service.)

- [ ] **Step 5: Analyze + full detail-screen test suite**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart && fvm flutter test test/features/daily_story/presentation/screens/`
Expected: No issues; existing `daily_story_detail_screen_test.dart` still passes.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart \
        frontend/test/features/daily_story/presentation/screens/daily_story_share_button_test.dart
git commit -m "feat(daily-story): share button on story detail screen"
```

---

### Task 6: Manual device verification + full suite

**Files:** none (verification only).

- [ ] **Step 1: Run the full frontend suite**

Run: `cd frontend && fvm flutter analyze --fatal-infos && fvm flutter test`
Expected: analyze clean; all tests pass.

- [ ] **Step 2: Manual share on a device/simulator**

Run the app, open a daily story (both a card-layout story and a legacy-layout story), tap the share button, and confirm:
- the share sheet opens with a PNG image preview,
- the image shows the header photo (or clay placeholder), title, hook, `place · location · era` caption, and the `LORESCAPE` wordmark,
- the share text ends with `https://lorescape.app/<lang>/story/<date>?utm_source=story_share&utm_medium=app` matching the story's language and date.

- [ ] **Step 3: No commit** (verification only). Record any follow-ups as new tasks.

---

## Deferred to later plans / phases

- **Phase 1 analytics (optional add-on):** in-app `story_share_tapped` /
  `story_share_completed` events. The existing `AnalyticsEvent` sealed type is
  narration-scoped (requires `narrationId` and is exhaustively switched in
  `firebaseParametersFor`), so a story-share event does not fit it cleanly.
  Downstream conversion is already measured by the UTM params on the share URL
  (GA4 + store install attribution), so in-app share analytics is deferred; if
  added later, log it via a direct `FirebaseAnalytics.logEvent('story_share', …)`
  call rather than forcing it into the narration envelope. Not required for the
  loop to function or be measured.
- **Phase 2 (web landing `/[locale]/story/[date]`)** — its own plan (Next.js +
  Supabase anon read + OG tags). This is what makes the shared link resolve for
  people without the app.
- **Phase 3 (Universal Link)** — its own plan (iOS Associated Domains + AASA,
  Android App Links + assetlinks, `go_router` `/story/:date` route with
  load-by-date, cold/warm start handling).

## Self-review notes

- Spec coverage: Phase 1 spec bullets (card widget, reuse of sharing pattern,
  watermark, share text with URL+UTM, entry on detail screen, widget test) each
  map to Tasks 1–6. Analytics is explicitly deferred with rationale (UTM covers
  downstream). Phases 2–3 are out of scope for this plan by design.
- Type consistency: `DailyStorySharingCard` params
  (`title/hook/placeName/placeLocation/era/imageUrl/imageBytes`) are identical
  in Task 3 (definition), Task 4 (usage), and the tests.
  `buildDailyStoryShareUrl` and `DailyStorySharingService.shareStoryCard`
  signatures match across Tasks 1, 4, 5.
- No placeholders: every code step contains complete code; every run step has an
  exact command and expected result.
