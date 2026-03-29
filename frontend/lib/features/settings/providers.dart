import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:context_app/features/settings/presentation/controllers/language_provider.dart';

// ============================================================================
// App Info Providers
// ============================================================================

/// Provider for app information (version, build number, etc.)
final appInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

/// Provider for formatted app version string
final appVersionStringProvider = FutureProvider<String>((ref) async {
  final packageInfo = await ref.watch(appInfoProvider.future);
  return 'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})';
});

// ============================================================================
// Language Providers
// ============================================================================

/// 當前語言 Provider
final currentLanguageProvider = NotifierProvider<LanguageNotifier, Language>(
  LanguageNotifier.new,
);

// ============================================================================
// Controller Providers
// ============================================================================

/// 設定控制器 Provider
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<void>>(
      (ref) => SettingsController(),
    );
