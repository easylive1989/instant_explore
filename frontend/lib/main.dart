import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/api_config.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: InstantExploreApp()));
}

class InstantExploreApp extends ConsumerWidget {
  const InstantExploreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiConfig = ref.watch(apiConfigProvider);

    // 初始化 Supabase
    _initializeSupabase(apiConfig);

    return MaterialApp(
      title: 'Instant Explore',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }

  /// 初始化 Supabase
  void _initializeSupabase(ApiConfig apiConfig) {
    if (apiConfig.isSupabaseConfigured) {
      // 在 Supabase 已配置時初始化
      Supabase.initialize(
        url: apiConfig.supabaseUrl,
        anonKey: apiConfig.supabaseAnonKey,
      ).catchError((error) {
        debugPrint('❌ Supabase 初始化失敗: $error');
        return Supabase.instance;
      });
    } else {
      debugPrint('⚠️ Supabase 未配置，跳過初始化');
    }
  }
}
