import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/narration/presentation/widgets/transcript_segment_item.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// 導覽轉錄文本顯示區域
class NarrationTranscriptArea extends ConsumerWidget {
  final AutoScrollController scrollController;
  final Color backgroundColor;
  final Color primaryColor;

  const NarrationTranscriptArea({
    super.key,
    required this.scrollController,
    required this.backgroundColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);

    // 載入中且尚無內容時顯示 spinner（TTS 初始化中）
    if (playerState.isLoading && playerState.content == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(
              'player_screen.loading'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // 錯誤狀態
    if (playerState.hasError) {
      final errorMessage =
          playerState.errorMessage ?? 'player_screen.error'.tr();

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 顯示導覽文本
    final content = playerState.content;
    if (content == null) {
      return const SizedBox.shrink();
    }
    final currentSegmentIndex = playerState.currentSegmentIndex;

    return Stack(
      children: [
        // Transcript List
        ListView.builder(
          physics: const ClampingScrollPhysics(),
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          itemCount: content.segments.length + 2,
          itemBuilder: (context, index) {
            // 頂部空白
            if (index == 0) {
              return const SizedBox(height: 60);
            }

            // 底部空白
            if (index == content.segments.length + 1) {
              return const SizedBox(height: 200);
            }

            // 文本段落
            final segmentIndex = index - 1;
            final segment = content.segments[segmentIndex];
            final isActive = currentSegmentIndex == segmentIndex;

            return TranscriptSegmentItem(
              segment: segment,
              isActive: isActive,
              primaryColor: primaryColor,
              scrollController: scrollController,
              index: index,
            );
          },
        ),
        // Top Gradient Fade
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [backgroundColor, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Bottom Gradient Fade
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [backgroundColor, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
