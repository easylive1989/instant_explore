import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/auth/services/auth_service.dart';
import 'package:travel_diary/features/auth/providers/auth_state_provider.dart';
import 'package:travel_diary/features/tags/screens/tag_management_screen.dart';
import 'package:travel_diary/shared/widgets/settings_section.dart';
import 'package:travel_diary/shared/widgets/settings_tile.dart';

/// 設定畫面
///
/// 顯示應用程式設定選項與使用者資訊
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('auth.logoutConfirmTitle'.tr()),
        content: Text('auth.logoutConfirmMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('auth.logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('auth.loginSuccess'.tr())));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'auth.loginFailed'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('auth.deleteAccountConfirmTitle'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('auth.deleteAccountConfirmMessage'.tr()),
            const SizedBox(height: 16),
            Text(
              'auth.deleteAccountWarning'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: Text('auth.deleteAccount'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('auth.deleteAccountSuccess'.tr())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'auth.deleteAccountFailed'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // 使用者資訊
          if (user != null) ...[
            SettingsSection(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          user.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email ?? 'settings.account'.tr(),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'settings.planTrial'.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 應用程式設定
          SettingsSection(
            children: [
              SettingsTile(
                leading: const Icon(Icons.language),
                title: 'settings.language'.tr(),
                subtitle: 'settings.languageHint'.tr(),
                trailing: DropdownButton<Locale>(
                  value: context.locale,
                  underline: const SizedBox(),
                  items: context.supportedLocales.map((locale) {
                    // 使用該語言本身的名稱顯示，不翻譯
                    String languageName;
                    switch (locale.toString()) {
                      case 'zh_TW':
                        languageName = '繁體中文';
                        break;
                      case 'en':
                        languageName = 'English';
                        break;
                      default:
                        languageName = locale.toString();
                    }
                    return DropdownMenuItem(
                      value: locale,
                      child: Text(languageName),
                    );
                  }).toList(),
                  onChanged: (newLocale) {
                    if (newLocale != null) {
                      context.setLocale(newLocale);
                    }
                  },
                ),
              ),
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              SettingsTile(
                leading: const Icon(Icons.label_outline),
                title: 'settings.tagManagement'.tr(),
                subtitle: 'settings.tagManagementHint'.tr(),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TagManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 系統功能
          SettingsSection(
            children: [
              SettingsTile(
                leading: const Icon(Icons.info_outline),
                title: 'settings.about'.tr(),
                subtitle: '${'settings.version'.tr()} 1.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'app.name'.tr(),
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2025 ${'app.name'.tr()}',
                    children: [
                      const SizedBox(height: 16),
                      Text('app.tagline'.tr()),
                    ],
                  );
                },
              ),
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              SettingsTile(
                leading: const Icon(Icons.logout),
                title: 'auth.logout'.tr(),
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () => _signOut(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 危險操作
          SettingsSection(
            children: [
              SettingsTile(
                leading: const Icon(Icons.delete_forever),
                title: 'auth.deleteAccount'.tr(),
                subtitle: 'auth.deleteAccountHint'.tr(),
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () => _deleteAccount(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
