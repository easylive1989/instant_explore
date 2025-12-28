import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:context_app/app.dart';
import 'package:context_app/common/config/api_config.dart';
import 'package:context_app/firebase_options.dart';
import 'package:context_app/features/subscription/data/entitlement_repository_impl.dart';
import 'package:context_app/features/subscription/data/purchase_repository.dart';

/// 全域 ApiConfig 實例
late final ApiConfig apiConfig;

/// 全域 EntitlementRepository 實例
late final EntitlementRepositoryImpl entitlementRepository;

/// 全域 PurchaseRepository 實例
late final PurchaseRepository purchaseRepository;

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

  // Initialize Supabase (must be before EntitlementRepository)
  await _initializeSupabase();

  // Initialize EntitlementRepository (uses Supabase)
  entitlementRepository = EntitlementRepositoryImpl(Supabase.instance.client);

  // Initialize PurchaseRepository (RevenueCat)
  purchaseRepository = PurchaseRepository(apiConfig);
  await purchaseRepository.initialize();

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
  final apiConfig = ApiConfig.fromEnvironment();

  if (apiConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: apiConfig.supabaseUrl,
        anonKey: apiConfig.supabaseAnonKey,
      );
      debugPrint('✅ Supabase 初始化成功');
    } catch (error) {
      debugPrint('❌ Supabase 初始化失敗: $error');
      rethrow;
    }
  } else {
    debugPrint('⚠️ Supabase 未配置，請設定環境變數');
  }
}
