import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/shared/widgets/midnight/midnight.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 儲存到護照的按鈕。
///
/// 導覽內容已在生成時自動儲存到歷程，此按鈕僅導航到成功頁面。
class SaveToPassportButton extends ConsumerWidget {
  final Place place;

  const SaveToPassportButton({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final isDisabled =
        playerState.isLoading ||
        playerState.hasError ||
        playerState.content == null;

    return PillButton(
      label: easy.tr('player_screen.save_to_passport'),
      icon: Icons.bookmark_add,
      variant: PillButtonVariant.secondary,
      fullWidth: true,
      onPressed: isDisabled
          ? null
          : () => context.pushNamed('passport_success', extra: place),
    );
  }
}
