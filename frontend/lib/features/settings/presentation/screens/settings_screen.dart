import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/settings/presentation/providers/settings_controller.dart';
import 'package:context_app/features/settings/presentation/providers/app_info_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final appVersionAsync = ref.watch(appVersionStringProvider);

    // Colors
    const primaryColor = Color(0xFF137FEC);
    const backgroundColor = Color(0xFF101922);
    const surfaceColor = Color(0xFF1C2630);

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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withValues(alpha: 0.95),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[800], height: 1.0),
        ),
        title: Text(
          'settings.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
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
                _buildSectionContainer(surfaceColor, [
                  _buildSettingsTile(
                    icon: Icons.language,
                    iconColor: primaryColor,
                    iconBgColor: primaryColor.withValues(alpha: 0.2),
                    title: 'settings.change_language'.tr(),
                    subtitle: 'settings.change_language_subtitle'.tr(),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.locale.languageCode == 'en'
                              ? 'English'
                              : '繁體中文',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
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
                _buildSectionContainer(surfaceColor, [
                  _buildSettingsTile(
                    icon: Icons.logout,
                    iconColor: Colors.grey[300]!,
                    iconBgColor: Colors.grey[800]!,
                    title: 'settings.logout'.tr(),
                    subtitle: 'settings.logout_subtitle'.tr(),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
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
                  const Divider(height: 1, color: Colors.white10),
                  _buildSettingsTile(
                    icon: Icons.delete_forever,
                    iconColor: Colors.red,
                    iconBgColor: Colors.red.withValues(alpha: 0.2),
                    title: 'settings.delete_account'.tr(),
                    subtitle: 'settings.delete_account_subtitle'.tr(),
                    titleColor: Colors.red[400],
                    subtitleColor: Colors.red[400]!.withValues(alpha: 0.6),
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
                            color: Colors.grey,
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
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'settings.copyright'.tr(),
                        style: TextStyle(color: Colors.grey[700], fontSize: 10),
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
          color: Colors.grey,
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
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor ?? Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
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
          backgroundColor: const Color(0xFF1C2630),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(content, style: const TextStyle(color: Colors.grey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'settings.cancel'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'settings.confirm'.tr(),
                style: TextStyle(
                  color: isDestructive ? Colors.red : const Color(0xFF137FEC),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
