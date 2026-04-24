import 'dart:convert';

import 'package:context_app/features/explore/data/services/wikipedia_places_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('WikipediaPlacesService.geoSearch', () {
    test('calls correct URL with lang/coord/radius and parses response',
        () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      final mockClient = MockClient((req) async {
        capturedUri = req.url;
        capturedHeaders = req.headers;
        return http.Response.bytes(
          utf8.encode(jsonEncode({
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
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
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

  group('WikipediaPlacesService.fetchEntities', () {
    test('joins ids with | and parses claims', () async {
      late Uri capturedUri;
      final mockClient = MockClient((req) async {
        capturedUri = req.url;
        return http.Response.bytes(
          utf8.encode(jsonEncode({
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
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
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
        return http.Response.bytes(
          utf8.encode(jsonEncode({'entities': {}})),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service = WikipediaPlacesService(client: mockClient);

      final ids = List.generate(75, (i) => 'Q$i');
      await service.fetchEntities(ids);

      expect(calls, hasLength(2));
      expect(calls[0].split('|'), hasLength(50));
      expect(calls[1].split('|'), hasLength(25));
    });
  });

  group('WikipediaPlacesService.searchByText', () {
    test('issues generator=search and returns DTOs', () async {
      late Uri capturedUri;
      final mockClient = MockClient((req) async {
        capturedUri = req.url;
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'query': {
              'pages': {
                '1': {
                  'pageid': 1,
                  'title': '清水寺',
                  'coordinates': [
                    {'lat': 34.9948, 'lon': 135.7850}
                  ],
                  'pageprops': {'wikibase_item': 'Q221716'},
                },
              },
            },
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
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

  group('WikipediaPlacesService.fetchEntityById', () {
    test('fetches entity + page info and returns merged DTO', () async {
      final mockClient = MockClient((req) async {
        if (req.url.host == 'www.wikidata.org') {
          return http.Response.bytes(
            utf8.encode(jsonEncode({
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
            })),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        // ja.wikipedia.org page lookup
        expect(req.url.host, 'ja.wikipedia.org');
        expect(req.url.queryParameters['titles'], '清水寺');
        return http.Response.bytes(
          utf8.encode(jsonEncode({
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
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
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
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'entities': {
              'Q999': {
                'id': 'Q999',
                'claims': {},
                'sitelinks': {},
              },
            },
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service = WikipediaPlacesService(client: mockClient);

      expect(
        await service.fetchEntityById('Q999', wikiLang: 'en'),
        isNull,
      );
    });
  });
}
