import 'dart:io';
import 'dart:typed_data';

import 'package:context_app/features/quick_guide/data/hive_quick_guide_repository.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

QuickGuideEntry _makeEntry({String id = 'e1', DateTime? createdAt}) {
  final entry = QuickGuideEntry.create(
    imageBytes: Uint8List.fromList([1, 2, 3]),
    aiDescription: 'Test description',
    language: const Language('zh-TW'),
  );
  // Return a copy with the desired id and createdAt.
  return QuickGuideEntry(
    id: id,
    imageBytes: entry.imageBytes,
    aiDescription: entry.aiDescription,
    createdAt: createdAt ?? entry.createdAt,
    language: entry.language,
  );
}

void main() {
  late HiveQuickGuideRepository repo;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync();
    Hive.init(dir.path);
    repo = HiveQuickGuideRepository();
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
    expect(result.first.aiDescription, 'Test description');
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
    expect(restored.imageBytes, original.imageBytes);
    expect(restored.aiDescription, original.aiDescription);
    expect(restored.language.code, original.language.code);
    expect(
      restored.createdAt.toIso8601String(),
      original.createdAt.toIso8601String(),
    );
  });
}
