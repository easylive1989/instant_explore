import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/features/auth/domain/services/auth_service.dart';
import 'package:context_app/features/auth/providers.dart';
import 'package:context_app/features/onboarding/providers.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:context_app/features/sync/providers.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/midnight/midnight.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);
    final appVersionAsync = ref.watch(appVersionStringProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: MidnightAppBar(title: Text('settings.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _SectionHeader(title: 'settings.preferences'.tr()),
          const SizedBox(height: 8),
          _SectionContainer(children: [_LanguageTile(controller: controller)]),
          const SizedBox(height: 32),
          _SectionHeader(title: 'settings.account_section'.tr()),
          const SizedBox(height: 8),
          const _AccountSection(),
          const SizedBox(height: 32),
          _SectionHeader(title: 'settings.sync_section'.tr()),
          const SizedBox(height: 8),
          const _SyncSection(),
          const SizedBox(height: 32),
          _SectionHeader(title: 'settings.daily_usage'.tr()),
          const SizedBox(height: 8),
          _UsageSection(ref: ref),
          const SizedBox(height: 32),
          _SectionHeader(title: 'settings_onboarding.section'.tr()),
          const SizedBox(height: 8),
          const _OnboardingSection(),
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
                    child: AdaptiveProgressIndicator(strokeWidth: 1),
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
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(letterSpacing: 1.0),
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

// ============================================================================
// Tile widgets
// ============================================================================

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.controller});

  final dynamic controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SettingsTile(
      icon: Icons.language,
      iconColor: colorScheme.primary,
      iconBgColor: colorScheme.primary.withValues(alpha: 0.2),
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

class _OnboardingSection extends ConsumerWidget {
  const _OnboardingSection();

  Future<void> _confirmReplay(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings_onboarding.confirm_replay_title'.tr()),
        content: Text('settings_onboarding.confirm_replay_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('journey.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('settings_onboarding.confirm_replay_action'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(onboardingControllerProvider.notifier).resetAll();
    if (!context.mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SectionContainer(
      children: [
        _SettingsTile(
          icon: Icons.school_outlined,
          iconColor: colorScheme.primary,
          iconBgColor: colorScheme.primary.withValues(alpha: 0.2),
          title: 'settings_onboarding.replay'.tr(),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: colorScheme.onSurfaceVariant,
            size: 14,
          ),
          onTap: () => _confirmReplay(context, ref),
        ),
      ],
    );
  }
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
            iconColor: colorScheme.tertiary,
            iconBgColor: colorScheme.tertiary.withValues(alpha: 0.2),
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
          iconColor: colorScheme.primary,
          iconBgColor: colorScheme.primary.withValues(alpha: 0.2),
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
            iconColor: colorScheme.primary,
            iconBgColor: colorScheme.primary.withValues(alpha: 0.2),
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
                child: AdaptiveProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => _SettingsTile(
            icon: Icons.bar_chart,
            iconColor: colorScheme.primary,
            iconBgColor: colorScheme.primary.withValues(alpha: 0.2),
            title: 'settings.daily_usage'.tr(),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Account & Sync sections
// ============================================================================

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  Future<void> _handleSignIn(
    BuildContext context,
    WidgetRef ref, {
    required bool useApple,
  }) async {
    final service = ref.read(authServiceProvider);
    try {
      if (useApple) {
        await service.signInWithApple();
      } else {
        await service.signInWithGoogle();
      }
    } on AuthCancelledException {
      return;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('settings.sign_in_failed'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.sign_out'.tr()),
        content: Text('settings.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('settings.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('settings.sign_out'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (user != null) {
      return _SectionContainer(
        children: [
          _SettingsTile(
            icon: Icons.person,
            iconColor: colorScheme.primary,
            iconBgColor: colorScheme.primary.withValues(alpha: 0.2),
            title: 'settings.account_signed_in_as'.tr(
              namedArgs: {'name': user.displayName ?? user.email ?? user.id},
            ),
            trailing: TextButton(
              onPressed: () => _handleSignOut(context, ref),
              child: Text('settings.sign_out'.tr()),
            ),
          ),
        ],
      );
    }

    return _SectionContainer(
      children: [
        _SettingsTile(
          icon: Icons.person_outline,
          iconColor: colorScheme.primary,
          iconBgColor: colorScheme.primary.withValues(alpha: 0.2),
          title: 'settings.account_not_signed_in'.tr(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                key: const ValueKey('sign_in_google'),
                icon: const Icon(Icons.login),
                label: Text('settings.sign_in_google'.tr()),
                onPressed: () => _handleSignIn(context, ref, useApple: false),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('sign_in_apple'),
                icon: const Icon(Icons.apple),
                label: Text('settings.sign_in_apple'.tr()),
                onPressed: () => _handleSignIn(context, ref, useApple: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncSection extends ConsumerWidget {
  const _SyncSection();

  Future<void> _handleToggle(WidgetRef ref, bool value) async {
    await ref.read(syncSettingsProvider.notifier).setEnabled(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final enabled = ref.watch(syncSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isSignedIn = user != null;

    final subtitle = !isSignedIn
        ? 'settings.sync_requires_signin'.tr()
        : (enabled
              ? 'settings.sync_toggle_subtitle_on'.tr()
              : 'settings.sync_toggle_subtitle_off'.tr());

    return _SectionContainer(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_sync,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settings.sync_toggle'.tr(),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const ValueKey('sync_toggle_switch'),
                value: enabled && isSignedIn,
                onChanged: isSignedIn ? (v) => _handleToggle(ref, v) : null,
              ),
            ],
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
