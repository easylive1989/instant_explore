import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/grounding_info.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/narration/presentation/widgets/grounding_info_sheet.dart';
import 'package:context_app/features/narration/presentation/widgets/narration_transcript_area.dart';
import 'package:context_app/features/narration/presentation/widgets/narration_control_panel.dart';

/// 導覽播放頁面
///
/// 僅負責播放已生成的導覽內容，不負責生成。
class NarrationScreen extends ConsumerStatefulWidget {
  final Place place;
  final NarrationContent narrationContent;

  /// Whether to start playback automatically after initialisation.
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

  /// 自動滾動到當前播放的段落
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
    // 監聽當前段落索引變化並自動滾動
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

    const primaryColor = AppColors.primary;
    const primaryColorShadow = Color(0x4D137FEC);
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: colorScheme.onSurface,
                            size: 20,
                          ),
                          onPressed: () => context.go('/'),
                        ),
                        Expanded(
                          child: Text(
                            widget.place.name,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        NarrationTranscriptArea(
                          scrollController: _scrollController,
                          backgroundColor: backgroundColor,
                          primaryColor: primaryColor,
                        ),
                        if (widget.narrationContent.grounding != null)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: _GroundingInfoButton(
                              grounding: widget.narrationContent.grounding!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          NarrationControlPanel(
            place: widget.place,
            primaryColor: primaryColor,
            primaryColorShadow: primaryColorShadow,
            backgroundColor: backgroundColor,
          ),
        ],
      ),
    );
  }
}

class _GroundingInfoButton extends StatelessWidget {
  final GroundingInfo grounding;

  const _GroundingInfoButton({required this.grounding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: 'Google 搜尋結果',
        icon: Icon(Icons.info_outline, color: colorScheme.onSurface),
        onPressed: () => showGroundingInfoSheet(context, grounding: grounding),
      ),
    );
  }
}
