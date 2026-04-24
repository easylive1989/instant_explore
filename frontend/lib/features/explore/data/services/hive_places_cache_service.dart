import 'dart:convert';
import 'dart:math';

import 'package:context_app/features/explore/data/mappers/place_json_mapper.dart';
import 'package:context_app/features/explore/data/mappers/place_location_mapper.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:hive/hive.dart';

/// Hive-backed cache for nearby places.
///
/// Stores [Place] objects directly as JSON. A [_cacheSchemaVersion] key
/// is bumped when the on-disk format changes; a mismatch clears the box
/// so callers transparently re-fetch fresh data.
class HivePlacesCacheService {
  static const String _boxName = 'places_cache';
  static const String _placesKey = 'cached_places';
  static const String _timestampKey = 'cache_timestamp';
  static const String _locationKey = 'last_search_location';
  static const String _versionKey = 'cache_schema_version';

  /// Bump whenever the on-disk format changes.
  static const int _cacheSchemaVersion = 2;

  static const Duration _cacheTtl = Duration(hours: 24);
  static const double _refreshDistanceThreshold = 500.0;

  Box? _box;

  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(_boxName);
    await _migrateIfNeeded(_box!);
    return _box!;
  }

  Future<void> _migrateIfNeeded(Box box) async {
    final stored = box.get(_versionKey);
    if (stored != _cacheSchemaVersion) {
      await box.clear();
      await box.put(_versionKey, _cacheSchemaVersion);
    }
  }

  Future<List<Place>?> getCachedPlaces() async {
    try {
      final box = await _getBox();
      final placesJson = box.get(_placesKey) as String?;
      if (placesJson == null) return null;

      final list = jsonDecode(placesJson) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map(PlaceJsonMapper.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> cachePlaces(List<Place> places) async {
    final box = await _getBox();
    final data = places.map(PlaceJsonMapper.toJson).toList();
    await box.put(_placesKey, jsonEncode(data));
    await box.put(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<PlaceLocation?> getLastSearchLocation() async {
    try {
      final box = await _getBox();
      final raw = box.get(_locationKey) as String?;
      if (raw == null) return null;
      return PlaceLocationMapper.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastSearchLocation(PlaceLocation location) async {
    final box = await _getBox();
    await box.put(
      _locationKey,
      jsonEncode(PlaceLocationMapper.toJson(location)),
    );
  }

  Future<void> clearCache() async {
    final box = await _getBox();
    await box.delete(_placesKey);
    await box.delete(_timestampKey);
    await box.delete(_locationKey);
  }

  Future<bool> shouldRefresh(PlaceLocation currentLocation) async {
    if (await _isCacheExpired()) return true;
    final last = await getLastSearchLocation();
    if (last == null) return true;
    return _distanceMeters(last, currentLocation) > _refreshDistanceThreshold;
  }

  Future<bool> _isCacheExpired() async {
    final box = await _getBox();
    final ts = box.get(_timestampKey) as int?;
    if (ts == null) return true;
    final cached = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(cached) > _cacheTtl;
  }

  double _distanceMeters(PlaceLocation a, PlaceLocation b) {
    const earthRadius = 6371000.0;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final h =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(h), sqrt(1 - h));
  }
}
