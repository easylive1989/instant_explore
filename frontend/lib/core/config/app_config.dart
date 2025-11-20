/// Application-wide configuration settings.
///
/// This class contains general app configuration that doesn't fit into
/// specific categories like API keys or theming.
class AppConfig {
  AppConfig._();

  /// App name displayed in UI
  static const String appName = '旅食日記';

  /// App version (should match pubspec.yaml)
  static const String appVersion = '1.0.0';

  /// Enable debug mode features
  static const bool isDebugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: false,
  );

  /// Enable analytics
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  /// Maximum number of images per diary entry
  static const int maxImagesPerDiary = 10;

  /// Image upload max size in MB
  static const int maxImageSizeMB = 10;

  /// Default search radius in meters for nearby places
  static const int defaultSearchRadiusMeters = 5000;

  /// Maximum search radius in meters
  static const int maxSearchRadiusMeters = 50000;
}
