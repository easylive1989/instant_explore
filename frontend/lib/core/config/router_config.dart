import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_diary/core/utils/go_router_refresh_stream.dart';
import 'package:travel_diary/features/auth/services/auth_service.dart';
import 'package:travel_diary/features/auth/screens/login_screen.dart';
import 'package:travel_diary/features/auth/screens/register_screen.dart';
import 'package:travel_diary/features/home/screens/home_screen.dart';

/// Router configuration using go_router for declarative navigation.
///
/// Handles authentication redirects and defines all app routes.
/// Uses a hybrid approach:
/// - go_router for main screens without return values
/// - Navigator.push for screens that need to return values
class RouterConfig {
  RouterConfig._();

  /// Create the GoRouter instance
  static GoRouter createRouter(Ref ref) {
    // 監聽認證狀態變化，當狀態改變時重新評估路由
    final authService = ref.watch(authServiceProvider);
    final authStateStream = authService.authStateChanges;

    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: false,
      refreshListenable: GoRouterRefreshStream(authStateStream),
      redirect: (context, state) {
        final supabase = Supabase.instance.client;
        final isAuthenticated = supabase.auth.currentSession != null;
        final isGoingToLogin = state.matchedLocation == '/login';
        final isGoingToRegister = state.matchedLocation == '/register';

        // Redirect to login if not authenticated and not already going there
        if (!isAuthenticated && !isGoingToLogin && !isGoingToRegister) {
          return '/login';
        }

        // Redirect to home if authenticated and going to login/register
        if (isAuthenticated && (isGoingToLogin || isGoingToRegister)) {
          return '/';
        }

        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
          routes: const [],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found: ${state.matchedLocation}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider for the GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  return RouterConfig.createRouter(ref);
});
