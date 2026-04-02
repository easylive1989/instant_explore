import 'dart:ui';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 導覽播放控制面板
class NarrationControlPanel extends ConsumerWidget {
  final Place place;
  final Color primaryColor;
  final Color primaryColorShadow;
  final Color surfaceColor;
  final Color backgroundColor;

  const NarrationControlPanel({
    super.key,
    required this.place,
    required this.primaryColor,
    required this.primaryColorShadow,
    required this.surfaceColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Bar
                SizedBox(
                  height: 6,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: playerState.progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 上一段按鈕區域（固定寬度，用 Opacity 控制可見性）
                    SizedBox(
                      width: 48 + 24, // 按鈕寬度 + margin
                      child: playerState.shouldShowSkipButtons
                          ? Opacity(
                              opacity: playerState.canSkipPrevious ? 1.0 : 0.0,
                              child: Container(
                                height: 48,
                                width: 48,
                                margin: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  onPressed: playerState.canSkipPrevious
                                      ? () => playerController
                                            .skipToPreviousSegment()
                                      : null,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // 播放/暫停按鈕（始終置中）
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColorShadow,
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          playerState.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 32,
                          color: Colors.white,
                        ),
                        onPressed: playerState.isLoading || playerState.hasError
                            ? null
                            : () => playerController.playPause(),
                      ),
                    ),

                    // 下一段按鈕區域（固定寬度，用 Opacity 控制可見性）
                    SizedBox(
                      width: 48 + 24, // 按鈕寬度 + margin
                      child: playerState.shouldShowSkipButtons
                          ? Opacity(
                              opacity: playerState.canSkipNext ? 1.0 : 0.0,
                              child: Container(
                                height: 48,
                                width: 48,
                                margin: const EdgeInsets.only(left: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.skip_next,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  onPressed: playerState.canSkipNext
                                      ? () =>
                                            playerController.skipToNextSegment()
                                      : null,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
