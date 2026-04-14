import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/saved_locations/presentation/widgets/saved_locations_dialog.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Floating action button that opens the saved locations dialog
/// with a hero-style expand animation from the FAB position.
class SavedLocationsFab extends ConsumerWidget {
  const SavedLocationsFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLocations = ref.watch(savedLocationsProvider);
    final count = savedLocations.valueOrNull?.length ?? 0;

    return FloatingActionButton(
      heroTag: 'saved_locations_fab',
      onPressed: () {
        final box = context.findRenderObject() as RenderBox?;
        final fabRect = _computeFabRect(context, box);
        Navigator.of(context).push(
          _SavedLocationsRoute(fabRect: fabRect),
        );
      },
      backgroundColor: AppColors.primary,
      child: Badge(
        isLabelVisible: count > 0,
        label: Text('$count', style: const TextStyle(fontSize: 10)),
        child: const Icon(Icons.bookmark, color: Colors.white),
      ),
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

/// Custom page route: expands a rounded rect from [fabRect] to
/// a centered dialog, with content fading in.
class _SavedLocationsRoute extends PageRouteBuilder<void> {
  _SavedLocationsRoute({required Rect fabRect})
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) => const SavedLocationsDialog(),
          transitionsBuilder: (context, animation, _, child) {
            final size = MediaQuery.of(context).size;
            final dialogRect = Rect.fromLTRB(
              20,
              size.height * 0.15,
              size.width - 20,
              size.height * 0.85,
            );

            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final rectTween = RectTween(
              begin: fabRect,
              end: dialogRect,
            );

            final radiusTween = Tween<double>(begin: 28, end: 20);
            final fadeTween = Tween<double>(begin: 0, end: 1);
            final fadeCurved = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.2, 0.6),
            );

            return ListenableBuilder(
              listenable: animation,
              builder: (context, _) {
                final rect = rectTween.evaluate(curved);
                if (rect == null) return const SizedBox.shrink();
                final radius = radiusTween.evaluate(curved);

                return Stack(
                  children: [
                    Positioned(
                      left: rect.left,
                      top: rect.top,
                      width: rect.width,
                      height: rect.height,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 8,
                        borderRadius: BorderRadius.circular(radius),
                        clipBehavior: Clip.antiAlias,
                        child: Opacity(
                          opacity: fadeTween.evaluate(fadeCurved),
                          child: child,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
}
