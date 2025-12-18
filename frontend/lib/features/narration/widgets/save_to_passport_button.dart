import 'package:context_app/core/config/app_colors.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 儲存到護照的按鈕
class SaveToPassportButton extends ConsumerStatefulWidget {
  final Place place;
  final Color surfaceColor;

  const SaveToPassportButton({
    super.key,
    required this.place,
    required this.surfaceColor,
  });

  @override
  ConsumerState<SaveToPassportButton> createState() =>
      _SaveToPassportButtonState();
}

class _SaveToPassportButtonState extends ConsumerState<SaveToPassportButton> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            (playerState.isLoading ||
                playerState.hasError ||
                playerState.narration == null ||
                _isSaving)
            ? null
            : () async {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('player_screen.please_login'.tr())),
                  );
                  return;
                }

                setState(() {
                  _isSaving = true;
                });

                try {
                  await playerController.saveToJourney(userId);
                  if (context.mounted) {
                    context.pushNamed('passport_success', extra: widget.place);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${'player_screen.save_failed'.tr()}: $e',
                        ),
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSaving = false;
                    });
                  }
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity:
              (playerState.isLoading ||
                  playerState.hasError ||
                  playerState.narration == null ||
                  _isSaving)
              ? 0.5
              : 1.0,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: widget.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _isSaving
                  ? const [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ]
                  : [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.bookmark_add,
                          color: AppColors.amber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'player_screen.save_to_passport'.tr(),
                        style: const TextStyle(
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
    );
  }
}
