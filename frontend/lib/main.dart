import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/api_keys.dart';
import 'services/service_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Validate API keys (non-blocking)
    ApiKeys.validateKeys();

    // E2E 測試模式下跳過 Supabase 初始化
    if (!ApiKeys.isE2ETestMode) {
      // Initialize Supabase (必須初始化)
      if (ApiKeys.supabaseUrl.isEmpty || ApiKeys.supabaseAnonKey.isEmpty) {
        throw Exception(
          '❌ Supabase 憑證未設定！請檢查 .env 檔案中的 SUPABASE_URL 和 SUPABASE_ANON_KEY',
        );
      }

      await Supabase.initialize(
        url: ApiKeys.supabaseUrl,
        anonKey: ApiKeys.supabaseAnonKey,
      );
    } else {
      debugPrint('🧪 E2E 測試模式：跳過 Supabase 初始化');
    }

    // Initialize Services through ServiceProvider
    serviceProvider.initializeServices();

    runApp(const InstantExploreApp());
  } catch (e) {
    debugPrint('❌ 應用程式初始化失敗: $e');
    // 即使初始化失敗，仍嘗試啟動 app
    runApp(const InstantExploreApp());
  }
}

class InstantExploreApp extends StatelessWidget {
  const InstantExploreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instant Explore',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    if (ApiKeys.isE2ETestMode) {
      // E2E 測試模式：使用 Fake 服務的認證狀態監聽
      debugPrint('🧪 AuthWrapper: 使用測試模式認證監聽');
      serviceProvider.authService.authStateChanges.listen((data) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      // 正常模式：使用 Supabase 認證狀態監聽
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      bool isSignedIn = false;

      if (ApiKeys.isE2ETestMode) {
        // E2E 測試模式：使用 Fake 服務檢查登入狀態
        isSignedIn = serviceProvider.authService.isSignedIn;
        debugPrint('🧪 AuthWrapper: 測試模式登入狀態 = $isSignedIn');
      } else {
        // 正常模式：使用 Supabase 檢查登入狀態
        final session = Supabase.instance.client.auth.currentSession;
        isSignedIn = session != null;
      }

      if (isSignedIn) {
        // 使用者已登入，顯示首頁
        return const HomeScreen();
      } else {
        // 使用者未登入，顯示登入畫面
        return const LoginScreen();
      }
    } catch (e) {
      debugPrint('❌ AuthWrapper build error: $e');
      return const LoginScreen();
    }
  }
}
