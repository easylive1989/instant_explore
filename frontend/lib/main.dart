import 'dart:io' show Platform;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:context_app/app.dart';
import 'package:context_app/app/config/api_config.dart';
import 'package:context_app/features/analytics/providers.dart';
import 'package:context_app/features/auth/data/supabase_auth_service.dart';
import 'package:context_app/features/onboarding/providers.dart';
import 'package:context_app/firebase_options.dart';
import 'package:context_app/features/subscription/data/revenuecat_subscription_service.dart';
import 'package:logging/logging.dart';

/// 全域 ApiConfig 實例
late final ApiConfig apiConfig;

final _log = Logger('bootstrap');

void main() async {
  runApp(await init());
}

Future<Widget> init() async {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  // Load API configuration
  apiConfig = ApiConfig.fromEnvironment();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Hive for local caching
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Activate App Check before any Firebase AI call so Gemini requests carry
  // a valid attestation token. Non-fatal on failure.
  await _initializeAppCheck();

  // Initialize Supabase
  await _initializeSupabase();

  // Ensure an (anonymous) session so authenticated backend APIs are
  // reachable before the user signs in. Requires "Anonymous sign-ins" to
  // be enabled in Supabase Auth; a failure here is non-fatal — the app
  // still launches and backend calls will surface a 401 instead.
  await _ensureSignedIn();

  // Initialize RevenueCat SDK (global, one-time) and identify it with the
  // Supabase user id so server-side webhooks/reconcile attribute purchases
  // to the right backend user.
  final revenueCatApiKey = Platform.isIOS
      ? apiConfig.revenueCatApiKeyIos
      : apiConfig.revenueCatApiKeyAndroid;
  if (revenueCatApiKey.isNotEmpty) {
    await RevenueCatSubscriptionService.configureSDK(apiKey: revenueCatApiKey);
    await _identifyRevenueCat();
  }

  // Eagerly resolve SharedPreferences so analytics providers
  // (consent repository, install id) can be read synchronously on the
  // first frame without callers having to deal with AsyncLoading.
  final sharedPreferences = await SharedPreferences.getInstance();

  return EasyLocalization(
    supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('zh', 'TW'),
    saveLocale: true,
    child: ProviderScope(
      overrides: [
        defaultOnboardingRepositoryOverride,
        sharedPreferencesProvider.overrideWith(
          (ref) async => sharedPreferences,
        ),
      ],
      child: const LorescapeApp(),
    ),
  );
}

/// Activates Firebase App Check so only the genuine app binary can call
/// Firebase AI. Debug builds use the debug provider so local development and
/// simulators are not blocked. Activation failure is non-fatal: the app still
/// launches and unverified requests are simply rejected once enforcement is on.
Future<void> _initializeAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestProvider(),
    );
  } catch (e, stack) {
    _log.warning('Firebase App Check activation failed at startup', e, stack);
  }
}

/// Initialize Supabase with configuration from environment variables
Future<void> _initializeSupabase() async {
  await Supabase.initialize(
    url: apiConfig.supabaseUrl,
    anonKey: apiConfig.supabaseAnonKey,
  );
}

/// Ensure an anonymous session exists so backend calls are authenticated.
///
/// Best-effort: a failure (e.g. anonymous sign-ins disabled) is logged but
/// does not block startup.
Future<void> _ensureSignedIn() async {
  try {
    await SupabaseAuthService(apiConfig: apiConfig).ensureSignedIn();
  } catch (e, stack) {
    _log.warning('Anonymous sign-in failed at startup', e, stack);
  }
}

/// Tie the RevenueCat app user id to the current Supabase user id.
///
/// Best-effort: a failure is logged but does not block startup.
Future<void> _identifyRevenueCat() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  try {
    await RevenueCatSubscriptionService.identify(userId);
  } catch (e, stack) {
    _log.warning('RevenueCat identify failed at startup', e, stack);
  }
}
