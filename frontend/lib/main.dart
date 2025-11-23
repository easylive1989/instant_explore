import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_diary/app.dart';
import 'package:travel_diary/core/config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Supabase
  await _initializeSupabase();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('zh', 'TW'),
      saveLocale: true,
      child: const ProviderScope(child: TravelDiaryApp()),
    ),
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
