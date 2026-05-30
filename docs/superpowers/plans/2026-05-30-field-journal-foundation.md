# Field Journal Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the dark Midnight Kyoto theme with a single warm light "Field Journal" theme whose brand accent / reading surface / headline font are switchable at runtime and persisted, plus the cross-feature `CategoryTag` / `GlyphThumb` primitives and re-skinned global chrome.

**Architecture:** Design tokens live in a `LorescapeTokens` `ThemeExtension` resolved per (accent, reading). A Riverpod `Notifier` holds the persisted appearance choices and feeds `app.dart`, which builds one `ThemeData` and sets `themeMode: light`. Category visuals live in a `PlaceCategory` enum consumed by shared primitives. Old `midnight/` widgets stay until each screen migrates.

**Tech Stack:** Flutter, Dart, Riverpod (`Notifier`/`NotifierProvider`), `google_fonts` (Noto Serif TC / Noto Sans TC), `shared_preferences`, `flutter_test`.

**Commands:** use `fvm` for all Flutter/Dart commands. After each implementation task run `fvm flutter analyze --fatal-infos` and the task's tests.

---

## File Structure

**Create:**
- `lib/app/config/appearance_options.dart` — `BrandAccent`, `ReadingSurface`, `HeadlineFont` enums + storage encode/decode (app-wide, feature-agnostic).
- `lib/app/config/lorescape_tokens.dart` — `LorescapeTokens` `ThemeExtension` + `forAppearance(...)` factory.
- `lib/shared/widgets/journal/place_category.dart` — `PlaceCategory` enum (label/icon/ink/bg).
- `lib/shared/widgets/journal/category_tag.dart` — `CategoryTag` pill widget.
- `lib/shared/widgets/journal/glyph_thumb.dart` — `GlyphThumb` placeholder widget.
- `lib/features/settings/domain/repositories/appearance_preferences_repository.dart` — interface.
- `lib/features/settings/data/local_appearance_preferences_repository.dart` — SharedPreferences impl.
- `lib/features/settings/presentation/controllers/appearance_notifier.dart` — `AppearanceState` + `AppearanceNotifier`.
- `lib/features/settings/presentation/widgets/appearance_section.dart` — Settings「外觀」UI.
- Matching tests under `test/` mirroring each path.

**Modify:**
- `lib/app/config/theme_config.dart` — replace dark theme with `buildLorescapeTheme(...)`; add `lorescapeThemeProvider`-style builder.
- `lib/app.dart` — build theme from appearance notifier, `themeMode: light`, remove dark `AmbientBackdrop` wrapper.
- `lib/features/settings/providers.dart` — add appearance repo + notifier providers.
- `lib/features/settings/presentation/screens/settings_screen.dart` — insert `AppearanceSection`.
- `lib/app/shell/main_screen.dart` — re-skin bottom nav.

---

## Task 1: Appearance option enums

**Files:**
- Create: `lib/app/config/appearance_options.dart`
- Test: `test/app/config/appearance_options_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appearance option enums', () {
    test('BrandAccent round-trips through storage strings', () {
      for (final v in BrandAccent.values) {
        expect(BrandAccentX.fromStorage(v.storageKey), v);
      }
    });

    test('unknown BrandAccent storage string falls back to terracotta', () {
      expect(BrandAccentX.fromStorage('bogus'), BrandAccent.terracotta);
      expect(BrandAccentX.fromStorage(null), BrandAccent.terracotta);
    });

    test('ReadingSurface round-trips and defaults to paper', () {
      for (final v in ReadingSurface.values) {
        expect(ReadingSurfaceX.fromStorage(v.storageKey), v);
      }
      expect(ReadingSurfaceX.fromStorage('x'), ReadingSurface.paper);
    });

    test('HeadlineFont round-trips and defaults to serif', () {
      for (final v in HeadlineFont.values) {
        expect(HeadlineFontX.fromStorage(v.storageKey), v);
      }
      expect(HeadlineFontX.fromStorage(null), HeadlineFont.serif);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/app/config/appearance_options_test.dart`
Expected: FAIL — target file does not exist.

- [ ] **Step 3: Write minimal implementation**

```dart
/// User-switchable appearance options for the Field Journal theme.
///
/// These live in `app/config` (feature-agnostic) so both the theme layer
/// and the settings feature can depend on them without violating the
/// app→feature dependency rule.
library;

/// Brand accent colour family (terracotta / amber / sage).
enum BrandAccent { terracotta, amber, sage }

/// Reading-surface palette for immersive reading contexts.
enum ReadingSurface { paper, sepia, night }

/// Headline typeface choice.
enum HeadlineFont { serif, sans }

extension BrandAccentX on BrandAccent {
  String get storageKey => name;

  static BrandAccent fromStorage(String? raw) => BrandAccent.values
      .firstWhere((e) => e.name == raw, orElse: () => BrandAccent.terracotta);
}

extension ReadingSurfaceX on ReadingSurface {
  String get storageKey => name;

  static ReadingSurface fromStorage(String? raw) => ReadingSurface.values
      .firstWhere((e) => e.name == raw, orElse: () => ReadingSurface.paper);
}

extension HeadlineFontX on HeadlineFont {
  String get storageKey => name;

  static HeadlineFont fromStorage(String? raw) => HeadlineFont.values
      .firstWhere((e) => e.name == raw, orElse: () => HeadlineFont.serif);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/app/config/appearance_options_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Analyze + commit**

```bash
fvm flutter analyze --fatal-infos
git add lib/app/config/appearance_options.dart test/app/config/appearance_options_test.dart
git commit -m "feat(theme): appearance option enums for field-journal redesign"
```

---

## Task 2: `LorescapeTokens` ThemeExtension

**Files:**
- Create: `lib/app/config/lorescape_tokens.dart`
- Test: `test/app/config/lorescape_tokens_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LorescapeTokens.forAppearance', () {
    test('terracotta accent resolves clay family', () {
      final t = LorescapeTokens.forAppearance(
        accent: BrandAccent.terracotta,
        reading: ReadingSurface.paper,
      );
      expect(t.clay, const Color(0xFFBC5E3E));
      expect(t.clayDeep, const Color(0xFF97442A));
      expect(t.paper, const Color(0xFFF7F1E6));
    });

    test('sage accent swaps the clay family', () {
      final t = LorescapeTokens.forAppearance(
        accent: BrandAccent.sage,
        reading: ReadingSurface.paper,
      );
      expect(t.clay, const Color(0xFF5F7148));
    });

    test('night reading surface swaps read fields and keeps accent cap', () {
      final t = LorescapeTokens.forAppearance(
        accent: BrandAccent.terracotta,
        reading: ReadingSurface.night,
      );
      expect(t.readBg, const Color(0xFF1B1611));
      expect(t.readInk, const Color(0xFFE9E1D2));
      // drop-cap colour tracks the accent's deep shade.
      expect(t.readCap, const Color(0xFF97442A));
    });

    test('lerp at t=0 returns the start values', () {
      final a = LorescapeTokens.forAppearance(
        accent: BrandAccent.terracotta,
        reading: ReadingSurface.paper,
      );
      final b = LorescapeTokens.forAppearance(
        accent: BrandAccent.sage,
        reading: ReadingSurface.paper,
      );
      final mid = a.lerp(b, 0) as LorescapeTokens;
      expect(mid.clay, a.clay);
    });

    test('is retrievable from a ThemeData that registers it', () {
      final tokens = LorescapeTokens.forAppearance(
        accent: BrandAccent.amber,
        reading: ReadingSurface.paper,
      );
      final theme = ThemeData(extensions: [tokens]);
      expect(theme.extension<LorescapeTokens>()!.clay,
          const Color(0xFFB7842B));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/app/config/lorescape_tokens_test.dart`
Expected: FAIL — `lorescape_tokens.dart` not found.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'dart:ui' show lerpDouble;

import 'package:context_app/app/config/appearance_options.dart';
import 'package:flutter/material.dart';

/// Warm "Field Journal" design tokens, resolved for the active brand
/// accent and reading surface.
///
/// Read via `Theme.of(context).extension<LorescapeTokens>()!`. Values come
/// from the design handoff (`ls2.css`, `app.jsx`).
@immutable
class LorescapeTokens extends ThemeExtension<LorescapeTokens> {
  const LorescapeTokens({
    required this.paper,
    required this.paperRaised,
    required this.paperSunk,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.clay,
    required this.clayDeep,
    required this.claySoft,
    required this.clayTint,
    required this.inkBg,
    required this.inkBg2,
    required this.inkBg3,
    required this.onDark,
    required this.onDark2,
    required this.onDark3,
    required this.readBg,
    required this.readInk,
    required this.readDim,
    required this.readLine,
    required this.readCap,
    required this.rSm,
    required this.rMd,
    required this.rLg,
    required this.rXl,
    required this.rImg,
    required this.e1,
    required this.e2,
    required this.e3,
  });

  // Paper / line
  final Color paper;
  final Color paperRaised;
  final Color paperSunk;
  final Color line;
  final Color lineStrong;
  // Ink (text on paper)
  final Color ink;
  final Color ink2;
  final Color ink3;
  // Clay (brand, switchable)
  final Color clay;
  final Color clayDeep;
  final Color claySoft;
  final Color clayTint;
  // Dark surfaces (immersive / paywall / night)
  final Color inkBg;
  final Color inkBg2;
  final Color inkBg3;
  final Color onDark;
  final Color onDark2;
  final Color onDark3;
  // Reading surface (switchable)
  final Color readBg;
  final Color readInk;
  final Color readDim;
  final Color readLine;
  final Color readCap;
  // Radii
  final double rSm;
  final double rMd;
  final double rLg;
  final double rXl;
  final double rImg;
  // Warm shadows
  final List<BoxShadow> e1;
  final List<BoxShadow> e2;
  final List<BoxShadow> e3;

  /// Resolves the full token set for a given [accent] + [reading].
  factory LorescapeTokens.forAppearance({
    required BrandAccent accent,
    required ReadingSurface reading,
  }) {
    final (clay, clayDeep, claySoft, clayTint) = switch (accent) {
      BrandAccent.terracotta => (
          Color(0xFFBC5E3E),
          Color(0xFF97442A),
          Color(0xFFF1DDCE),
          Color(0xFFF7E8DD),
        ),
      BrandAccent.amber => (
          Color(0xFFB7842B),
          Color(0xFF8A5F18),
          Color(0xFFF0E5C8),
          Color(0xFFF6EED8),
        ),
      BrandAccent.sage => (
          Color(0xFF5F7148),
          Color(0xFF46542F),
          Color(0xFFE3E8D3),
          Color(0xFFEBEFE0),
        ),
    };
    final (readBg, readInk, readDim, readLine) = switch (reading) {
      ReadingSurface.paper => (
          Color(0xFFF7F1E6),
          Color(0xFF221C14),
          Color(0xFF5E5341),
          Color(0xFFE4DAC8),
        ),
      ReadingSurface.sepia => (
          Color(0xFFEFE2CB),
          Color(0xFF2A2013),
          Color(0xFF6A5A3E),
          Color(0xFFDDCBA8),
        ),
      ReadingSurface.night => (
          Color(0xFF1B1611),
          Color(0xFFE9E1D2),
          Color(0xFF9A8E7B),
          Color.fromRGBO(247, 241, 230, 0.14),
        ),
    };
    return LorescapeTokens(
      paper: const Color(0xFFF7F1E6),
      paperRaised: const Color(0xFFFDFAF3),
      paperSunk: const Color(0xFFECE3D3),
      line: const Color(0xFFE4DAC8),
      lineStrong: const Color(0xFFCDBFA6),
      ink: const Color(0xFF221C14),
      ink2: const Color(0xFF5E5341),
      ink3: const Color(0xFF918471),
      clay: clay,
      clayDeep: clayDeep,
      claySoft: claySoft,
      clayTint: clayTint,
      inkBg: const Color(0xFF1B1611),
      inkBg2: const Color(0xFF251E17),
      inkBg3: const Color(0xFF312820),
      onDark: const Color(0xFFF7F1E6),
      onDark2: const Color(0xFFC3B7A4),
      onDark3: const Color(0xFF8C8170),
      readBg: readBg,
      readInk: readInk,
      readDim: readDim,
      readLine: readLine,
      readCap: clayDeep,
      rSm: 8,
      rMd: 12,
      rLg: 16,
      rXl: 22,
      rImg: 10,
      e1: const [
        BoxShadow(
          color: Color.fromRGBO(40, 30, 18, 0.06),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
      e2: const [
        BoxShadow(
          color: Color.fromRGBO(40, 30, 18, 0.09),
          offset: Offset(0, 6),
          blurRadius: 18,
        ),
      ],
      e3: const [
        BoxShadow(
          color: Color.fromRGBO(28, 20, 10, 0.20),
          offset: Offset(0, 18),
          blurRadius: 44,
        ),
      ],
    );
  }

  @override
  LorescapeTokens copyWith({
    Color? paper,
    Color? paperRaised,
    Color? paperSunk,
    Color? line,
    Color? lineStrong,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? clay,
    Color? clayDeep,
    Color? claySoft,
    Color? clayTint,
    Color? inkBg,
    Color? inkBg2,
    Color? inkBg3,
    Color? onDark,
    Color? onDark2,
    Color? onDark3,
    Color? readBg,
    Color? readInk,
    Color? readDim,
    Color? readLine,
    Color? readCap,
    double? rSm,
    double? rMd,
    double? rLg,
    double? rXl,
    double? rImg,
    List<BoxShadow>? e1,
    List<BoxShadow>? e2,
    List<BoxShadow>? e3,
  }) {
    return LorescapeTokens(
      paper: paper ?? this.paper,
      paperRaised: paperRaised ?? this.paperRaised,
      paperSunk: paperSunk ?? this.paperSunk,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      clay: clay ?? this.clay,
      clayDeep: clayDeep ?? this.clayDeep,
      claySoft: claySoft ?? this.claySoft,
      clayTint: clayTint ?? this.clayTint,
      inkBg: inkBg ?? this.inkBg,
      inkBg2: inkBg2 ?? this.inkBg2,
      inkBg3: inkBg3 ?? this.inkBg3,
      onDark: onDark ?? this.onDark,
      onDark2: onDark2 ?? this.onDark2,
      onDark3: onDark3 ?? this.onDark3,
      readBg: readBg ?? this.readBg,
      readInk: readInk ?? this.readInk,
      readDim: readDim ?? this.readDim,
      readLine: readLine ?? this.readLine,
      readCap: readCap ?? this.readCap,
      rSm: rSm ?? this.rSm,
      rMd: rMd ?? this.rMd,
      rLg: rLg ?? this.rLg,
      rXl: rXl ?? this.rXl,
      rImg: rImg ?? this.rImg,
      e1: e1 ?? this.e1,
      e2: e2 ?? this.e2,
      e3: e3 ?? this.e3,
    );
  }

  @override
  LorescapeTokens lerp(ThemeExtension<LorescapeTokens>? other, double t) {
    if (other is! LorescapeTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    List<BoxShadow> s(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t)!;
    return LorescapeTokens(
      paper: c(paper, other.paper),
      paperRaised: c(paperRaised, other.paperRaised),
      paperSunk: c(paperSunk, other.paperSunk),
      line: c(line, other.line),
      lineStrong: c(lineStrong, other.lineStrong),
      ink: c(ink, other.ink),
      ink2: c(ink2, other.ink2),
      ink3: c(ink3, other.ink3),
      clay: c(clay, other.clay),
      clayDeep: c(clayDeep, other.clayDeep),
      claySoft: c(claySoft, other.claySoft),
      clayTint: c(clayTint, other.clayTint),
      inkBg: c(inkBg, other.inkBg),
      inkBg2: c(inkBg2, other.inkBg2),
      inkBg3: c(inkBg3, other.inkBg3),
      onDark: c(onDark, other.onDark),
      onDark2: c(onDark2, other.onDark2),
      onDark3: c(onDark3, other.onDark3),
      readBg: c(readBg, other.readBg),
      readInk: c(readInk, other.readInk),
      readDim: c(readDim, other.readDim),
      readLine: c(readLine, other.readLine),
      readCap: c(readCap, other.readCap),
      rSm: d(rSm, other.rSm),
      rMd: d(rMd, other.rMd),
      rLg: d(rLg, other.rLg),
      rXl: d(rXl, other.rXl),
      rImg: d(rImg, other.rImg),
      e1: s(e1, other.e1),
      e2: s(e2, other.e2),
      e3: s(e3, other.e3),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/app/config/lorescape_tokens_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Analyze + commit**

```bash
fvm flutter analyze --fatal-infos
git add lib/app/config/lorescape_tokens.dart test/app/config/lorescape_tokens_test.dart
git commit -m "feat(theme): LorescapeTokens ThemeExtension with accent/reading resolution"
```

---

## Task 3: `PlaceCategory` enum

**Files:**
- Create: `lib/shared/widgets/journal/place_category.dart`
- Test: `test/shared/widgets/journal/place_category_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/shared/widgets/journal/place_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaceCategory', () {
    test('nature maps to pine-green ink on soft-green bg', () {
      expect(PlaceCategory.nature.ink, const Color(0xFF4E6138));
      expect(PlaceCategory.nature.bg, const Color(0xFFE6E8D5));
      expect(PlaceCategory.nature.label, '自然景觀');
    });

    test('every category has a non-placeholder icon and distinct bg', () {
      final bgs = PlaceCategory.values.map((c) => c.bg.toARGB32()).toSet();
      expect(bgs.length, PlaceCategory.values.length);
      for (final c in PlaceCategory.values) {
        expect(c.icon, isA<IconData>());
        expect(c.label.isNotEmpty, isTrue);
      }
    });

    test('sacred maps to plum ink', () {
      expect(PlaceCategory.sacred.ink, const Color(0xFF6E4A63));
      expect(PlaceCategory.sacred.bg, const Color(0xFFECDCE6));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/shared/widgets/journal/place_category_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';

/// Visual identity for a place category in the Field Journal design.
///
/// Colours and labels come from the design handoff's five-category system.
/// Icons use the closest Material match; bespoke line icons may replace
/// these in a later cycle without changing this enum's API.
enum PlaceCategory {
  nature('自然景觀', Icons.terrain_outlined, Color(0xFF4E6138), Color(0xFFE6E8D5)),
  heritage('人文古蹟', Icons.account_balance_outlined, Color(0xFF8A6320),
      Color(0xFFF0E5CC)),
  urban('城市地標', Icons.apartment_outlined, Color(0xFF44597A), Color(0xFFDFE4EC)),
  coast('海岸水域', Icons.waves_outlined, Color(0xFF2F6566), Color(0xFFD9E7E4)),
  sacred('信仰聖地', Icons.menu_book_outlined, Color(0xFF6E4A63), Color(0xFFECDCE6));

  const PlaceCategory(this.label, this.icon, this.ink, this.bg);

  /// Localised display label.
  final String label;

  /// Glyph shown in tags and placeholder thumbs.
  final IconData icon;

  /// Foreground (text/icon) colour.
  final Color ink;

  /// Background fill colour.
  final Color bg;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/shared/widgets/journal/place_category_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Analyze + commit**

```bash
fvm flutter analyze --fatal-infos
git add lib/shared/widgets/journal/place_category.dart test/shared/widgets/journal/place_category_test.dart
git commit -m "feat(shared): PlaceCategory enum with field-journal category palette"
```

---

## Task 4: `AppearancePreferencesRepository` + local impl

**Files:**
- Create: `lib/features/settings/domain/repositories/appearance_preferences_repository.dart`
- Create: `lib/features/settings/data/local_appearance_preferences_repository.dart`
- Test: `test/features/settings/data/local_appearance_preferences_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/data/local_appearance_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LocalAppearancePreferencesRepository', () {
    final repo = LocalAppearancePreferencesRepository();

    test('returns null fields when nothing saved', () async {
      expect(await repo.loadAccent(), isNull);
      expect(await repo.loadReadingSurface(), isNull);
      expect(await repo.loadHeadlineFont(), isNull);
    });

    test('persists and reloads each field', () async {
      await repo.saveAccent(BrandAccent.sage);
      await repo.saveReadingSurface(ReadingSurface.night);
      await repo.saveHeadlineFont(HeadlineFont.sans);

      expect(await repo.loadAccent(), BrandAccent.sage);
      expect(await repo.loadReadingSurface(), ReadingSurface.night);
      expect(await repo.loadHeadlineFont(), HeadlineFont.sans);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/features/settings/data/local_appearance_preferences_repository_test.dart`
Expected: FAIL — files not found.

- [ ] **Step 3: Write minimal implementation**

Interface:

```dart
import 'package:context_app/app/config/appearance_options.dart';

/// Persistence for the user's Field Journal appearance choices.
///
/// Returns `null` when a value has never been saved so callers can apply
/// their own default.
abstract interface class AppearancePreferencesRepository {
  Future<BrandAccent?> loadAccent();
  Future<void> saveAccent(BrandAccent accent);

  Future<ReadingSurface?> loadReadingSurface();
  Future<void> saveReadingSurface(ReadingSurface surface);

  Future<HeadlineFont?> loadHeadlineFont();
  Future<void> saveHeadlineFont(HeadlineFont font);
}
```

Local impl:

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/domain/repositories/appearance_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [AppearancePreferencesRepository] backed by [SharedPreferences].
class LocalAppearancePreferencesRepository
    implements AppearancePreferencesRepository {
  static const _kAccent = 'appearance_accent';
  static const _kReading = 'appearance_reading';
  static const _kHeadlineFont = 'appearance_headline_font';

  @override
  Future<BrandAccent?> loadAccent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAccent);
    return raw == null ? null : BrandAccentX.fromStorage(raw);
  }

  @override
  Future<void> saveAccent(BrandAccent accent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccent, accent.storageKey);
  }

  @override
  Future<ReadingSurface?> loadReadingSurface() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kReading);
    return raw == null ? null : ReadingSurfaceX.fromStorage(raw);
  }

  @override
  Future<void> saveReadingSurface(ReadingSurface surface) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReading, surface.storageKey);
  }

  @override
  Future<HeadlineFont?> loadHeadlineFont() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHeadlineFont);
    return raw == null ? null : HeadlineFontX.fromStorage(raw);
  }

  @override
  Future<void> saveHeadlineFont(HeadlineFont font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHeadlineFont, font.storageKey);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/features/settings/data/local_appearance_preferences_repository_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Analyze + commit**

```bash
fvm flutter analyze --fatal-infos
git add lib/features/settings/domain/repositories/appearance_preferences_repository.dart lib/features/settings/data/local_appearance_preferences_repository.dart test/features/settings/data/local_appearance_preferences_repository_test.dart
git commit -m "feat(settings): appearance preferences repository"
```

---

## Task 5: `AppearanceState` + `AppearanceNotifier` + providers

**Files:**
- Create: `lib/features/settings/presentation/controllers/appearance_notifier.dart`
- Modify: `lib/features/settings/providers.dart` (append providers)
- Test: `test/features/settings/presentation/controllers/appearance_notifier_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/domain/repositories/appearance_preferences_repository.dart';
import 'package:context_app/features/settings/presentation/controllers/appearance_notifier.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements AppearancePreferencesRepository {
  BrandAccent? accent;
  ReadingSurface? reading;
  HeadlineFont? font;

  @override
  Future<BrandAccent?> loadAccent() async => accent;
  @override
  Future<void> saveAccent(BrandAccent a) async => accent = a;
  @override
  Future<ReadingSurface?> loadReadingSurface() async => reading;
  @override
  Future<void> saveReadingSurface(ReadingSurface s) async => reading = s;
  @override
  Future<HeadlineFont?> loadHeadlineFont() async => font;
  @override
  Future<void> saveHeadlineFont(HeadlineFont f) async => font = f;
}

ProviderContainer _container(_FakeRepo repo) {
  final c = ProviderContainer(
    overrides: [
      appearancePreferencesRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('AppearanceNotifier', () {
    test('defaults to terracotta / paper / serif', () {
      final c = _container(_FakeRepo());
      final s = c.read(appearanceNotifierProvider);
      expect(s.accent, BrandAccent.terracotta);
      expect(s.reading, ReadingSurface.paper);
      expect(s.headlineFont, HeadlineFont.serif);
    });

    test('applies persisted values after async load', () async {
      final repo = _FakeRepo()
        ..accent = BrandAccent.sage
        ..reading = ReadingSurface.night
        ..font = HeadlineFont.sans;
      final c = _container(repo);
      c.read(appearanceNotifierProvider); // trigger build
      await Future<void>.delayed(Duration.zero);

      final s = c.read(appearanceNotifierProvider);
      expect(s.accent, BrandAccent.sage);
      expect(s.reading, ReadingSurface.night);
      expect(s.headlineFont, HeadlineFont.sans);
    });

    test('setAccent updates state and persists', () async {
      final repo = _FakeRepo();
      final c = _container(repo);
      c.read(appearanceNotifierProvider);

      await c.read(appearanceNotifierProvider.notifier)
          .setAccent(BrandAccent.amber);

      expect(c.read(appearanceNotifierProvider).accent, BrandAccent.amber);
      expect(repo.accent, BrandAccent.amber);
    });

    test('setReadingSurface and setHeadlineFont update + persist', () async {
      final repo = _FakeRepo();
      final c = _container(repo);
      c.read(appearanceNotifierProvider);

      await c.read(appearanceNotifierProvider.notifier)
          .setReadingSurface(ReadingSurface.sepia);
      await c.read(appearanceNotifierProvider.notifier)
          .setHeadlineFont(HeadlineFont.sans);

      final s = c.read(appearanceNotifierProvider);
      expect(s.reading, ReadingSurface.sepia);
      expect(s.headlineFont, HeadlineFont.sans);
      expect(repo.reading, ReadingSurface.sepia);
      expect(repo.font, HeadlineFont.sans);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/features/settings/presentation/controllers/appearance_notifier_test.dart`
Expected: FAIL — notifier/providers not found.

- [ ] **Step 3: Write minimal implementation**

`appearance_notifier.dart`:

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable snapshot of the user's appearance choices.
@immutable
class AppearanceState {
  const AppearanceState({
    this.accent = BrandAccent.terracotta,
    this.reading = ReadingSurface.paper,
    this.headlineFont = HeadlineFont.serif,
  });

  final BrandAccent accent;
  final ReadingSurface reading;
  final HeadlineFont headlineFont;

  AppearanceState copyWith({
    BrandAccent? accent,
    ReadingSurface? reading,
    HeadlineFont? headlineFont,
  }) {
    return AppearanceState(
      accent: accent ?? this.accent,
      reading: reading ?? this.reading,
      headlineFont: headlineFont ?? this.headlineFont,
    );
  }
}

/// Holds and persists the Field Journal appearance choices.
///
/// `build()` returns defaults synchronously and kicks off an async load so
/// the first frame renders immediately; persisted values are applied as
/// soon as they resolve.
class AppearanceNotifier extends Notifier<AppearanceState> {
  @override
  AppearanceState build() {
    _loadFromPrefs();
    return const AppearanceState();
  }

  Future<void> _loadFromPrefs() async {
    final repo = ref.read(appearancePreferencesRepositoryProvider);
    final accent = await repo.loadAccent();
    final reading = await repo.loadReadingSurface();
    final font = await repo.loadHeadlineFont();
    state = state.copyWith(
      accent: accent,
      reading: reading,
      headlineFont: font,
    );
  }

  Future<void> setAccent(BrandAccent accent) async {
    state = state.copyWith(accent: accent);
    await ref.read(appearancePreferencesRepositoryProvider).saveAccent(accent);
  }

  Future<void> setReadingSurface(ReadingSurface surface) async {
    state = state.copyWith(reading: surface);
    await ref
        .read(appearancePreferencesRepositoryProvider)
        .saveReadingSurface(surface);
  }

  Future<void> setHeadlineFont(HeadlineFont font) async {
    state = state.copyWith(headlineFont: font);
    await ref
        .read(appearancePreferencesRepositoryProvider)
        .saveHeadlineFont(font);
  }
}
```

Append to `lib/features/settings/providers.dart` (add the two imports at the top with the other settings imports, and the providers under a new section):

```dart
import 'package:context_app/features/settings/data/local_appearance_preferences_repository.dart';
import 'package:context_app/features/settings/domain/repositories/appearance_preferences_repository.dart';
import 'package:context_app/features/settings/presentation/controllers/appearance_notifier.dart';
```

```dart
// ============================================================================
// Appearance Providers (Field Journal theme)
// ============================================================================

/// Persistence for appearance choices. Override in tests with a fake.
final appearancePreferencesRepositoryProvider =
    Provider<AppearancePreferencesRepository>((ref) {
      return LocalAppearancePreferencesRepository();
    });

/// Field Journal appearance state (accent / reading / headline font).
final appearanceNotifierProvider =
    NotifierProvider<AppearanceNotifier, AppearanceState>(
      AppearanceNotifier.new,
    );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/features/settings/presentation/controllers/appearance_notifier_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Analyze + commit**

```bash
fvm flutter analyze --fatal-infos
git add lib/features/settings/presentation/controllers/appearance_notifier.dart lib/features/settings/providers.dart test/features/settings/presentation/controllers/appearance_notifier_test.dart
git commit -m "feat(settings): AppearanceNotifier with persistence"
```

---

## Task 6: `buildLorescapeTheme` — replace dark theme

**Files:**
- Modify: `lib/app/config/theme_config.dart` (full rewrite of the class body)
- Test: `test/app/config/theme_config_test.dart` (may already exist — replace contents)

Note: `theme_config.dart` currently exposes `darkTheme` / `lightTheme` getters
consumed only by `app.dart`. Those callers are updated in Task 7. This task
introduces the new builder and removes the old getters.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/app/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildLorescapeTheme', () {
    final tokens = LorescapeTokens.forAppearance(
      accent: BrandAccent.terracotta,
      reading: ReadingSurface.paper,
    );

    test('is a light theme with clay primary and paper scaffold', () {
      final theme = buildLorescapeTheme(
        tokens: tokens,
        headlineFont: HeadlineFont.serif,
      );
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, tokens.clay);
      expect(theme.scaffoldBackgroundColor, tokens.paper);
    });

    test('registers the LorescapeTokens extension', () {
      final theme = buildLorescapeTheme(
        tokens: tokens,
        headlineFont: HeadlineFont.serif,
      );
      expect(theme.extension<LorescapeTokens>(), isNotNull);
      expect(theme.extension<LorescapeTokens>()!.clay, tokens.clay);
    });

    test('amber tokens flow into the colour scheme primary', () {
      final amber = LorescapeTokens.forAppearance(
        accent: BrandAccent.amber,
        reading: ReadingSurface.paper,
      );
      final theme = buildLorescapeTheme(
        tokens: amber,
        headlineFont: HeadlineFont.serif,
      );
      expect(theme.colorScheme.primary, const Color(0xFFB7842B));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/app/config/theme_config_test.dart`
Expected: FAIL — `buildLorescapeTheme` not defined.

- [ ] **Step 3: Write minimal implementation**

Replace the entire contents of `lib/app/config/theme_config.dart` with:

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds the warm "Field Journal" light theme from resolved [tokens].
///
/// Headlines use Noto Serif TC (or Noto Sans TC when [headlineFont] is
/// [HeadlineFont.sans]); body text uses Noto Sans TC. The returned
/// [ThemeData] registers [LorescapeTokens] so widgets can read warm tokens
/// not covered by the standard [ColorScheme].
ThemeData buildLorescapeTheme({
  required LorescapeTokens tokens,
  required HeadlineFont headlineFont,
}) {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: tokens.clay,
        brightness: Brightness.light,
      ).copyWith(
        primary: tokens.clay,
        onPrimary: const Color(0xFFFBF1E9),
        primaryContainer: tokens.clayTint,
        onPrimaryContainer: tokens.clayDeep,
        surface: tokens.paper,
        onSurface: tokens.ink,
        onSurfaceVariant: tokens.ink2,
        surfaceContainerLow: tokens.paperRaised,
        surfaceContainerHighest: tokens.paperSunk,
        outline: tokens.lineStrong,
        outlineVariant: tokens.line,
      );

  TextStyle headline(double size, {FontWeight weight = FontWeight.w700}) {
    final base = headlineFont == HeadlineFont.sans
        ? GoogleFonts.notoSansTc
        : GoogleFonts.notoSerifTc;
    return base(fontSize: size, fontWeight: weight, color: tokens.ink);
  }

  final textTheme = TextTheme(
    displayLarge: headline(34).copyWith(letterSpacing: 1, height: 1.1),
    displayMedium: headline(28),
    displaySmall: headline(24),
    headlineMedium: headline(20),
    titleLarge: headline(18).copyWith(letterSpacing: 0.5),
    titleMedium: GoogleFonts.notoSansTc(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: tokens.ink,
    ),
    bodyLarge: GoogleFonts.notoSansTc(
      fontSize: 16,
      height: 1.5,
      color: tokens.ink,
    ),
    bodyMedium: GoogleFonts.notoSansTc(
      fontSize: 14,
      height: 1.5,
      color: tokens.ink2,
    ),
    bodySmall: GoogleFonts.notoSansTc(
      fontSize: 13,
      color: tokens.ink3,
    ),
    labelLarge: GoogleFonts.notoSansTc(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: tokens.ink,
    ),
    labelSmall: GoogleFonts.notoSansTc(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: tokens.ink3,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.paper,
    textTheme: textTheme,
    extensions: [tokens],
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.paper,
      foregroundColor: tokens.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: headline(18).copyWith(letterSpacing: 0.5),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: tokens.paperRaised,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.rLg),
        side: BorderSide(color: tokens.line),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.clay,
        foregroundColor: const Color(0xFFFBF1E9),
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.rLg),
        ),
        textStyle: GoogleFonts.notoSansTc(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.ink,
        backgroundColor: tokens.paperRaised,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: BorderSide(color: tokens.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.rLg),
        ),
        textStyle: GoogleFonts.notoSansTc(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: tokens.clay),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: tokens.clay,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.paperRaised,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.notoSansTc(color: tokens.ink3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.rMd),
        borderSide: BorderSide(color: tokens.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.rMd),
        borderSide: BorderSide(color: tokens.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.rMd),
        borderSide: BorderSide(color: tokens.clay, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: tokens.paperSunk,
      side: BorderSide(color: tokens.line),
      labelStyle: GoogleFonts.notoSansTc(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: tokens.ink,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
    ),
    dividerTheme: DividerThemeData(color: tokens.line, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.paper,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.rXl),
      ),
      titleTextStyle: headline(21),
      contentTextStyle: GoogleFonts.notoSansTc(
        fontSize: 15,
        height: 1.6,
        color: tokens.ink2,
      ),
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/app/config/theme_config_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Analyze + commit**

Note: `analyze` will report errors in `app.dart` (it still calls the removed
`ThemeConfig.darkTheme`). That is expected and fixed in Task 7. Scope the
analyze to the changed file:

```bash
fvm flutter analyze --fatal-infos lib/app/config/theme_config.dart test/app/config/theme_config_test.dart
git add lib/app/config/theme_config.dart test/app/config/theme_config_test.dart
git commit -m "feat(theme): buildLorescapeTheme light field-journal ThemeData"
```

---

## Task 7: Wire `app.dart` to the new theme

**Files:**
- Modify: `lib/app.dart`
- Test: `test/app/lorescape_theme_wiring_test.dart`

The wiring builds the theme from `appearanceNotifierProvider` and resolves
`LorescapeTokens`. To keep it testable, add a small top-level helper in
`app.dart` and test that helper (pumping the full `MaterialApp.router` is too
heavy and pulls in Supabase/router deps).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/app.dart';
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/features/settings/presentation/controllers/appearance_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lorescapeThemeFor', () {
    test('builds a light theme reflecting the appearance state', () {
      const state = AppearanceState(
        accent: BrandAccent.sage,
        reading: ReadingSurface.paper,
        headlineFont: HeadlineFont.serif,
      );
      final theme = lorescapeThemeFor(state);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF5F7148));
      expect(theme.extension<LorescapeTokens>(), isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/app/lorescape_theme_wiring_test.dart`
Expected: FAIL — `lorescapeThemeFor` not defined.

- [ ] **Step 3: Write minimal implementation**

In `lib/app.dart`:

1. Update imports — remove the now-unused dark wrapper import and add the new ones:

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/app/config/theme_config.dart';
import 'package:context_app/features/settings/presentation/controllers/appearance_notifier.dart';
import 'package:context_app/features/settings/providers.dart';
```

Remove the import of `midnight.dart` ONLY IF nothing else in the file uses it
after the edit below (it provides `AmbientBackdrop`). If other midnight symbols
are still referenced, keep the import.

2. Add this top-level function (outside the class):

```dart
/// Builds the Field Journal [ThemeData] for the given appearance [state].
ThemeData lorescapeThemeFor(AppearanceState state) {
  final tokens = LorescapeTokens.forAppearance(
    accent: state.accent,
    reading: state.reading,
  );
  return buildLorescapeTheme(
    tokens: tokens,
    headlineFont: state.headlineFont,
  );
}
```

3. In `build`, read the appearance state and use the helper:

```dart
final appearance = ref.watch(appearanceNotifierProvider);
final theme = lorescapeThemeFor(appearance);
```

4. Replace the `MaterialApp.router` theme lines:

```dart
theme: theme,
themeMode: ThemeMode.light,
```

(delete the `darkTheme:` and the old `theme: ThemeConfig.darkTheme` lines.)

5. Replace the `builder:` body — drop the dark `AmbientBackdrop` so the paper
scaffold shows through; keep the share-loading overlay:

```dart
builder: (context, child) {
  return Stack(
    children: [
      child!,
      if (pendingShare != null && pendingShare.isLoading)
        const _ShareLoadingOverlay(),
    ],
  );
},
```

- [ ] **Step 4: Run test + analyze to verify**

Run: `fvm flutter test test/app/lorescape_theme_wiring_test.dart`
Expected: PASS (1 test).

Run: `fvm flutter analyze --fatal-infos lib/app.dart lib/app/config/theme_config.dart`
Expected: No issues (the Task 6 cross-file error is now resolved). If analyze
flags an unused `midnight.dart` import, remove it.

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart test/app/lorescape_theme_wiring_test.dart
git commit -m "feat(app): wire MaterialApp to field-journal light theme"
```

---

## Task 8: `CategoryTag` widget

**Files:**
- Create: `lib/shared/widgets/journal/category_tag.dart`
- Test: `test/shared/widgets/journal/category_tag_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/shared/widgets/journal/category_tag.dart';
import 'package:context_app/shared/widgets/journal/place_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );
  }

  group('CategoryTag', () {
    testWidgets('shows the category label and icon', (tester) async {
      await pump(tester, const CategoryTag(category: PlaceCategory.nature));

      expect(find.text('自然景觀'), findsOneWidget);
      expect(find.byIcon(Icons.terrain_outlined), findsOneWidget);
    });

    testWidgets('uses the category background colour by default',
        (tester) async {
      await pump(tester, const CategoryTag(category: PlaceCategory.urban));

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('category-tag-surface')),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, PlaceCategory.urban.bg);
    });

    testWidgets('onPhoto variant uses a dark translucent surface',
        (tester) async {
      await pump(
        tester,
        const CategoryTag(category: PlaceCategory.urban, onPhoto: true),
      );

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('category-tag-surface')),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0x80141008));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/shared/widgets/journal/category_tag_test.dart`
Expected: FAIL — widget not found.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:context_app/shared/widgets/journal/place_category.dart';
import 'package:flutter/material.dart';

/// A pill-shaped category label: glyph + name on a category-tinted surface.
///
/// Set [onPhoto] when the tag sits over an image; it switches to a dark
/// translucent surface with white text for legibility.
class CategoryTag extends StatelessWidget {
  const CategoryTag({
    super.key,
    required this.category,
    this.onPhoto = false,
  });

  final PlaceCategory category;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final fg = onPhoto ? Colors.white : category.ink;
    final bg = onPhoto ? const Color(0x80141008) : category.bg;

    return Container(
      key: const ValueKey('category-tag-surface'),
      height: 28,
      padding: const EdgeInsets.fromLTRB(9, 0, 11, 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            category.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/shared/widgets/journal/category_tag_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Analyze + commit**

```bash
fvm flutter analyze --fatal-infos
git add lib/shared/widgets/journal/category_tag.dart test/shared/widgets/journal/category_tag_test.dart
git commit -m "feat(shared): CategoryTag pill widget"
```

---

## Task 9: `GlyphThumb` widget

**Files:**
- Create: `lib/shared/widgets/journal/glyph_thumb.dart`
- Test: `test/shared/widgets/journal/glyph_thumb_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/shared/widgets/journal/glyph_thumb.dart';
import 'package:context_app/shared/widgets/journal/place_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );
  }

  group('GlyphThumb', () {
    testWidgets('fills with the category background and shows its glyph',
        (tester) async {
      await pump(
        tester,
        const GlyphThumb(category: PlaceCategory.coast, size: 64),
      );

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('glyph-thumb-surface')),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, PlaceCategory.coast.bg);

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, PlaceCategory.coast.icon);
      expect(icon.color, PlaceCategory.coast.ink);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/shared/widgets/journal/glyph_thumb_test.dart`
Expected: FAIL — widget not found.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:context_app/shared/widgets/journal/place_category.dart';
import 'package:flutter/material.dart';

/// Square placeholder thumbnail for places without a photo: the category
/// background tint with its glyph centered.
class GlyphThumb extends StatelessWidget {
  const GlyphThumb({
    super.key,
    required this.category,
    this.size = 64,
    this.borderRadius = 12,
  });

  final PlaceCategory category;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('glyph-thumb-surface'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(category.icon, size: size * 0.5, color: category.ink),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/shared/widgets/journal/glyph_thumb_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Analyze + commit**

```bash
fvm flutter analyze --fatal-infos
git add lib/shared/widgets/journal/glyph_thumb.dart test/shared/widgets/journal/glyph_thumb_test.dart
git commit -m "feat(shared): GlyphThumb placeholder widget"
```

---

## Task 10: Settings「外觀」appearance section

**Files:**
- Create: `lib/features/settings/presentation/widgets/appearance_section.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Test: `test/features/settings/presentation/widgets/appearance_section_test.dart`

The section renders three segmented controls bound to `AppearanceNotifier`. To
keep this self-contained, it ships its own small `_SegmentedRow` rather than
depending on a not-yet-built shared control.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/presentation/controllers/appearance_notifier.dart';
import 'package:context_app/features/settings/presentation/widgets/appearance_section.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AppearanceSection()),
          ),
        ),
      ),
    );
  }

  group('AppearanceSection', () {
    testWidgets('renders the three appearance controls', (tester) async {
      await pump(tester);
      expect(find.text('陶土'), findsOneWidget); // terracotta accent label
      expect(find.text('紙感'), findsOneWidget); // paper reading label
      expect(find.text('襯線'), findsOneWidget); // serif headline label
    });

    testWidgets('tapping an accent option updates the notifier',
        (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: Scaffold(body: AppearanceSection()),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('橄欖')); // sage
      await tester.pump();

      expect(
        container.read(appearanceNotifierProvider).accent,
        BrandAccent.sage,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/features/settings/presentation/widgets/appearance_section_test.dart`
Expected: FAIL — widget not found.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/features/settings/presentation/controllers/appearance_notifier.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings「外觀」section: switch brand accent, reading surface and
/// headline font. Replaces the prototype's floating Tweaks dev panel.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appearanceNotifierProvider);
    final notifier = ref.read(appearanceNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 10),
          child: Text(
            '外觀',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        _SegmentedRow<BrandAccent>(
          label: '品牌主色',
          value: state.accent,
          options: const {
            BrandAccent.terracotta: '陶土',
            BrandAccent.amber: '琥珀',
            BrandAccent.sage: '橄欖',
          },
          onChanged: notifier.setAccent,
        ),
        _SegmentedRow<ReadingSurface>(
          label: '閱讀介面',
          value: state.reading,
          options: const {
            ReadingSurface.paper: '紙感',
            ReadingSurface.sepia: '復古',
            ReadingSurface.night: '夜間',
          },
          onChanged: notifier.setReadingSurface,
        ),
        _SegmentedRow<HeadlineFont>(
          label: '標題字體',
          value: state.headlineFont,
          options: const {
            HeadlineFont.serif: '襯線',
            HeadlineFont.sans: '黑體',
          },
          onChanged: notifier.setHeadlineFont,
        ),
      ],
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                for (final entry in options.entries)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(entry.key),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: entry.key == value
                              ? scheme.surfaceContainerLow
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: entry.key == value
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

Then insert the section into `settings_screen.dart`. Find the top-level
settings list/column body and add `const AppearanceSection()` near the top of
the groups (after any account/header block, before other groups). Add the
import:

```dart
import 'package:context_app/features/settings/presentation/widgets/appearance_section.dart';
```

Place the widget consistent with the screen's existing group layout (if the
screen wraps groups in padding, match it). Keep the change minimal — one
widget insertion plus the import.

- [ ] **Step 4: Run tests to verify they pass**

Run: `fvm flutter test test/features/settings/presentation/widgets/appearance_section_test.dart`
Expected: PASS (2 tests).

Run the existing settings screen tests to confirm no regression:
Run: `fvm flutter test test/features/settings/presentation/screens/`
Expected: PASS.

- [ ] **Step 5: Analyze + commit**

```bash
fvm flutter analyze --fatal-infos
git add lib/features/settings/presentation/widgets/appearance_section.dart lib/features/settings/presentation/screens/settings_screen.dart test/features/settings/presentation/widgets/appearance_section_test.dart
git commit -m "feat(settings): 外觀 appearance section replacing dev tweaks panel"
```

---

## Task 11: Re-skin the bottom navigation

**Files:**
- Modify: `lib/app/shell/main_screen.dart`
- Test: `test/app/shell/main_screen_nav_test.dart`

Re-skin the existing `BottomNavigationBar`: paper surface, line top border,
clay selected colour from the theme, journal-friendly icons. Keep the 4 tabs
and `easy_localization` labels unchanged.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:context_app/app/config/appearance_options.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/app/config/theme_config.dart';
import 'package:context_app/app/shell/main_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
  });

  ThemeData theme() => buildLorescapeTheme(
        tokens: LorescapeTokens.forAppearance(
          accent: BrandAccent.terracotta,
          reading: ReadingSurface.paper,
        ),
        headlineFont: HeadlineFont.serif,
      );

  testWidgets('bottom nav selected colour is clay', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: EasyLocalization(
          supportedLocales: const [Locale('zh', 'TW')],
          path: 'assets/translations',
          fallbackLocale: const Locale('zh', 'TW'),
          child: Builder(
            builder: (context) => MaterialApp(
              theme: theme(),
              locale: const Locale('zh', 'TW'),
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const MainScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.items.length, 4);
    expect(nav.selectedItemColor, const Color(0xFFBC5E3E));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/app/shell/main_screen_nav_test.dart`
Expected: FAIL — selectedItemColor is still `AppColors.primary` (blue).

- [ ] **Step 3: Write minimal implementation**

In `lib/app/shell/main_screen.dart`:

1. Remove `import 'package:context_app/app/config/app_colors.dart';` (no longer
   needed).
2. Read tokens from the theme inside `build` and restyle the nav. Replace the
   `bottomNavigationBar:` with:

```dart
bottomNavigationBar: DecoratedBox(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    border: Border(
      top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
  ),
  child: BottomNavigationBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    type: BottomNavigationBarType.fixed,
    currentIndex: _selectedIndex,
    onTap: _onItemTapped,
    selectedItemColor: Theme.of(context).colorScheme.primary,
    unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
    items: <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.auto_stories_outlined),
        activeIcon: const Icon(Icons.auto_stories),
        label: 'bottom_nav.stories'.tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.explore_outlined),
        activeIcon: const Icon(Icons.explore),
        label: 'bottom_nav.explore'.tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.menu_book_outlined),
        activeIcon: const Icon(Icons.menu_book),
        label: 'bottom_nav.journey'.tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings_outlined),
        activeIcon: const Icon(Icons.settings),
        label: 'bottom_nav.settings'.tr(),
      ),
    ],
  ),
),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/app/shell/main_screen_nav_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze + commit**

```bash
fvm flutter analyze --fatal-infos
git add lib/app/shell/main_screen.dart test/app/shell/main_screen_nav_test.dart
git commit -m "feat(shell): re-skin bottom nav for field-journal theme"
```

---

## Task 12: Full suite + manual verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full analyzer**

Run: `fvm flutter analyze --fatal-infos`
Expected: No issues. (If the old dark `AppColors` is now unused anywhere, that
is fine — it stays for screens not yet migrated.)

- [ ] **Step 2: Run the full test suite**

Run: `fvm flutter test`
Expected: All tests pass. Investigate any failure caused by screens that
hard-coded dark colours or assumed `ThemeMode.dark`; if a pre-existing test
asserted the dark theme, update it to the new light expectation (note it in the
commit).

- [ ] **Step 3: Manual smoke (real app)**

Launch the app (use the `/run` skill or `fvm flutter run`). Verify:
- App opens on a warm paper background (no dark Midnight backdrop).
- Bottom nav: paper surface, clay selected tab.
- Settings → 外觀: switching 主色 / 閱讀介面 / 標題字體 re-skins the chrome live
  (accent colour changes on the selected nav tab and buttons; headline font
  toggles serif/sans on titles).
- No dark-theme remnants on global chrome or the settings screen.

- [ ] **Step 4: Commit any test fixes**

```bash
git add -A
git commit -m "test: align existing tests with field-journal light theme"
```

(Skip if nothing changed.)

---

## Self-Review Notes

- **Spec coverage:** tokens (T2), single light theme (T6+T7), Noto Serif/Sans
  typography (T6), appearance persistence + apply (T4+T5+T7), Settings UI (T10),
  global chrome re-skin (T7 backdrop removal + T11 nav + T6 app-bar theme),
  CategoryTag/GlyphThumb/PlaceCategory primitives (T3+T8+T9). Dark theme removed
  (T6+T7). All foundation spec sections map to a task.
- **Out of scope honoured:** no screen-body migration; midnight widgets not
  deleted (only the dark `AmbientBackdrop` wrapper in `app.dart` is bypassed,
  which is required for the light theme to be visible).
- **Type consistency:** `LorescapeTokens.forAppearance({accent, reading})`,
  `buildLorescapeTheme({tokens, headlineFont})`, `lorescapeThemeFor(state)`,
  `appearanceNotifierProvider` / `appearancePreferencesRepositoryProvider`,
  and the `BrandAccent`/`ReadingSurface`/`HeadlineFont` enums are used with the
  same signatures across all tasks.
- **Risk:** existing widget tests may assume the dark theme; Task 12 Step 2
  catches and fixes those.
```
