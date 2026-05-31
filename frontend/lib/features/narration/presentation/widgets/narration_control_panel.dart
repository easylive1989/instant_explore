import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_state.dart';
import 'package:context_app/features/narration/presentation/widgets/reading_palette.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 導覽播放控制面板（Field Journal 深色音訊列）
class NarrationControlPanel extends ConsumerWidget {
  final Place place;

  const NarrationControlPanel({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);
    final palette = ReadingPalette.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Container(
          decoration: BoxDecoration(
            color: palette.inkBg2,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59140C08),
                offset: Offset(0, 10),
                blurRadius: 28,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProgressBar(progress: playerState.progress, palette: palette),
              const SizedBox(height: 12),
              _ControlsRow(
                playerState: playerState,
                palette: palette,
                onPlayPause: () => playerController.playPause(),
                onSkipPrev: playerState.canSkipPrevious
                    ? playerController.skipToPreviousSegment
                    : null,
                onSkipNext: playerState.canSkipNext
                    ? playerController.skipToNextSegment
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final ReadingPalette palette;
  const _ProgressBar({required this.progress, required this.palette});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.onDark.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.clay,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsRow extends StatelessWidget {
  final NarrationState playerState;
  final ReadingPalette palette;
  final VoidCallback onPlayPause;
  final VoidCallback? onSkipPrev;
  final VoidCallback? onSkipNext;

  const _ControlsRow({
    required this.playerState,
    required this.palette,
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
          width: 60,
          child: playerState.shouldShowSkipButtons
              ? Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Opacity(
                    opacity: playerState.canSkipPrevious ? 1.0 : 0.0,
                    child: _CircleControl(
                      icon: Icons.skip_previous,
                      size: 40,
                      filled: false,
                      palette: palette,
                      onPressed: onSkipPrev,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        _CircleControl(
          icon: playerState.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 52,
          filled: true,
          palette: palette,
          onPressed: playerState.isLoading || playerState.hasError
              ? null
              : onPlayPause,
        ),
        SizedBox(
          width: 60,
          child: playerState.shouldShowSkipButtons
              ? Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Opacity(
                    opacity: playerState.canSkipNext ? 1.0 : 0.0,
                    child: _CircleControl(
                      icon: Icons.skip_next,
                      size: 40,
                      filled: false,
                      palette: palette,
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

/// Circular control: a filled clay play button, or a ghost skip button, on
/// the dark audio bar.
class _CircleControl extends StatelessWidget {
  const _CircleControl({
    required this.icon,
    required this.size,
    required this.filled,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final double size;
  final bool filled;
  final ReadingPalette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: filled
          ? (disabled ? palette.clay.withValues(alpha: 0.5) : palette.clay)
          : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.5,
            color: filled ? const Color(0xFFFBF1E9) : palette.onDark2,
          ),
        ),
      ),
    );
  }
}
