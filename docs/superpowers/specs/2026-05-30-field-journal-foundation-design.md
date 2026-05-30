# Field Journal Redesign — Foundation (Sub-project 1)

_Date: 2026-05-30_

## Background

Lorescape currently uses the dark **Midnight Kyoto** theme (electric blue
`#137FEC`, glass cards, dark navy surfaces, `themeMode: dark` hard-wired in
`app.dart`). A new design handoff from Claude Design pivots the entire app to a
warm, light **Field Journal**（地誌手記）literary language: cream paper
surfaces, terracotta（陶土）accents, Noto Serif TC headlines, refined
five-category colour system.

The redesign is delivered **foundation-first, migrated incrementally**. This
spec covers **only the foundation**. Each screen migration (stories feed,
reader, explore, history, settings, paywall, …) is a separate later cycle with
its own spec → plan.

### Approved decisions

- **Fully replace** the dark Midnight theme with a single warm light theme.
- **Keep the Tweaks switching** (accent / reading surface / headline font) as a
  real user-facing feature — surfaced in a Settings「外觀」section, NOT the
  prototype's floating dev panel.
- Fonts via `google_fonts` runtime download (matches existing usage).
- Old `lib/shared/widgets/midnight/` components are NOT deleted in the
  foundation cycle; they are retired per-screen as each screen migrates.

## Goals

1. Establish the warm token system as a `ThemeExtension` switchable at runtime.
2. Build a single `ThemeData` from those tokens replacing the dark theme.
3. Apply Noto Serif TC headline / Noto Sans TC body typography.
4. Persist and apply user appearance choices (accent / reading / font).
5. Add an Appearance section to Settings to drive those choices.
6. Re-skin global chrome (bottom nav, app bar) to the new language.
7. Ship genuinely cross-feature primitives: `CategoryTag`, `GlyphThumb`,
   `PlaceCategory`.

Non-goals (explicitly deferred to later cycles): migrating any feature
*screen's* body content, the reader, timeline, paywall, place-story flow, or
deleting midnight widgets.

## Source of truth — design tokens

From `ls2.css` and `app.jsx` of the handoff bundle.

### Paper / ink / line (base light surfaces)

| Token | Hex |
|-------|-----|
| paper | `#F7F1E6` |
| paper-raised | `#FDFAF3` |
| paper-sunk | `#ECE3D3` |
| line | `#E4DAC8` |
| line-strong | `#CDBFA6` |
| ink | `#221C14` |
| ink-2 | `#5E5341` |
| ink-3 | `#918471` |

### Dark surfaces (used by immersive screens / night reading / paywall later)

| Token | Hex |
|-------|-----|
| ink-bg | `#1B1611` |
| ink-bg-2 | `#251E17` |
| ink-bg-3 | `#312820` |
| on-dark | `#F7F1E6` |
| on-dark-2 | `#C3B7A4` |
| on-dark-3 | `#8C8170` |
| line-dark | `rgba(247,241,230,.12)` |

### Category palette (muted, refined) — five categories

| Category | ink | bg | glyph |
|----------|-----|----|----|
| nature 自然景觀 | `#4E6138` | `#E6E8D5` | mountain |
| heritage 人文古蹟 | `#8A6320` | `#F0E5CC` | columns |
| urban 城市地標 | `#44597A` | `#DFE4EC` | building |
| coast 海岸水域 | `#2F6566` | `#D9E7E4` | waves |
| sacred 信仰聖地 | `#6E4A63` | `#ECDCE6` | book-marker |

### Radius / shadow

- radii: sm 8, md 12, lg 16, xl 22, img 10, pill 999
- e1: `0 1px 2px rgba(40,30,18,.06)`
- e2: `0 6px 18px rgba(40,30,18,.09)`
- e3: `0 18px 44px rgba(28,20,10,.20)`

### Switchable: accent (brand) — 3 options

| Accent | clay | deep | soft | tint |
|--------|------|------|------|------|
| terracotta (default) | `#BC5E3E` | `#97442A` | `#F1DDCE` | `#F7E8DD` |
| amber | `#B7842B` | `#8A5F18` | `#F0E5C8` | `#F6EED8` |
| sage | `#5F7148` | `#46542F` | `#E3E8D3` | `#EBEFE0` |

### Switchable: reading surface — 3 options

| Reading | bg | ink | dim | line |
|---------|----|----|----|----|
| paper (default) | `#F7F1E6` | `#221C14` | `#5E5341` | `#E4DAC8` |
| sepia | `#EFE2CB` | `#2A2013` | `#6A5A3E` | `#DDCBA8` |
| night | `#1B1611` | `#E9E1D2` | `#9A8E7B` | `rgba(247,241,230,.14)` |

Reading `cap`（drop-cap colour）= accent `deep`.

### Switchable: headline font — 2 options

- `serif` (default): Noto Serif TC
- `sans`: Noto Sans TC

## Architecture

Lives under `lib/app/config/` (theme) + `lib/shared/widgets/journal/`
(primitives) + a new appearance feature slice. Dependency direction respects
the project rules (`app/` and `shared/` do not depend on `features/`).

### Units

1. **`LorescapeTokens` (`lib/app/config/lorescape_tokens.dart`)** — a
   `ThemeExtension<LorescapeTokens>` carrying every token above as `Color` /
   `double` / `List<BoxShadow>` fields, plus the category map and the active
   reading-surface fields. Implements `copyWith` and `lerp`. This is the single
   object widgets read via `Theme.of(context).extension<LorescapeTokens>()!`.
   - What it does: holds resolved design-token values for the current
     accent + reading surface.
   - How to use: read it in any widget for warm colours/radii/shadows.
   - Depends on: nothing (pure data).

2. **`AppearanceState` + `AppearanceNotifier`
   (`lib/features/settings/.../appearance_controller.dart` +
   `providers.dart`)** — Riverpod `StateNotifier` holding `accent`,
   `readingSurface`, `headlineFont` enums. Loads from / persists to
   `shared_preferences`. Exposes setters used by the Appearance UI.
   - Lives in the settings feature (it is appearance preference state).
   - Depends on: `shared_preferences`.

3. **`buildLorescapeTheme(LorescapeTokens tokens, {required headlineFont})`
   (`lib/app/config/theme_config.dart`, replacing the dark theme)** — pure
   function producing `ThemeData` from tokens: scaffold = paper; `ColorScheme`
   (light) mapped from tokens (primary = clay, surface = paper, etc.);
   `TextTheme` from the type scale using Noto Serif TC / Noto Sans TC; component
   themes for ElevatedButton (clay primary), OutlinedButton (ghost), Card,
   InputDecoration, Chip, BottomNavigationBar (paper blur + clay selected),
   AppBar (centered serif), Dialog, FAB (clay). Registers `LorescapeTokens` in
   `extensions`.

4. **App wiring (`lib/app.dart`)** — `MaterialApp` reads `AppearanceNotifier`,
   resolves `LorescapeTokens` for the active accent/reading, builds the theme,
   sets `theme` only and `themeMode: ThemeMode.light`. Remove the dark theme
   references.

5. **Typography scale (inside `theme_config.dart`)** — map the design's scale:
   displayLarge 34/serif/w700, headline/story title 24/serif/w700, titleLarge
   18/serif, body 16 serif for reading contexts vs 14–16 sans for UI, overline
   11/uppercase/.18em. Reader-specific 18.5 line-height 1.92 is applied by the
   reader screen later, not the global theme.

6. **`PlaceCategory` (`lib/shared/widgets/journal/place_category.dart`)** —
   enum `{ nature, heritage, urban, coast, sacred }` with `label`(zh),
   `glyph`(icon), `ink`, `bg`. Source of category visuals for tags & glyph
   thumbs.

7. **`CategoryTag` (`lib/shared/widgets/journal/category_tag.dart`)** — pill
   tag: 28px height, category bg/ink, glyph + label; `onPhoto` variant (dark
   translucent over images).

8. **`GlyphThumb` (`lib/shared/widgets/journal/glyph_thumb.dart`)** — square
   placeholder for photoless places: category bg fill + centered category glyph.

9. **Journal line-icon set** — the design uses a custom 24×24 line-icon set
   (mountain, columns, building, waves, book-marker, compass, book-open, gem,
   sparkle, …). Foundation ships only the icons the foundation primitives need
   (the 5 category glyphs + bottom-nav icons book-open/compass/book/settings).
   Remaining icons are added as their screens migrate. Implemented as an
   `IconData`-or-custom mapping; prefer existing Material icons where a faithful
   match exists, custom `CustomPainter`/SVG-path icons only where Material has
   no close equivalent.

10. **Settings Appearance section
    (`lib/features/settings/.../appearance_section.dart`)** — a Settings group
    「外觀」with three segmented controls (主色 / 閱讀介面 / 標題字體) bound to
    `AppearanceNotifier`. Reuses the design's segmented-control styling.

11. **Global chrome** — `lib/app/shell/main_screen.dart` bottom nav re-skinned
    (paper translucent blur, line top border, clay selected, journal icons,
    labels 故事/探索/歷程/設定). Global AppBar theme already handled by (3).

## Data flow

```
AppearanceNotifier (persisted prefs)
        │ accent / reading / font
        ▼
app.dart resolves LorescapeTokens(accent, reading)
        │
        ▼
buildLorescapeTheme(tokens, headlineFont) → ThemeData (+ LorescapeTokens ext)
        │
        ▼
MaterialApp(theme) → all screens read Theme.of(context) + .extension<LorescapeTokens>()
```

Changing a tweak in Settings → notifier updates → prefs persist → MaterialApp
rebuilds with new theme → whole app re-skins live.

## Error handling

- `shared_preferences` read failure → fall back to defaults (terracotta /
  paper / serif); never block startup.
- Unknown persisted enum string → default for that field.
- `google_fonts` offline → google_fonts falls back to bundled/system; acceptable.

## Testing

- **Unit**: `AppearanceNotifier` — defaults, set each field, persistence
  round-trip (fake `SharedPreferences`); `LorescapeTokens.lerp`/`copyWith`;
  accent/reading enum → token resolution.
- **Widget**: `CategoryTag` renders correct colour/label/glyph per category and
  the `onPhoto` variant; `GlyphThumb` per category; Appearance section
  segmented controls call the right setter; bottom nav shows 4 labelled tabs
  with clay selected colour. Follow `flutter-widget-tests` project conventions
  (BDD naming, pump helpers, fakes over mocks).
- **Manual**: launch app, toggle each appearance option, confirm live re-skin
  with no dark-theme remnants on the global chrome / settings screen.

## Out of scope (later cycles)

Migrating screen bodies (stories, reader, explore + sheets, place-story flow,
history timeline + trips, create-trip + date picker, settings rows beyond
Appearance, paywall) and deleting midnight widgets.
