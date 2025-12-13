import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provider for app information (version, build number, etc.)
final appInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

/// Provider for formatted app version string
final appVersionStringProvider = FutureProvider<String>((ref) async {
  final packageInfo = await ref.watch(appInfoProvider.future);
  return 'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})';
});
