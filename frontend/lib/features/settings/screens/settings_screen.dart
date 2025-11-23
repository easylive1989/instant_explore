import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/auth/services/auth_service.dart';
import 'package:travel_diary/features/auth/providers/auth_state_provider.dart';
import 'package:travel_diary/features/tags/screens/tag_management_screen.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: ListView(
        children: [
          // 使用者資訊
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surfaceContainerHighest,
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
                          'auth.loginSuccess'.tr(),
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
            const Divider(height: 1),
          ],

          // 語言設定
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('settings.language'.tr()),
            subtitle: Text('settings.languageHint'.tr()),
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

          const Divider(),

          // 標籤管理
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text('settings.tagManagement'.tr()),
            subtitle: Text('settings.tagManagementHint'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TagManagementScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // 關於
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('settings.about'.tr()),
            subtitle: Text('${'settings.version'.tr()} 1.0.0'),
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

          const Divider(),

          // 登出
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'auth.logout'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}
