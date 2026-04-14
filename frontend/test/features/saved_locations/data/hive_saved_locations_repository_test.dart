import 'dart:io';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/saved_locations/data/hive_saved_locations_repository.dart';
import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

SavedLocationEntry _makeEntry({
  String placeId = 'p1',
  DateTime? savedAt,
}) {
  final place = Place(
    id: placeId,
    name: 'Place $placeId',
    formattedAddress: 'Address $placeId',
    location: const PlaceLocation(latitude: 25.0, longitude: 121.5),
    types: const [],
    photos: const [],
    category: PlaceCategory.historicalCultural,
  );

  final entry = SavedLocationEntry.fromPlace(place);
  if (savedAt != null) {
    return SavedLocationEntry(
      placeId: entry.placeId,
      name: entry.name,
      formattedAddress: entry.formattedAddress,
      latitude: entry.latitude,
      longitude: entry.longitude,
      types: entry.types,
      photosJson: entry.photosJson,
      categoryKey: entry.categoryKey,
      savedAt: savedAt,
    );
  }
  return entry;
}

void main() {
  late HiveSavedLocationsRepository repo;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync();
    Hive.init(dir.path);
    repo = HiveSavedLocationsRepository();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('getAll returns empty list when no entries saved', () async {
    final result = await repo.getAll();
    expect(result, isEmpty);
  });

  test('save then getAll returns the saved entry', () async {
    final entry = _makeEntry(placeId: 'abc');
    await repo.save(entry);

    final result = await repo.getAll();
    expect(result.length, 1);
    expect(result.first.placeId, 'abc');
    expect(result.first.name, 'Place abc');
  });

  test('getAll returns entries sorted newest first', () async {
    final old = _makeEntry(
      placeId: 'old',
      savedAt: DateTime(2026, 1, 1),
    );
    final recent = _makeEntry(
      placeId: 'recent',
      savedAt: DateTime(2026, 3, 1),
    );

    await repo.save(old);
    await repo.save(recent);

    final result = await repo.getAll();
    expect(result.first.placeId, 'recent');
    expect(result.last.placeId, 'old');
  });

  test('delete removes the entry', () async {
    final entry = _makeEntry(placeId: 'del');
    await repo.save(entry);
    await repo.delete('del');

    final result = await repo.getAll();
    expect(result, isEmpty);
  });

  test('delete non-existent id does nothing', () async {
    await repo.save(_makeEntry(placeId: 'keep'));
    await repo.delete('nope');

    final result = await repo.getAll();
    expect(result.length, 1);
  });

  test('isSaved returns true for saved entry', () async {
    await repo.save(_makeEntry(placeId: 'check'));
    expect(await repo.isSaved('check'), isTrue);
  });

  test('isSaved returns false for unsaved entry', () async {
    expect(await repo.isSaved('missing'), isFalse);
  });

  test('save overwrites entry with same placeId', () async {
    await repo.save(_makeEntry(placeId: 'dup'));
    await repo.save(_makeEntry(placeId: 'dup'));

    final result = await repo.getAll();
    expect(result.length, 1);
  });

  test('save preserves all fields through JSON round-trip', () async {
    final original = _makeEntry(placeId: 'rt');
    await repo.save(original);

    final result = await repo.getAll();
    final restored = result.first;

    expect(restored.placeId, original.placeId);
    expect(restored.name, original.name);
    expect(restored.formattedAddress, original.formattedAddress);
    expect(restored.latitude, original.latitude);
    expect(restored.longitude, original.longitude);
    expect(restored.categoryKey, original.categoryKey);
  });
}
