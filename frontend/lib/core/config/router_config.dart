import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_diary/features/auth/screens/login_screen.dart';
import 'package:travel_diary/features/diary/screens/diary_list_screen.dart';

/// Router configuration using go_router for declarative navigation.
///
/// Handles authentication redirects and defines all app routes.
/// Note: For now, we use simple routes. Complex navigation with params
/// will be handled by traditional Navigator.push in screens.
class RouterConfig {
  RouterConfig._();

  /// Create the GoRouter instance
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: false,
      redirect: (context, state) {
        final supabase = Supabase.instance.client;
        final isAuthenticated = supabase.auth.currentSession != null;
        final isGoingToLogin = state.matchedLocation == '/login';

        // Redirect to login if not authenticated and not already going there
        if (!isAuthenticated && !isGoingToLogin) {
          return '/login';
        }

        // Redirect to home if authenticated and going to login
        if (isAuthenticated && isGoingToLogin) {
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
          path: '/',
          name: 'diary-list',
          builder: (context, state) => const DiaryListScreen(),
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
  return RouterConfig.createRouter();
});
