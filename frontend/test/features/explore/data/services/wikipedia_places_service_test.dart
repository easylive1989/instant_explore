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
}
