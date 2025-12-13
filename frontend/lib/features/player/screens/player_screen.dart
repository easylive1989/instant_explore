import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:context_app/core/widgets/ai_over_limit_dialog.dart';
import 'package:context_app/features/places/models/place.dart';
import 'package:context_app/features/player/models/narration_error_type.dart';
import 'package:context_app/features/player/models/narration_style.dart';
import 'package:context_app/features/player/providers.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final Place place;
  final NarrationStyle narrationStyle;

  const PlayerScreen({
    super.key,
    required this.place,
    required this.narrationStyle,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化播放器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale =
          easy.EasyLocalization.of(context)?.locale.toString() ?? 'zh-TW';
      ref
          .read(playerControllerProvider.notifier)
          .initialize(widget.place, widget.narrationStyle, language: locale);
    });
  }

  /// 格式化時間顯示（秒 -> MM:SS）
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 格式化重試延遲時間
  String _formatRetryDelay(int seconds) {
    if (seconds < 60) {
      return '$seconds 秒';
    } else {
      return '${seconds ~/ 60} 分鐘';
    }
  }

  /// 顯示 AI 超限對話框
  void _showAiOverLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AiOverLimitDialog(),
    ).then((_) {
      // 對話框關閉後，導航回 config screen
      if (mounted) {
        context.pushReplacementNamed('config', extra: widget.place);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);

    // 監聽錯誤狀態並顯示對應的對話框
    ref.listen(playerControllerProvider, (previous, current) {
      // 當狀態從非錯誤變為錯誤時，且需要特殊對話框
      if ((previous == null || !previous.hasError) &&
          current.hasError &&
          current.errorType != null &&
          current.errorType!.requiresSpecialDialog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showAiOverLimitDialog();
        });
      }
    });

    // Colors from design
    const primaryColor = Color(0xFF137fec);
    const backgroundColor = Color(0xFF101922);
    const surfaceColor = Color(0xFF182430);
    const primaryColorShadow = Color(0x4D137FEC);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'AUDIO GUIDE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // Transcript Area
                Expanded(
                  child: _buildTranscriptArea(
                    playerState,
                    backgroundColor,
                    primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControlPanel(
              context,
              playerState,
              playerController,
              primaryColor,
              primaryColorShadow,
              surfaceColor,
              backgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立轉錄文本區域
  Widget _buildTranscriptArea(
    dynamic playerState,
    Color backgroundColor,
    Color primaryColor,
  ) {
    // 載入中狀態
    if (playerState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            const Text(
              '正在生成導覽內容...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 錯誤狀態
    if (playerState.hasError) {
      final locale =
          easy.EasyLocalization.of(context)?.locale.toString() ?? 'zh-TW';
      final errorType = playerState.errorType;

      // 取得錯誤訊息
      final errorMessage =
          errorType?.message ?? playerState.errorMessage ?? '發生錯誤';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),

              // 顯示建議的重試時間
              if (errorType?.suggestedRetryDelay != null &&
                  errorType != NarrationErrorType.aiQuotaExceeded) ...[
                const SizedBox(height: 8),
                Text(
                  '建議 ${_formatRetryDelay(errorType!.suggestedRetryDelay!)} 後重試',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],

              // 重試按鈕（僅在可重試且非 AI quota 錯誤時顯示）
              if (errorType?.isRetryable == true &&
                  errorType != NarrationErrorType.aiQuotaExceeded) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(playerControllerProvider.notifier)
                        .initialize(
                          widget.place,
                          widget.narrationStyle,
                          language: locale,
                        );
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
    final narration = playerState.narration;
    if (narration?.content == null) {
      return const SizedBox.shrink();
    }

    final content = narration!.content!;
    final currentSegmentIndex = playerState.currentSegmentIndex;

    return Stack(
      children: [
        // Transcript List
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          itemCount: content.segments.length + 2, // +2 for top/bottom spacing
          itemBuilder: (context, index) {
            // 頂部空白
            if (index == 0) {
              return const SizedBox(height: 24);
            }

            // 底部空白
            if (index == content.segments.length + 1) {
              return const SizedBox(height: 200);
            }

            // 文本段落
            final segmentIndex = index - 1;
            final segment = content.segments[segmentIndex];
            final isActive = currentSegmentIndex == segmentIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: isActive
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -20,
                          top: 6,
                          bottom: 6,
                          width: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          segment,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      segment,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 20,
                        height: 1.6,
                      ),
                    ),
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

  /// 建立控制面板
  Widget _buildControlPanel(
    BuildContext context,
    dynamic playerState,
    dynamic playerController,
    Color primaryColor,
    Color primaryColorShadow,
    Color surfaceColor,
    Color backgroundColor,
  ) {
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
                // Place Name
                Text(
                  widget.place.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),

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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(playerState.currentPosition),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(playerState.duration),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, size: 32),
                      color: const Color(0xFF94A3B8),
                      onPressed: playerState.isLoading || playerState.hasError
                          ? null
                          : () => playerController.seekBackward(),
                    ),
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
                    IconButton(
                      icon: const Icon(Icons.forward_10, size: 32),
                      color: const Color(0xFF94A3B8),
                      onPressed: playerState.isLoading || playerState.hasError
                          ? null
                          : () => playerController.seekForward(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Save Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.pushNamed(
                        'passport_success',
                        extra: widget.place,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.bookmark_add,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Save to Knowledge Passport',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
