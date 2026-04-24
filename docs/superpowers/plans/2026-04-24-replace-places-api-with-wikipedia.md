# Replace Places API with Wikipedia — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Google Places API with Wikipedia GeoSearch + Wikidata P31 filtering in the `explore` feature to eliminate external API costs while preserving domain model, repository interface, and UI.

**Architecture:** New thin `WikipediaPlacesService` handles HTTP (geosearch + wbgetentities); new pure `WikidataCategoryMapper` applies P31 whitelist → `PlaceCategory`. `PlacesRepositoryImpl` orchestrates the two calls plus dynamic-radius retry and language fallback. `HivePlacesCacheService` is refactored to serialize `Place` directly (no longer depends on Google DTO / API key).

**Tech Stack:** Dart, Flutter, `http` (with `http/testing.MockClient`), `mocktail`, Riverpod, Hive.

**Spec:** `docs/superpowers/specs/2026-04-24-replace-places-api-with-wikipedia-design.md`

---

## File Structure

### New files

| Path | Responsibility |
|---|---|
| `lib/features/explore/data/dto/wiki_geo_search_result_dto.dart` | Single GeoSearch result (title, coords, thumbnail, wikidataId) |
| `lib/features/explore/data/dto/wikidata_entity_dto.dart` | Parsed `wbgetentities` entity with P31 class IDs + labels |
| `lib/features/explore/data/mappers/wikidata_category_mapper.dart` | P31 whitelist → `PlaceCategory`; returns null for non-whitelisted |
| `lib/features/explore/data/mappers/place_json_mapper.dart` | `Place` ↔ JSON (for Hive cache; no API key) |
| `lib/features/explore/data/services/wikipedia_places_service.dart` | Thin HTTP wrapper: `geoSearch`, `searchByText`, `fetchEntities`, `fetchEntityById` |
| `test/features/explore/data/dto/wiki_geo_search_result_dto_test.dart` | unit test |
| `test/features/explore/data/dto/wikidata_entity_dto_test.dart` | unit test |
| `test/features/explore/data/mappers/wikidata_category_mapper_test.dart` | unit test |
| `test/features/explore/data/mappers/place_json_mapper_test.dart` | unit test |
| `test/features/explore/data/services/wikipedia_places_service_test.dart` | unit test with `MockClient` |

### Modified files

| Path | Change |
|---|---|
| `lib/features/explore/data/repositories/places_repository_impl.dart` | Use new service + mapper; add radius retry + language fallback |
| `lib/features/explore/data/services/hive_places_cache_service.dart` | Use `PlaceJsonMapper`; remove `_apiKey` field; add `_cacheSchemaVersion` check |
| `lib/features/explore/providers.dart` | Swap `placesApiServiceProvider` → `wikipediaPlacesServiceProvider`; drop apiKey from cache provider |
| `test/features/explore/data/repositories/places_repository_impl_test.dart` | Rewrite to test against `WikipediaPlacesService` + new behaviors |

### Deleted files (last)

- `lib/features/explore/data/services/places_api_service.dart`
- `lib/features/explore/data/dto/google_place_dto.dart`
- `lib/features/explore/data/dto/google_place_photo_dto.dart`
- `lib/features/explore/data/mappers/place_category_mapper.dart`

---

## Commands reference

- Run a single test file: `cd frontend && fvm flutter test <path>`
- Run all tests: `cd frontend && fvm flutter test`
- Static analysis: `cd frontend && fvm flutter analyze --fatal-infos`

---

# Phase 1: Pure DTOs & Mapper

## Task 1: `WikiGeoSearchResultDto`

**Files:**
- Create: `frontend/lib/features/explore/data/dto/wiki_geo_search_result_dto.dart`
- Test: `frontend/test/features/explore/data/dto/wiki_geo_search_result_dto_test.dart`

A single GeoSearch page result (merged with `pageimages` + `pageprops.wikibase_item` from the same response).

- [ ] **Step 1: Write the failing test**

```dart
// frontend/test/features/explore/data/dto/wiki_geo_search_result_dto_test.dart
import 'package:context_app/features/explore/data/dto/wiki_geo_search_result_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WikiGeoSearchResultDto.fromPage', () {
    test('parses page with thumbnail and wikidata id', () {
      final page = {
        'pageid': 7253,
        'title': '台北101',
        'coordinates': [
          {'lat': 25.0336, 'lon': 121.5644, 'primary': ''}
        ],
        'thumbnail': {
          'source': 'https://upload.wikimedia.org/x.jpg',
          'width': 400,
          'height': 300,
        },
        'pageprops': {'wikibase_item': 'Q83101'},
      };

      final dto = WikiGeoSearchResultDto.fromPage(page);

      expect(dto.pageId, 7253);
      expect(dto.title, '台北101');
      expect(dto.lat, 25.0336);
      expect(dto.lon, 121.5644);
      expect(dto.thumbnailUrl, 'https://upload.wikimedia.org/x.jpg');
      expect(dto.thumbnailWidth, 400);
      expect(dto.thumbnailHeight, 300);
      expect(dto.wikidataId, 'Q83101');
    });

    test('handles missing thumbnail and wikidata id', () {
      final page = {
        'pageid': 1,
        'title': 'No data place',
        'coordinates': [
          {'lat': 10.0, 'lon': 20.0}
        ],
      };

      final dto = WikiGeoSearchResultDto.fromPage(page);

      expect(dto.thumbnailUrl, isNull);
      expect(dto.wikidataId, isNull);
    });

    test('returns null when coordinates are missing', () {
      final page = {'pageid': 1, 'title': 'Bad page'};
      expect(WikiGeoSearchResultDto.fromPage(page), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/dto/wiki_geo_search_result_dto_test.dart
```

Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// frontend/lib/features/explore/data/dto/wiki_geo_search_result_dto.dart
class WikiGeoSearchResultDto {
  final int pageId;
  final String title;
  final double lat;
  final double lon;
  final String? thumbnailUrl;
  final int? thumbnailWidth;
  final int? thumbnailHeight;
  final String? wikidataId;

  const WikiGeoSearchResultDto({
    required this.pageId,
    required this.title,
    required this.lat,
    required this.lon,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
    this.wikidataId,
  });

  /// Parses a single page entry from the merged GeoSearch response.
  ///
  /// Returns null if the page lacks primary coordinates.
  static WikiGeoSearchResultDto? fromPage(Map<String, dynamic> page) {
    final coords = page['coordinates'];
    if (coords is! List || coords.isEmpty) return null;
    final first = coords.first;
    if (first is! Map) return null;

    final lat = (first['lat'] as num?)?.toDouble();
    final lon = (first['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final thumb = page['thumbnail'];
    final pageProps = page['pageprops'];

    return WikiGeoSearchResultDto(
      pageId: (page['pageid'] as num).toInt(),
      title: page['title'] as String,
      lat: lat,
      lon: lon,
      thumbnailUrl: thumb is Map ? thumb['source'] as String? : null,
      thumbnailWidth: thumb is Map ? (thumb['width'] as num?)?.toInt() : null,
      thumbnailHeight: thumb is Map ? (thumb['height'] as num?)?.toInt() : null,
      wikidataId:
          pageProps is Map ? pageProps['wikibase_item'] as String? : null,
    );
  }
}
```

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/dto/wiki_geo_search_result_dto_test.dart
```

Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/dto/wiki_geo_search_result_dto.dart \
  frontend/test/features/explore/data/dto/wiki_geo_search_result_dto_test.dart
git commit -m "feat(explore): add WikiGeoSearchResultDto"
```

---

## Task 2: `WikidataEntityDto`

**Files:**
- Create: `frontend/lib/features/explore/data/dto/wikidata_entity_dto.dart`
- Test: `frontend/test/features/explore/data/dto/wikidata_entity_dto_test.dart`

Parses a single entity from `wbgetentities`. Exposes `p31ClassIds` (list of `Q…` ids from `claims.P31`).

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/features/explore/data/dto/wikidata_entity_dto_test.dart
import 'package:context_app/features/explore/data/dto/wikidata_entity_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WikidataEntityDto.fromEntity', () {
    test('extracts P31 class ids', () {
      final entity = {
        'id': 'Q221716',
        'claims': {
          'P31': [
            {
              'mainsnak': {
                'datavalue': {
                  'value': {'id': 'Q5393308'}
                }
              }
            }
          ],
        },
      };

      final dto = WikidataEntityDto.fromEntity(entity);

      expect(dto.id, 'Q221716');
      expect(dto.p31ClassIds, ['Q5393308']);
    });

    test('handles multiple P31 values', () {
      final entity = {
        'id': 'Q11574990',
        'claims': {
          'P31': [
            {'mainsnak': {'datavalue': {'value': {'id': 'Q79007'}}}},
            {'mainsnak': {'datavalue': {'value': {'id': 'Q667783'}}}},
          ],
        },
      };

      final dto = WikidataEntityDto.fromEntity(entity);

      expect(dto.p31ClassIds, ['Q79007', 'Q667783']);
    });

    test('returns empty list when P31 missing', () {
      final entity = {'id': 'Q1', 'claims': <String, dynamic>{}};
      final dto = WikidataEntityDto.fromEntity(entity);
      expect(dto.p31ClassIds, isEmpty);
    });

    test('skips malformed P31 claims without raising', () {
      final entity = {
        'id': 'Q1',
        'claims': {
          'P31': [
            {'mainsnak': {}},
            {'mainsnak': {'datavalue': {'value': {'id': 'Q33506'}}}},
          ],
        },
      };

      final dto = WikidataEntityDto.fromEntity(entity);
      expect(dto.p31ClassIds, ['Q33506']);
    });
  });
}
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/dto/wikidata_entity_dto_test.dart
```

Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// frontend/lib/features/explore/data/dto/wikidata_entity_dto.dart
class WikidataEntityDto {
  final String id;
  final List<String> p31ClassIds;

  const WikidataEntityDto({required this.id, required this.p31ClassIds});

  factory WikidataEntityDto.fromEntity(Map<String, dynamic> entity) {
    final claims = entity['claims'];
    final p31Claims = (claims is Map ? claims['P31'] : null) as List? ?? [];

    final classIds = <String>[];
    for (final claim in p31Claims) {
      if (claim is! Map) continue;
      final mainsnak = claim['mainsnak'];
      if (mainsnak is! Map) continue;
      final datavalue = mainsnak['datavalue'];
      if (datavalue is! Map) continue;
      final value = datavalue['value'];
      if (value is! Map) continue;
      final classId = value['id'];
      if (classId is String) classIds.add(classId);
    }

    return WikidataEntityDto(
      id: entity['id'] as String,
      p31ClassIds: classIds,
    );
  }
}
```

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/dto/wikidata_entity_dto_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/dto/wikidata_entity_dto.dart \
  frontend/test/features/explore/data/dto/wikidata_entity_dto_test.dart
git commit -m "feat(explore): add WikidataEntityDto with P31 extraction"
```

---

## Task 3: `WikidataCategoryMapper` (P31 whitelist → `PlaceCategory`)

**Files:**
- Create: `frontend/lib/features/explore/data/mappers/wikidata_category_mapper.dart`
- Test: `frontend/test/features/explore/data/mappers/wikidata_category_mapper_test.dart`

Pure static mapping. Returns `null` if no P31 matches the whitelist (caller drops the place).

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/features/explore/data/mappers/wikidata_category_mapper_test.dart
import 'package:context_app/features/explore/data/mappers/wikidata_category_mapper.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WikidataCategoryMapper.categorize', () {
    test('Buddhist temple (Q5393308) → historicalCultural', () {
      expect(
        WikidataCategoryMapper.categorize(['Q5393308']),
        PlaceCategory.historicalCultural,
      );
    });

    test('Shinto shrine (Q845945) → historicalCultural', () {
      expect(
        WikidataCategoryMapper.categorize(['Q845945']),
        PlaceCategory.historicalCultural,
      );
    });

    test('Chinese temple (Q2680845) → historicalCultural', () {
      expect(
        WikidataCategoryMapper.categorize(['Q2680845']),
        PlaceCategory.historicalCultural,
      );
    });

    test('museum (Q33506) → museumArt', () {
      expect(
        WikidataCategoryMapper.categorize(['Q33506']),
        PlaceCategory.museumArt,
      );
    });

    test('art museum (Q207694) → museumArt', () {
      expect(
        WikidataCategoryMapper.categorize(['Q207694']),
        PlaceCategory.museumArt,
      );
    });

    test('mountain (Q8502) → naturalLandscape', () {
      expect(
        WikidataCategoryMapper.categorize(['Q8502']),
        PlaceCategory.naturalLandscape,
      );
    });

    test('urban park (Q22698) → naturalLandscape', () {
      expect(
        WikidataCategoryMapper.categorize(['Q22698']),
        PlaceCategory.naturalLandscape,
      );
    });

    test('tourist attraction (Q570116) → modernUrban', () {
      expect(
        WikidataCategoryMapper.categorize(['Q570116']),
        PlaceCategory.modernUrban,
      );
    });

    test('returns first whitelist hit when multiple P31 values', () {
      // street (not in WL) + sandō (in WL, cultural)
      expect(
        WikidataCategoryMapper.categorize(['Q79007', 'Q667783']),
        PlaceCategory.historicalCultural,
      );
    });

    test('returns null for high school (Q56351315, not whitelisted)', () {
      expect(WikidataCategoryMapper.categorize(['Q56351315']), isNull);
    });

    test('returns null for police station (Q861951)', () {
      expect(WikidataCategoryMapper.categorize(['Q861951']), isNull);
    });

    test('returns null for district court (Q75029)', () {
      expect(WikidataCategoryMapper.categorize(['Q75029']), isNull);
    });

    test('returns null for empty list', () {
      expect(WikidataCategoryMapper.categorize([]), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/mappers/wikidata_category_mapper_test.dart
```

Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// frontend/lib/features/explore/data/mappers/wikidata_category_mapper.dart
import 'package:context_app/features/explore/domain/models/place_category.dart';

/// Maps Wikidata P31 (instance of) class IDs to app [PlaceCategory].
///
/// Returns null if none of the class IDs is in the whitelist, signalling
/// that the corresponding place should be dropped.
class WikidataCategoryMapper {
  static const Map<String, PlaceCategory> _whitelist = {
    // --- historical & cultural ---
    'Q5393308': PlaceCategory.historicalCultural, // Buddhist temple
    'Q845945': PlaceCategory.historicalCultural,  // Shinto shrine
    'Q2680845': PlaceCategory.historicalCultural, // Chinese temple
    'Q16970': PlaceCategory.historicalCultural,   // church building
    'Q32815': PlaceCategory.historicalCultural,   // mosque
    'Q23413': PlaceCategory.historicalCultural,   // castle
    'Q16560': PlaceCategory.historicalCultural,   // palace
    'Q4989906': PlaceCategory.historicalCultural, // monument
    'Q839954': PlaceCategory.historicalCultural,  // archaeological site
    'Q22746': PlaceCategory.historicalCultural,   // historic site
    'Q123314524': PlaceCategory.historicalCultural, // yamajiro
    'Q667783': PlaceCategory.historicalCultural,  // sandō
    'Q162633': PlaceCategory.historicalCultural,  // academy (書院)

    // --- museum / art ---
    'Q33506': PlaceCategory.museumArt,           // museum
    'Q207694': PlaceCategory.museumArt,          // art museum
    'Q2065736': PlaceCategory.museumArt,         // cultural institution
    'Q7075': PlaceCategory.museumArt,            // library

    // --- natural landscape ---
    'Q22698': PlaceCategory.naturalLandscape,    // park
    'Q46831': PlaceCategory.naturalLandscape,    // mountain range
    'Q8502': PlaceCategory.naturalLandscape,     // mountain
    'Q23397': PlaceCategory.naturalLandscape,    // lake
    'Q34038': PlaceCategory.naturalLandscape,    // waterfall
    'Q46169': PlaceCategory.naturalLandscape,    // national park
    'Q40080': PlaceCategory.naturalLandscape,    // beach
    'Q43501': PlaceCategory.naturalLandscape,    // zoo
    'Q130003': PlaceCategory.naturalLandscape,   // aquarium

    // --- modern / urban ---
    'Q570116': PlaceCategory.modernUrban,        // tourist attraction
    'Q12280': PlaceCategory.modernUrban,         // bridge
    'Q11303': PlaceCategory.modernUrban,         // skyscraper
    'Q44782': PlaceCategory.modernUrban,         // urban park
  };

  /// Returns the [PlaceCategory] of the first whitelisted P31 class id,
  /// or null if none match.
  static PlaceCategory? categorize(List<String> p31ClassIds) {
    for (final id in p31ClassIds) {
      final category = _whitelist[id];
      if (category != null) return category;
    }
    return null;
  }
}
```

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/mappers/wikidata_category_mapper_test.dart
```

Expected: PASS (13 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/mappers/wikidata_category_mapper.dart \
  frontend/test/features/explore/data/mappers/wikidata_category_mapper_test.dart
git commit -m "feat(explore): add WikidataCategoryMapper with P31 whitelist"
```

---

# Phase 2: HTTP service

## Task 4: `WikipediaPlacesService.geoSearch`

**Files:**
- Create: `frontend/lib/features/explore/data/services/wikipedia_places_service.dart`
- Test: `frontend/test/features/explore/data/services/wikipedia_places_service_test.dart`

Uses injected `http.Client` so tests can use `MockClient`. User-Agent header required by Wikimedia.

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/features/explore/data/services/wikipedia_places_service_test.dart
import 'dart:convert';

import 'package:context_app/features/explore/data/services/wikipedia_places_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('WikipediaPlacesService.geoSearch', () {
    test('calls correct URL with lang/coord/radius and parses response', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      final mockClient = MockClient((req) async {
        capturedUri = req.url;
        capturedHeaders = req.headers;
        return http.Response(
          jsonEncode({
            'query': {
              'pages': {
                '7253': {
                  'pageid': 7253,
                  'title': '台北101',
                  'coordinates': [
                    {'lat': 25.0336, 'lon': 121.5644}
                  ],
                  'thumbnail': {
                    'source': 'https://upload.wikimedia.org/x.jpg',
                    'width': 400,
                    'height': 300,
                  },
                  'pageprops': {'wikibase_item': 'Q83101'},
                },
              },
            },
          }),
          200,
        );
      });

      final service = WikipediaPlacesService(client: mockClient);

      final results = await service.geoSearch(
        lat: 25.0336,
        lon: 121.5644,
        radiusMeters: 1000,
        wikiLang: 'zh',
      );

      expect(capturedUri.host, 'zh.wikipedia.org');
      expect(capturedUri.path, '/w/api.php');
      expect(capturedUri.queryParameters['action'], 'query');
      expect(capturedUri.queryParameters['generator'], 'geosearch');
      expect(capturedUri.queryParameters['ggscoord'], '25.0336|121.5644');
      expect(capturedUri.queryParameters['ggsradius'], '1000');
      expect(capturedUri.queryParameters['prop'],
          'pageimages|coordinates|pageprops');
      expect(capturedHeaders['User-Agent'], contains('InstantExplore'));

      expect(results, hasLength(1));
      expect(results.first.title, '台北101');
      expect(results.first.wikidataId, 'Q83101');
    });

    test('returns empty list when query.pages missing', () async {
      final mockClient = MockClient((_) async => http.Response(
            jsonEncode({'batchcomplete': ''}),
            200,
          ));
      final service = WikipediaPlacesService(client: mockClient);

      final results = await service.geoSearch(
        lat: 0,
        lon: 0,
        radiusMeters: 1000,
        wikiLang: 'en',
      );

      expect(results, isEmpty);
    });

    test('throws on non-200 response', () async {
      final mockClient = MockClient((_) async => http.Response('err', 503));
      final service = WikipediaPlacesService(client: mockClient);

      expect(
        () => service.geoSearch(
          lat: 0, lon: 0, radiusMeters: 1000, wikiLang: 'en'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/services/wikipedia_places_service_test.dart
```

Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// frontend/lib/features/explore/data/services/wikipedia_places_service.dart
import 'dart:convert';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/data/dto/wiki_geo_search_result_dto.dart';
import 'package:context_app/features/explore/domain/errors/place_error.dart';
import 'package:http/http.dart' as http;

/// Thin HTTP wrapper around Wikipedia + Wikidata public APIs.
class WikipediaPlacesService {
  static const String _userAgent =
      'InstantExplore/1.0 (https://instant-explore.app; support@instant-explore.app)';
  static const int _thumbSize = 400;

  final http.Client _client;

  WikipediaPlacesService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<WikiGeoSearchResultDto>> geoSearch({
    required double lat,
    required double lon,
    required double radiusMeters,
    required String wikiLang,
    int limit = 10,
  }) async {
    final uri = Uri.https('$wikiLang.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'generator': 'geosearch',
      'ggscoord': '$lat|$lon',
      'ggsradius': radiusMeters.toInt().toString(),
      'ggslimit': limit.toString(),
      'prop': 'pageimages|coordinates|pageprops',
      'pithumbsize': '$_thumbSize',
      'ppprop': 'wikibase_item',
      'format': 'json',
    });

    final response = await _client.get(uri, headers: {
      'User-Agent': _userAgent,
    });

    if (response.statusCode != 200) {
      throw AppError(
        type: PlaceError.searchFailed,
        message: 'Wikipedia GeoSearch failed',
        context: {'status_code': response.statusCode},
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final pages = (data['query'] as Map?)?['pages'];
    if (pages is! Map) return const [];

    final results = <WikiGeoSearchResultDto>[];
    for (final page in pages.values) {
      if (page is! Map) continue;
      final dto = WikiGeoSearchResultDto.fromPage(
        Map<String, dynamic>.from(page),
      );
      if (dto != null) results.add(dto);
    }
    return results;
  }
}
```

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/services/wikipedia_places_service_test.dart
```

Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/services/wikipedia_places_service.dart \
  frontend/test/features/explore/data/services/wikipedia_places_service_test.dart
git commit -m "feat(explore): add WikipediaPlacesService.geoSearch"
```

---

## Task 5: `WikipediaPlacesService.fetchEntities`

**Files:**
- Modify: `frontend/lib/features/explore/data/services/wikipedia_places_service.dart`
- Modify: `frontend/test/features/explore/data/services/wikipedia_places_service_test.dart`

- [ ] **Step 1: Add failing test**

Append to `wikipedia_places_service_test.dart`:

```dart
  group('WikipediaPlacesService.fetchEntities', () {
    test('joins ids with | and parses claims', () async {
      late Uri capturedUri;
      final mockClient = MockClient((req) async {
        capturedUri = req.url;
        return http.Response(
          jsonEncode({
            'entities': {
              'Q221716': {
                'id': 'Q221716',
                'claims': {
                  'P31': [
                    {'mainsnak': {'datavalue': {'value': {'id': 'Q5393308'}}}},
                  ],
                },
              },
            },
          }),
          200,
        );
      });
      final service = WikipediaPlacesService(client: mockClient);

      final entities = await service.fetchEntities(['Q221716']);

      expect(capturedUri.host, 'www.wikidata.org');
      expect(capturedUri.queryParameters['action'], 'wbgetentities');
      expect(capturedUri.queryParameters['ids'], 'Q221716');
      expect(capturedUri.queryParameters['props'], 'claims');
      expect(entities['Q221716']?.p31ClassIds, ['Q5393308']);
    });

    test('returns empty map when given empty id list', () async {
      final mockClient = MockClient((_) async {
        fail('HTTP should not be called for empty list');
      });
      final service = WikipediaPlacesService(client: mockClient);
      expect(await service.fetchEntities([]), isEmpty);
    });

    test('chunks requests of more than 50 ids', () async {
      final calls = <String>[];
      final mockClient = MockClient((req) async {
        calls.add(req.url.queryParameters['ids']!);
        return http.Response(jsonEncode({'entities': {}}), 200);
      });
      final service = WikipediaPlacesService(client: mockClient);

      final ids = List.generate(75, (i) => 'Q$i');
      await service.fetchEntities(ids);

      expect(calls, hasLength(2));
      expect(calls[0].split('|'), hasLength(50));
      expect(calls[1].split('|'), hasLength(25));
    });
  });
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/services/wikipedia_places_service_test.dart
```

Expected: FAIL — method does not exist.

- [ ] **Step 3: Implement**

Add these imports at top of `wikipedia_places_service.dart`:

```dart
import 'package:context_app/features/explore/data/dto/wikidata_entity_dto.dart';
```

Append to the class:

```dart
  static const int _batchSize = 50;

  /// Batch-fetches Wikidata entities by id.
  ///
  /// Chunks requests of more than [_batchSize] ids into multiple calls.
  Future<Map<String, WikidataEntityDto>> fetchEntities(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const {};

    final result = <String, WikidataEntityDto>{};
    for (var i = 0; i < ids.length; i += _batchSize) {
      final chunk = ids.sublist(
        i,
        i + _batchSize > ids.length ? ids.length : i + _batchSize,
      );
      result.addAll(await _fetchEntityChunk(chunk));
    }
    return result;
  }

  Future<Map<String, WikidataEntityDto>> _fetchEntityChunk(
    List<String> ids,
  ) async {
    final uri = Uri.https('www.wikidata.org', '/w/api.php', {
      'action': 'wbgetentities',
      'ids': ids.join('|'),
      'props': 'claims',
      'format': 'json',
    });

    final response = await _client.get(uri, headers: {
      'User-Agent': _userAgent,
    });

    if (response.statusCode != 200) {
      throw AppError(
        type: PlaceError.searchFailed,
        message: 'Wikidata wbgetentities failed',
        context: {'status_code': response.statusCode},
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final entities = data['entities'];
    if (entities is! Map) return const {};

    final result = <String, WikidataEntityDto>{};
    for (final entry in entities.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      result[entry.key] = WikidataEntityDto.fromEntity(
        Map<String, dynamic>.from(value),
      );
    }
    return result;
  }
```

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/services/wikipedia_places_service_test.dart
```

Expected: PASS (6 tests total).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/services/wikipedia_places_service.dart \
  frontend/test/features/explore/data/services/wikipedia_places_service_test.dart
git commit -m "feat(explore): add WikipediaPlacesService.fetchEntities"
```

---

## Task 6: `WikipediaPlacesService.searchByText`

**Files:**
- Modify: `frontend/lib/features/explore/data/services/wikipedia_places_service.dart`
- Modify: `frontend/test/features/explore/data/services/wikipedia_places_service_test.dart`

Uses `list=search` + `prop=pageimages|coordinates|pageprops` (via `generator=search`) so results share the same DTO as geoSearch.

- [ ] **Step 1: Add failing test**

Append to test file:

```dart
  group('WikipediaPlacesService.searchByText', () {
    test('issues generator=search and returns DTOs', () async {
      late Uri capturedUri;
      final mockClient = MockClient((req) async {
        capturedUri = req.url;
        return http.Response(
          jsonEncode({
            'query': {
              'pages': {
                '1': {
                  'pageid': 1,
                  'title': '清水寺',
                  'coordinates': [{'lat': 34.9948, 'lon': 135.7850}],
                  'pageprops': {'wikibase_item': 'Q221716'},
                },
              },
            },
          }),
          200,
        );
      });
      final service = WikipediaPlacesService(client: mockClient);

      final results = await service.searchByText('清水寺', wikiLang: 'zh');

      expect(capturedUri.host, 'zh.wikipedia.org');
      expect(capturedUri.queryParameters['generator'], 'search');
      expect(capturedUri.queryParameters['gsrsearch'], '清水寺');
      expect(results.first.wikidataId, 'Q221716');
    });
  });
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/services/wikipedia_places_service_test.dart
```

Expected: FAIL — method does not exist.

- [ ] **Step 3: Implement**

Append to `wikipedia_places_service.dart`:

```dart
  Future<List<WikiGeoSearchResultDto>> searchByText(
    String query, {
    required String wikiLang,
    int limit = 10,
  }) async {
    final uri = Uri.https('$wikiLang.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'generator': 'search',
      'gsrsearch': query,
      'gsrlimit': limit.toString(),
      'prop': 'pageimages|coordinates|pageprops',
      'pithumbsize': '$_thumbSize',
      'ppprop': 'wikibase_item',
      'format': 'json',
    });

    final response = await _client.get(uri, headers: {
      'User-Agent': _userAgent,
    });

    if (response.statusCode != 200) {
      throw AppError(
        type: PlaceError.searchFailed,
        message: 'Wikipedia text search failed',
        context: {'status_code': response.statusCode},
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final pages = (data['query'] as Map?)?['pages'];
    if (pages is! Map) return const [];

    final results = <WikiGeoSearchResultDto>[];
    for (final page in pages.values) {
      if (page is! Map) continue;
      final dto = WikiGeoSearchResultDto.fromPage(
        Map<String, dynamic>.from(page),
      );
      if (dto != null) results.add(dto);
    }
    return results;
  }
```

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/services/wikipedia_places_service_test.dart
```

Expected: PASS (7 tests total).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/services/wikipedia_places_service.dart \
  frontend/test/features/explore/data/services/wikipedia_places_service_test.dart
git commit -m "feat(explore): add WikipediaPlacesService.searchByText"
```

---

## Task 7: `WikipediaPlacesService.fetchEntityById`

For `getPlaceById`. We need both the entity (for P31) and the associated wiki page (title/coords/thumbnail). Approach: use Wikidata's `sites=enwiki|zhwiki|jawiki` link to find the matching wiki page title, then call geoSearch-style page lookup.

Simpler: call `wbgetentities` with `props=claims|sitelinks` + `sitelinkprops=url`, then call the wiki's `prop=pageimages|coordinates` using the sitelink title.

**Files:**
- Modify: `frontend/lib/features/explore/data/services/wikipedia_places_service.dart`
- Modify: `frontend/test/features/explore/data/services/wikipedia_places_service_test.dart`

- [ ] **Step 1: Add failing test**

Append to test file:

```dart
  group('WikipediaPlacesService.fetchEntityById', () {
    test('fetches entity + page info and returns merged DTO', () async {
      final mockClient = MockClient((req) async {
        if (req.url.host == 'www.wikidata.org') {
          return http.Response(
            jsonEncode({
              'entities': {
                'Q221716': {
                  'id': 'Q221716',
                  'claims': {
                    'P31': [
                      {'mainsnak': {'datavalue': {'value': {'id': 'Q5393308'}}}},
                    ],
                  },
                  'sitelinks': {
                    'jawiki': {'site': 'jawiki', 'title': '清水寺'},
                  },
                },
              },
            }),
            200,
          );
        }
        // ja.wikipedia.org page lookup
        expect(req.url.host, 'ja.wikipedia.org');
        expect(req.url.queryParameters['titles'], '清水寺');
        return http.Response(
          jsonEncode({
            'query': {
              'pages': {
                '1758861': {
                  'pageid': 1758861,
                  'title': '清水寺',
                  'coordinates': [{'lat': 34.9948, 'lon': 135.785}],
                  'thumbnail': {
                    'source': 'https://upload.wikimedia.org/k.jpg',
                    'width': 400,
                    'height': 300,
                  },
                  'pageprops': {'wikibase_item': 'Q221716'},
                },
              },
            },
          }),
          200,
        );
      });
      final service = WikipediaPlacesService(client: mockClient);

      final result = await service.fetchEntityById(
        'Q221716',
        wikiLang: 'ja',
      );

      expect(result, isNotNull);
      expect(result!.dto.title, '清水寺');
      expect(result.dto.wikidataId, 'Q221716');
      expect(result.entity.p31ClassIds, ['Q5393308']);
    });

    test('returns null when entity has no matching sitelink', () async {
      final mockClient = MockClient((req) async {
        expect(req.url.host, 'www.wikidata.org');
        return http.Response(
          jsonEncode({
            'entities': {
              'Q999': {
                'id': 'Q999',
                'claims': {},
                'sitelinks': {},
              },
            },
          }),
          200,
        );
      });
      final service = WikipediaPlacesService(client: mockClient);

      expect(
        await service.fetchEntityById('Q999', wikiLang: 'en'),
        isNull,
      );
    });
  });
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/services/wikipedia_places_service_test.dart
```

Expected: FAIL — method does not exist.

- [ ] **Step 3: Implement**

Append to `wikipedia_places_service.dart` (above, outside the class body, add this helper class):

```dart
/// Combined result of [WikipediaPlacesService.fetchEntityById].
class WikiEntityWithPage {
  final WikiGeoSearchResultDto dto;
  final WikidataEntityDto entity;
  const WikiEntityWithPage({required this.dto, required this.entity});
}
```

Append to the service class:

```dart
  /// Fetches a Wikidata entity by id plus the associated wiki page info
  /// (title, coordinates, thumbnail) via the matching sitelink.
  ///
  /// Returns null if the entity has no sitelink on the requested wiki and
  /// no fallback sitelink was found.
  Future<WikiEntityWithPage?> fetchEntityById(
    String wikidataId, {
    required String wikiLang,
  }) async {
    final uri = Uri.https('www.wikidata.org', '/w/api.php', {
      'action': 'wbgetentities',
      'ids': wikidataId,
      'props': 'claims|sitelinks',
      'format': 'json',
    });

    final response = await _client.get(uri, headers: {
      'User-Agent': _userAgent,
    });
    if (response.statusCode != 200) {
      throw AppError(
        type: PlaceError.searchFailed,
        message: 'Wikidata wbgetentities failed',
        context: {'status_code': response.statusCode},
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final entityRaw = (data['entities'] as Map?)?[wikidataId];
    if (entityRaw is! Map) return null;

    final entity = WikidataEntityDto.fromEntity(
      Map<String, dynamic>.from(entityRaw),
    );
    final sitelinks = entityRaw['sitelinks'];
    if (sitelinks is! Map) return null;

    // Prefer the user's language, fall back to enwiki.
    final langKey = '${wikiLang}wiki';
    final Map? link =
        (sitelinks[langKey] ?? sitelinks['enwiki']) as Map?;
    if (link == null) return null;
    final title = link['title'];
    if (title is! String) return null;

    final effectiveLang =
        link['site'] == 'enwiki' ? 'en' : wikiLang;

    final dto = await _fetchPageByTitle(title, wikiLang: effectiveLang);
    if (dto == null) return null;

    return WikiEntityWithPage(dto: dto, entity: entity);
  }

  Future<WikiGeoSearchResultDto?> _fetchPageByTitle(
    String title, {
    required String wikiLang,
  }) async {
    final uri = Uri.https('$wikiLang.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'titles': title,
      'prop': 'pageimages|coordinates|pageprops',
      'pithumbsize': '$_thumbSize',
      'ppprop': 'wikibase_item',
      'format': 'json',
    });

    final response = await _client.get(uri, headers: {
      'User-Agent': _userAgent,
    });
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final pages = (data['query'] as Map?)?['pages'];
    if (pages is! Map) return null;
    for (final page in pages.values) {
      if (page is! Map) continue;
      final dto = WikiGeoSearchResultDto.fromPage(
        Map<String, dynamic>.from(page),
      );
      if (dto != null) return dto;
    }
    return null;
  }
```

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/services/wikipedia_places_service_test.dart
```

Expected: PASS (9 tests total).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/services/wikipedia_places_service.dart \
  frontend/test/features/explore/data/services/wikipedia_places_service_test.dart
git commit -m "feat(explore): add WikipediaPlacesService.fetchEntityById"
```

---

# Phase 3: Repository

## Task 8: Rewrite `PlacesRepositoryImpl.getNearbyPlaces` (basic flow)

**Files:**
- Modify: `frontend/lib/features/explore/data/repositories/places_repository_impl.dart`
- Rewrite: `frontend/test/features/explore/data/repositories/places_repository_impl_test.dart`

Drop `_includedTypes`. Repository now:
1. calls `geoSearch`
2. collects non-null wikidata ids
3. calls `fetchEntities`
4. for each geosearch result with a matching entity, runs `WikidataCategoryMapper.categorize` — drops nulls
5. builds `Place` from DTO + category

Note: `Place.id` becomes `'wikidata:${entity.id}'`. Thumbnail URL goes directly into `Place.photos[0].url`.

Language-code conversion: `Language.code` is like `zh-TW`/`en-US`. Helper: `wikiLang = language.code.split('-').first.toLowerCase()`.

- [ ] **Step 1: Rewrite the test file**

Replace entire contents of `frontend/test/features/explore/data/repositories/places_repository_impl_test.dart`:

```dart
import 'package:context_app/features/explore/data/dto/wiki_geo_search_result_dto.dart';
import 'package:context_app/features/explore/data/dto/wikidata_entity_dto.dart';
import 'package:context_app/features/explore/data/repositories/places_repository_impl.dart';
import 'package:context_app/features/explore/data/services/wikipedia_places_service.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWikipediaPlacesService extends Mock
    implements WikipediaPlacesService {}

void main() {
  late PlacesRepositoryImpl repository;
  late MockWikipediaPlacesService mockService;

  const testLocation = PlaceLocation(latitude: 25.0336, longitude: 121.5644);
  const testLanguage = Language.traditionalChinese;
  const testRadius = 1000.0;

  setUp(() {
    mockService = MockWikipediaPlacesService();
    repository = PlacesRepositoryImpl(mockService);
  });

  WikiGeoSearchResultDto geoDto({
    required String title,
    required String wikidataId,
    String? thumb = 'https://img/x.jpg',
  }) {
    return WikiGeoSearchResultDto(
      pageId: title.hashCode,
      title: title,
      lat: 25.0,
      lon: 121.0,
      thumbnailUrl: thumb,
      thumbnailWidth: thumb == null ? null : 400,
      thumbnailHeight: thumb == null ? null : 300,
      wikidataId: wikidataId,
    );
  }

  group('getNearbyPlaces', () {
    test('calls geoSearch with zh, then wbgetentities, builds Place list', () async {
      when(() => mockService.geoSearch(
            lat: any(named: 'lat'),
            lon: any(named: 'lon'),
            radiusMeters: any(named: 'radiusMeters'),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((_) async => [
            geoDto(title: '清水寺', wikidataId: 'Q221716'),
            geoDto(title: '小学校', wikidataId: 'Q17219693'),
          ]);

      when(() => mockService.fetchEntities(any())).thenAnswer((_) async => {
            'Q221716': const WikidataEntityDto(
              id: 'Q221716',
              p31ClassIds: ['Q5393308'], // temple → kept
            ),
            'Q17219693': const WikidataEntityDto(
              id: 'Q17219693',
              p31ClassIds: ['Q5358913'], // elementary school → dropped
            ),
          });

      final result = await repository.getNearbyPlaces(
        testLocation,
        language: testLanguage,
        radius: testRadius,
      );

      expect(result, hasLength(1));
      expect(result.first.name, '清水寺');
      expect(result.first.id, 'wikidata:Q221716');
      expect(result.first.category, PlaceCategory.historicalCultural);
      expect(result.first.photos.first.url, 'https://img/x.jpg');

      verify(() => mockService.geoSearch(
            lat: 25.0336,
            lon: 121.5644,
            radiusMeters: 1000.0,
            wikiLang: 'zh',
          )).called(1);
    });

    test('skips results with no wikidata id', () async {
      when(() => mockService.geoSearch(
            lat: any(named: 'lat'),
            lon: any(named: 'lon'),
            radiusMeters: any(named: 'radiusMeters'),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((_) async => [
            WikiGeoSearchResultDto(
              pageId: 1, title: 'orphan', lat: 0, lon: 0,
              // no wikidataId
            ),
          ]);
      when(() => mockService.fetchEntities(any()))
          .thenAnswer((_) async => {});

      final result = await repository.getNearbyPlaces(
        testLocation,
        language: testLanguage,
        radius: testRadius,
      );

      expect(result, isEmpty);
    });

    test('Place.photos is empty when no thumbnail', () async {
      when(() => mockService.geoSearch(
            lat: any(named: 'lat'),
            lon: any(named: 'lon'),
            radiusMeters: any(named: 'radiusMeters'),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((_) async => [
            geoDto(title: 't', wikidataId: 'Q1', thumb: null),
          ]);
      when(() => mockService.fetchEntities(any())).thenAnswer((_) async => {
            'Q1': const WikidataEntityDto(id: 'Q1', p31ClassIds: ['Q33506']),
          });

      final result = await repository.getNearbyPlaces(
        testLocation, language: testLanguage, radius: testRadius);

      expect(result.first.photos, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/repositories/places_repository_impl_test.dart
```

Expected: FAIL — `PlacesRepositoryImpl` still takes old API.

- [ ] **Step 3: Replace `places_repository_impl.dart`**

Replace entire file with:

```dart
import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/data/dto/wiki_geo_search_result_dto.dart';
import 'package:context_app/features/explore/data/dto/wikidata_entity_dto.dart';
import 'package:context_app/features/explore/data/mappers/wikidata_category_mapper.dart';
import 'package:context_app/features/explore/data/services/wikipedia_places_service.dart';
import 'package:context_app/features/explore/domain/errors/place_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final WikipediaPlacesService _service;

  PlacesRepositoryImpl(this._service);

  @override
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    required Language language,
    required double radius,
  }) async {
    try {
      final wikiLang = _wikiLang(language);
      final dtos = await _service.geoSearch(
        lat: location.latitude,
        lon: location.longitude,
        radiusMeters: radius,
        wikiLang: wikiLang,
      );
      return _buildPlaces(dtos);
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.unknown,
        message: '獲取附近地點失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Place>> searchPlaces(String query, {
    required Language language,
  }) async {
    // Implemented in Task 11.
    throw UnimplementedError();
  }

  @override
  Future<Place?> getPlaceById(String placeId, {
    required Language language,
  }) async {
    // Implemented in Task 12.
    throw UnimplementedError();
  }

  Future<List<Place>> _buildPlaces(List<WikiGeoSearchResultDto> dtos) async {
    final withIds = dtos
        .where((dto) => dto.wikidataId != null)
        .toList();
    if (withIds.isEmpty) return const [];

    final entities = await _service.fetchEntities(
      withIds.map((dto) => dto.wikidataId!).toList(),
    );

    final places = <Place>[];
    for (final dto in withIds) {
      final entity = entities[dto.wikidataId!];
      if (entity == null) continue;
      final category = WikidataCategoryMapper.categorize(entity.p31ClassIds);
      if (category == null) continue;
      places.add(_placeFromDto(dto, entity, category));
    }
    return places;
  }

  Place _placeFromDto(
    WikiGeoSearchResultDto dto,
    WikidataEntityDto entity,
    PlaceCategory category,
  ) {
    return Place(
      id: 'wikidata:${entity.id}',
      name: dto.title,
      formattedAddress: '',
      location: PlaceLocation(latitude: dto.lat, longitude: dto.lon),
      rating: null,
      userRatingCount: null,
      types: entity.p31ClassIds,
      photos: dto.thumbnailUrl == null
          ? const []
          : [
              PlacePhoto(
                url: dto.thumbnailUrl!,
                widthPx: dto.thumbnailWidth ?? 0,
                heightPx: dto.thumbnailHeight ?? 0,
                authorAttributions: const [],
              ),
            ],
      category: category,
    );
  }

  String _wikiLang(Language language) =>
      language.code.split('-').first.toLowerCase();
}
```

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/repositories/places_repository_impl_test.dart
```

Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/repositories/places_repository_impl.dart \
  frontend/test/features/explore/data/repositories/places_repository_impl_test.dart
git commit -m "refactor(explore): rewrite PlacesRepositoryImpl for Wikipedia source"
```

Note: build will now fail because `providers.dart` still refers to the old service. That's fixed in Task 15.

---

## Task 9: Dynamic radius retry

**Files:**
- Modify: `frontend/lib/features/explore/data/repositories/places_repository_impl.dart`
- Modify: `frontend/test/features/explore/data/repositories/places_repository_impl_test.dart`

If `<3` kept places, retry geoSearch once with radius × 5.

- [ ] **Step 1: Add failing test**

Append to test file (inside the `main()` body, after the existing `group('getNearbyPlaces', …)`):

```dart
  group('getNearbyPlaces dynamic radius', () {
    test('retries once with radius*5 when <3 kept places', () async {
      final calls = <double>[];

      when(() => mockService.geoSearch(
            lat: any(named: 'lat'),
            lon: any(named: 'lon'),
            radiusMeters: any(named: 'radiusMeters'),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((inv) async {
        calls.add(inv.namedArguments[#radiusMeters] as double);
        if (calls.length == 1) {
          return [geoDto(title: 'a', wikidataId: 'Q1')];
        }
        return [
          geoDto(title: 'a', wikidataId: 'Q1'),
          geoDto(title: 'b', wikidataId: 'Q2'),
          geoDto(title: 'c', wikidataId: 'Q3'),
        ];
      });

      when(() => mockService.fetchEntities(any())).thenAnswer((inv) async {
        final ids = inv.positionalArguments.first as List<String>;
        return {
          for (final id in ids)
            id: WikidataEntityDto(id: id, p31ClassIds: const ['Q33506']),
        };
      });

      final result = await repository.getNearbyPlaces(
        testLocation, language: testLanguage, radius: 1000);

      expect(calls, [1000.0, 5000.0]);
      expect(result, hasLength(3));
    });

    test('does not retry when >=3 kept places', () async {
      final calls = <double>[];
      when(() => mockService.geoSearch(
            lat: any(named: 'lat'),
            lon: any(named: 'lon'),
            radiusMeters: any(named: 'radiusMeters'),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((inv) async {
        calls.add(inv.namedArguments[#radiusMeters] as double);
        return [
          geoDto(title: 'a', wikidataId: 'Q1'),
          geoDto(title: 'b', wikidataId: 'Q2'),
          geoDto(title: 'c', wikidataId: 'Q3'),
        ];
      });
      when(() => mockService.fetchEntities(any())).thenAnswer((inv) async {
        final ids = inv.positionalArguments.first as List<String>;
        return {
          for (final id in ids)
            id: WikidataEntityDto(id: id, p31ClassIds: const ['Q33506']),
        };
      });

      await repository.getNearbyPlaces(
        testLocation, language: testLanguage, radius: 1000);

      expect(calls, [1000.0]);
    });
  });
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/repositories/places_repository_impl_test.dart
```

Expected: FAIL — retry test fails (only 1 call).

- [ ] **Step 3: Update repository**

Replace `getNearbyPlaces` in `places_repository_impl.dart`:

```dart
  static const int _minResultsBeforeRetry = 3;
  static const double _retryRadiusFactor = 5.0;

  @override
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    required Language language,
    required double radius,
  }) async {
    try {
      final wikiLang = _wikiLang(language);
      final places = await _searchAtRadius(location, wikiLang, radius);
      if (places.length >= _minResultsBeforeRetry) return places;

      final retried = await _searchAtRadius(
        location, wikiLang, radius * _retryRadiusFactor);
      // Prefer the larger list.
      return retried.length > places.length ? retried : places;
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.unknown,
        message: '獲取附近地點失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<Place>> _searchAtRadius(
    PlaceLocation location,
    String wikiLang,
    double radius,
  ) async {
    final dtos = await _service.geoSearch(
      lat: location.latitude,
      lon: location.longitude,
      radiusMeters: radius,
      wikiLang: wikiLang,
    );
    return _buildPlaces(dtos);
  }
```

Remove the old inline body — `_buildPlaces` and `_placeFromDto` stay unchanged.

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/repositories/places_repository_impl_test.dart
```

Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/repositories/places_repository_impl.dart \
  frontend/test/features/explore/data/repositories/places_repository_impl_test.dart
git commit -m "feat(explore): add dynamic radius retry to getNearbyPlaces"
```

---

## Task 10: Language fallback to en.wiki on 0 results

**Files:**
- Modify: `frontend/lib/features/explore/data/repositories/places_repository_impl.dart`
- Modify: `frontend/test/features/explore/data/repositories/places_repository_impl_test.dart`

If the initial (post-retry) result is empty and the requested wikiLang is not `en`, retry once with `en`.

- [ ] **Step 1: Add failing test**

Append to test file:

```dart
  group('getNearbyPlaces language fallback', () {
    test('falls back to en.wiki on zero results', () async {
      final langs = <String>[];
      when(() => mockService.geoSearch(
            lat: any(named: 'lat'),
            lon: any(named: 'lon'),
            radiusMeters: any(named: 'radiusMeters'),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((inv) async {
        final lang = inv.namedArguments[#wikiLang] as String;
        langs.add(lang);
        if (lang == 'zh') return [];
        return [geoDto(title: 'en place', wikidataId: 'Q1')];
      });
      when(() => mockService.fetchEntities(any())).thenAnswer((_) async => {
            'Q1': const WikidataEntityDto(
              id: 'Q1', p31ClassIds: ['Q33506']),
          });

      final result = await repository.getNearbyPlaces(
        testLocation, language: testLanguage, radius: 1000);

      expect(langs, contains('zh'));
      expect(langs, contains('en'));
      expect(result.first.name, 'en place');
    });

    test('does not fall back when language is already en', () async {
      final langs = <String>[];
      when(() => mockService.geoSearch(
            lat: any(named: 'lat'),
            lon: any(named: 'lon'),
            radiusMeters: any(named: 'radiusMeters'),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((inv) async {
        langs.add(inv.namedArguments[#wikiLang] as String);
        return [];
      });
      when(() => mockService.fetchEntities(any()))
          .thenAnswer((_) async => {});

      await repository.getNearbyPlaces(
        testLocation, language: Language.english, radius: 1000);

      expect(langs.every((l) => l == 'en'), isTrue);
    });
  });
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/repositories/places_repository_impl_test.dart
```

Expected: FAIL — no fallback logic.

- [ ] **Step 3: Add fallback logic**

Replace `getNearbyPlaces` body in `places_repository_impl.dart`:

```dart
  @override
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    required Language language,
    required double radius,
  }) async {
    try {
      final wikiLang = _wikiLang(language);
      final initial = await _searchWithRetry(location, wikiLang, radius);
      if (initial.isNotEmpty || wikiLang == 'en') return initial;

      return _searchWithRetry(location, 'en', radius);
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.unknown,
        message: '獲取附近地點失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<Place>> _searchWithRetry(
    PlaceLocation location,
    String wikiLang,
    double radius,
  ) async {
    final places = await _searchAtRadius(location, wikiLang, radius);
    if (places.length >= _minResultsBeforeRetry) return places;
    final retried = await _searchAtRadius(
      location, wikiLang, radius * _retryRadiusFactor);
    return retried.length > places.length ? retried : places;
  }
```

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/repositories/places_repository_impl_test.dart
```

Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/repositories/places_repository_impl.dart \
  frontend/test/features/explore/data/repositories/places_repository_impl_test.dart
git commit -m "feat(explore): add en.wiki language fallback to getNearbyPlaces"
```

---

## Task 11: Implement `PlacesRepositoryImpl.searchPlaces`

**Files:**
- Modify: `frontend/lib/features/explore/data/repositories/places_repository_impl.dart`
- Modify: `frontend/test/features/explore/data/repositories/places_repository_impl_test.dart`

- [ ] **Step 1: Add failing test**

Append to test file:

```dart
  group('searchPlaces', () {
    test('calls searchByText and applies P31 filter', () async {
      when(() => mockService.searchByText(
            any(),
            wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((_) async => [
            geoDto(title: '清水寺', wikidataId: 'Q221716'),
            geoDto(title: '小学校', wikidataId: 'Q17219693'),
          ]);
      when(() => mockService.fetchEntities(any())).thenAnswer((_) async => {
            'Q221716': const WikidataEntityDto(
              id: 'Q221716', p31ClassIds: ['Q5393308']),
            'Q17219693': const WikidataEntityDto(
              id: 'Q17219693', p31ClassIds: ['Q5358913']),
          });

      final result = await repository.searchPlaces(
        '清水寺', language: testLanguage);

      expect(result, hasLength(1));
      expect(result.first.name, '清水寺');
    });
  });
```

- [ ] **Step 2: Run test, verify failure**

Expected: FAIL with `UnimplementedError`.

- [ ] **Step 3: Implement**

Replace `searchPlaces` in `places_repository_impl.dart`:

```dart
  @override
  Future<List<Place>> searchPlaces(String query, {
    required Language language,
  }) async {
    try {
      final wikiLang = _wikiLang(language);
      final dtos = await _service.searchByText(query, wikiLang: wikiLang);
      return _buildPlaces(dtos);
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.unknown,
        message: '搜尋地點失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }
```

- [ ] **Step 4: Run test, verify pass**

Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/repositories/places_repository_impl.dart \
  frontend/test/features/explore/data/repositories/places_repository_impl_test.dart
git commit -m "feat(explore): implement searchPlaces via Wikipedia text search"
```

---

## Task 12: Implement `PlacesRepositoryImpl.getPlaceById`

Accepts `wikidata:Qxxx` format.

**Files:**
- Modify: `frontend/lib/features/explore/data/repositories/places_repository_impl.dart`
- Modify: `frontend/test/features/explore/data/repositories/places_repository_impl_test.dart`

- [ ] **Step 1: Add failing test**

Append to test file:

```dart
  group('getPlaceById', () {
    test('returns Place for valid wikidata:Q id', () async {
      when(() => mockService.fetchEntityById(
            any(), wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((_) async => WikiEntityWithPage(
            dto: geoDto(title: '清水寺', wikidataId: 'Q221716'),
            entity: const WikidataEntityDto(
              id: 'Q221716', p31ClassIds: ['Q5393308']),
          ));

      final place = await repository.getPlaceById(
        'wikidata:Q221716', language: testLanguage);

      expect(place, isNotNull);
      expect(place!.id, 'wikidata:Q221716');
      expect(place.category, PlaceCategory.historicalCultural);
    });

    test('returns null when service returns null', () async {
      when(() => mockService.fetchEntityById(
            any(), wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((_) async => null);

      expect(
        await repository.getPlaceById(
          'wikidata:Q999', language: testLanguage),
        isNull,
      );
    });

    test('returns null when P31 not in whitelist', () async {
      when(() => mockService.fetchEntityById(
            any(), wikiLang: any(named: 'wikiLang'),
          )).thenAnswer((_) async => WikiEntityWithPage(
            dto: geoDto(title: 'school', wikidataId: 'Q17219693'),
            entity: const WikidataEntityDto(
              id: 'Q17219693', p31ClassIds: ['Q5358913']),
          ));

      expect(
        await repository.getPlaceById(
          'wikidata:Q17219693', language: testLanguage),
        isNull,
      );
    });

    test('returns null when id lacks wikidata: prefix', () async {
      expect(
        await repository.getPlaceById(
          'ChIJN1t_xxxx', language: testLanguage),
        isNull,
      );
    });
  });
```

- [ ] **Step 2: Run test, verify failure**

Expected: FAIL (`UnimplementedError`).

- [ ] **Step 3: Implement**

Replace `getPlaceById` in `places_repository_impl.dart`:

```dart
  static const String _wikidataPrefix = 'wikidata:';

  @override
  Future<Place?> getPlaceById(String placeId, {
    required Language language,
  }) async {
    if (!placeId.startsWith(_wikidataPrefix)) return null;
    final wikidataId = placeId.substring(_wikidataPrefix.length);

    try {
      final wikiLang = _wikiLang(language);
      final combined = await _service.fetchEntityById(
        wikidataId, wikiLang: wikiLang);
      if (combined == null) return null;

      final category =
          WikidataCategoryMapper.categorize(combined.entity.p31ClassIds);
      if (category == null) return null;

      return _placeFromDto(combined.dto, combined.entity, category);
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.unknown,
        message: '取得地點詳情失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }
```

- [ ] **Step 4: Run test, verify pass**

Expected: PASS (12 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/repositories/places_repository_impl.dart \
  frontend/test/features/explore/data/repositories/places_repository_impl_test.dart
git commit -m "feat(explore): implement getPlaceById with wikidata: prefix"
```

---

# Phase 4: Cache refactor

## Task 13: `PlaceJsonMapper`

Direct `Place` ↔ JSON. No Google-specific intermediate.

**Files:**
- Create: `frontend/lib/features/explore/data/mappers/place_json_mapper.dart`
- Test: `frontend/test/features/explore/data/mappers/place_json_mapper_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// frontend/test/features/explore/data/mappers/place_json_mapper_test.dart
import 'package:context_app/features/explore/data/mappers/place_json_mapper.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaceJsonMapper', () {
    final place = Place(
      id: 'wikidata:Q221716',
      name: '清水寺',
      formattedAddress: '',
      location: const PlaceLocation(latitude: 34.9948, longitude: 135.785),
      rating: null,
      userRatingCount: null,
      types: const ['Q5393308'],
      photos: const [
        PlacePhoto(
          url: 'https://img/x.jpg',
          widthPx: 400,
          heightPx: 300,
          authorAttributions: [],
        ),
      ],
      category: PlaceCategory.historicalCultural,
    );

    test('round-trips through JSON', () {
      final json = PlaceJsonMapper.toJson(place);
      final parsed = PlaceJsonMapper.fromJson(json);
      expect(parsed, place);
    });

    test('handles empty photos', () {
      final noPhotos = Place(
        id: place.id,
        name: place.name,
        formattedAddress: place.formattedAddress,
        location: place.location,
        types: place.types,
        photos: const [],
        category: place.category,
      );
      final json = PlaceJsonMapper.toJson(noPhotos);
      expect(PlaceJsonMapper.fromJson(json).photos, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test, verify failure**

```
cd frontend && fvm flutter test test/features/explore/data/mappers/place_json_mapper_test.dart
```

Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// frontend/lib/features/explore/data/mappers/place_json_mapper.dart
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';

/// Serialises [Place] to/from a plain JSON map for local persistence.
class PlaceJsonMapper {
  static Map<String, dynamic> toJson(Place p) => {
        'id': p.id,
        'name': p.name,
        'formattedAddress': p.formattedAddress,
        'location': {
          'latitude': p.location.latitude,
          'longitude': p.location.longitude,
        },
        'rating': p.rating,
        'userRatingCount': p.userRatingCount,
        'types': p.types,
        'photos': p.photos
            .map((photo) => {
                  'url': photo.url,
                  'widthPx': photo.widthPx,
                  'heightPx': photo.heightPx,
                  'authorAttributions': photo.authorAttributions,
                })
            .toList(),
        'category': p.category.name,
      };

  static Place fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>;
    final photos = (json['photos'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(
          (p) => PlacePhoto(
            url: p['url'] as String,
            widthPx: (p['widthPx'] as num?)?.toInt() ?? 0,
            heightPx: (p['heightPx'] as num?)?.toInt() ?? 0,
            authorAttributions:
                (p['authorAttributions'] as List? ?? []).cast<String>(),
          ),
        )
        .toList();

    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      formattedAddress: json['formattedAddress'] as String? ?? '',
      location: PlaceLocation(
        latitude: (loc['latitude'] as num).toDouble(),
        longitude: (loc['longitude'] as num).toDouble(),
      ),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: (json['userRatingCount'] as num?)?.toInt(),
      types: (json['types'] as List? ?? []).cast<String>(),
      photos: photos,
      category: PlaceCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => PlaceCategory.modernUrban,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test, verify pass**

```
cd frontend && fvm flutter test test/features/explore/data/mappers/place_json_mapper_test.dart
```

Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/data/mappers/place_json_mapper.dart \
  frontend/test/features/explore/data/mappers/place_json_mapper_test.dart
git commit -m "feat(explore): add PlaceJsonMapper for direct Place serialisation"
```

---

## Task 14: Refactor `HivePlacesCacheService`

**Files:**
- Modify: `frontend/lib/features/explore/data/services/hive_places_cache_service.dart`

Drop `_apiKey` field; use `PlaceJsonMapper`. Add `_cacheSchemaVersion` check that wipes the cache on mismatch (old cache stored Google DTOs — incompatible).

- [ ] **Step 1: Replace the file**

Replace entire contents of `hive_places_cache_service.dart`:

```dart
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
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(h), sqrt(1 - h));
  }
}
```

- [ ] **Step 2: Run static analysis**

```
cd frontend && fvm flutter analyze --fatal-infos lib/features/explore/data/services/hive_places_cache_service.dart
```

Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/explore/data/services/hive_places_cache_service.dart
git commit -m "refactor(explore): decouple HivePlacesCacheService from Google DTO"
```

---

# Phase 5: Wire-up & cleanup

## Task 15: Update `providers.dart`

**Files:**
- Modify: `frontend/lib/features/explore/providers.dart`

- [ ] **Step 1: Replace the infrastructure providers**

In `frontend/lib/features/explore/providers.dart`, replace lines for `placesApiServiceProvider`, `placesRepositoryProvider`, `placesCacheServiceProvider` with:

```dart
final wikipediaPlacesServiceProvider = Provider<WikipediaPlacesService>((ref) {
  return WikipediaPlacesService();
});

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  final service = ref.watch(wikipediaPlacesServiceProvider);
  final cacheService = ref.watch(placesCacheServiceProvider);
  final apiRepository = PlacesRepositoryImpl(service);
  return CachingPlacesRepository(apiRepository, cacheService);
});

final placesCacheServiceProvider = Provider<HivePlacesCacheService>((ref) {
  return HivePlacesCacheService();
});
```

Update imports at top of `providers.dart`:
- Remove: `import '.../data/services/places_api_service.dart';`
- Remove: `import '.../common/config/api_config.dart';` (if unused — leave if still referenced)
- Add: `import 'package:context_app/features/explore/data/services/wikipedia_places_service.dart';`

- [ ] **Step 2: Run analyze**

```
cd frontend && fvm flutter analyze --fatal-infos
```

Expected: any remaining errors are in the files deleted in Task 16 — the wiring here should compile.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/explore/providers.dart
git commit -m "refactor(explore): wire Wikipedia service into providers"
```

---

## Task 16: Delete old Google-specific code

**Files deleted:**
- `frontend/lib/features/explore/data/services/places_api_service.dart`
- `frontend/lib/features/explore/data/dto/google_place_dto.dart`
- `frontend/lib/features/explore/data/dto/google_place_photo_dto.dart`
- `frontend/lib/features/explore/data/mappers/place_category_mapper.dart`

- [ ] **Step 1: Check for any remaining imports**

```
cd frontend && grep -rn "google_place_dto\|google_place_photo_dto\|places_api_service\|place_category_mapper" lib test
```

Expected: no matches. If there are matches outside the files being deleted, fix those imports first.

- [ ] **Step 2: Delete files**

```
cd frontend && rm \
  lib/features/explore/data/services/places_api_service.dart \
  lib/features/explore/data/dto/google_place_dto.dart \
  lib/features/explore/data/dto/google_place_photo_dto.dart \
  lib/features/explore/data/mappers/place_category_mapper.dart
```

- [ ] **Step 3: Run analyze**

```
cd frontend && fvm flutter analyze --fatal-infos
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add -u frontend/lib/features/explore/
git commit -m "chore(explore): remove Google Places API code"
```

---

## Task 17: Full test + analyze sweep

- [ ] **Step 1: Run full test suite**

```
cd frontend && fvm flutter test
```

Expected: all tests pass. If any widget test fails due to changed `Place.id` format, fix it — those are regressions the plan missed.

- [ ] **Step 2: Run analysis**

```
cd frontend && fvm flutter analyze --fatal-infos
```

Expected: no errors, warnings, or infos.

- [ ] **Step 3: Commit if any follow-up fixes were needed**

```bash
git commit -am "chore(explore): fix follow-up issues from full test sweep"
```

(Skip if no changes.)

---

## Task 18: Manual verification against real coordinates

Run the app locally and visit the Explore screen at each of these coordinates (use a location-spoofing tool or temporarily override `LocationService` for testing). Confirm reasonable results for each.

- [ ] Taipei 101 (25.0336, 121.5644) — expect landmarks, no MRT stations / 里
- [ ] Kiyomizu-dera (34.9948, 135.7850) — expect temples, no 小学校
- [ ] Tainan old town (23.0000, 120.2000) — expect temples / markets, no 稅務局
- [ ] Paris Eiffel (48.8584, 2.2945) — expect landmarks
- [ ] Cinque Terre (44.1347, 9.6840) — few results expected; verify radius retry kicked in (check logs if needed)
- [ ] Golden Gate (37.8199, −122.4783) — expect bridge + historic sites
- [ ] Stowe, VT (44.4654, −72.6874) — expect historic districts
- [ ] Penghu (23.5655, 119.5836) — expect temples
- [ ] Furano (43.3423, 142.3830) — expect museum; most noise rejected

Pass criterion: for each coordinate, at least one relevant tourist place appears, and no obvious noise (school, police station, post office, tax office) is shown.

- [ ] **Record findings and decide on whitelist adjustments**

If a notable place is consistently missing (e.g., a famous location with a P31 not in the whitelist), add that P31 id in a follow-up commit to `WikidataCategoryMapper._whitelist`.

---

## Self-Review

**Spec coverage:**
- ✅ Wikipedia GeoSearch — Task 4
- ✅ Wikidata P31 filter — Tasks 2, 3, 8
- ✅ P31 → PlaceCategory — Task 3
- ✅ Dynamic radius — Task 9
- ✅ Language fallback — Task 10
- ✅ User-Agent header — Task 4
- ✅ Cache schema version — Task 14
- ✅ Place.id with `wikidata:` prefix — Task 8, verified in Task 12
- ✅ Delete Google code — Task 16
- ✅ Manual verification on 9 coordinates — Task 18
- ✅ Static analysis — Task 17

**Placeholder scan:** No "TBD", "TODO", or "similar to Task N" references. Every code step contains the full code.

**Type consistency:** Signatures verified:
- `WikipediaPlacesService.geoSearch({required double lat, required double lon, required double radiusMeters, required String wikiLang, int limit})`
- `WikipediaPlacesService.fetchEntities(List<String> ids)` → `Map<String, WikidataEntityDto>`
- `WikipediaPlacesService.fetchEntityById(String wikidataId, {required String wikiLang})` → `WikiEntityWithPage?`
- `WikipediaPlacesService.searchByText(String query, {required String wikiLang, int limit})`
- `WikidataCategoryMapper.categorize(List<String>)` → `PlaceCategory?`
- `PlaceJsonMapper.toJson(Place)` / `fromJson(Map<String, dynamic>)`

These match their call sites in Tasks 5–15.
