import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/presentation/narration_state_error_type.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/narration/widgets/transcript_segment_item.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// 導覽轉錄文本顯示區域
class NarrationTranscriptArea extends ConsumerWidget {
  final AutoScrollController scrollController;
  final Color backgroundColor;
  final Color primaryColor;
  final Place place;
  final NarrationAspect? narrationAspect;

  const NarrationTranscriptArea({
    super.key,
    required this.scrollController,
    required this.backgroundColor,
    required this.primaryColor,
    required this.place,
    this.narrationAspect,
  });

  /// 格式化重試延遲時間
  String _formatRetryDelay(int seconds) {
    if (seconds < 60) {
      return '$seconds 秒';
    } else {
      return '${seconds ~/ 60} 分鐘';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);

    // 載入中狀態
    if (playerState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(
              'player_screen.loading'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 錯誤狀態
    if (playerState.hasError) {
      final locale =
          easy.EasyLocalization.of(context)?.locale.toLanguageTag() ?? 'zh-TW';
      final errorType = playerState.errorType;

      // 取得錯誤訊息
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
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),

              // 顯示建議的重試時間
              if (errorType?.suggestedRetryDelay != null &&
                  errorType != NarrationStateErrorType.aiQuotaExceeded) ...[
                const SizedBox(height: 8),
                Text(
                  'player_screen.suggested_retry'.tr(
                    namedArgs: {
                      'delay': _formatRetryDelay(
                        errorType!.suggestedRetryDelay!,
                      ),
                    },
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],

              // 重試按鈕（僅在可重試且非 AI quota 錯誤時顯示，且有 narrationAspect 時）
              if (errorType?.isRetryable == true &&
                  errorType != NarrationStateErrorType.aiQuotaExceeded &&
                  narrationAspect != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(playerControllerProvider.notifier)
                        .initialize(place, narrationAspect!, language: locale);
                  },
                  child: const Text('重試'),
                ),
              ],
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
          // +2 for top/bottom spacing
          itemBuilder: (context, index) {
            // 頂部空白 - 不需要 AutoScrollTag
            if (index == 0) {
              return const SizedBox(height: 60);
            }

            // 底部空白 - 不需要 AutoScrollTag
            if (index == content.segments.length + 1) {
              return const SizedBox(height: 200);
            }

            // 文本段落 - 使用 AutoScrollTag 包裝
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
