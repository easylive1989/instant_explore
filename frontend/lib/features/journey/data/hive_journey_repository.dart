import 'dart:convert';

import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

/// Hive-based local implementation of [JourneyRepository].
///
/// Stores each [JourneyEntry] as a JSON string with key = entry.id.
class HiveJourneyRepository implements JourneyRepository {
  static const String _boxName = 'journey_entries';
  static final _log = Logger('HiveJourneyRepository');

  Future<Box<dynamic>> _getBox() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<List<JourneyEntry>> getAll() async {
    try {
      final box = await _getBox();
      return box.values
          .map(
            (v) => JourneyEntry.fromJson(
              jsonDecode(v as String) as Map<String, dynamic>,
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, stack) {
      _log.warning('Failed to load journey entries', e, stack);
      return [];
    }
  }

  @override
  Future<void> save(JourneyEntry entry) async {
    final box = await _getBox();
    await box.put(entry.id, jsonEncode(entry.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
