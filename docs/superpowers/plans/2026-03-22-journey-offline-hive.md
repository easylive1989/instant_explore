# Journey Offline Hive Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove Supabase dependency from Journey feature, replacing it with pure Hive local storage so all users can use Journey without logging in.

**Architecture:** Replace `CachingJourneyRepository` (wrapping Supabase + HiveCache) with a new `HiveJourneyRepository` that stores JSON strings in a Hive box. Update `JourneyRepository` interface to remove `userId`. Remove all auth gates from UI and delete obsolete data-layer files.

**Tech Stack:** Flutter, Riverpod, Hive (JSON string in `Box<dynamic>`, no TypeAdapter), mocktail (not needed for Hive tests — use `Hive.init()` with temp dir), fvm for running flutter/dart commands.

---

## File Map

### Create
- `lib/features/journey/data/hive_journey_repository.dart` — Hive CRUD implementation of updated `JourneyRepository`
- `test/features/journey/data/hive_journey_repository_test.dart` — CRUD + sort + round-trip tests

### Modify
- `lib/features/journey/domain/models/journey_entry.dart` — Remove `userId`, add `toJson()`/`fromJson()`/`JourneyEntry.create()` without `userId`
- `lib/features/journey/domain/repositories/journey_repository.dart` — Replace methods with `getAll()`/`save()`/`delete()`
- `lib/features/journey/providers.dart` — Use `HiveJourneyRepository`, remove Supabase providers
- `lib/features/narration/presentation/controllers/player_controller.dart` — Remove `userId` param from `saveToJourney()`
- `lib/features/narration/presentation/widgets/save_to_passport_button.dart` — Remove auth check/login dialog
- `lib/features/journey/presentation/screens/journey_screen.dart` — Remove auth gate, show list directly
- `lib/features/journey/presentation/widgets/timeline_entry.dart` — Change `.deleteJourneyEntry()` → `.delete()`
- `test/features/journey/domain/models/journey_entry_test.dart` — Remove `userId` param and assertions

### Delete
- `lib/features/journey/data/supabase_journey_repository.dart`
- `lib/features/journey/data/caching_journey_repository.dart`
- `lib/features/journey/data/journey_entry_mapper.dart`
- `lib/features/journey/data/services/hive_journey_cache_service.dart`
- `test/features/journey/data/supabase_journey_repository_test.dart`
- `test/features/journey/data/caching_journey_repository_test.dart`
- `test/features/journey/data/services/hive_journey_cache_service_test.dart`

---

## Task 1: Update JourneyEntry model and its test

**Files:**
- Modify: `lib/features/journey/domain/models/journey_entry.dart`
- Modify: `test/features/journey/domain/models/journey_entry_test.dart`

- [ ] **Step 1: Update the test first — remove `userId` references**

Open `test/features/journey/domain/models/journey_entry_test.dart`. Make these changes:
1. Remove `userId: 'user-1'` / `userId: 'user-2'` from every `JourneyEntry.create()` call (3 places)
2. Remove the `expect(entry.userId, equals('user-1'))` and `expect(entry.userId, equals('user-2'))` assertions (2 places)
3. Add a `toJson()`/`fromJson()` round-trip test at the bottom of the file

The full updated file:

```dart
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JourneyEntry.create', () {
    test('creates entry with correct data when place has no photos', () {
      const place = Place(
        id: 'place-1',
        name: 'Test Place',
        formattedAddress: 'Test Address',
        location: PlaceLocation(latitude: 25.0, longitude: 121.0),
        types: [],
        photos: [],
        category: PlaceCategory.historicalCultural,
      );

      const aspect = NarrationAspect.historicalBackground;
      final content = NarrationContent.create(
        'Test narration',
        language: Language.traditionalChinese,
      );

      final entry = JourneyEntry.create(
        place: place,
        aspect: aspect,
        content: content,
        language: Language.traditionalChinese,
      );

      expect(
        entry.place,
        equals(
          const SavedPlace(
            id: 'place-1',
            name: 'Test Place',
            address: 'Test Address',
          ),
        ),
      );
      expect(entry.narrationContent, equals(content));
      expect(entry.narrationAspect, equals(aspect));
      expect(entry.language, equals(Language.traditionalChinese));
      expect(entry.id, isNotEmpty);
    });

    test(
      'creates entry with imageUrl from primaryPhoto when place has photos',
      () {
        const placePhoto = PlacePhoto(
          url: 'https://example.com/photo.jpg',
          widthPx: 800,
          heightPx: 600,
          authorAttributions: ['Author Name'],
        );

        const place = Place(
          id: 'place-2',
          name: 'Place With Photo',
          formattedAddress: 'Address 2',
          location: PlaceLocation(latitude: 25.0, longitude: 121.0),
          types: [],
          photos: [placePhoto],
          category: PlaceCategory.naturalLandscape,
        );

        const aspect = NarrationAspect.geology;
        final content = NarrationContent.create(
          'Geology narration',
          language: Language.traditionalChinese,
        );

        final entry = JourneyEntry.create(
          place: place,
          aspect: aspect,
          content: content,
          language: Language.traditionalChinese,
        );

        expect(
          entry.place,
          equals(
            const SavedPlace(
              id: 'place-2',
              name: 'Place With Photo',
              address: 'Address 2',
              imageUrl: 'https://example.com/photo.jpg',
            ),
          ),
        );
        expect(entry.narrationContent, equals(content));
        expect(entry.narrationAspect, equals(aspect));
        expect(entry.language, equals(Language.traditionalChinese));
      },
    );

    test('generates unique IDs for different entries', () {
      const place = Place(
        id: 'place-1',
        name: 'Place With Photo',
        formattedAddress: 'Test Address',
        location: PlaceLocation(latitude: 25.0, longitude: 121.0),
        types: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );

      const aspect = NarrationAspect.designConcept;
      final content = NarrationContent.create(
        'Test narration',
        language: Language.traditionalChinese,
      );

      final entry1 = JourneyEntry.create(
        place: place,
        aspect: aspect,
        content: content,
        language: Language.traditionalChinese,
      );

      final entry2 = JourneyEntry.create(
        place: place,
        aspect: aspect,
        content: content,
        language: Language.traditionalChinese,
      );

      expect(entry1.id, isNot(equals(entry2.id)));
    });
  });

  group('JourneyEntry JSON round-trip', () {
    test('toJson/fromJson preserves all fields', () {
      const place = Place(
        id: 'place-rt',
        name: 'Round Trip Place',
        formattedAddress: 'RT Address',
        location: PlaceLocation(latitude: 25.0, longitude: 121.0),
        types: [],
        photos: [],
        category: PlaceCategory.historicalCultural,
      );

      const aspect = NarrationAspect.historicalBackground;
      final content = NarrationContent.create(
        'Round trip text',
        language: Language.traditionalChinese,
      );

      final original = JourneyEntry.create(
        place: place,
        aspect: aspect,
        content: content,
        language: Language.traditionalChinese,
      );

      final restored = JourneyEntry.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.place.id, original.place.id);
      expect(restored.place.name, original.place.name);
      expect(restored.place.address, original.place.address);
      expect(restored.narrationContent.text, original.narrationContent.text);
      expect(restored.narrationAspect, original.narrationAspect);
      expect(restored.language, original.language);
    });

    test('fromJson uses language.code (not toString)', () {
      const place = Place(
        id: 'p1',
        name: 'Test',
        formattedAddress: 'Addr',
        location: PlaceLocation(latitude: 0, longitude: 0),
        types: [],
        photos: [],
        category: PlaceCategory.modernUrban,
      );
      final content = NarrationContent.create(
        'text',
        language: Language.english,
      );
      final entry = JourneyEntry.create(
        place: place,
        aspect: NarrationAspect.historicalBackground,
        content: content,
        language: Language.english,
      );
      final json = entry.toJson();
      // language.code returns 'en', not 'Instance of Language'
      expect(json['language'], equals(Language.english.code));
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test test/features/journey/domain/models/journey_entry_test.dart
```

Expected: FAIL — `JourneyEntry.create` still requires `userId`, `fromJson`/`toJson` don't exist yet.

- [ ] **Step 3: Update `journey_entry.dart`**

Replace the entire file with:

```dart
import 'dart:convert';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/data/mappers/narration_aspect_mapper.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:uuid/uuid.dart';

class JourneyEntry {
  final String id;
  final SavedPlace place;
  final NarrationContent narrationContent;
  final NarrationAspect narrationAspect;
  final DateTime createdAt;
  final Language language;

  const JourneyEntry({
    required this.id,
    required this.place,
    required this.narrationContent,
    required this.narrationAspect,
    required this.createdAt,
    required this.language,
  });

  /// 建立新的旅程記錄
  factory JourneyEntry.create({
    required Place place,
    required NarrationAspect aspect,
    required NarrationContent content,
    required Language language,
  }) {
    const uuid = Uuid();

    String? imageUrl;
    if (place.primaryPhoto != null) {
      imageUrl = place.primaryPhoto!.url;
    }

    final savedPlace = SavedPlace(
      id: place.id,
      name: place.name,
      address: place.formattedAddress,
      imageUrl: imageUrl,
    );

    return JourneyEntry(
      id: uuid.v4(),
      place: savedPlace,
      narrationContent: content,
      narrationAspect: aspect,
      createdAt: DateTime.now(),
      language: language,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'place_id': place.id,
    'place_name': place.name,
    'place_address': place.address,
    'place_image_url': place.imageUrl,
    'narration_text': narrationContent.text,
    'narration_style': NarrationAspectMapper.toApiString(narrationAspect),
    'created_at': createdAt.toIso8601String(),
    'language': language.code,
  };

  factory JourneyEntry.fromJson(Map<String, dynamic> json) {
    final languageStr = json['language'] as String? ?? 'zh-TW';
    final language = Language(languageStr);

    final place = SavedPlace(
      id: json['place_id'] as String,
      name: json['place_name'] as String,
      address: json['place_address'] as String,
      imageUrl: json['place_image_url'] as String?,
    );

    final narrationContent = NarrationContent.create(
      json['narration_text'] as String,
      language: language,
    );

    final narrationAspect =
        NarrationAspectMapper.fromString(
          json['narration_style'] as String,
        ) ??
        NarrationAspect.historicalBackground;

    return JourneyEntry(
      id: json['id'] as String,
      place: place,
      narrationContent: narrationContent,
      narrationAspect: narrationAspect,
      createdAt: DateTime.parse(json['created_at'] as String),
      language: language,
    );
  }
}
```

> Note: The `dart:convert` import is needed for `jsonDecode`/`jsonEncode` used by `HiveJourneyRepository` in Task 2; it does no harm here. Actually scratch that — `journey_entry.dart` itself doesn't use `dart:convert`. Remove that import from the file above.

Corrected: **Do not** include `import 'dart:convert';` in `journey_entry.dart`. Only the repository uses it.

- [ ] **Step 4: Run the test to confirm it passes**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test test/features/journey/domain/models/journey_entry_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && git add lib/features/journey/domain/models/journey_entry.dart test/features/journey/domain/models/journey_entry_test.dart && git commit -m "feat: remove userId from JourneyEntry, add toJson/fromJson"
```

---

## Task 2: Update JourneyRepository interface

**Files:**
- Modify: `lib/features/journey/domain/repositories/journey_repository.dart`

- [ ] **Step 1: Update the interface**

Replace the file with:

```dart
import 'package:context_app/features/journey/domain/models/journey_entry.dart';

abstract class JourneyRepository {
  Future<List<JourneyEntry>> getAll();
  Future<void> save(JourneyEntry entry);
  Future<void> delete(String id);
}
```

- [ ] **Step 2: Run analyzer to surface all compile errors caused by the interface change**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter analyze lib/features/journey
```

Expected: Errors in `supabase_journey_repository.dart`, `caching_journey_repository.dart`, `providers.dart`, `player_controller.dart`, `timeline_entry.dart`. These are resolved in later tasks — do not fix them yet. The goal here is just to commit the interface change in isolation.

- [ ] **Step 3: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && git add lib/features/journey/domain/repositories/journey_repository.dart && git commit -m "refactor: update JourneyRepository interface — getAll/save/delete, no userId"
```

---

## Task 3: Create HiveJourneyRepository with tests

**Files:**
- Create: `lib/features/journey/data/hive_journey_repository.dart`
- Create: `test/features/journey/data/hive_journey_repository_test.dart`

- [ ] **Step 1: Write the failing test first**

Create `test/features/journey/data/hive_journey_repository_test.dart`:

```dart
import 'dart:io';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/journey/data/hive_journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

JourneyEntry _makeEntry({
  String id = 'e1',
  DateTime? createdAt,
}) {
  const place = Place(
    id: 'p1',
    name: 'Test Place',
    formattedAddress: 'Test Address',
    location: PlaceLocation(latitude: 25.0, longitude: 121.0),
    types: [],
    photos: [],
    category: PlaceCategory.historicalCultural,
  );

  const aspect = NarrationAspect.historicalBackground;
  final content = NarrationContent.create(
    'Narration text',
    language: Language.traditionalChinese,
  );

  final entry = JourneyEntry.create(
    place: place,
    aspect: aspect,
    content: content,
    language: Language.traditionalChinese,
  );

  // Return a copy with controlled id/createdAt for sort tests
  return JourneyEntry(
    id: id,
    place: entry.place,
    narrationContent: entry.narrationContent,
    narrationAspect: entry.narrationAspect,
    createdAt: createdAt ?? DateTime.now(),
    language: entry.language,
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
    expect(restored.language, original.language);
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test test/features/journey/data/hive_journey_repository_test.dart
```

Expected: FAIL — `HiveJourneyRepository` doesn't exist yet.

- [ ] **Step 3: Create `hive_journey_repository.dart`**

Create `lib/features/journey/data/hive_journey_repository.dart`:

```dart
import 'dart:convert';

import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:hive/hive.dart';

/// Hive-based local implementation of [JourneyRepository].
///
/// Stores each [JourneyEntry] as a JSON string with key = entry.id.
class HiveJourneyRepository implements JourneyRepository {
  static const String _boxName = 'journey_entries';

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
    } catch (_) {
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
```

- [ ] **Step 4: Run the test to confirm it passes**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test test/features/journey/data/hive_journey_repository_test.dart
```

Expected: All 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && git add lib/features/journey/data/hive_journey_repository.dart test/features/journey/data/hive_journey_repository_test.dart && git commit -m "feat: add HiveJourneyRepository with CRUD and sort"
```

---

## Task 4: Update providers and PlayerController

**Files:**
- Modify: `lib/features/journey/providers.dart`
- Modify: `lib/features/narration/presentation/controllers/player_controller.dart`

- [ ] **Step 1: Replace `providers.dart`**

Replace the entire file with:

```dart
import 'package:context_app/features/journey/data/hive_journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return HiveJourneyRepository();
});

final myJourneyProvider = FutureProvider.autoDispose<List<JourneyEntry>>((
  ref,
) {
  return ref.watch(journeyRepositoryProvider).getAll();
});
```

- [ ] **Step 2: Update `player_controller.dart` — remove `userId` from `saveToJourney`**

Find the `saveToJourney` method (lines 136–159 in original file) and replace it:

Old:
```dart
  /// 儲存導覽到歷程
  Future<void> saveToJourney(
    String userId, {
    required Language language,
  }) async {
    if (state.content == null || state.place == null || state.aspect == null) {
      return;
    }

    try {
      final entry = JourneyEntry.create(
        userId: userId,
        place: state.place!,
        aspect: state.aspect!,
        content: state.content!,
        language: language,
      );

      await _journeyRepository.addJourneyEntry(entry);
    } catch (e) {
      // 這裡可以選擇透過 state 通知 UI 錯誤，或者拋出異常讓 UI 處理
      // 為了簡單起見，我們暫時不改變 state，但理想情況下應該有 toast 通知
      rethrow;
    }
  }
```

New:
```dart
  /// 儲存導覽到歷程
  Future<void> saveToJourney({required Language language}) async {
    if (state.content == null || state.place == null || state.aspect == null) {
      return;
    }

    try {
      final entry = JourneyEntry.create(
        place: state.place!,
        aspect: state.aspect!,
        content: state.content!,
        language: language,
      );

      await _journeyRepository.save(entry);
    } catch (e) {
      rethrow;
    }
  }
```

- [ ] **Step 3: Run analyzer to verify these two files are now clean**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter analyze lib/features/journey/providers.dart lib/features/narration/presentation/controllers/player_controller.dart
```

Expected: No issues in these two files (other files still have errors from the interface change — that's fine).

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && git add lib/features/journey/providers.dart lib/features/narration/presentation/controllers/player_controller.dart && git commit -m "feat: update Journey providers and PlayerController for Hive-only storage"
```

---

## Task 5: Update UI components

**Files:**
- Modify: `lib/features/narration/presentation/widgets/save_to_passport_button.dart`
- Modify: `lib/features/journey/presentation/screens/journey_screen.dart`
- Modify: `lib/features/journey/presentation/widgets/timeline_entry.dart`

- [ ] **Step 1: Update `save_to_passport_button.dart`**

Replace the entire file with:

```dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 儲存到護照的按鈕
class SaveToPassportButton extends ConsumerStatefulWidget {
  final Place place;
  final Color surfaceColor;

  const SaveToPassportButton({
    super.key,
    required this.place,
    required this.surfaceColor,
  });

  @override
  ConsumerState<SaveToPassportButton> createState() =>
      _SaveToPassportButtonState();
}

class _SaveToPassportButtonState extends ConsumerState<SaveToPassportButton> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            (playerState.isLoading ||
                playerState.hasError ||
                playerState.content == null ||
                _isSaving)
            ? null
            : () async {
                final locale =
                    easy.EasyLocalization.of(context)?.locale.toLanguageTag() ??
                    'zh-TW';

                setState(() {
                  _isSaving = true;
                });

                try {
                  await playerController.saveToJourney(
                    language: Language(locale),
                  );
                  if (context.mounted) {
                    context.pushNamed('passport_success', extra: widget.place);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${easy.tr('player_screen.save_failed')}: $e',
                        ),
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSaving = false;
                    });
                  }
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity:
              (playerState.isLoading ||
                  playerState.hasError ||
                  playerState.content == null ||
                  _isSaving)
              ? 0.5
              : 1.0,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: widget.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _isSaving
                  ? const [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ]
                  : [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.bookmark_add,
                          color: AppColors.amber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        easy.tr('player_screen.save_to_passport'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update `journey_screen.dart`**

Replace the entire file with:

```dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/journey/presentation/widgets/timeline_entry.dart';

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(
          'passport.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildJourneyList(ref),
    );
  }

  Widget _buildJourneyList(WidgetRef ref) {
    final journeyAsyncValue = ref.watch(myJourneyProvider);

    return journeyAsyncValue.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text(
              'passport.no_entries'.tr(),
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isLast = index == entries.length - 1;
            return TimelineEntry(
              key: ValueKey(entry.id),
              entry: entry,
              isLast: isLast,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          '${'passport.load_error'.tr()}: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Update `timeline_entry.dart` — change `.deleteJourneyEntry()` to `.delete()`**

In `lib/features/journey/presentation/widgets/timeline_entry.dart`, find and replace (line ~72):

Old:
```dart
        await ref
            .read(journeyRepositoryProvider)
            .deleteJourneyEntry(widget.entry.id);
```

New:
```dart
        await ref
            .read(journeyRepositoryProvider)
            .delete(widget.entry.id);
```

- [ ] **Step 4: Run analyzer on the UI files**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter analyze lib/features/narration/presentation/widgets/save_to_passport_button.dart lib/features/journey/presentation/screens/journey_screen.dart lib/features/journey/presentation/widgets/timeline_entry.dart
```

Expected: No issues in these three files.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && git add lib/features/narration/presentation/widgets/save_to_passport_button.dart lib/features/journey/presentation/screens/journey_screen.dart lib/features/journey/presentation/widgets/timeline_entry.dart && git commit -m "feat: remove auth gate from Journey UI"
```

---

## Task 6: Delete obsolete files

**Files to delete:**
- `lib/features/journey/data/supabase_journey_repository.dart`
- `lib/features/journey/data/caching_journey_repository.dart`
- `lib/features/journey/data/journey_entry_mapper.dart`
- `lib/features/journey/data/services/hive_journey_cache_service.dart`
- `test/features/journey/data/supabase_journey_repository_test.dart`
- `test/features/journey/data/caching_journey_repository_test.dart`
- `test/features/journey/data/services/hive_journey_cache_service_test.dart`

- [ ] **Step 1: Delete all obsolete files**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && rm lib/features/journey/data/supabase_journey_repository.dart lib/features/journey/data/caching_journey_repository.dart lib/features/journey/data/journey_entry_mapper.dart lib/features/journey/data/services/hive_journey_cache_service.dart test/features/journey/data/supabase_journey_repository_test.dart test/features/journey/data/caching_journey_repository_test.dart test/features/journey/data/services/hive_journey_cache_service_test.dart
```

- [ ] **Step 2: Run full analyzer to confirm no remaining errors**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter analyze
```

Expected: No errors. (Warnings about unused imports in other parts of the codebase are OK to ignore if they pre-existed.)

- [ ] **Step 3: Run all journey tests**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test test/features/journey/
```

Expected: All tests PASS (journey_entry_test + hive_journey_repository_test).

- [ ] **Step 4: Run full test suite**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && fvm flutter test
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore/frontend && git add -A && git commit -m "chore: delete obsolete Journey Supabase/caching data layer"
```
