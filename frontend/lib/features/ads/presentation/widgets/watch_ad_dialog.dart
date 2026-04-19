import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/ads/providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';

/// 顯示觀看廣告對話框
///
/// 回傳 true 表示已觀看並獲得獎勵，false/null 表示取消，
/// 回傳 'subscribe' 表示使用者選擇訂閱
Future<dynamic> showWatchAdDialog(BuildContext context, WidgetRef ref) {
  return showAdaptiveModalBottomSheet<dynamic>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _WatchAdDialog(ref: ref),
  );
}

class _WatchAdDialog extends StatefulWidget {
  final WidgetRef ref;

  const _WatchAdDialog({required this.ref});

  @override
  State<_WatchAdDialog> createState() => _WatchAdDialogState();
}

class _WatchAdDialogState extends State<_WatchAdDialog> {
  bool _isLoading = false;

  Future<void> _watchAd() async {
    setState(() => _isLoading = true);

    try {
      final adService = widget.ref.read(rewardedAdServiceProvider);
      final watched = await adService.showAd();

      if (watched) {
        final usageRepo = widget.ref.read(usageRepositoryProvider);
        await usageRepo.addBonusFromAd();
        // 重新整理 usageStatusProvider
        widget.ref.invalidate(usageStatusProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ads.ad_reward_success'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.play_circle_outline,
              size: 28,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'ads.quota_exceeded_title'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'ads.watch_ad_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Watch Ad Button
          AdaptiveButton(
            expanded: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: AdaptiveProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow, color: Colors.white),
            onPressed: _isLoading ? null : _watchAd,
            child: Text(
              'ads.watch_video'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Subscribe Button
          AdaptiveButton(
            expanded: true,
            style: AdaptiveButtonStyle.outlined,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            icon: const Icon(Icons.workspace_premium, color: AppColors.primary),
            onPressed: _isLoading
                ? null
                : () {
                    // 回傳 'subscribe' 讓呼叫端導航
                    Navigator.of(context).pop('subscribe');
                  },
            child: Text(
              'subscription.upgrade_cta'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel
          AdaptiveButton(
            style: AdaptiveButtonStyle.text,
            onPressed: _isLoading
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text(
              'settings.cancel'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
