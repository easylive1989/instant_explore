import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/saved_locations/presentation/widgets/saved_locations_dialog.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the saved-locations morph route is currently on screen,
/// so the underlying FAB can hide itself to avoid appearing alongside the
/// morphing dialog.
final ValueNotifier<bool> _savedLocationsRouteActive = ValueNotifier<bool>(
  false,
);

/// Floating action button that morphs into the saved locations dialog
/// with a container-transform style animation from the FAB position.
class SavedLocationsFab extends ConsumerWidget {
  const SavedLocationsFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLocations = ref.watch(savedLocationsProvider);
    final count = savedLocations.valueOrNull?.length ?? 0;

    return ValueListenableBuilder<bool>(
      valueListenable: _savedLocationsRouteActive,
      builder: (context, isRouteActive, _) {
        // Hide the FAB (including hit-testing) as soon as the morph route
        // is pushed, so the dialog truly appears to *become* the FAB rather
        // than co-exist with it.
        return Visibility(
          visible: !isRouteActive,
          maintainState: true,
          maintainSize: true,
          maintainAnimation: true,
          child: FloatingActionButton(
            heroTag: 'saved_locations_fab',
            shape: const CircleBorder(),
            onPressed: () {
              final box = context.findRenderObject() as RenderBox?;
              final fabRect = _computeFabRect(context, box);
              Navigator.of(
                context,
              ).push(_SavedLocationsRoute(fabRect: fabRect));
            },
            backgroundColor: AppColors.primary,
            child: Badge(
              isLabelVisible: count > 0,
              label: Text('$count', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.bookmark, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Rect _computeFabRect(BuildContext context, RenderBox? box) {
    if (box != null && box.hasSize) {
      final offset = box.localToGlobal(Offset.zero);
      return offset & box.size;
    }
    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(size.width - 76, size.height - 160, 56, 56);
  }
}

/// Custom page route: morphs the circular FAB into a rounded dialog.
///
/// The container expands from [fabRect] to a centered dialog rect while
/// its corner radius morphs from 28 (circle) to 20, and its color fades
/// from the FAB's primary tint to the dialog's surface color. The FAB
/// icon is shown early in the transition and fades out as the real
/// dialog content fades in. On pop, the whole animation plays in reverse.
class _SavedLocationsRoute extends PageRouteBuilder<void> {
  _SavedLocationsRoute({required Rect fabRect})
    : super(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const SavedLocationsDialog(),
        transitionsBuilder: (context, animation, _, child) {
          final mediaSize = MediaQuery.of(context).size;
          final dialogRect = Rect.fromLTRB(
            20,
            mediaSize.height * 0.15,
            mediaSize.width - 20,
            mediaSize.height * 0.85,
          );

          final colorScheme = Theme.of(context).colorScheme;

          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          final rectTween = RectTween(begin: fabRect, end: dialogRect);
          final radiusTween = Tween<double>(begin: 28, end: 20);
          final colorTween = ColorTween(
            begin: AppColors.primary,
            end: colorScheme.surface,
          );

          // FAB icon is visible at the start and fades out early.
          final iconOpacity = Tween<double>(begin: 1, end: 0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
            ),
          );
          // Dialog content fades in after the morph is mostly done.
          final contentOpacity = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
            ),
          );

          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final rect = rectTween.evaluate(curved) ?? fabRect;
              final radius = radiusTween.evaluate(curved);
              final bgColor =
                  colorTween.evaluate(curved) ?? colorScheme.surface;

              return Stack(
                children: [
                  Positioned.fromRect(
                    rect: rect,
                    child: Material(
                      color: bgColor,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(radius),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Dialog content laid out at final dialog size,
                          // clipped to the current morph rect. Ignores
                          // pointer events until nearly fully visible.
                          IgnorePointer(
                            ignoring: contentOpacity.value < 0.95,
                            child: Opacity(
                              opacity: contentOpacity.value,
                              child: OverflowBox(
                                alignment: Alignment.topLeft,
                                minWidth: dialogRect.width,
                                maxWidth: dialogRect.width,
                                minHeight: dialogRect.height,
                                maxHeight: dialogRect.height,
                                child: child,
                              ),
                            ),
                          ),
                          // FAB's bookmark icon, visible during the
                          // circular phase of the morph.
                          IgnorePointer(
                            child: Center(
                              child: Opacity(
                                opacity: iconOpacity.value,
                                child: const Icon(
                                  Icons.bookmark,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

  @override
  TickerFuture didPush() {
    _savedLocationsRouteActive.value = true;
    return super.didPush();
  }

  @override
  void dispose() {
    // Reset only after the reverse morph fully finishes (route disposal),
    // so the underlying FAB stays hidden through the entire transition.
    _savedLocationsRouteActive.value = false;
    super.dispose();
  }
}
