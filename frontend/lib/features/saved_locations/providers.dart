import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/saved_locations/data/hive_saved_locations_repository.dart';
import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:context_app/features/saved_locations/domain/repositories/saved_locations_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton repository provider.
final savedLocationsRepositoryProvider = Provider<SavedLocationsRepository>((
  ref,
) {
  return HiveSavedLocationsRepository();
});

/// Notifier that manages the saved locations list.
final savedLocationsProvider =
    AsyncNotifierProvider<SavedLocationsNotifier, List<SavedLocationEntry>>(() {
      return SavedLocationsNotifier();
    });

class SavedLocationsNotifier extends AsyncNotifier<List<SavedLocationEntry>> {
  @override
  Future<List<SavedLocationEntry>> build() async {
    final repo = ref.read(savedLocationsRepositoryProvider);
    return repo.getAll();
  }

  /// Saves a place. Does nothing if already saved.
  Future<void> savePlace(Place place) async {
    final repo = ref.read(savedLocationsRepositoryProvider);
    final alreadySaved = await repo.isSaved(place.id);
    if (alreadySaved) return;

    final entry = SavedLocationEntry.fromPlace(place);
    await repo.save(entry);
    state = AsyncValue.data([entry, ...state.valueOrNull ?? []]);
  }

  /// Removes a saved location by place ID.
  Future<void> removePlace(String placeId) async {
    final repo = ref.read(savedLocationsRepositoryProvider);
    await repo.delete(placeId);
    state = AsyncValue.data(
      (state.valueOrNull ?? []).where((e) => e.placeId != placeId).toList(),
    );
  }

  /// Toggles save state for a place.
  Future<void> togglePlace(Place place) async {
    final repo = ref.read(savedLocationsRepositoryProvider);
    final alreadySaved = await repo.isSaved(place.id);
    if (alreadySaved) {
      await removePlace(place.id);
    } else {
      await savePlace(place);
    }
  }

  /// Checks if a place is saved (synchronous, from current state).
  bool isSaved(String placeId) {
    final entries = state.valueOrNull ?? [];
    return entries.any((e) => e.placeId == placeId);
  }
}
