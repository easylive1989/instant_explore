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
            final index = tab == 'passport' ? 2 : 0;
            return MainScreen(initialIndex: index);
          },
        ),
        GoRoute(
          path: '/config',
          name: 'config',
          redirect: (context, state) {
            final extra = state.extra;
            if (extra == null) return '/';
            if (extra is! Place && extra is! Map<String, dynamic>) return '/';
            if (extra is Map<String, dynamic> && extra['place'] is! Place) {
              return '/';
            }
            return null;
          },
          builder: (context, state) {
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
            final extra = state.extra;
            if (extra == null || extra is! Map<String, dynamic>) return '/';
            if (extra['place'] is! Place) return '/';
            return null;
          },
          builder: (context, state) {
            final params = state.extra as Map<String, dynamic>;
            final place = params['place'] as Place;
            final narrationAspect =
                params['narrationAspect'] as NarrationAspect?;
            final narrationContent =
                params['narrationContent'] as NarrationContent?;
            final autoPlay = params['autoPlay'] as bool? ?? false;
            return NarrationScreen(
              place: place,
              narrationAspect: narrationAspect,
              narrationContent: narrationContent,
              autoPlay: autoPlay,
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
