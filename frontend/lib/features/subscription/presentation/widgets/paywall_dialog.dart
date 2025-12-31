import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/subscription/domain/models/pass_type.dart';

/// 付費牆對話框
///
/// 當用戶超過免費使用額度時顯示
/// 注意：價格資訊在購買頁面從 RevenueCat 動態取得
class PaywallDialog extends StatelessWidget {
  /// 每日免費使用上限
  final int dailyFreeLimit;

  /// 點擊購買按鈕的回調
  final VoidCallback? onPurchaseTap;

  /// 點擊繼續使用免費版的回調
  final VoidCallback? onContinueFree;

  const PaywallDialog({
    super.key,
    this.dailyFreeLimit = 3,
    this.onPurchaseTap,
    this.onContinueFree,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 圖示
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // 標題
            Text(
              'subscription.paywall_title'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // 副標題
            Text(
              'subscription.paywall_subtitle'.tr(
                namedArgs: {'limit': dailyFreeLimit.toString()},
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 方案卡片（不顯示價格，價格在購買頁面顯示）
            _buildPassCard(
              context,
              passType: PassType.dayPass,
              icon: Icons.today,
            ),
            const SizedBox(height: 12),
            _buildPassCard(
              context,
              passType: PassType.tripPass,
              icon: Icons.flight_takeoff,
              isRecommended: true,
            ),
            const SizedBox(height: 24),

            // 購買按鈕
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPurchaseTap,
                child: Text('subscription.view_plans'.tr()),
              ),
            ),
            const SizedBox(height: 8),

            // 繼續使用免費版
            TextButton(
              onPressed: onContinueFree ?? () => Navigator.of(context).pop(),
              child: Text('subscription.continue_free'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassCard(
    BuildContext context, {
    required PassType passType,
    required IconData icon,
    bool isRecommended = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title = passType == PassType.dayPass
        ? 'subscription.day_pass'.tr()
        : 'subscription.trip_pass'.tr();

    final description = passType == PassType.dayPass
        ? 'subscription.day_pass_description'.tr()
        : 'subscription.trip_pass_description'.tr();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecommended
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: isRecommended
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28,
            color: isRecommended ? colorScheme.primary : colorScheme.onSurface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '推薦',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // 箭頭指示可查看詳情
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// 顯示付費牆對話框
Future<void> showPaywallDialog(
  BuildContext context, {
  int dailyFreeLimit = 3,
  VoidCallback? onPurchaseTap,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => PaywallDialog(
      dailyFreeLimit: dailyFreeLimit,
      onPurchaseTap: onPurchaseTap,
    ),
  );
}
