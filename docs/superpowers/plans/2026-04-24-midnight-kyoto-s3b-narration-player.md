# Midnight Kyoto S3-b — Narration Player Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the narration player ecosystem (6 widget files) to use Midnight Kyoto components from S2 — `PillIconButton` for controls, `PillButton.secondary` for save-to-journey, `PillIconButton.ghost` for grounding info, and `textTheme` everywhere — while removing parent-to-child Color parameter passing.

**Architecture:** Single source-of-truth refactor. Child widgets stop receiving `primaryColor` / `backgroundColor` / `surfaceColor` and read directly from `Theme.of(context).colorScheme`. Scaffold no longer paints a solid background — `AmbientBackdrop` (S2) handles it globally.

**Tech Stack:** Dart, Flutter, Material 3, Riverpod, S2 Midnight Kyoto components.

**Spec:** `docs/superpowers/specs/2026-04-24-midnight-kyoto-s3b-narration-player-design.md`

---

## File Structure

### Modified
- `frontend/lib/features/narration/presentation/screens/narration_screen.dart`
- `frontend/lib/features/narration/presentation/widgets/narration_control_panel.dart`
- `frontend/lib/features/narration/presentation/widgets/narration_transcript_area.dart`
- `frontend/lib/features/narration/presentation/widgets/transcript_segment_item.dart`
- `frontend/lib/features/narration/presentation/widgets/save_to_journey_button.dart`
- `frontend/lib/features/narration/presentation/widgets/grounding_info_sheet.dart`
- (test) `frontend/test/features/narration/presentation/screens/narration_screen_test.dart`
- (test) `frontend/test/features/narration/presentation/widgets/grounding_info_sheet_test.dart` (only if assertions break)

### Untouched (out of scope)
- All controllers / state / domain / providers under `narration/`
- `select_narration_aspect_screen.dart` (S3-bb)

---

## Task D1: Refactor narration player ecosystem

**Files:** all 6 widget files above + at least the narration_screen_test.dart.

This is a single commit because the changes interlock — `narration_screen` removes color parameters that child widgets no longer need.

### Order of edits (top-down so each child file becomes self-contained before parent stops passing colors)

#### Step 1: Refactor `transcript_segment_item.dart`

- [ ] Remove the `primaryColor` constructor parameter.
- [ ] Read `cs.primary` and theme text styles internally.
- [ ] Active segment: 4px primary bar + `displaySmall.copyWith(weight: w800, height: 1.4)` text.
- [ ] Inactive segment: `bodyLarge.copyWith(fontSize: 20, height: 1.6, color: cs.onSurfaceVariant)` text.

Final implementation (full file replacement):

```dart
import 'package:context_app/features/narration/domain/models/narration_segment.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// 單個轉錄文本段落項目
class TranscriptSegmentItem extends StatelessWidget {
  final NarrationSegment segment;
  final bool isActive;
  final AutoScrollController scrollController;
  final int index;

  const TranscriptSegmentItem({
    super.key,
    required this.segment,
    required this.isActive,
    required this.scrollController,
    required this.index,
  });

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
}
```

#### Step 2: Refactor `narration_transcript_area.dart`

- [ ] Remove `backgroundColor` and `primaryColor` constructor parameters.
- [ ] Replace `AppColors.error` with `cs.error`.
- [ ] Top/bottom gradient uses `cs.surface` instead of the removed `backgroundColor` param.
- [ ] Spinner color uses `cs.primary`.
- [ ] Loading text + error text use `textTheme.bodyLarge`.
- [ ] `TranscriptSegmentItem` instantiation no longer passes `primaryColor`.

Replace entire file:

```dart
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/narration/presentation/widgets/transcript_segment_item.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// 導覽轉錄文本顯示區域
class NarrationTranscriptArea extends ConsumerWidget {
  final AutoScrollController scrollController;

  const NarrationTranscriptArea({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final cs = Theme.of(context).colorScheme;

    if (playerState.isLoading && playerState.content == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AdaptiveProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'player_screen.loading'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (playerState.hasError) {
      final errorMessage =
          playerState.errorMessage ?? 'player_screen.error'.tr();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: cs.error, size: 48),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final content = playerState.content;
    if (content == null) {
      return const SizedBox.shrink();
    }
    final currentSegmentIndex = playerState.currentSegmentIndex;

    return Stack(
      children: [
        ListView.builder(
          physics: const ClampingScrollPhysics(),
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: content.segments.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) return const SizedBox(height: 60);
            if (index == content.segments.length + 1) {
              return const SizedBox(height: 200);
            }
            final segmentIndex = index - 1;
            final segment = content.segments[segmentIndex];
            final isActive = currentSegmentIndex == segmentIndex;
            return TranscriptSegmentItem(
              segment: segment,
              isActive: isActive,
              scrollController: scrollController,
              index: index,
            );
          },
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.surface, cs.surface.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [cs.surface, cs.surface.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

#### Step 3: Refactor `narration_control_panel.dart`

- [ ] Remove `primaryColor`, `primaryColorShadow`, `backgroundColor` constructor parameters (now only `Place place` remains).
- [ ] Remove the `Container(color: backgroundColor)` wrapper — let the AmbientBackdrop show through.
- [ ] Replace play button container with `PillIconButton(filled, size: 64)`.
- [ ] Replace skip buttons with `PillIconButton(ghost, size: 48)`.
- [ ] Extract `_ProgressBar` and `_ControlsRow` private widgets for clarity.

Full file replacement:

```dart
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/presentation/controllers/player_state.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/shared/widgets/midnight/midnight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 導覽播放控制面板
class NarrationControlPanel extends ConsumerWidget {
  final Place place;

  const NarrationControlPanel({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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

Verify that `PlayerState` is exported from `controllers/player_state.dart` — that import path may need adjustment after reading the file.

#### Step 4: Refactor `save_to_journey_button.dart`

- [ ] Drop `surfaceColor` parameter.
- [ ] Replace entire body with `PillButton(secondary, fullWidth, icon: Icons.bookmark_add)`.
- [ ] Remove `AppColors.amber` reference.

```dart
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/shared/widgets/midnight/midnight.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 儲存到歷程的按鈕
class SaveToJourneyButton extends ConsumerWidget {
  final Place place;

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

⚠️ **Check before committing:** is this widget referenced anywhere outside `narration_screen.dart`? If yes, those callers need to drop the `surfaceColor:` named arg too. Grep for `SaveToJourneyButton(` in `lib/` first.

#### Step 5: Refactor `grounding_info_sheet.dart`

- [ ] Light typography pass: `_SourceTile` icon color → `cs.onSurfaceVariant`.
- [ ] No structural changes; existing typography (`titleMedium`, `titleSmall`) already uses theme.

Surgical edits (NOT full file replacement):

In `_SourceTile.build`, change:
```dart
leading: const Icon(Icons.link),
```
to:
```dart
leading: Icon(
  Icons.link,
  color: Theme.of(context).colorScheme.onSurfaceVariant,
),
```

(Other parts unchanged.)

#### Step 6: Refactor `narration_screen.dart`

- [ ] Drop the `const primaryColor = AppColors.primary;` and `const primaryColorShadow = Color(0x4D137FEC);` lines.
- [ ] Drop the `final backgroundColor = colorScheme.surface;` line.
- [ ] Remove `Scaffold.backgroundColor` argument.
- [ ] `NarrationTranscriptArea(...)` no longer receives `backgroundColor` / `primaryColor`.
- [ ] `NarrationControlPanel(...)` only receives `place`.
- [ ] Replace `_GroundingInfoButton(grounding: ...)` with inline `PillIconButton(ghost, size: 40, icon: Icons.info_outline, tooltip: ..., onPressed: ...)`.
- [ ] Extract `_NarrationHeader(placeName)` private widget for the back-button + title row.

Full file replacement (after the imports — keep `dart:` and `package:` block intact, ADD `import 'package:context_app/shared/widgets/midnight/midnight.dart';`, REMOVE `import 'package:context_app/common/config/app_colors.dart';`):

```dart
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/presentation/widgets/grounding_info_sheet.dart';
import 'package:context_app/features/narration/presentation/widgets/narration_control_panel.dart';
import 'package:context_app/features/narration/presentation/widgets/narration_transcript_area.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/midnight/midnight.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// 導覽播放頁面
///
/// 僅負責播放已生成的導覽內容，不負責生成。
class NarrationScreen extends ConsumerStatefulWidget {
  final Place place;
  final NarrationContent narrationContent;
  final bool autoPlay;

  const NarrationScreen({
    super.key,
    required this.place,
    required this.narrationContent,
    this.autoPlay = false,
  });

  @override
  ConsumerState<NarrationScreen> createState() => _NarrationScreenState();
}

class _NarrationScreenState extends ConsumerState<NarrationScreen> {
  final AutoScrollController _scrollController = AutoScrollController();
  int? _lastSegmentIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(playerControllerProvider.notifier)
          .initializeWithContent(widget.place, widget.narrationContent)
          .then((_) {
            if (!mounted || !widget.autoPlay) return;
            ref.read(playerControllerProvider.notifier).play();
          });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentSegment(int? segmentIndex) {
    if (segmentIndex == null ||
        segmentIndex == _lastSegmentIndex ||
        !_scrollController.hasClients) {
      return;
    }
    _lastSegmentIndex = segmentIndex;
    _scrollController.scrollToIndex(
      segmentIndex + 1,
      preferPosition: AutoScrollPosition.middle,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playerControllerProvider, (previous, current) {
      final previousIndex = previous?.currentSegmentIndex;
      final currentIndex = current.currentSegmentIndex;
      if (previousIndex != currentIndex && currentIndex != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToCurrentSegment(currentIndex);
        });
      }
    });

    return Scaffold(
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
                              tooltip:
                                  'narration.grounding_info_tooltip'.tr(),
                              onPressed: () => showGroundingInfoSheet(
                                context,
                                grounding:
                                    widget.narrationContent.grounding!,
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
  }
}

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
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
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

⚠️ The new code uses `'narration.grounding_info_tooltip'` translation key. **Check `frontend/assets/translations/zh-TW.json` and `en-US.json`** before committing — if the key doesn't exist, either:
   - (a) Add the key to both translation files (preferred, low cost), or
   - (b) Pass `tooltip: null` (accept missing tooltip).

Pick (a) and add a sensible string in both languages.

#### Step 7: Update tests

- [ ] Read `narration_screen_test.dart` and trace which assertions reference removed APIs (e.g., `_GroundingInfoButton`, `Container.shape`, `primaryColor` props passed to widgets).
- [ ] Update finders to use widget types or icons (`find.byIcon(Icons.info_outline)`, `find.byType(PillIconButton)`).
- [ ] If a test asserts on `Scaffold.backgroundColor`, remove that assertion.
- [ ] Read `grounding_info_sheet_test.dart` — it should pass unchanged since our edits there were minimal. Run to confirm.

#### Step 8: Verify

- [ ] **Targeted analyzer:**
  ```
  cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter analyze --fatal-infos lib/features/narration/presentation/screens/ lib/features/narration/presentation/widgets/ test/features/narration/presentation/screens/narration_screen_test.dart
  ```
  Expected: No issues.

- [ ] **Narration tests:**
  ```
  cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test test/features/narration/
  ```
  Expected: all pass.

- [ ] **Full suite:**
  ```
  cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test
  ```
  Expected: 390+ pass.

#### Step 9: Commit

```bash
cd /Users/paulwu/Documents/Github/instant_explore && \
  git add frontend/lib/features/narration/presentation/screens/narration_screen.dart \
    frontend/lib/features/narration/presentation/widgets/narration_control_panel.dart \
    frontend/lib/features/narration/presentation/widgets/narration_transcript_area.dart \
    frontend/lib/features/narration/presentation/widgets/transcript_segment_item.dart \
    frontend/lib/features/narration/presentation/widgets/save_to_journey_button.dart \
    frontend/lib/features/narration/presentation/widgets/grounding_info_sheet.dart \
    frontend/test/features/narration/presentation/screens/narration_screen_test.dart \
    frontend/assets/translations/zh-TW.json \
    frontend/assets/translations/en-US.json && \
  git commit -m "$(cat <<'EOF'
feat(narration): apply Midnight Kyoto components to player screen

Refactors all six player widgets to use PillIconButton (filled play /
ghost skip + grounding info), PillButton.secondary for save-to-journey
(drops AppColors.amber and the bespoke icon-in-circle), textTheme for
transcript and headers. Child widgets stop receiving primaryColor /
backgroundColor / surfaceColor params; they read directly from
Theme.of(context). Scaffold no longer paints solid surface — the
S2 AmbientBackdrop shows through.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ Player play/skip → Step 3
- ✅ Save-to-journey → Step 4
- ✅ Grounding info → Step 6
- ✅ Transcript → Steps 1-2
- ✅ Header → Step 6
- ✅ Scaffold backgroundColor removed → Step 6
- ✅ AppColors.amber removed → Step 4
- ✅ AppColors.error swapped to cs.error → Step 2

**Placeholder scan:** None.

**Type consistency:** Verify these before edits:
- `PlayerState` import path in `narration_control_panel.dart`
- Translation key `narration.grounding_info_tooltip` existence
- `SaveToJourneyButton(surfaceColor:)` callers (grep `lib/`)
