import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';

/// Abstract repository for managing saved locations.
abstract class SavedLocationsRepository {
  /// Returns all saved locations, newest first.
  Future<List<SavedLocationEntry>> getAll();

  /// Saves a location. If a location with the same placeId
  /// already exists, it is overwritten.
  Future<void> save(SavedLocationEntry entry);

  /// Deletes a saved location by its place ID.
  Future<void> delete(String placeId);

  /// Returns whether a location is already saved.
  Future<bool> isSaved(String placeId);
}
