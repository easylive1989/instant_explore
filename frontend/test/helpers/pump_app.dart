import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Common widget test bootstrap used across all screen tests.
///
/// Installs an in-memory [SharedPreferences] before each test and ensures
/// [EasyLocalization] is initialised so screens can call `tr()` and read
/// `context.locale` without crashing.
Future<void> initTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
}

/// AssetLoader that returns no translations so `tr()` always returns the key.
///
/// Keeping translations out of the tests lets assertions match the raw
/// i18n key, which is both deterministic and locale-independent.
class _EmptyAssetLoader extends AssetLoader {
  const _EmptyAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      <String, dynamic>{};
}

const _kEmptyAssetLoader = _EmptyAssetLoader();

/// Pumps [child] inside a minimal app host with [EasyLocalization],
/// [ProviderScope] and a [MaterialApp] wrapper.
///
/// Use this for screens that do not rely on GoRouter navigation.
Future<void> pumpScreen(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
  Locale locale = const Locale('zh', 'TW'),
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: locale,
      startLocale: locale,
      assetLoader: _kEmptyAssetLoader,
      useOnlyLangCode: false,
      child: ProviderScope(
        overrides: overrides,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: child,
          ),
        ),
      ),
    ),
  );
  await _settleBoot(tester);
}

/// Pumps a GoRouter-driven app for screens that rely on routing.
///
/// Pass the list of [routes] the test cares about along with an optional
/// [initialLocation]. Provider [overrides] replace production services.
Future<void> pumpRouterApp(
  WidgetTester tester, {
  required List<RouteBase> routes,
  String initialLocation = '/',
  Object? initialExtra,
  List<Override> overrides = const [],
  Locale locale = const Locale('zh', 'TW'),
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    initialExtra: initialExtra,
    routes: routes,
  );

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: locale,
      startLocale: locale,
      assetLoader: _kEmptyAssetLoader,
      useOnlyLangCode: false,
      child: ProviderScope(
        overrides: overrides,
        child: Builder(
          builder: (context) => MaterialApp.router(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            routerConfig: router,
          ),
        ),
      ),
    ),
  );
  await _settleBoot(tester);
}

/// Pumps enough frames for [EasyLocalization] to finish its async
/// bootstrap and for first-frame post-callbacks to run.
Future<void> _settleBoot(WidgetTester tester) async {
  for (var i = 0; i < 3; i += 1) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}
