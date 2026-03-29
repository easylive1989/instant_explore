import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/features/main_screen.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/presentation/screens/select_narration_aspect_screen.dart';
import 'package:context_app/features/narration/presentation/screens/narration_screen.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/journey/presentation/screens/save_success_screen.dart';
import 'package:context_app/features/camera/presentation/screens/camera_screen.dart';
import 'package:context_app/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:context_app/features/route/presentation/screens/route_planning_screen.dart';
import 'package:context_app/features/route/presentation/screens/route_preview_screen.dart';
import 'package:context_app/features/route/presentation/screens/route_navigation_screen.dart';

class RouterConfig {
  RouterConfig._();

  static GoRouter createRouter(Ref ref) {
    return GoRouter(
      initialLocation: '/',
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
          path: '/config',
          name: 'config',
          redirect: (context, state) {
            // 如果沒有傳入 extra 或類型不正確，導回首頁
            final extra = state.extra;
            if (extra == null) {
              return '/';
            }
            if (extra is! Place && extra is! Map<String, dynamic>) {
              return '/';
            }
            // 如果是 Map，確保包含必要的 'place' 欄位
            if (extra is Map<String, dynamic> && extra['place'] is! Place) {
              return '/';
            }
            return null;
          },
          builder: (context, state) {
            // 支援兩種傳入方式：直接傳 Place 或傳 Map（包含 capturedImageBytes）
            final extra = state.extra;
            if (extra is Place) {
              return SelectNarrationAspectScreen(place: extra);
            }
            final mapExtra = extra as Map<String, dynamic>;
            final place = mapExtra['place'] as Place;
            final capturedImageBytes =
                mapExtra['capturedImageBytes'] as Uint8List?;
            return SelectNarrationAspectScreen(
              place: place,
              capturedImageBytes: capturedImageBytes,
            );
          },
        ),
        GoRoute(
          path: '/player',
          name: 'player',
          redirect: (context, state) {
            // 如果沒有傳入 extra 或類型不正確，導回首頁
            final extra = state.extra;
            if (extra == null || extra is! Map<String, dynamic>) {
              return '/';
            }
            // 確保包含必要的 'place' 欄位
            if (extra['place'] is! Place) {
              return '/';
            }
            return null;
          },
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
          path: '/route/planning',
          name: 'route_planning',
          redirect: (context, state) {
            if (state.extra is! List<Place>) return '/';
            return null;
          },
          builder: (context, state) {
            return RoutePlanningScreen(
              candidatePlaces: state.extra as List<Place>,
            );
          },
        ),
        GoRoute(
          path: '/route/preview',
          name: 'route_preview',
          builder: (context, state) {
            return const RoutePreviewScreen();
          },
        ),
        GoRoute(
          path: '/route/navigate',
          name: 'route_navigate',
          builder: (context, state) {
            return const RouteNavigationScreen();
          },
        ),
        GoRoute(
          path: '/camera',
          name: 'camera',
          builder: (context, state) => const CameraScreen(),
        ),
        GoRoute(
          path: '/subscription',
          name: 'subscription',
          builder: (context, state) => const SubscriptionScreen(),
        ),
      ],
      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return RouterConfig.createRouter(ref);
});
