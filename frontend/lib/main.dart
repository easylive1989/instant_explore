import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/api_config.dart';
import 'providers/service_providers.dart';
import 'screens/login_screen.dart';
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
      home: const AuthWrapper(),
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

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    final authService = ref.read(authServiceProvider);

    // 統一使用 authService 的認證狀態監聽
    authService.authStateChanges.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final authService = ref.watch(authServiceProvider);

      // 統一使用 authService 檢查登入狀態
      if (authService.isSignedIn) {
        return const HomeScreen();
      } else {
        return const LoginScreen();
      }
    } catch (e) {
      debugPrint('❌ AuthWrapper build error: $e');
      return const LoginScreen();
    }
  }
}
