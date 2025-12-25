import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:context_app/app.dart';
import 'package:context_app/common/config/api_config.dart';
import 'package:context_app/firebase_options.dart';

void main() async {
  runApp(await init());
}

Future<Widget> init() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Hive for local caching
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await _initializeSupabase();

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
