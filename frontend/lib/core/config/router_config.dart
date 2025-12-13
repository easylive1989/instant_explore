import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/features/main_screen.dart';
import 'package:context_app/features/places/models/place.dart';
import 'package:context_app/features/player/screens/config_screen.dart';
import 'package:context_app/features/player/screens/player_screen.dart';
import 'package:context_app/features/player/models/narration_style.dart';
import 'package:context_app/features/passport/screens/save_success_screen.dart';
import 'package:context_app/features/auth/screens/login_screen.dart';
import 'package:context_app/features/auth/providers/auth_state_provider.dart';

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
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/config',
          name: 'config',
          builder: (context, state) {
            final place = state.extra as Place;
            return ConfigScreen(place: place);
          },
        ),
        GoRoute(
          path: '/player',
          name: 'player',
          builder: (context, state) {
            final params = state.extra as Map<String, dynamic>;
            final place = params['place'] as Place;
            final narrationStyle = params['narrationStyle'] as NarrationStyle;
            final initialContent = params['initialContent'] as String?;
            final enableSave = params['enableSave'] as bool? ?? true;
            return PlayerScreen(
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
                context.pop();
              },
            );
          },
        ),
      ],
      redirect: (context, state) {
        final isSignedIn = ref.read(isSignedInProvider);
        final loggingIn = state.matchedLocation == '/login';

        // If not signed in and not on the login page, redirect to login
        if (!isSignedIn && !loggingIn) {
          return '/login';
        }
        // If signed in and on the login page, redirect to home
        if (isSignedIn && loggingIn) {
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
