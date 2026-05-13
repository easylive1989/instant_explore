import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_state.dart';
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProgressBar(progress: playerState.progress),
            const SizedBox(height: 10),
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
            const SizedBox(height: 4),
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
  final NarrationState playerState;
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
          width: 40 + 20,
          child: playerState.shouldShowSkipButtons
              ? Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Opacity(
                    opacity: playerState.canSkipPrevious ? 1.0 : 0.0,
                    child: PillIconButton(
                      icon: Icons.skip_previous,
                      size: 40,
                      variant: PillIconButtonVariant.ghost,
                      onPressed: onSkipPrev,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        PillIconButton(
          icon: playerState.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 52,
          onPressed: playerState.isLoading || playerState.hasError
              ? null
              : onPlayPause,
        ),
        SizedBox(
          width: 40 + 20,
          child: playerState.shouldShowSkipButtons
              ? Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Opacity(
                    opacity: playerState.canSkipNext ? 1.0 : 0.0,
                    child: PillIconButton(
                      icon: Icons.skip_next,
                      size: 40,
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
