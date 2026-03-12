import 'dart:io' show Platform;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:context_app/app.dart';
import 'package:context_app/common/config/api_config.dart';
import 'package:context_app/firebase_options.dart';
import 'package:context_app/features/subscription/data/revenuecat_subscription_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 全域 ApiConfig 實例
late final ApiConfig apiConfig;

void main() async {
  runApp(await init());
}

Future<Widget> init() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load API configuration
  apiConfig = ApiConfig.fromEnvironment();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Hive for local caching
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await _initializeSupabase();

  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();

  // Initialize RevenueCat SDK (global, one-time)
  final revenueCatApiKey = Platform.isIOS
      ? apiConfig.revenueCatApiKeyIos
      : apiConfig.revenueCatApiKeyAndroid;
  if (revenueCatApiKey.isNotEmpty) {
    await RevenueCatSubscriptionService.configureSDK(apiKey: revenueCatApiKey);
  }

  return EasyLocalization(
    supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('zh', 'TW'),
    saveLocale: true,
    child: const ProviderScope(child: ContextureApp()),
  );
}

/// Initialize Supabase with configuration from environment variables
Future<void> _initializeSupabase() async {
  await Supabase.initialize(
    url: apiConfig.supabaseUrl,
    anonKey: apiConfig.supabaseAnonKey,
  );
}
