import 'dart:convert';

import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:context_app/features/saved_locations/domain/repositories/saved_locations_repository.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

/// Hive-based local implementation of [SavedLocationsRepository].
///
/// Stores each [SavedLocationEntry] as a JSON string keyed by placeId.
class HiveSavedLocationsRepository implements SavedLocationsRepository {
  static const String _boxName = 'saved_locations';
  static final _log = Logger('HiveSavedLocationsRepository');

  Future<Box<dynamic>> _getBox() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<List<SavedLocationEntry>> getAll() async {
    try {
      final box = await _getBox();
      return box.values
          .map(
            (v) => SavedLocationEntry.fromJson(
              jsonDecode(v as String) as Map<String, dynamic>,
            ),
          )
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (e, stack) {
      _log.warning('Failed to load saved locations', e, stack);
      return [];
    }
  }

  @override
  Future<void> save(SavedLocationEntry entry) async {
    final box = await _getBox();
    await box.put(entry.placeId, jsonEncode(entry.toJson()));
  }

  @override
  Future<void> delete(String placeId) async {
    final box = await _getBox();
    await box.delete(placeId);
  }

  @override
  Future<bool> isSaved(String placeId) async {
    final box = await _getBox();
    return box.containsKey(placeId);
  }
}
