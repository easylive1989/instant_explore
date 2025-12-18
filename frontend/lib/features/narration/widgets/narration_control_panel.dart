import 'dart:ui';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/narration/widgets/save_to_passport_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 導覽播放控制面板
class NarrationControlPanel extends ConsumerWidget {
  final Place place;
  final Color primaryColor;
  final Color primaryColorShadow;
  final Color surfaceColor;
  final Color backgroundColor;
  final bool enableSave;

  const NarrationControlPanel({
    super.key,
    required this.place,
    required this.primaryColor,
    required this.primaryColorShadow,
    required this.surfaceColor,
    required this.backgroundColor,
    this.enableSave = true,
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
                  ],
                ),

                const SizedBox(height: 24),

                // Save Button
                if (enableSave)
                  SaveToPassportButton(
                    place: place,
                    surfaceColor: surfaceColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
