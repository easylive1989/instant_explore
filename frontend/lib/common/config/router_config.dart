import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/features/main_screen.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/screens/select_narration_aspect_screen.dart';
import 'package:context_app/features/narration/screens/narration_screen.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/journey/screens/save_success_screen.dart';
import 'package:context_app/features/auth/screens/login_screen.dart';
import 'package:context_app/features/auth/screens/register_screen.dart';
import 'package:context_app/features/auth/screens/forgot_password_screen.dart';
import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:context_app/features/camera/screens/camera_screen.dart';
import 'package:context_app/common/config/go_router_refresh_stream.dart';

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
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/config',
          name: 'config',
          builder: (context, state) {
            // 支援兩種傳入方式：直接傳 Place 或傳 Map（包含 capturedImageBytes）
            final extra = state.extra;
            if (extra is Place) {
              return SelectNarrationAspectScreen(place: extra);
            } else if (extra is Map<String, dynamic>) {
              final place = extra['place'] as Place;
              final capturedImageBytes =
                  extra['capturedImageBytes'] as Uint8List?;
              return SelectNarrationAspectScreen(
                place: place,
                capturedImageBytes: capturedImageBytes,
              );
            }
            throw ArgumentError('Invalid extra type for /config route');
          },
        ),
        GoRoute(
          path: '/player',
          name: 'player',
          builder: (context, state) {
            final params = state.extra as Map<String, dynamic>;
            final place = params['place'] as Place;
            final narrationAspect =
                params['narrationAspect'] as NarrationAspect?;
            final narrationContent =
                params['narrationContent'] as NarrationContent?;
            final enableSave = params['enableSave'] as bool? ?? true;
            return NarrationScreen(
              place: place,
              narrationAspect: narrationAspect,
              narrationContent: narrationContent,
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
                context.pop();
              },
            );
          },
        ),
        GoRoute(
          path: '/camera',
          name: 'camera',
          builder: (context, state) => const CameraScreen(),
        ),
      ],
      redirect: (context, state) {
        // 直接從 authService 讀取最新的認證狀態，避免 provider 異步更新延遲
        final authService = ref.read(authServiceProvider);
        final isSignedIn = authService.isSignedIn;
        final location = state.matchedLocation;

        // 公開頁面（不需要登入）
        final publicPages = ['/login', '/register', '/forgot-password'];
        final isPublicPage = publicPages.contains(location);

        // If not signed in and not on a public page, redirect to login
        if (!isSignedIn && !isPublicPage) {
          return '/login';
        }
        // If signed in and on a login/register page, redirect to home
        // (但不影響 forgot-password，已登入用戶也可以訪問)
        if (isSignedIn && (location == '/login' || location == '/register')) {
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
