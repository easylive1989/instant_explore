import 'dart:convert';

import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

/// Hive-based local implementation of [TripRepository].
///
/// Stores each [Trip] as a JSON string with key = trip.id.
class HiveTripRepository implements TripRepository {
  static const String _boxName = 'trips';
  static final _log = Logger('HiveTripRepository');

  Future<Box<dynamic>> _getBox() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<List<Trip>> getAll() async {
    try {
      final box = await _getBox();
      return box.values
          .map(
            (v) =>
                Trip.fromJson(jsonDecode(v as String) as Map<String, dynamic>),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, stack) {
      _log.warning('Failed to load trips', e, stack);
      return [];
    }
  }

  @override
  Future<Trip?> getById(String id) async {
    try {
      final box = await _getBox();
      final raw = box.get(id);
      if (raw is! String) return null;
      return Trip.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, stack) {
      _log.warning('Failed to load trip $id', e, stack);
      return null;
    }
  }

  @override
  Future<void> save(Trip trip) async {
    final box = await _getBox();
    await box.put(trip.id, jsonEncode(trip.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
