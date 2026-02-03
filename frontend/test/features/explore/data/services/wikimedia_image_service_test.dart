import 'package:context_app/features/explore/data/services/wikimedia_image_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('WikimediaImageService', () {
    test('searchImage returns image URL when search succeeds', () async {
      final mockClient = MockClient((request) async {
        final uri = request.url;

        if (uri.queryParameters['list'] == 'search') {
          return http.Response(
            jsonEncode({
              'query': {
                'search': [
                  {'title': 'File:Test_Image.jpg'}
                ]
              }
            }),
            200,
          );
        }

        if (uri.queryParameters['prop'] == 'imageinfo') {
          return http.Response(
            jsonEncode({
              'query': {
                'pages': {
                  '123': {
                    'imageinfo': [
                      {
                        'thumburl': 'https://example.com/thumb.jpg',
                        'url': 'https://example.com/full.jpg',
                      }
                    ]
                  }
                }
              }
            }),
            200,
          );
        }

        return http.Response('Not found', 404);
      });

      final service = WikimediaImageService(client: mockClient);
      final result = await service.searchImage('Taipei 101');

      expect(result, equals('https://example.com/thumb.jpg'));
    });

    test('searchImage returns null when no search results', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'query': {'search': []}
          }),
          200,
        );
      });

      final service = WikimediaImageService(client: mockClient);
      final result = await service.searchImage('NonExistentPlace');

      expect(result, isNull);
    });

    test('searchImage returns null on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = WikimediaImageService(client: mockClient);
      final result = await service.searchImage('Test Place');

      expect(result, isNull);
    });

    test('searchImage returns full URL when thumburl is not available',
        () async {
      final mockClient = MockClient((request) async {
        final uri = request.url;

        if (uri.queryParameters['list'] == 'search') {
          return http.Response(
            jsonEncode({
              'query': {
                'search': [
                  {'title': 'File:Test_Image.jpg'}
                ]
              }
            }),
            200,
          );
        }

        if (uri.queryParameters['prop'] == 'imageinfo') {
          return http.Response(
            jsonEncode({
              'query': {
                'pages': {
                  '123': {
                    'imageinfo': [
                      {
                        'url': 'https://example.com/full.jpg',
                      }
                    ]
                  }
                }
              }
            }),
            200,
          );
        }

        return http.Response('Not found', 404);
      });

      final service = WikimediaImageService(client: mockClient);
      final result = await service.searchImage('Test Place');

      expect(result, equals('https://example.com/full.jpg'));
    });

    test('searchImage handles exceptions gracefully', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final service = WikimediaImageService(client: mockClient);
      final result = await service.searchImage('Test Place');

      expect(result, isNull);
    });

    test('searchImage returns null when imageinfo is empty', () async {
      final mockClient = MockClient((request) async {
        final uri = request.url;

        if (uri.queryParameters['list'] == 'search') {
          return http.Response(
            jsonEncode({
              'query': {
                'search': [
                  {'title': 'File:Test_Image.jpg'}
                ]
              }
            }),
            200,
          );
        }

        if (uri.queryParameters['prop'] == 'imageinfo') {
          return http.Response(
            jsonEncode({
              'query': {
                'pages': {
                  '123': {'imageinfo': []}
                }
              }
            }),
            200,
          );
        }

        return http.Response('Not found', 404);
      });

      final service = WikimediaImageService(client: mockClient);
      final result = await service.searchImage('Test Place');

      expect(result, isNull);
    });
  });
}
