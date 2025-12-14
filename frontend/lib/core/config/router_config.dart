import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/features/main_screen.dart';
import 'package:context_app/features/explore/models/place.dart';
import 'package:context_app/features/narration/screens/select_narration_style_screen.dart';
import 'package:context_app/features/narration/screens/narration_screen.dart';
import 'package:context_app/features/narration/models/narration_style.dart';
import 'package:context_app/features/journey/screens/save_success_screen.dart';
import 'package:context_app/features/auth/screens/login_screen.dart';
import 'package:context_app/features/auth/screens/register_screen.dart';
import 'package:context_app/features/auth/services/auth_service.dart';
import 'package:context_app/core/config/go_router_refresh_stream.dart';

/// Router refresh provider
/// 監聽認證狀態變化並通知 GoRouter 重新評估路由
final routerRefreshProvider = Provider<GoRouterRefreshStream>((ref) {
  final authService = ref.watch(authServiceProvider);
  return GoRouterRefreshStream(authService.authStateChanges);
});

class RouterConfig {
  RouterConfig._();

  static GoRouter createRouter(Ref ref) {
    // 使用 provider 管理的 refresh stream
    final refreshListenable = ref.watch(routerRefreshProvider);

    return GoRouter(
      initialLocation: '/',
      refreshListenable: refreshListenable,
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'];
            final index = tab == 'passport' ? 1 : 0;
            return MainScreen(initialIndex: index);
          },
        ),
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
          path: '/config',
          name: 'config',
          builder: (context, state) {
            final extra = state.extra;
            final place = extra is Place
                ? extra
                : Place.fromJson(extra as Map<String, dynamic>);
            return SelectNarrationStyleScreen(place: place);
          },
        ),
        GoRoute(
          path: '/player',
          name: 'player',
          builder: (context, state) {
            final params = state.extra as Map<String, dynamic>;
            final placeData = params['place'];
            final place = placeData is Place
                ? placeData
                : Place.fromJson(placeData as Map<String, dynamic>);
            final narrationStyle = params['narrationStyle'] as NarrationStyle;
            final initialContent = params['initialContent'] as String?;
            final enableSave = params['enableSave'] as bool? ?? true;
            return NarrationScreen(
              place: place,
              narrationStyle: narrationStyle,
              initialContent: initialContent,
              enableSave: enableSave,
            );
          },
        ),
        GoRoute(
          path: '/passport/success',
          name: 'passport_success',
          builder: (context, state) {
            final place = state.extra as Place;
            return SaveSuccessScreen(
              place: place,
              onViewPassport: () {
                context.go('/?tab=passport');
              },
              onContinueTour: () {
                context.go('/');
              },
            );
          },
        ),
      ],
      redirect: (context, state) {
        // 直接從 authService 讀取最新的認證狀態，避免 provider 異步更新延遲
        final authService = ref.read(authServiceProvider);
        final isSignedIn = authService.isSignedIn;
        final loggingIn = state.matchedLocation == '/login';
        final registering = state.matchedLocation == '/register';

        // If not signed in and not on a public page, redirect to login
        if (!isSignedIn && !loggingIn && !registering) {
          return '/login';
        }
        // If signed in and on a public page, redirect to home
        if (isSignedIn && (loggingIn || registering)) {
          return '/';
        }

        // No redirect needed
        return null;
      },
      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return RouterConfig.createRouter(ref);
});
