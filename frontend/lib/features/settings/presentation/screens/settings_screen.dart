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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            height: 1.0,
          ),
        ),
        title: Text('settings.title'.tr(), style: textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _SectionHeader(title: 'settings.preferences'.tr()),
          const SizedBox(height: 8),
          _SectionContainer(
            children: [
              _LanguageTile(controller: controller),
              _Divider(),
              const _ThemeModeTile(),
            ],
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'settings.daily_usage'.tr()),
          const SizedBox(height: 8),
          _UsageSection(ref: ref),
          const SizedBox(height: 32),
          _SectionHeader(title: 'subscription.title'.tr()),
          const SizedBox(height: 8),
          _SubscriptionSection(context: context, ref: ref),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                appVersionAsync.when(
                  data: (version) => Text(
                    version,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  ),
                  error: (_, __) => Text(
                    'settings.app_version'.tr(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'settings.copyright'.tr(),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
}

// ============================================================================
// Section widgets
// ============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(
          BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 60,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ============================================================================
// Tile widgets
// ============================================================================

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.controller});

  final dynamic controller;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.language,
      iconColor: AppColors.primary,
      iconBgColor: AppColors.primary.withValues(alpha: 0.2),
      title: 'settings.change_language'.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.locale.languageCode == 'en' ? 'English' : '繁體中文',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 14,
          ),
        ],
      ),
      onTap: () => controller.changeLanguage(context),
    );
  }
}

class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return _SettingsTile(
      icon: isDark ? Icons.dark_mode : Icons.light_mode,
      iconColor: isDark ? AppColors.amber : AppColors.primary,
      iconBgColor: isDark
          ? AppColors.amber.withValues(alpha: 0.2)
          : AppColors.primary.withValues(alpha: 0.2),
      title: 'settings.theme'.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _label(themeMode),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: themeMode == ThemeMode.dark,
            activeThumbColor: AppColors.primary,
            onChanged: (value) =>
                notifier.setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
          ),
        ],
      ),
    );
  }

  String _label(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => 'settings.theme_dark'.tr(),
    ThemeMode.light => 'settings.theme_light'.tr(),
    ThemeMode.system => 'settings.theme_system'.tr(),
  };
}

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({required this.context, required this.ref});

  final BuildContext context;
  final WidgetRef ref;

  @override
  Widget build(BuildContext outerContext) {
    final isPremium = ref.watch(isPremiumProvider);
    final statusAsync = ref.watch(subscriptionStatusProvider);
    final colorScheme = Theme.of(outerContext).colorScheme;

    if (isPremium) {
      final expirationDate = statusAsync.valueOrNull?.expirationDate;
      final formattedDate = expirationDate != null
          ? DateFormat.yMMMd().format(expirationDate)
          : '';
      return _SectionContainer(
        children: [
          _SettingsTile(
            icon: Icons.workspace_premium,
            iconColor: AppColors.amber,
            iconBgColor: AppColors.amber.withValues(alpha: 0.2),
            title: 'subscription.premium_active'.tr(),
            trailing: formattedDate.isNotEmpty
                ? Text(
                    'subscription.expires'.tr(
                      namedArgs: {'date': formattedDate},
                    ),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
        ],
      );
    }

    return _SectionContainer(
      children: [
        _SettingsTile(
          icon: Icons.workspace_premium,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primary.withValues(alpha: 0.2),
          title: 'subscription.upgrade_cta'.tr(),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: colorScheme.onSurfaceVariant,
            size: 14,
          ),
          onTap: () => outerContext.pushNamed('subscription'),
        ),
      ],
    );
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(usageStatusProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionContainer(
      children: [
        usageAsync.when(
          data: (status) => _SettingsTile(
            icon: Icons.bar_chart,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primary.withValues(alpha: 0.2),
            title: 'settings.daily_usage'.tr(),
            trailing: Text(
              isPremium
                  ? 'subscription.unlimited_access'.tr()
                  : 'settings.remaining_today'.tr(
                      namedArgs: {'remaining': status.remaining.toString()},
                    ),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
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
          error: (_, __) => _SettingsTile(
            icon: Icons.bar_chart,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primary.withValues(alpha: 0.2),
            title: 'settings.daily_usage'.tr(),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Base tile
// ============================================================================

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
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
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
