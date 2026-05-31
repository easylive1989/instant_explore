import 'package:context_app/features/saved_locations/presentation/widgets/saved_locations_sheet.dart';
import 'package:context_app/features/saved_locations/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Floating action button that opens the saved locations as a bottom sheet,
/// with a badge reflecting the saved count.
class SavedLocationsFab extends ConsumerWidget {
  const SavedLocationsFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLocations = ref.watch(savedLocationsProvider);
    final count = savedLocations.valueOrNull?.length ?? 0;

    return FloatingActionButton(
      shape: const CircleBorder(),
      onPressed: () => showSavedLocationsSheet(context),
      child: Badge(
        isLabelVisible: count > 0,
        label: Text('$count', style: const TextStyle(fontSize: 10)),
        child: Icon(
          Icons.bookmark,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
