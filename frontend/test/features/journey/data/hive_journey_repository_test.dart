import 'dart:io';

import 'package:context_app/features/journey/data/hive_journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

JourneyEntry _makeEntry({String id = 'e1', DateTime? createdAt}) {
  const place = SavedPlace(
    id: 'p1',
    name: 'Test Place',
    address: 'Test Address',
  );

  const aspect = NarrationAspect.historicalBackground;
  final content = NarrationContent.create(
    'Narration text',
    language: const Language('zh-TW'),
  );

  return JourneyEntry(
    id: id,
    place: place,
    narrationContent: content,
    narrationAspect: aspect,
    createdAt: createdAt ?? DateTime.now(),
    language: const Language('zh-TW'),
  );
}

void main() {
  late HiveJourneyRepository repo;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync();
    Hive.init(dir.path);
    repo = HiveJourneyRepository();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('getAll returns empty list when no entries saved', () async {
    final result = await repo.getAll();
    expect(result, isEmpty);
  });

  test('save then getAll returns the saved entry', () async {
    final entry = _makeEntry(id: 'abc');
    await repo.save(entry);

    final result = await repo.getAll();
    expect(result.length, 1);
    expect(result.first.id, 'abc');
    expect(result.first.place.name, 'Test Place');
  });

  test('getAll returns entries sorted newest first', () async {
    final old = _makeEntry(id: 'old', createdAt: DateTime(2026, 1, 1));
    final recent = _makeEntry(id: 'recent', createdAt: DateTime(2026, 3, 1));

    await repo.save(old);
    await repo.save(recent);

    final result = await repo.getAll();
    expect(result.first.id, 'recent');
    expect(result.last.id, 'old');
  });

  test('delete removes the entry', () async {
    final entry = _makeEntry(id: 'del');
    await repo.save(entry);
    await repo.delete('del');

    final result = await repo.getAll();
    expect(result, isEmpty);
  });

  test('delete non-existent id does nothing', () async {
    await repo.save(_makeEntry(id: 'keep'));
    await repo.delete('nope');

    final result = await repo.getAll();
    expect(result.length, 1);
  });

  test('save preserves all fields through JSON round-trip', () async {
    final original = _makeEntry(id: 'rt');
    await repo.save(original);

    final result = await repo.getAll();
    final restored = result.first;

    expect(restored.id, original.id);
    expect(restored.place.id, original.place.id);
    expect(restored.place.name, original.place.name);
    expect(restored.place.address, original.place.address);
    expect(restored.narrationContent.text, original.narrationContent.text);
    expect(restored.narrationAspect, original.narrationAspect);
    expect(restored.language.code, original.language.code);
  });
}
