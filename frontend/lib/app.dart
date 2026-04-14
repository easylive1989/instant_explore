import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/common/config/theme_config.dart';
import 'package:context_app/common/config/router_config.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:context_app/features/settings/providers.dart';
import 'package:context_app/features/share/providers.dart';

/// Main application widget using go_router for navigation.
///
/// This widget sets up the app theme, routing, and global configuration.
/// Also initialises share intent listeners so the app can receive
/// places shared from Google Maps and save them directly.
class ContextureApp extends ConsumerWidget {
  const ContextureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Initialise share intent listeners (idempotent).
    ref.watch(shareIntentInitProvider);

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
          _showSnackBar(
            router,
            context,
            SnackBar(
              content: Text('shared_place.error'.tr()),
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
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: themeMode,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (pendingShare != null && pendingShare.isLoading)
              const _ShareLoadingOverlay(),
          ],
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
                CircularProgressIndicator(color: colorScheme.primary),
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
