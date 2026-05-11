import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/app/config/theme_config.dart';
import 'package:context_app/app/config/router_config.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/onboarding/providers.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:context_app/features/share/providers.dart';
import 'package:context_app/features/sync/domain/services/sync_session.dart';
import 'package:context_app/features/sync/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/midnight/midnight.dart';

/// Main application widget using go_router for navigation.
///
/// This widget sets up the app theme, routing, and global configuration.
/// Also initialises share intent listeners so the app can receive
/// places shared from Google Maps and save them directly.
class LorescapeApp extends ConsumerWidget {
  const LorescapeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialise share intent listeners (idempotent).
    ref.watch(shareIntentInitProvider);

    // Kick off the onboarding state load on app start. The controller
    // itself stays in `initial` until this completes, so the router
    // redirect knows to wait instead of flashing `/onboarding`.
    ref.read(onboardingControllerProvider.notifier).ensureLoaded();

    // When the sync session becomes active (toggle on + signed in),
    // run a full sync pass. Re-entry is guarded inside the coordinator.
    ref.listen<SyncSession>(syncSessionProvider, (prev, next) {
      if (next.isActive && !(prev?.isActive ?? false)) {
        ref.read(syncCoordinatorProvider).runFullSync();
      }
    });

    // Listen for resolved shared places and save directly.
    ref.listen<AsyncValue<Place>?>(pendingSharedPlaceProvider, (prev, next) {
      if (next == null) return;

      next.when(
        data: (place) {
          ref.read(pendingSharedPlaceProvider.notifier).state = null;
          // Save the place directly to saved locations.
          ref.read(savedLocationsProvider.notifier).savePlace(place);
          _showSnackBar(
            router,
            context,
            SnackBar(
              content: Text('shared_place.saved'.tr(args: [place.name])),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        loading: () {},
        error: (error, _) {
          ref.read(pendingSharedPlaceProvider.notifier).state = null;
          // `_resolveAndSetPlace` emits the literal key
          // `'shared_place.not_found'` when the share was parsed
          // but no matching place was found — show a more specific
          // message in that case.
          final messageKey = error == 'shared_place.not_found'
              ? 'shared_place.not_found'
              : 'shared_place.error';
          _showSnackBar(
            router,
            context,
            SnackBar(
              content: Text(messageKey.tr()),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    final pendingShare = ref.watch(pendingSharedPlaceProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => 'name'.tr(),
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.darkTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.dark,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      routerConfig: router,
      builder: (context, child) {
        return AmbientBackdrop(
          child: Stack(
            children: [
              child!,
              if (pendingShare != null && pendingShare.isLoading)
                const _ShareLoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(
    GoRouter router,
    BuildContext fallback,
    SnackBar snackBar,
  ) {
    final ctx = router.routerDelegate.navigatorKey.currentContext ?? fallback;
    ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
  }
}

/// Full-screen loading overlay shown while resolving a shared place.
class _ShareLoadingOverlay extends StatelessWidget {
  const _ShareLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdaptiveProgressIndicator(color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'shared_place.loading'.tr(),
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
