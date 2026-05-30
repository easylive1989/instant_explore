import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:context_app/features/settings/data/local_appearance_preferences_repository.dart';
import 'package:context_app/features/settings/data/local_settings_preferences_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/settings/domain/repositories/appearance_preferences_repository.dart';
import 'package:context_app/features/settings/domain/repositories/settings_preferences_repository.dart';
import 'package:context_app/features/settings/presentation/controllers/appearance_notifier.dart';
import 'package:context_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:context_app/features/settings/presentation/controllers/language_provider.dart';

// ============================================================================
// Repositories
// ============================================================================

/// Persistence for settings (theme mode, etc). Override in tests with a
/// fake to keep them off SharedPreferences.
final settingsPreferencesRepositoryProvider =
    Provider<SettingsPreferencesRepository>((ref) {
      return LocalSettingsPreferencesRepository();
    });

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
    NotifierProvider<SettingsController, AsyncValue<void>>(
      SettingsController.new,
    );

// ============================================================================
// Appearance Providers (Field Journal theme)
// ============================================================================

/// Persistence for appearance choices. Override in tests with a fake.
final appearancePreferencesRepositoryProvider =
    Provider<AppearancePreferencesRepository>((ref) {
      return LocalAppearancePreferencesRepository();
    });

/// Field Journal appearance state (accent / reading / headline font).
final appearanceNotifierProvider =
    NotifierProvider<AppearanceNotifier, AppearanceState>(
      AppearanceNotifier.new,
    );
