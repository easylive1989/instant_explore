import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_diary/core/utils/go_router_refresh_stream.dart';
import 'package:travel_diary/features/auth/services/auth_service.dart';
import 'package:travel_diary/features/auth/screens/login_screen.dart';
import 'package:travel_diary/features/auth/screens/register_screen.dart';
import 'package:travel_diary/features/diary/screens/diary_list_screen.dart';
import 'package:travel_diary/features/diary/screens/diary_detail_screen.dart';
import 'package:travel_diary/features/diary/screens/diary_create_screen.dart';
import 'package:travel_diary/features/images/widgets/full_image_viewer.dart';
import 'package:travel_diary/features/settings/screens/settings_screen.dart';
import 'package:travel_diary/features/tags/screens/tag_management_screen.dart';

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
          name: 'diary-list',
          builder: (context, state) => const DiaryListScreen(),
          routes: [
            // Settings
            GoRoute(
              path: 'settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                // Tag Management
                GoRoute(
                  path: 'tags',
                  name: 'tag-management',
                  builder: (context, state) => const TagManagementScreen(),
                ),
              ],
            ),
            // Diary Detail (supports deep linking, but uses Navigator.push for return values)
            GoRoute(
              path: 'diary/:id',
              name: 'diary-detail',
              builder: (context, state) {
                final diaryId = state.pathParameters['id']!;
                return DiaryDetailScreen(diaryId: diaryId);
              },
            ),
            // Create Diary
            GoRoute(
              path: 'diary/create',
              name: 'diary-create',
              builder: (context, state) => const DiaryCreateScreen(),
            ),
            // Edit Diary
            GoRoute(
              path: 'diary/:id/edit',
              name: 'diary-edit',
              builder: (context, state) {
                final diaryId = state.pathParameters['id']!;
                return DiaryCreateScreen(diaryId: diaryId);
              },
            ),
            // Full Image Viewer
            GoRoute(
              path: 'images',
              name: 'image-viewer',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>;
                return FullImageViewer.network(
                  imageUrls: extra['imageUrls'] as List<String>,
                  initialIndex: extra['initialIndex'] as int,
                );
              },
            ),
          ],
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
