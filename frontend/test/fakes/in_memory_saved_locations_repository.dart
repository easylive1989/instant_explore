import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:context_app/features/saved_locations/domain/repositories/saved_locations_repository.dart';

/// In-memory [SavedLocationsRepository] used by widget tests.
class InMemorySavedLocationsRepository implements SavedLocationsRepository {
  final Map<String, SavedLocationEntry> _entries = {};

  @override
  Future<List<SavedLocationEntry>> getAll() async {
    final list = _entries.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  @override
  Future<void> save(SavedLocationEntry entry) async {
    _entries[entry.placeId] = entry;
  }

  @override
  Future<void> delete(String placeId) async {
    _entries.remove(placeId);
  }

  @override
  Future<bool> isSaved(String placeId) async {
    return _entries.containsKey(placeId);
  }
}
