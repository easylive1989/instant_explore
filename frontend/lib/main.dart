import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/api_keys.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Validate API keys (non-blocking)
    ApiKeys.validateKeys();

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

    // Initialize Auth Service
    AuthService().initialize();

    runApp(const InstantExploreApp());
  } catch (e) {
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
    // Supabase 已經在 main() 中初始化，直接設定監聽器
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Supabase 已經在 main() 中初始化，直接檢查認證狀態
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        // 使用者已登入，顯示首頁
        return const HomeScreen();
      } else {
        // 使用者未登入，顯示登入畫面
        return const LoginScreen();
      }
    } catch (e) {
      return const LoginScreen();
    }
  }
}
