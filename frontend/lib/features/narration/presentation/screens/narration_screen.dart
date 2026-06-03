import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/presentation/widgets/grounding_info_sheet.dart';
import 'package:context_app/features/narration/presentation/widgets/narration_control_panel.dart';
import 'package:context_app/features/narration/presentation/widgets/narration_transcript_area.dart';
import 'package:context_app/features/narration/presentation/controllers/player_controller.dart';
import 'package:context_app/features/narration/presentation/widgets/reading_palette.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// 導覽播放頁面
///
/// 僅負責播放已生成的導覽內容，不負責生成。
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

  @override
  ConsumerState<NarrationScreen> createState() => _NarrationScreenState();
}

class _NarrationScreenState extends ConsumerState<NarrationScreen> {
  final AutoScrollController _scrollController = AutoScrollController();
  int? _lastSegmentIndex;

  /// Cached in [initState] so [dispose] can stop playback without `ref`,
  /// which is no longer usable once the widget has been disposed.
  late final PlayerController _playerController;

  @override
  void initState() {
    super.initState();
    _playerController = ref.read(playerControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _playerController
          .initializeWithContent(widget.place, widget.narrationContent)
          .then((_) {
            if (!mounted || !widget.autoPlay) return;
            _playerController.play();
          });
    });
  }

  @override
  void dispose() {
    // Explicitly stop TTS when leaving the player. playerControllerProvider
    // is autoDispose and originally relied on autoDispose firing _cleanup()
    // (which stops TTS). But the app-wide NarrationAnalyticsObserver keeps a
    // permanent ref.listen on this provider, so it never auto-disposes; we
    // must stop playback here instead.
    _playerController.stop();
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

    final palette = ReadingPalette.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: palette.readBg,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                child: Column(
                  children: [
                    _NarrationHeader(
                      placeName: widget.place.name,
                      palette: palette,
                    ),
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
                              child: _InfoButton(
                                palette: palette,
                                tooltip: 'narration.grounding_info_tooltip'
                                    .tr(),
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
      ),
    );
  }
}

class _NarrationHeader extends StatelessWidget {
  final String placeName;
  final ReadingPalette palette;
  const _NarrationHeader({required this.placeName, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          AdaptiveIconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: palette.clay),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              placeName,
              style: GoogleFonts.notoSerifTc(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: palette.readInk,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular ghost info button sitting on the reading surface.
class _InfoButton extends StatelessWidget {
  const _InfoButton({
    required this.palette,
    required this.tooltip,
    required this.onPressed,
  });

  final ReadingPalette palette;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.readBg,
        shape: CircleBorder(side: BorderSide(color: palette.readLine)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.info_outline, size: 20, color: palette.readDim),
          ),
        ),
      ),
    );
  }
}
