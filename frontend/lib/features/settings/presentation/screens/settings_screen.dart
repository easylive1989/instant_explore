import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/settings/presentation/providers/settings_controller.dart';
import 'package:context_app/features/settings/presentation/providers/app_info_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final appVersionAsync = ref.watch(appVersionStringProvider);

    // Listen for state changes (e.g., successful logout)
    ref.listen<AsyncValue<void>>(settingsControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error_prefix'.tr()}: ${next.error}'),
          ),
        );
      }
      // Assuming auth state change listener in main app will handle navigation upon logout
    });

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
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                          context.locale.languageCode == 'en'
                              ? 'English'
                              : '繁體中文',
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
                _buildSectionHeader('settings.account'.tr()),
                const SizedBox(height: 8),
                _buildSectionContainer(AppColors.surfaceDark, [
                  _buildSettingsTile(
                    icon: Icons.logout,
                    iconColor: AppColors.textPrimaryDark.withValues(alpha: 0.7),
                    iconBgColor: AppColors.surfaceDarkPlayer,
                    title: 'settings.logout'.tr(),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textSecondaryDark,
                      size: 14,
                    ),
                    onTap: () async {
                      final confirm = await _showConfirmationDialog(
                        context,
                        'settings.logout'.tr(),
                        'settings.logout_confirm'.tr(),
                      );
                      if (confirm == true) {
                        await controller.logout();
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppColors.white10),
                  _buildSettingsTile(
                    icon: Icons.delete_forever,
                    iconColor: AppColors.error,
                    iconBgColor: AppColors.error.withValues(alpha: 0.2),
                    title: 'settings.delete_account'.tr(),
                    titleColor: AppColors.error,
                    subtitleColor: AppColors.error.withValues(alpha: 0.6),
                    onTap: () async {
                      final confirm = await _showConfirmationDialog(
                        context,
                        'settings.delete_account'.tr(),
                        'settings.delete_account_confirm'.tr(),
                        isDestructive: true,
                      );
                      if (confirm == true) {
                        await controller.deleteAccount();
                      }
                    },
                  ),
                ]),
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
                          color: AppColors.textSecondaryDark.withValues(
                            alpha: 0.7,
                          ),
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

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    Widget? trailing,
    Color? titleColor,
    Color? subtitleColor,
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

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content, {
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            title,
            style: const TextStyle(color: AppColors.textPrimaryDark),
          ),
          content: Text(
            content,
            style: const TextStyle(color: AppColors.textSecondaryDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'settings.cancel'.tr(),
                style: const TextStyle(color: AppColors.textSecondaryDark),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'settings.confirm'.tr(),
                style: TextStyle(
                  color: isDestructive ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
