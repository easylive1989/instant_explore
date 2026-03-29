import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:context_app/features/usage/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);
    final appVersionAsync = ref.watch(appVersionStringProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark.withValues(alpha: 0.95),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            height: 1.0,
          ),
        ),
        title: Text(
          'settings.title'.tr(),
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('settings.preferences'.tr()),
          const SizedBox(height: 8),
          _buildSectionContainer(AppColors.surfaceDark, [
            _buildSettingsTile(
              icon: Icons.language,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withValues(alpha: 0.2),
              title: 'settings.change_language'.tr(),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.locale.languageCode == 'en' ? 'English' : '繁體中文',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondaryDark,
                    size: 14,
                  ),
                ],
              ),
              onTap: () => controller.changeLanguage(context),
            ),
          ]),
          const SizedBox(height: 32),
          _buildSectionHeader('settings.daily_usage'.tr()),
          const SizedBox(height: 8),
          _buildUsageSection(ref),
          const SizedBox(height: 32),
          _buildSectionHeader('subscription.title'.tr()),
          const SizedBox(height: 8),
          _buildSubscriptionSection(context, ref),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                appVersionAsync.when(
                  data: (version) => Text(
                    version,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  ),
                  error: (_, __) => Text(
                    'settings.app_version'.tr(),
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'settings.copyright'.tr(),
                  style: TextStyle(
                    color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final statusAsync = ref.watch(subscriptionStatusProvider);

    if (isPremium) {
      final expirationDate = statusAsync.valueOrNull?.expirationDate;
      final formattedDate = expirationDate != null
          ? DateFormat.yMMMd().format(expirationDate)
          : '';
      return _buildSectionContainer(AppColors.surfaceDark, [
        _buildSettingsTile(
          icon: Icons.workspace_premium,
          iconColor: AppColors.amber,
          iconBgColor: AppColors.amber.withValues(alpha: 0.2),
          title: 'subscription.premium_active'.tr(),
          trailing: formattedDate.isNotEmpty
              ? Text(
                  'subscription.expires'.tr(namedArgs: {'date': formattedDate}),
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                )
              : null,
        ),
      ]);
    }

    return _buildSectionContainer(AppColors.surfaceDark, [
      _buildSettingsTile(
        icon: Icons.workspace_premium,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primary.withValues(alpha: 0.2),
        title: 'subscription.upgrade_cta'.tr(),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondaryDark,
          size: 14,
        ),
        onTap: () => context.pushNamed('subscription'),
      ),
    ]);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.white10),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildUsageSection(WidgetRef ref) {
    final usageAsync = ref.watch(usageStatusProvider);

    return _buildSectionContainer(AppColors.surfaceDark, [
      usageAsync.when(
        data: (status) => _buildSettingsTile(
          icon: Icons.bar_chart,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primary.withValues(alpha: 0.2),
          title: 'settings.daily_usage'.tr(),
          trailing: Text(
            'settings.remaining_today'.tr(
              namedArgs: {'remaining': status.remaining.toString()},
            ),
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
            ),
          ),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => _buildSettingsTile(
          icon: Icons.bar_chart,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primary.withValues(alpha: 0.2),
          title: 'settings.daily_usage'.tr(),
        ),
      ),
    ]);
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? AppColors.textPrimaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
