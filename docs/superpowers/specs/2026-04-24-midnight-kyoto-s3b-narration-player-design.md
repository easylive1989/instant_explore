# Midnight Kyoto S3-b — Narration Player 設計文件

- 日期：2026-04-24
- Sprint：S3-b（共 7 個 mini-sprint，這是第二個）
- 範圍：`frontend/lib/features/narration/presentation/screens/narration_screen.dart` + 5 個支援 widgets

## 背景與目標

Narration 是用戶停留最久的「沈浸式播放器」畫面，是 Midnight Kyoto 設計的招牌——「在霧氣濛濛的歷史街區夜晚漫步」這種編輯感最該在這裡出現。

S3-b 把 player 生態系翻新為 MK 風格：透明 backdrop（已由 S2 全局接線提供）、玻璃元件、pill 控制按鈕、編輯排版的 transcript。

## 不在 S3-b 範圍

- ❌ `select_narration_aspect_screen.dart`（→ S3-bb）
- ❌ Narration 其他 controllers / state / domain models（純邏輯）
- ❌ `AppColors` 的最終刪除（→ S3-g）
- ❌ Save-to-journey **路由目標**（journey_success 螢幕另一個 mini-sprint）

## 影響檔案盤點

| 檔案 | 行數 | 含 deprecated tokens? | 動作 |
|---|---|---|---|
| `narration_screen.dart` | 189 | ❌（直接 `Color(0x4D137FEC)` 硬編碼）| 重 |
| `narration_control_panel.dart` | 162 | ❌（純 colorScheme）| 重 |
| `narration_transcript_area.dart` | 159 | ✅ `AppColors.error`（line 58 — 仍是有效 token，但要改 colorScheme）| 中 |
| `transcript_segment_item.dart` | 68 | ❌ | 中 |
| `save_to_journey_button.dart` | 84 | ✅ `AppColors.amber` deprecated | 大 |
| `grounding_info_sheet.dart` | 124 | ❌ | 小 |

對應測試：`narration_screen_test.dart`（123 行）、`grounding_info_sheet_test.dart`（43 行）。

## 已決策事項（依 brainstorm 收斂）

| 議題 | 決定 |
|---|---|
| 控制按鈕樣式 | play 用 `PillIconButton(filled, size: 64)`、skip 用 `PillIconButton(ghost, size: 48)` |
| 進度條 | **保留現有 Stack 自畫實作**，僅顏色 token 化（用 `colorScheme.surfaceContainerHigh` 與 `colorScheme.primary`）。MK 沒有特定 progress bar 元件，自畫的 6px 高條已經符合 MK 簡潔感 |
| Transcript 段落字級 | active 改 `displaySmall.copyWith(weight: w800)` (24/w800)；inactive 改 `bodyLarge.copyWith(fontSize: 20, height: 1.6)` (20/w400)。維持 active vs inactive 的視覺差，但與 MK textTheme 對齊 |
| Active segment indicator | 維持左側 4px 直條，色用 `colorScheme.primary` |
| Transcript 邊緣漸層 | 仍用 `backgroundColor` 但改用 `colorScheme.surface`（因為 S2 後 scaffold 是 transparent，要用 colorScheme.surface 才能漸入 MK 黑底）|
| Save-to-journey 按鈕 | 改用 `PillButton(secondary, fullWidth, icon: Icons.bookmark_add)`；移除 `AppColors.amber`，icon 色由 `secondary` variant 自動套用 `onSurface` |
| Grounding info button | 改用 `PillIconButton(ghost, size: 40, icon: Icons.info_outline, tooltip)`，原 elevation 改由 ghost border 表達；移除 `Material(elevation: 2)` |
| Header back button | 維持 `AdaptiveIconButton`（cross-platform 抽象，不在 MK 範圍）；place name 字級 `textTheme.titleMedium` |
| Loading / error 狀態 | typography 改 textTheme；error icon 色用 `colorScheme.error` |
| `narration_screen.dart` 的 `Scaffold.backgroundColor` | 移除（S2 後 ThemeData 已將 scaffoldBackgroundColor 設成 transparent，AmbientBackdrop 全局處理） |
| `_GroundingInfoButton` | 拆掉這個 wrapper widget，直接用 `PillIconButton.ghost`（外層其實只是給圓形 + elevation） |

## 設計細節

### 1. `narration_screen.dart`

刪除 `const primaryColor = AppColors.primary;` 和 `const primaryColorShadow = Color(0x4D137FEC);`——不再傳 color 給子 widget；子 widget 直接從 Theme.of 拿。

```dart
return Scaffold(
  // 移除 backgroundColor: backgroundColor
  body: Column(
    children: [
      Expanded(
        child: SafeArea(
          child: Column(
            children: [
              _NarrationHeader(placeName: widget.place.name),
              Expanded(
                child: Stack(
                  children: [
                    NarrationTranscriptArea(
                      scrollController: _scrollController,
                    ),
                    if (widget.narrationContent.grounding != null)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: PillIconButton(
                          icon: Icons.info_outline,
                          size: 40,
                          variant: PillIconButtonVariant.ghost,
                          tooltip: 'narration.grounding_info_tooltip'.tr(),
                          onPressed: () => showGroundingInfoSheet(
                            context,
                            grounding: widget.narrationContent.grounding!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      NarrationControlPanel(place: widget.place),
    ],
  ),
);
```

`_NarrationHeader` 抽成 private widget：

```dart
class _NarrationHeader extends StatelessWidget {
  final String placeName;
  const _NarrationHeader({required this.placeName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AdaptiveIconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
            ),
            onPressed: () => context.go('/'),
          ),
          Expanded(
            child: Text(
              placeName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 2. `NarrationControlPanel`

API 簡化——移除 `primaryColor` / `primaryColorShadow` / `backgroundColor` 參數：

```dart
class NarrationControlPanel extends ConsumerWidget {
  final Place place;
  const NarrationControlPanel({super.key, required this.place});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      // 移除 color: backgroundColor — Scaffold 透明，控制面板也透明讓 backdrop 看穿
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProgressBar(progress: playerState.progress),
            const SizedBox(height: 16),
            _ControlsRow(
              playerState: playerState,
              onPlayPause: () => playerController.playPause(),
              onSkipPrev: playerState.canSkipPrevious
                  ? playerController.skipToPreviousSegment
                  : null,
              onSkipNext: playerState.canSkipNext
                  ? playerController.skipToNextSegment
                  : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
```

`_ProgressBar`：

```dart
class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 6,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

`_ControlsRow`（顯示 / 隱藏 skip 邏輯不變，但用 PillIconButton 替換）：

```dart
class _ControlsRow extends StatelessWidget {
  final PlayerState playerState;
  final VoidCallback onPlayPause;
  final VoidCallback? onSkipPrev;
  final VoidCallback? onSkipNext;
  
  const _ControlsRow({
    required this.playerState,
    required this.onPlayPause,
    required this.onSkipPrev,
    required this.onSkipNext,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 48 + 24,
          child: playerState.shouldShowSkipButtons
              ? Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Opacity(
                    opacity: playerState.canSkipPrevious ? 1.0 : 0.0,
                    child: PillIconButton(
                      icon: Icons.skip_previous,
                      size: 48,
                      variant: PillIconButtonVariant.ghost,
                      onPressed: onSkipPrev,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        PillIconButton(
          icon: playerState.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 64,
          variant: PillIconButtonVariant.filled,
          onPressed: playerState.isLoading || playerState.hasError
              ? null
              : onPlayPause,
        ),
        SizedBox(
          width: 48 + 24,
          child: playerState.shouldShowSkipButtons
              ? Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Opacity(
                    opacity: playerState.canSkipNext ? 1.0 : 0.0,
                    child: PillIconButton(
                      icon: Icons.skip_next,
                      size: 48,
                      variant: PillIconButtonVariant.ghost,
                      onPressed: onSkipNext,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
```

⚠️ `PillIconButton.filled` 內建 size*0.5 icon size——64px 按鈕 → 32px icon，匹配原本 `Icons.play_arrow size: 32`。

⚠️ `Opacity(0.0, child)` 仍接收 hit test。原本 `onPressed: null` 也透過按鈕本身停用——`PillIconButton` 在 `onPressed: null` 時會走 disabled state，但配 `Opacity(0)` 看起來是 hidden 但仍可 tap（無效）。視覺上正確。

### 3. `NarrationTranscriptArea`

API 簡化——移除 `backgroundColor` / `primaryColor` 參數：

```dart
class NarrationTranscriptArea extends ConsumerWidget {
  final AutoScrollController scrollController;
  const NarrationTranscriptArea({super.key, required this.scrollController});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final cs = Theme.of(context).colorScheme;
    // ...
```

裡面：
- spinner 的 `color: primaryColor` → `color: cs.primary`
- error icon `color: AppColors.error` → `color: cs.error`
- error text style → `Theme.of(context).textTheme.bodyLarge`
- top/bottom gradient 的 `backgroundColor` → `cs.surface`（S2 後 surface 是 backgroundDark；漸出到透明）
- TranscriptSegmentItem 的 `primaryColor` → 不再傳，segment 自己拿

### 4. `TranscriptSegmentItem`

API 簡化——移除 `primaryColor` 參數：

```dart
@override
Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return AutoScrollTag(
    key: ValueKey(index),
    controller: scrollController,
    index: index,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: isActive
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -20,
                  top: 6,
                  bottom: 6,
                  width: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  segment.text,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                ),
              ],
            )
          : Text(
              segment.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 20,
                    height: 1.6,
                    color: cs.onSurfaceVariant,
                  ),
            ),
    ),
  );
}
```

### 5. `SaveToJourneyButton`

整個改寫：

```dart
class SaveToJourneyButton extends ConsumerWidget {
  final Place place;
  // 移除 surfaceColor 參數

  const SaveToJourneyButton({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final isDisabled = playerState.isLoading ||
        playerState.hasError ||
        playerState.content == null;

    return PillButton(
      label: easy.tr('player_screen.save_to_journey'),
      icon: Icons.bookmark_add,
      variant: PillButtonVariant.secondary,
      fullWidth: true,
      onPressed: isDisabled
          ? null
          : () => context.pushNamed('journey_success', extra: place),
    );
  }
}
```

⚠️ 失去原本「icon 在小圓圈」的設計。`PillButton` 的 icon 是 leading icon（與 label 同色）。視覺更收斂於品牌。

⚠️ 失去原本 56px 高度——`PillButton` 預設 padding 14v、加 icon 後總高約 46px。如果用戶覺得太矮可在 S3 review 時調整 spec。

### 6. `GroundingInfoSheet`

純 typography 微調：

- `'Google 搜尋結果'` → `theme.textTheme.titleMedium`（原本就是了，但確認不被 size 16 hardcoded 覆蓋）
- `'來源'` → `theme.textTheme.titleSmall`（原本就是了）
- `_SourceTile` 的 leading icon `Icons.link` 顏色 → `cs.onSurfaceVariant`
- `_SourceTile.title` text style → `theme.textTheme.titleMedium`
- `_SourceTile.subtitle` text style → `theme.textTheme.bodySmall`

幾乎不動，僅將硬編碼字級替換為 textTheme tokens。

## 測試策略

### `narration_screen_test.dart`（123 行）
最小修改：
- 仍能找到 `Icons.arrow_back_ios_new`、`Icons.info_outline`、`Icons.play_arrow` 等
- 控制按鈕測試若驗證 `Container.shape == BoxShape.circle` 的 → 改 `find.byType(PillIconButton)` 檢查 + `variant` 屬性
- `Scaffold.backgroundColor` 斷言 → 移除（現在透明）

### `grounding_info_sheet_test.dart`（43 行）
僅 typography 動，行為測試應全 pass。

### `save_to_journey_button` 沒有獨立測試
保持現狀，此次改動視覺優先。

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| `PillButton` icon-in-button 變化讓 save-to-journey 失去「特殊感」 | 中 | 視 UI review 後決定是否回頭加 hero variant；S3-b 不解決 |
| 控制面板的 `Opacity(0)` skip 按鈕 + `PillIconButton(onPressed: null)` 雙層停用——可能讓 hit test 不一致 | 中 | 改用 `Visibility` 而非 Opacity 完全移除 hit test：但這會破壞布局穩定性。維持 `Opacity` + 確認 `null onPressed` 為主要停用機制 |
| 既有測試斷言 `Container` shape | 中 | 改 finder 為 `PillIconButton` 並檢查 variant |
| Transcript 字級從 20/24 變動可能影響可讀性 | 低 | 保留主要尺寸（20/24），僅換成 textTheme 來源 |
| S2 後 scaffoldBackgroundColor 是透明，但 `Container(color: backgroundColor)` 在 ControlPanel 把 backdrop 蓋住 | 高 | 移除 ControlPanel 的 `color: backgroundColor`——讓 backdrop 透出來 |

## 成功指標

1. 6 個 widget 檔內 hardcoded `Color(0x...)` 為 0；`AppColors.amber` 引用為 0。
2. 既有 `narration_screen_test.dart` 與 `grounding_info_sheet_test.dart` 全 pass。
3. `flutter analyze --fatal-infos` 對 6 個改動檔 clean。
4. 全 suite 維持 390+ pass。
5. **跑起來看**：play 按鈕電光藍 + shadow、進度條乾淨、transcript active 段有左側電光藍直條 + 加大字、save-to-journey 是 secondary pill button、grounding info 是 ghost icon 圓鈕。
