# Midnight Kyoto S1 — Theme Foundation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish Midnight Kyoto's color tokens, full Material 3 ColorScheme override, dark-only ThemeData, and pin the app to `ThemeMode.dark` while preserving the `ThemeModeNotifier` architecture for future light-theme reintroduction.

**Architecture:** Token expansion in `app_colors.dart` (~30 const colors); full ColorScheme + component themes in `theme_config.dart`; `app.dart` always uses `ThemeMode.dark`; `ThemeModeNotifier` keeps SharedPreferences plumbing but its `state` reads as `ThemeMode.dark` regardless of saved value; settings UI removes the toggle tile.

**Tech Stack:** Dart, Flutter, Material 3, Riverpod, SharedPreferences, easy_localization.

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s1-foundation-design.md`

---

## File Structure

### Modified
- `frontend/lib/common/config/app_colors.dart` (expand)
- `frontend/lib/common/config/theme_config.dart` (rewrite)
- `frontend/lib/app.dart` (lock themeMode)
- `frontend/lib/features/settings/presentation/controllers/theme_mode_notifier.dart` (pin to dark)
- `frontend/lib/features/settings/presentation/screens/settings_screen.dart` (remove `_ThemeModeTile`)
- `frontend/test/features/settings/presentation/screens/settings_screen_test.dart` (remove theme-toggle assertions)

### Created
- `frontend/test/common/config/theme_config_test.dart`
- `frontend/test/features/settings/presentation/controllers/theme_mode_notifier_test.dart`

---

## Commands reference

- Run a test file: `cd frontend && fvm flutter test <path>`
- Run all tests: `cd frontend && fvm flutter test`
- Static analysis: `cd frontend && fvm flutter analyze --fatal-infos`

---

## Task A1: Expand `app_colors.dart`

**Files:**
- Modify: `frontend/lib/common/config/app_colors.dart`

Add the full Midnight Kyoto token set as `const Color`. Keep existing constants in place (don't remove `surfaceDarkPlayer`, `surfaceDarkConfig`, `success`, `amber`, `errorBg` etc.) — those are consumed by 31 call sites and will be cleaned up in S3.

- [ ] **Step 1: Replace file contents**

```dart
import 'package:flutter/material.dart';

/// Midnight Kyoto color tokens.
///
/// Names follow Material 3 conventions where possible. Legacy aliases
/// (`surfaceDarkPlayer`, `surfaceDarkConfig`, `surfaceDarkCard`,
/// `success`, `amber`, `errorBg`) are kept for backwards-compat with
/// existing screens; they will be replaced in S3.
class AppColors {
  AppColors._();

  // --- Brand primary (electric blue) ---
  static const Color primary = Color(0xFF137FEC);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0x33137FEC); // primary @ 20%
  static const Color onPrimaryContainer = Color(0xFFA8C8FF);
  static const Color primaryFixed = Color(0xFFD5E3FF);
  static const Color primaryFixedDim = Color(0xFFA8C8FF);
  static const Color onPrimaryFixed = Color(0xFF001B3C);
  static const Color onPrimaryFixedVariant = Color(0xFF004689);
  static const Color inversePrimary = Color(0xFF005EB4);
  static const Color surfaceTint = Color(0xFF137FEC);

  // --- Secondary (soft blue) ---
  static const Color secondary = Color(0xFFADC8F7);
  static const Color onSecondary = Color(0xFF123158);
  static const Color secondaryContainer = Color(0xFF2C4770);
  static const Color onSecondaryContainer = Color(0xFF9BB6E5);
  static const Color secondaryFixed = Color(0xFFD5E3FF);
  static const Color secondaryFixedDim = Color(0xFFADC8F7);
  static const Color onSecondaryFixed = Color(0xFF001B3C);
  static const Color onSecondaryFixedVariant = Color(0xFF2C4770);

  // --- Tertiary (warm orange) ---
  static const Color tertiary = Color(0xFFFFB68C);
  static const Color onTertiary = Color(0xFF532200);
  static const Color tertiaryContainer = Color(0xFFE47019);
  static const Color onTertiaryContainer = Color(0xFF481D00);
  static const Color tertiaryFixed = Color(0xFFFFDBC9);
  static const Color tertiaryFixedDim = Color(0xFFFFB68C);
  static const Color onTertiaryFixed = Color(0xFF321200);
  static const Color onTertiaryFixedVariant = Color(0xFF753400);

  // --- Surface ladder (dark to light navy-grey) ---
  static const Color backgroundDark = Color(0xFF101922);
  static const Color surfaceDim = Color(0xFF0D141B);
  static const Color surfaceContainerLowest = Color(0xFF0B1117);
  static const Color surfaceContainerLow = Color(0xFF151E27);
  static const Color surfaceContainer = Color(0xFF1C2630);
  static const Color surfaceContainerHigh = Color(0xFF27313C);
  static const Color surfaceContainerHighest = Color(0xFF323C48);
  static const Color surfaceBright = Color(0xFF222D39);
  /// Glass card primary fill (white at 8% opacity).
  static const Color surfaceVariant = Color(0x14FFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFC1C6D5);
  static const Color inverseSurface = Color(0xFFE0E2EC);
  static const Color inverseOnSurface = Color(0xFF2D3038);
  static const Color onBackground = Color(0xFFFFFFFF);

  // --- Outline (ghost border) ---
  static const Color outline = Color(0xFF8B919F);
  /// Ghost border (white at 10% opacity).
  static const Color outlineVariant = Color(0x1AFFFFFF);

  // --- Error ---
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // --- Convenience aliases ---
  /// Same as [outlineVariant]; kept under the old name for legacy callers.
  static const Color glassBorder = outlineVariant;
  static const Color white10 = outlineVariant;
  static const Color white20 = Color(0x33FFFFFF);
  static const Color black20 = Color(0x33000000);

  // --- Legacy (S3 will remove these) ---
  @Deprecated('Use surfaceContainer; will be removed in S3.')
  static const Color surfaceDark = surfaceContainer;
  @Deprecated('Use surfaceContainer; will be removed in S3.')
  static const Color surfaceDarkPlayer = Color(0xFF182430);
  @Deprecated('Use surfaceContainer; will be removed in S3.')
  static const Color surfaceDarkConfig = Color(0xFF192633);
  @Deprecated('Use surfaceContainer; will be removed in S3.')
  static const Color surfaceDarkCard = Color(0xFF1C2732);
  @Deprecated('Use a tertiary or new token; will be removed in S3.')
  static const Color success = Color(0xFF10B981);
  @Deprecated('Use a tertiary or new token; will be removed in S3.')
  static const Color amber = Color(0xFFF59E0B);
  @Deprecated('Use errorContainer or your own opacity; will be removed in S3.')
  static const Color errorBg = Color(0x1AF44336);

  // --- Legacy text aliases ---
  @Deprecated('Use onSurface (dark theme is now mandatory).')
  static const Color textPrimaryLight = Color(0xFF0F172A);
  @Deprecated('Use onSurfaceVariant (dark theme is now mandatory).')
  static const Color textSecondaryLight = Color(0xFF64748B);
  @Deprecated('Use onSurface; will be removed in S3.')
  static const Color textPrimaryDark = onSurface;
  @Deprecated('Use onSurfaceVariant; will be removed in S3.')
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  @Deprecated('Use onSurfaceVariant; will be removed in S3.')
  static const Color textTertiaryDark = Colors.white60;
  @Deprecated('Use onSurfaceVariant; will be removed in S3.')
  static const Color textQuaternaryDark = Colors.white54;

  @Deprecated('Light theme retired; use backgroundDark.')
  static const Color backgroundLight = Color(0xFFF6F7F8);
}
```

- [ ] **Step 2: Run analyzer**

```
cd frontend && fvm flutter analyze --fatal-infos lib/common/config/app_colors.dart
```

Expected: No issues. (Deprecated annotations don't trigger info issues at the declaration site.)

- [ ] **Step 3: Run full test suite to confirm 31 callers still compile**

```
cd frontend && fvm flutter test
```

Expected: all tests pass. Any deprecation warning at call sites is INFO and shouldn't fail the build (will still pass `--fatal-infos` because deprecation lint isn't info by default).

If `--fatal-infos` fails on a deprecation warning at a call site, **stop and report BLOCKED** — that's a flag we need to address before proceeding.

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore && \
  git add frontend/lib/common/config/app_colors.dart && \
  git commit -m "feat(theme): expand AppColors with Midnight Kyoto token palette"
```

---

## Task A2: Rewrite `theme_config.dart`

**Files:**
- Modify: `frontend/lib/common/config/theme_config.dart`
- Create: `frontend/test/common/config/theme_config_test.dart`

Replace `lightTheme`/`darkTheme` with a single Midnight Kyoto dark theme. `lightTheme` getter remains for architectural reasons but returns `darkTheme` as a placeholder.

- [ ] **Step 1: Write failing test first**

Create `frontend/test/common/config/theme_config_test.dart`:

```dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/common/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeConfig.darkTheme', () {
    final theme = ThemeConfig.darkTheme;

    test('uses Midnight Kyoto primary as colorScheme.primary', () {
      expect(theme.colorScheme.primary, AppColors.primary);
    });

    test('uses backgroundDark as scaffoldBackgroundColor', () {
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
    });

    test('uses backgroundDark as colorScheme.surface', () {
      expect(theme.colorScheme.surface, AppColors.backgroundDark);
    });

    test('cardTheme has no border (no-line rule)', () {
      final shape = theme.cardTheme.shape;
      expect(shape, isA<RoundedRectangleBorder>());
      final rounded = shape! as RoundedRectangleBorder;
      expect(rounded.side.width, 0.0);
    });

    test('elevatedButtonTheme uses StadiumBorder (pill shape)', () {
      final shape = theme.elevatedButtonTheme.style?.shape?.resolve({});
      expect(shape, isA<StadiumBorder>());
    });

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('brightness is dark', () {
      expect(theme.brightness, Brightness.dark);
    });
  });

  group('ThemeConfig.lightTheme', () {
    test('is a placeholder that returns darkTheme', () {
      // Light theme is intentionally not implemented yet; getter exists
      // for architectural symmetry per S1 spec.
      expect(
        ThemeConfig.lightTheme.colorScheme.primary,
        ThemeConfig.darkTheme.colorScheme.primary,
      );
    });
  });
}
```

- [ ] **Step 2: Run test, expect failure**

```
cd frontend && fvm flutter test test/common/config/theme_config_test.dart
```

Expected: Most tests fail (current darkTheme uses fromSeed, has bordered cards, ElevatedButton is rounded rect, lightTheme is different from darkTheme).

- [ ] **Step 3: Replace `theme_config.dart` entirely**

```dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';

/// Theme configuration for the application.
///
/// Provides the Midnight Kyoto dark theme. The light theme getter is
/// retained as a placeholder (returns dark theme) so future
/// re-introduction of a light variant is a drop-in change.
class ThemeConfig {
  ThemeConfig._();

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.backgroundDark,
    onSurface: AppColors.onSurface,
    surfaceDim: AppColors.surfaceDim,
    surfaceBright: AppColors.surfaceBright,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.inversePrimary,
    surfaceTint: AppColors.surfaceTint,
  );

  /// Midnight Kyoto dark theme.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // Typography — Midnight Kyoto editorial rhythm
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: AppColors.onSurface,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: AppColors.onSurface,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: AppColors.onSurfaceVariant,
        ),
        bodySmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),

      // AppBar — transparent with bold uppercase title
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.onSurface,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      // Cards — glass-style: no border, glass-variant background
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceVariant,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide.none,
        ),
      ),

      // Buttons — pill-shaped (StadiumBorder)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: const StadiumBorder(),
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shape: StadiumBorder(),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      // Chips — stadium with surfaceContainerHigh background
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        selectedColor: AppColors.primaryContainer,
        side: const BorderSide(color: AppColors.outlineVariant),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.onPrimaryContainer,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Dividers — ghost lines
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 0.5,
        space: 0.5,
      ),

      // Bottom navigation — transparent so backdrop blur reads through
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Light theme placeholder.
  ///
  /// Currently returns [darkTheme]. The getter is retained so that
  /// future light-theme work is a localised change inside this method
  /// without touching `MaterialApp` or callers.
  static ThemeData get lightTheme => darkTheme;
}
```

- [ ] **Step 4: Run tests, expect pass**

```
cd frontend && fvm flutter test test/common/config/theme_config_test.dart
```

Expected: 8/8 PASS.

- [ ] **Step 5: Run analyzer**

```
cd frontend && fvm flutter analyze --fatal-infos lib/common/config/theme_config.dart test/common/config/theme_config_test.dart
```

Expected: No issues.

- [ ] **Step 6: Commit**

```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore && \
  git add frontend/lib/common/config/theme_config.dart \
    frontend/test/common/config/theme_config_test.dart && \
  git commit -m "refactor(theme): rewrite ThemeConfig as Midnight Kyoto dark theme"
```

---

## Task A3: Pin `themeMode` and update `ThemeModeNotifier`

**Files:**
- Modify: `frontend/lib/app.dart`
- Modify: `frontend/lib/features/settings/presentation/controllers/theme_mode_notifier.dart`
- Create: `frontend/test/features/settings/presentation/controllers/theme_mode_notifier_test.dart`

- [ ] **Step 1: Write notifier test**

Create `frontend/test/features/settings/presentation/controllers/theme_mode_notifier_test.dart`:

```dart
import 'package:context_app/features/settings/presentation/controllers/theme_mode_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeModeNotifier', () {
    test('always exposes ThemeMode.dark even with saved light value',
        () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Allow async _loadFromPrefs to complete.
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('setThemeMode persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Trigger build.
      container.read(themeModeProvider);

      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('exposed state stays ThemeMode.dark after setThemeMode(light)',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider);

      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
```

- [ ] **Step 2: Run test, expect failure**

```
cd frontend && fvm flutter test test/features/settings/presentation/controllers/theme_mode_notifier_test.dart
```

Expected: failure on tests 1 and 3 (current notifier exposes saved value, not pinned dark).

- [ ] **Step 3: Update `theme_mode_notifier.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

/// Manages the app's [ThemeMode] and persists it to SharedPreferences.
///
/// The app is currently locked to [ThemeMode.dark] (Midnight Kyoto).
/// This notifier still reads/writes the SharedPreferences key so the
/// architecture is intact for future re-introduction of a light theme:
///
/// 1. Implement [ThemeConfig.lightTheme] with a real light variant.
/// 2. In `app.dart`, replace `themeMode: ThemeMode.dark` with
///    `themeMode: ref.watch(themeModeProvider)`.
/// 3. Restore the toggle UI in settings_screen.
/// 4. Remove the override in [build] so the saved value is honoured.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _dark = 'dark';
  static const _light = 'light';
  static const _system = 'system';

  @override
  ThemeMode build() {
    // Still load the persisted value so future light-theme work picks
    // it up automatically — but always expose dark for now.
    _loadFromPrefs();
    return ThemeMode.dark;
  }

  /// Persists the user's preference. The exposed [state] stays
  /// [ThemeMode.dark] until the app's light theme is re-enabled.
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _encode(mode));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Read but ignore — kept so the value survives across upgrades and
    // is available the moment the override is removed.
    prefs.getString(_kThemeModeKey);
  }

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => _dark,
        ThemeMode.light => _light,
        ThemeMode.system => _system,
      };
}
```

- [ ] **Step 4: Run notifier test**

```
cd frontend && fvm flutter test test/features/settings/presentation/controllers/theme_mode_notifier_test.dart
```

Expected: 3/3 PASS.

- [ ] **Step 5: Update `app.dart`**

In `frontend/lib/app.dart`:

Replace lines around 25 and 80–82:

Remove:
```dart
final themeMode = ref.watch(themeModeProvider);
```

(That single `final themeMode` line — leave the surrounding code intact.)

In the `MaterialApp.router(...)` constructor, replace:
```dart
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: themeMode,
```

With:
```dart
      theme: ThemeConfig.darkTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.dark,
```

(Both `theme` and `darkTheme` set to dark so any unexpected `themeMode` flip in subsystems still renders Midnight Kyoto.)

- [ ] **Step 6: Run analyzer + tests**

```
cd frontend && fvm flutter analyze --fatal-infos lib/app.dart lib/features/settings/presentation/controllers/theme_mode_notifier.dart test/features/settings/presentation/controllers/theme_mode_notifier_test.dart
```

Expected: No issues.

```
cd frontend && fvm flutter test
```

Expected: full suite passes (settings_screen_test may still pass — it doesn't necessarily exercise the toggle directly; if it fails on a toggle assertion, that gets fixed in Task A4).

If a settings widget test fails specifically on the theme toggle, **proceed to Task A4 first** — don't try to fix it in this commit. Otherwise commit now.

- [ ] **Step 7: Commit**

```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore && \
  git add frontend/lib/app.dart \
    frontend/lib/features/settings/presentation/controllers/theme_mode_notifier.dart \
    frontend/test/features/settings/presentation/controllers/theme_mode_notifier_test.dart && \
  git commit -m "feat(theme): lock MaterialApp to ThemeMode.dark"
```

---

## Task A4: Remove `_ThemeModeTile` from settings

**Files:**
- Modify: `frontend/lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `frontend/test/features/settings/presentation/screens/settings_screen_test.dart` (if needed)

- [ ] **Step 1: Edit `settings_screen.dart`**

(a) In the `_SectionContainer` for preferences (around line 38–44), remove the `_Divider()` and `_ThemeModeTile()` lines. Should leave just `_LanguageTile`:

Before:
```dart
          _SectionContainer(
            children: [
              _LanguageTile(controller: controller),
              _Divider(),
              const _ThemeModeTile(),
            ],
          ),
```

After:
```dart
          _SectionContainer(
            children: [
              _LanguageTile(controller: controller),
            ],
          ),
```

(b) Delete the entire `_ThemeModeTile` widget class (currently around lines 196–244).

(c) Remove the import `import 'package:context_app/features/settings/providers.dart';` IF after the removal there are no other usages of `themeModeProvider` in the file. Verify with grep first; if `settingsControllerProvider` is also from that file, keep the import.

- [ ] **Step 2: Run analyzer**

```
cd frontend && fvm flutter analyze --fatal-infos lib/features/settings/presentation/screens/settings_screen.dart
```

Expected: No issues. If there are unused imports, remove them.

- [ ] **Step 3: Run settings widget test**

```
cd frontend && fvm flutter test test/features/settings/presentation/screens/settings_screen_test.dart
```

If this fails because the existing test asserts the theme toggle exists or interacts with it: locate those assertions and either delete them entirely (if the whole test was about the toggle) or strip the toggle-related part from the assertion. Don't introduce new test cases — just remove ones for the deleted UI.

- [ ] **Step 4: Run full suite**

```
cd frontend && fvm flutter test
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/PLRepo/instant_explore && \
  git add frontend/lib/features/settings/presentation/screens/settings_screen.dart \
    frontend/test/features/settings/presentation/screens/settings_screen_test.dart && \
  git commit -m "feat(settings): remove theme-mode toggle (dark-only)"
```

---

## Task A5: Final sweep

- [ ] **Step 1: Full analyzer run**

```
cd frontend && fvm flutter analyze --fatal-infos
```

Expected: No issues across the whole frontend.

- [ ] **Step 2: Full test run**

```
cd frontend && fvm flutter test
```

Expected: all pass (347+ tests).

- [ ] **Step 3: If both green, S1 complete** — no commit needed (this task only verifies).

---

## Self-Review

**Spec coverage:**
- ✅ Token expansion → Task A1
- ✅ Full M3 ColorScheme override → Task A2
- ✅ Component themes (cards, buttons, chips, inputs, dividers, bottom nav, dialog) → Task A2
- ✅ MaterialApp.themeMode pinned to dark → Task A3
- ✅ ThemeModeNotifier preserved architecture → Task A3
- ✅ Settings UI cleanup → Task A4
- ✅ ThemeConfigTest → Task A2
- ✅ ThemeModeNotifier test → Task A3

**Placeholder scan:** No "TBD"/"TODO"/"similar to". All code blocks show full content.

**Type consistency:** `_ThemeModeTile` removal in Task A4 matches reference at line 42 of `settings_screen.dart`. `themeModeProvider` rename — wait, the import is `'package:context_app/features/settings/providers.dart'` and the provider is `themeModeProvider`. Confirm by grep before editing in case the test fails for that reason.

S2 and S3 are out of scope; they are already noted in the spec.
