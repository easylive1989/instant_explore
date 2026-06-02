# 播放頁改造成 Editorial Reader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把導覽播放頁 (`NarrationScreen`) 從強制夜間黑改成暖色紙質 editorial reader，並在可捲動內容最上方加入帶故事標題的 hero 圖片。

**Architecture:** 抽出共用的 `EditorialHeroBackground` 供故事選擇頁與播放頁共用；把故事標題從故事選擇頁經 router 傳進播放頁；播放頁移除夜間 token 覆寫、改用環境暖紙 `ReadingPalette`；hero 作為轉錄 `ListView` 的第一個項目（跟著捲走）；第一段加上內嵌近似的 drop cap。

**Tech Stack:** Flutter / Dart、Riverpod、go_router、google_fonts、cached_network_image、flutter_test（widget tests）。

**Branch:** 在功能分支 `feat/narration-editorial-reader` 上進行（非直接推 master），完成後開 PR。

**設計來源：** `docs/superpowers/specs/2026-06-02-narration-player-editorial-reader-design.md`

**通用指令：**
- 所有指令在 `frontend/` 目錄下執行，使用 `fvm`。
- 每個 Task 結尾都要跑 `fvm flutter analyze --fatal-infos` 且零問題才能 commit。

---

## Task 1: 抽出共用的 EditorialHeroBackground 與 scrim

把目前藏在 `select_story_hook_screen.dart` 的 hero 背景元件抽成可共用的 widget，讓播放頁也能用。這是行為不變的重構。

**Files:**
- Create: `frontend/lib/features/narration/presentation/widgets/editorial_hero.dart`
- Create: `frontend/test/features/narration/presentation/widgets/editorial_hero_test.dart`
- Modify: `frontend/lib/features/narration/presentation/screens/select_story_hook_screen.dart`

- [ ] **Step 1: 寫失敗測試**

建立 `frontend/test/features/narration/presentation/widgets/editorial_hero_test.dart`：

```dart
import 'package:context_app/features/narration/presentation/widgets/editorial_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('EditorialHeroBackground', () {
    testWidgets(
      'given a place with no photo, when rendered, '
      'then it falls back to a category glyph (an Icon), not a network image',
      (tester) async {
        await pumpScreen(
          tester,
          child: EditorialHeroBackground(place: buildPlace()),
        );

        expect(find.byType(Icon), findsOneWidget);
      },
    );
  });
}
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `fvm flutter test test/features/narration/presentation/widgets/editorial_hero_test.dart`
Expected: 編譯失敗（`editorial_hero.dart` 不存在 / `EditorialHeroBackground` 未定義）。

- [ ] **Step 3: 建立共用 widget**

建立 `frontend/lib/features/narration/presentation/widgets/editorial_hero.dart`：

```dart
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/core/services/place_image_cache_manager.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/presentation/extensions/place_category_extension.dart';
import 'package:context_app/shared/widgets/journal/journal_category.dart';
import 'package:flutter/material.dart';

/// Hero scrim (design token `.hero__scrim`): a top-and-bottom darkening so
/// overlaid back buttons and captions stay legible over any photo.
const LinearGradient kEditorialHeroScrim = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0x470F0B07),
    Color(0x000F0B07),
    Color(0x8C0F0B07),
    Color(0xEB0F0B07),
  ],
  stops: [0.0, 0.28, 0.78, 1.0],
);

/// Fills an editorial hero: a captured image if present, else the place photo,
/// else a category-tinted gradient with a centered glyph.
///
/// Draws only the background — compose the scrim ([kEditorialHeroScrim]) and any
/// caption on top inside a [Stack].
class EditorialHeroBackground extends StatelessWidget {
  final Place place;
  final Uint8List? capturedImageBytes;

  const EditorialHeroBackground({
    super.key,
    required this.place,
    this.capturedImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    if (capturedImageBytes != null) {
      return Image.memory(capturedImageBytes!, fit: BoxFit.cover);
    }

    final photoUrl = place.primaryPhoto?.url;
    final glyph = _GlyphBackground(category: place.category.journalCategory);
    if (photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        cacheManager: PlaceImageCacheManager.instance,
        placeholder: (context, url) => glyph,
        errorWidget: (context, url, error) => glyph,
      );
    }

    return glyph;
  }
}

/// Photo-less hero fill: a category-tinted dark gradient with a centered glyph
/// (design: `linear-gradient(160deg, var(--cat-*-ink), var(--ink-bg))`).
class _GlyphBackground extends StatelessWidget {
  final JournalCategory category;

  const _GlyphBackground({required this.category});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [category.ink, tokens?.inkBg ?? const Color(0xFF1B1611)],
        ),
      ),
      child: Center(
        child: Icon(
          category.icon,
          size: 34,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑測試確認通過**

Run: `fvm flutter test test/features/narration/presentation/widgets/editorial_hero_test.dart`
Expected: PASS。

- [ ] **Step 5: 改 `select_story_hook_screen.dart` 改用共用 widget**

在 import 區加入：

```dart
import 'package:context_app/features/narration/presentation/widgets/editorial_hero.dart';
```

把 `_HeroSection.build` 內的 hero 背景與 scrim 改成共用版本。將原本：

```dart
          _HeroBackground(place: place, capturedImageBytes: capturedImageBytes),
          const DecoratedBox(decoration: BoxDecoration(gradient: _kHeroScrim)),
```

改為：

```dart
          EditorialHeroBackground(
            place: place,
            capturedImageBytes: capturedImageBytes,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: kEditorialHeroScrim),
          ),
```

接著刪除此檔中已搬走、不再使用的程式碼：
- `const _kHeroScrim = LinearGradient(...)`（整段含註解）
- `class _HeroBackground extends StatelessWidget { ... }`（整個 class）
- `class _GlyphBackground extends StatelessWidget { ... }`（整個 class）

- [ ] **Step 6: 跑 analyze 並移除變為未使用的 import**

Run: `fvm flutter analyze --fatal-infos`
Expected: 可能回報 `select_story_hook_screen.dart` 中下列 import 已未使用——將它們刪除後再次執行直到零問題：
- `package:cached_network_image/cached_network_image.dart`
- `package:context_app/core/services/place_image_cache_manager.dart`
- `package:context_app/shared/widgets/journal/journal_category.dart`

（保留 `dart:typed_data`，因 `_HeroSection` 的 `capturedImageBytes` 仍是 `Uint8List?`；保留 `place_category_extension.dart`，第 ~224 行仍用到 `place.category.journalCategory`。）

- [ ] **Step 7: 跑相關測試確認無回歸**

Run: `fvm flutter test test/features/narration/presentation/screens/select_story_hook_screen_test.dart test/features/narration/presentation/widgets/editorial_hero_test.dart`
Expected: 全部 PASS。

- [ ] **Step 8: Commit**

```bash
git add frontend/lib/features/narration/presentation/widgets/editorial_hero.dart \
        frontend/test/features/narration/presentation/widgets/editorial_hero_test.dart \
        frontend/lib/features/narration/presentation/screens/select_story_hook_screen.dart
git commit -m "refactor(narration): extract shared EditorialHeroBackground widget"
```

---

## Task 2: 把故事標題傳進播放頁

新增 `NarrationScreen.storyTitle`，並從故事選擇頁經 router 帶過去。此 Task 只接通資料，尚未在畫面上使用（hero 在 Task 4 才呈現）。

**Files:**
- Modify: `frontend/lib/features/narration/presentation/screens/narration_screen.dart:42-58`
- Modify: `frontend/lib/app/config/router_config.dart:108-119`
- Modify: `frontend/lib/features/narration/presentation/screens/select_story_hook_screen.dart`
- Test: `frontend/test/features/narration/presentation/screens/select_story_hook_screen_test.dart`

- [ ] **Step 1: 新增 `NarrationScreen.storyTitle` 參數**

在 `narration_screen.dart` 的 `NarrationScreen` 加入欄位與建構子參數（先不使用）：

```dart
class NarrationScreen extends ConsumerStatefulWidget {
  final Place place;
  final NarrationContent narrationContent;

  /// 使用者所選故事鉤子的標題；用作 hero 主標題。
  /// 為 null（例如「聽預設」或從旅程時間軸進入）時，hero 改用地點名稱。
  final String? storyTitle;

  /// Whether to start playback automatically after initialisation.
  final bool autoPlay;

  const NarrationScreen({
    super.key,
    required this.place,
    required this.narrationContent,
    this.storyTitle,
    this.autoPlay = false,
  });
```

- [ ] **Step 2: router 讀取並傳遞 `storyTitle`**

在 `router_config.dart` 的 `player` route builder（約 108-119 行）改成：

```dart
          builder: (context, state) {
            final params = state.extra as Map<String, dynamic>;
            final place = params['place'] as Place;
            final narrationContent =
                params['narrationContent'] as NarrationContent;
            final autoPlay = params['autoPlay'] as bool? ?? false;
            final storyTitle = params['storyTitle'] as String?;
            return NarrationScreen(
              place: place,
              narrationContent: narrationContent,
              storyTitle: storyTitle,
              autoPlay: autoPlay,
            );
          },
```

（`redirect` 不需更動：`storyTitle` 允許為 null。）

- [ ] **Step 3: 擴充既有的「導頁到 player」測試**

`select_story_hook_screen_test.dart` 已有一個捕捉導頁 extra 的測試（約 260-311 行：
「given a router, when a hook is tapped and generation succeeds, then the player
route is pushed with the narration content」）。它把 `state.extra` 收進 `extras` 並
斷言 `extra['place'] / extra['narrationContent'] / extra['autoPlay']`。

在該測試的斷言區（`expect(extra['autoPlay'], isTrue);` 之後）新增一行，斷言 extra 帶上
所選 hook 的 title：

```dart
        expect(extra['storyTitle'], equals(_hook1.title));
```

不需新增 helper，沿用既有測試結構即可。

- [ ] **Step 4: 跑測試確認失敗**

Run: `fvm flutter test test/features/narration/presentation/screens/select_story_hook_screen_test.dart`
Expected: 新測試 FAIL（`capturedExtra['storyTitle']` 為 null，因尚未傳遞）。

- [ ] **Step 5: 故事選擇頁記住所選 title 並傳遞**

在 `_SelectStoryHookScreenState` 加入欄位：

```dart
  String? _selectedStoryTitle;
```

在 `_onHookSelected` 開頭記住所選 hook 的 title：

```dart
  void _onHookSelected(StoryHook? hook) {
    _selectedStoryTitle = hook?.title;
    // The backend is the source of truth for quota: just generate, and route
    // ...（其餘不變）
```

在 `_navigateToPlayer` 的 extra 加入 `storyTitle`：

```dart
  void _navigateToPlayer(NarrationGenerationState genState) {
    ref.read(narrationGenerationControllerProvider.notifier).reset();
    context.pushNamed(
      'player',
      extra: {
        'place': widget.place,
        'narrationContent': genState.content,
        'storyTitle': _selectedStoryTitle,
        'autoPlay': true,
      },
    );
  }
```

- [ ] **Step 6: 跑測試確認通過**

Run: `fvm flutter test test/features/narration/presentation/screens/select_story_hook_screen_test.dart`
Expected: PASS。

- [ ] **Step 7: analyze**

Run: `fvm flutter analyze --fatal-infos`
Expected: 零問題。

- [ ] **Step 8: Commit**

```bash
git add frontend/lib/features/narration/presentation/screens/narration_screen.dart \
        frontend/lib/app/config/router_config.dart \
        frontend/lib/features/narration/presentation/screens/select_story_hook_screen.dart \
        frontend/test/features/narration/presentation/screens/select_story_hook_screen_test.dart
git commit -m "feat(narration): thread selected story title into the player route"
```

---

## Task 3: 播放頁改用暖紙閱讀面

移除 `_nightReadingTokens` 強制覆寫，改用環境的 `ReadingPalette`（暖紙），狀態列圖示改深色。

**Files:**
- Modify: `frontend/lib/features/narration/presentation/screens/narration_screen.dart:20-37,109-182`
- Test: `frontend/test/features/narration/presentation/screens/narration_screen_test.dart`

- [ ] **Step 1: 寫失敗測試**

在 `narration_screen_test.dart` 的 `group('NarrationScreen', ...)` 內新增：

```dart
    testWidgets(
      'given the player loads, when rendered, '
      'then the reading surface is warm paper, not night black',
      (tester) async {
        await _givenNarrationScreen(
          tester,
          place: buildPlace(name: 'Kinkaku-ji'),
          content: buildNarrationContent(),
        );

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(const Color(0xFFEFE2CB)));
        expect(scaffold.backgroundColor, isNot(const Color(0xFF1B1611)));
      },
    );
```

> 說明：測試的 `pumpScreen` 用預設 Material theme、未註冊 `LorescapeTokens`，故 `ReadingPalette.of(context).readBg` 回退為 `0xFFEFE2CB`。實機有 tokens 時為 `#F7F1E6`。

- [ ] **Step 2: 跑測試確認失敗**

Run: `fvm flutter test test/features/narration/presentation/screens/narration_screen_test.dart`
Expected: 新測試 FAIL（背景目前是夜間黑 `0xFF1B1611`）。

- [ ] **Step 3: 移除夜間覆寫**

刪除 `narration_screen.dart` 頂部的 `_nightReadingTokens` 函式（約 20-37 行，含 doc 註解與 `LorescapeTokens`、`appearance_options.dart` 相關 import 若變為未使用）。

把 `build` 方法中包住整頁的 `Theme(...) → Builder(...)` 包裝拆掉，直接用環境 palette。將原本：

```dart
    final theme = Theme.of(context);
    final nightTokens = _nightReadingTokens(context);
    return Theme(
      data: theme.copyWith(extensions: <ThemeExtension<dynamic>>[nightTokens]),
      child: Builder(
        builder: (context) {
          final palette = ReadingPalette.of(context);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
            child: Scaffold(
              backgroundColor: palette.readBg,
              body: Column(
                // ...
              ),
            ),
          );
        },
      ),
    );
```

改為：

```dart
    final palette = ReadingPalette.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: palette.readBg,
        body: Column(
          // ...（內層 Column 內容原封不動）
        ),
      ),
    );
```

> 注意：保留內層 `Column`、`SafeArea`、`_NarrationHeader`、`Expanded(Stack(...))`、`NarrationControlPanel` 等結構不變，只是少了外層 `Theme`/`Builder` 兩層。

- [ ] **Step 4: 跑 analyze 並清掉未使用 import**

Run: `fvm flutter analyze --fatal-infos`
Expected: 若 `lorescape_tokens.dart`、`appearance_options.dart` 在移除 `_nightReadingTokens` 後變為未使用，刪除這些 import，重跑至零問題。

- [ ] **Step 5: 跑測試確認通過**

Run: `fvm flutter test test/features/narration/presentation/screens/narration_screen_test.dart`
Expected: 全部 PASS（含既有測試）。

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/narration/presentation/screens/narration_screen.dart \
        frontend/test/features/narration/presentation/screens/narration_screen_test.dart
git commit -m "feat(narration): use warm paper reading surface in the player"
```

---

## Task 4: 在轉錄區最上方加入可捲動的 hero

讓播放頁開頭出現地點照片 + 故事標題的 hero，並隨內容捲動消失。

**Files:**
- Modify: `frontend/lib/features/narration/presentation/widgets/narration_transcript_area.dart`
- Modify: `frontend/lib/features/narration/presentation/screens/narration_screen.dart`
- Test: `frontend/test/features/narration/presentation/screens/narration_screen_test.dart`

- [ ] **Step 1: 寫失敗測試**

在 `narration_screen_test.dart` 新增兩個測試與一個 import：

```dart
import 'package:context_app/features/narration/presentation/widgets/editorial_hero.dart';
```

```dart
    testWidgets(
      'given a story title, when the player loads, '
      'then the hero shows the story title plus the place name overline',
      (tester) async {
        await _givenNarrationScreen(
          tester,
          place: buildPlace(name: 'St Peters'),
          content: buildNarrationContent(),
          storyTitle: 'The Hundred-Year Gamble',
        );

        expect(find.byType(EditorialHeroBackground), findsOneWidget);
        expect(find.text('The Hundred-Year Gamble'), findsOneWidget);
        // Place name appears in the fixed top bar AND in the hero overline.
        expect(find.text('St Peters'), findsNWidgets(2));
      },
    );

    testWidgets(
      'given no story title, when the player loads, '
      'then the hero main title falls back to the place name',
      (tester) async {
        await _givenNarrationScreen(
          tester,
          place: buildPlace(name: 'St Peters'),
          content: buildNarrationContent(),
        );

        // Place name appears in the top bar AND as the hero main title.
        expect(find.text('St Peters'), findsNWidgets(2));
      },
    );
```

並更新 `_givenNarrationScreen` helper 以支援 `storyTitle`：

```dart
Future<void> _givenNarrationScreen(
  WidgetTester tester, {
  required Place place,
  required NarrationContent content,
  bool autoPlay = false,
  String? storyTitle,
  FakeTtsService? tts,
}) async {
  final resolvedTts = tts ?? FakeTtsService();
  await pumpScreen(
    tester,
    child: NarrationScreen(
      place: place,
      narrationContent: content,
      storyTitle: storyTitle,
      autoPlay: autoPlay,
    ),
    overrides: [
      ttsServiceProvider.overrideWithValue(resolvedTts),
    ],
  );
  await tester.pump(const Duration(milliseconds: 10));
}
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `fvm flutter test test/features/narration/presentation/screens/narration_screen_test.dart`
Expected: 新測試 FAIL（找不到 `EditorialHeroBackground` / 故事標題）。

- [ ] **Step 3: 讓 `NarrationTranscriptArea` 接受 header 並全寬呈現第一項**

修改 `narration_transcript_area.dart`：

1. 新增 `header` 參數：

```dart
class NarrationTranscriptArea extends ConsumerWidget {
  final AutoScrollController scrollController;
  final Widget? header;

  const NarrationTranscriptArea({
    super.key,
    required this.scrollController,
    this.header,
  });
```

2. 把 `ListView.builder` 的 `padding` 由 `const EdgeInsets.symmetric(horizontal: 24)` 改為 `EdgeInsets.zero`；第一項改成 header（無 header 時維持原本留白），段落項目改為自帶水平 padding：

```dart
        ListView.builder(
          physics: const ClampingScrollPhysics(),
          controller: scrollController,
          padding: EdgeInsets.zero,
          itemCount: content.segments.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return header ?? const SizedBox(height: 60);
            }
            if (index == content.segments.length + 1) {
              return const SizedBox(height: 200);
            }
            final segmentIndex = index - 1;
            final segment = content.segments[segmentIndex];
            final isActive = currentSegmentIndex == segmentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TranscriptSegmentItem(
                segment: segment,
                isActive: isActive,
                scrollController: scrollController,
                index: index,
              ),
            );
          },
        ),
```

3. 移除頂部漸層遮罩（`Positioned(top: 0, ... height: 100, ...)` 整段），因為 hero 現在佔據頂部，紙色漸層蓋在照片上會不自然。**保留**底部漸層遮罩（淡入暖紙、墊在浮動音訊列上方）。

- [ ] **Step 4: 在 `narration_screen.dart` 建立並傳入 hero header**

在 import 區加入：

```dart
import 'package:context_app/features/explore/domain/models/place.dart'; // 若尚未匯入則加
import 'package:context_app/features/narration/presentation/widgets/editorial_hero.dart';
```

把 `NarrationTranscriptArea(scrollController: _scrollController)` 改為：

```dart
                                NarrationTranscriptArea(
                                  scrollController: _scrollController,
                                  header: _ReaderHero(
                                    place: widget.place,
                                    storyTitle: widget.storyTitle,
                                  ),
                                ),
```

在檔案末端新增 `_ReaderHero` widget：

```dart
/// Bounded editorial hero shown as the first item of the reader's scroll view.
///
/// Shows the place photo (or a category glyph fallback) under a scrim, captioned
/// with the story title; the place name sits above it as an overline. When no
/// story title is available the place name becomes the main title and the
/// overline is omitted.
class _ReaderHero extends StatelessWidget {
  final Place place;
  final String? storyTitle;

  const _ReaderHero({required this.place, this.storyTitle});

  @override
  Widget build(BuildContext context) {
    final hasStoryTitle =
        storyTitle != null && storyTitle!.trim().isNotEmpty;
    final title = hasStoryTitle ? storyTitle!.trim() : place.name;
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          EditorialHeroBackground(place: place),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: kEditorialHeroScrim),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasStoryTitle) ...[
                  Text(
                    place.name,
                    style: GoogleFonts.notoSerifTc(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  style: GoogleFonts.notoSerifTc(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.16,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 18,
                        offset: Offset(0, 2),
                      ),
                    ],
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

- [ ] **Step 5: 跑測試確認通過**

Run: `fvm flutter test test/features/narration/presentation/screens/narration_screen_test.dart`
Expected: 全部 PASS。

- [ ] **Step 6: analyze**

Run: `fvm flutter analyze --fatal-infos`
Expected: 零問題（注意 `narration_screen.dart` 是否已匯入 `Place`、`google_fonts`；後者既有 `_NarrationHeader` 已在用）。

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/narration/presentation/widgets/narration_transcript_area.dart \
        frontend/lib/features/narration/presentation/screens/narration_screen.dart \
        frontend/test/features/narration/presentation/screens/narration_screen_test.dart
git commit -m "feat(narration): add scrollable editorial hero to the player"
```

---

## Task 5: 首段 drop cap（內嵌近似）

讓第一段以放大紅土色首字作為 lede 強調。

**Files:**
- Modify: `frontend/lib/features/narration/presentation/widgets/transcript_segment_item.dart`
- Modify: `frontend/lib/features/narration/presentation/widgets/narration_transcript_area.dart`
- Test: `frontend/test/features/narration/presentation/widgets/transcript_segment_item_test.dart` (Create)

- [ ] **Step 1: 寫失敗測試**

建立 `frontend/test/features/narration/presentation/widgets/transcript_segment_item_test.dart`：

```dart
import 'package:context_app/features/narration/domain/models/narration_segment.dart';
import 'package:context_app/features/narration/presentation/widgets/transcript_segment_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('TranscriptSegmentItem', () {
    testWidgets(
      'given isLede is true, when rendered, then a drop cap is shown',
      (tester) async {
        await pumpScreen(
          tester,
          child: TranscriptSegmentItem(
            segment: const NarrationSegment(
              text: '五○六年四月，羅馬的春風吹拂著梵蒂岡山丘。',
              startPosition: 0,
              endPosition: 20,
            ),
            isActive: false,
            scrollController: AutoScrollController(),
            index: 1,
            isLede: true,
          ),
        );

        expect(
          find.byKey(const Key('reader-lede-dropcap')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'given isLede is false, when rendered, then no drop cap is shown',
      (tester) async {
        await pumpScreen(
          tester,
          child: TranscriptSegmentItem(
            segment: const NarrationSegment(
              text: '對儒略二世而言，這座教堂是象徵。',
              startPosition: 0,
              endPosition: 16,
            ),
            isActive: false,
            scrollController: AutoScrollController(),
            index: 2,
          ),
        );

        expect(find.byKey(const Key('reader-lede-dropcap')), findsNothing);
      },
    );
  });
}
```

> 實作備註：請先確認 `NarrationSegment` 的建構子參數名（`text` / `startPosition` / `endPosition`）與上方一致；若不同，依實際定義調整測試。

- [ ] **Step 2: 跑測試確認失敗**

Run: `fvm flutter test test/features/narration/presentation/widgets/transcript_segment_item_test.dart`
Expected: 編譯失敗（`TranscriptSegmentItem` 尚無 `isLede` 具名參數）。

- [ ] **Step 3: 在 `TranscriptSegmentItem` 實作 drop cap**

改寫 `transcript_segment_item.dart`，在頂部加入 import：

```dart
import 'package:characters/characters.dart';
```

加入 `isLede` 參數並重構 `build`：

```dart
class TranscriptSegmentItem extends StatelessWidget {
  final NarrationSegment segment;
  final bool isActive;
  final AutoScrollController scrollController;
  final int index;

  /// 是否為導讀首段：為 true 時，首字以放大的紅土色 drop cap 呈現。
  final bool isLede;

  const TranscriptSegmentItem({
    super.key,
    required this.segment,
    required this.isActive,
    required this.scrollController,
    required this.index,
    this.isLede = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReadingPalette.of(context);
    final baseStyle = isActive
        ? GoogleFonts.notoSerifTc(
            fontSize: 20,
            height: 1.9,
            fontWeight: FontWeight.w600,
            color: palette.readInk,
          )
        : GoogleFonts.notoSerifTc(
            fontSize: 18.5,
            height: 1.9,
            color: palette.readDim,
          );

    final Widget text = isLede
        ? _buildLede(baseStyle, palette)
        : Text(segment.text, style: baseStyle);

    final Widget content = isActive
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -22,
                top: 6,
                bottom: 6,
                width: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.clay,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              text,
            ],
          )
        : text;

    return AutoScrollTag(
      key: ValueKey(index),
      controller: scrollController,
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: content,
      ),
    );
  }

  /// Lede 段落：首字放大為紅土色 drop cap，內嵌於段落起始（近似 CSS 的
  /// `.reader__lede .dropcap`；Flutter 無 float，故不做文字環繞）。
  Widget _buildLede(TextStyle baseStyle, ReadingPalette palette) {
    final chars = segment.text.characters;
    if (chars.isEmpty) {
      return Text(segment.text, style: baseStyle);
    }
    final first = chars.take(1).toString();
    final rest = chars.skip(1).toString();
    final dropStyle = GoogleFonts.notoSerifTc(
      fontSize: (baseStyle.fontSize ?? 18.5) * 2.4,
      height: 1.0,
      fontWeight: FontWeight.w700,
      color: palette.readCap,
    );
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                first,
                key: const Key('reader-lede-dropcap'),
                style: dropStyle,
              ),
            ),
          ),
          TextSpan(text: rest, style: baseStyle),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 在轉錄區把第一段標記為 lede**

於 `narration_transcript_area.dart`（Task 4 已加水平 padding 的段落項目）把 `TranscriptSegmentItem` 加上 `isLede`：

```dart
              child: TranscriptSegmentItem(
                segment: segment,
                isActive: isActive,
                scrollController: scrollController,
                index: index,
                isLede: segmentIndex == 0,
              ),
```

- [ ] **Step 5: 跑測試確認通過**

Run: `fvm flutter test test/features/narration/presentation/widgets/transcript_segment_item_test.dart`
Expected: 兩個測試 PASS。

- [ ] **Step 6: analyze + 全量測試**

Run: `fvm flutter analyze --fatal-infos`
Expected: 零問題。

Run: `fvm flutter test test/features/narration/`
Expected: narration 相關測試全部 PASS。

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/narration/presentation/widgets/transcript_segment_item.dart \
        frontend/lib/features/narration/presentation/widgets/narration_transcript_area.dart \
        frontend/test/features/narration/presentation/widgets/transcript_segment_item_test.dart
git commit -m "feat(narration): add lede drop cap to the first transcript segment"
```

---

## 收尾

- [ ] 跑完整測試套件確認無回歸：`fvm flutter test`
- [ ] 在實機/模擬器目視確認：播放頁為暖紙底、最上方有地點照片 hero（無照片走 glyph fallback）、有故事標題時 hero 顯示故事標題 + 地點小標、第一段有放大首字、hero 會隨內容捲走、音訊列正常。
- [ ] 用 `superpowers:finishing-a-development-branch` 收尾，開 PR（此為功能變更，依專案慣例走 PR 流程）。
