import 'package:context_app/features/share/domain/services/google_maps_url_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleMapsUrlParser', () {
    group('isGoogleMapsShare', () {
      test('detects short Google Maps link', () {
        const text = '台北101\nhttps://maps.app.goo.gl/abc123';
        expect(GoogleMapsUrlParser.isGoogleMapsShare(text), isTrue);
      });

      test('detects full Google Maps URL', () {
        const text =
            'https://www.google.com/maps/place/Taipei+101/@25.03,121.56';
        expect(GoogleMapsUrlParser.isGoogleMapsShare(text), isTrue);
      });

      test('detects maps.google.com URL', () {
        const text = 'https://maps.google.com/?q=25.03,121.56';
        expect(GoogleMapsUrlParser.isGoogleMapsShare(text), isTrue);
      });

      test('detects goo.gl/maps short link', () {
        const text = 'https://goo.gl/maps/xyz789';
        expect(GoogleMapsUrlParser.isGoogleMapsShare(text), isTrue);
      });

      test('returns false for non-maps text', () {
        const text = 'Hello, this is just normal text.';
        expect(GoogleMapsUrlParser.isGoogleMapsShare(text), isFalse);
      });

      test('returns false for other URLs', () {
        const text = 'https://example.com/some-page';
        expect(GoogleMapsUrlParser.isGoogleMapsShare(text), isFalse);
      });
    });

    group('parse', () {
      test('extracts place name and short URL', () {
        const text = '台北101\nhttps://maps.app.goo.gl/abc123';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.placeName, '台北101');
        expect(result.url, 'https://maps.app.goo.gl/abc123');
        expect(result.hasSearchQuery, isTrue);
      });

      test('extracts place name with multiple lines before URL', () {
        const text = '台北 101\n觀景台\nhttps://maps.app.goo.gl/abc';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.placeName, '台北 101 觀景台');
        expect(result.url, 'https://maps.app.goo.gl/abc');
      });

      test('extracts coordinates from @ pattern', () {
        const text =
            'https://www.google.com/maps/place/Taipei+101/@25.033964,121.564468,17z';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.latitude, closeTo(25.033964, 0.0001));
        expect(result.longitude, closeTo(121.564468, 0.0001));
      });

      test('extracts coordinates from query parameter', () {
        const text = 'https://maps.google.com/?q=25.033964,121.564468';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.latitude, closeTo(25.033964, 0.0001));
        expect(result.longitude, closeTo(121.564468, 0.0001));
      });

      test('extracts place name from URL path', () {
        const text =
            'https://www.google.com/maps/place/Taipei+101/@25.03,121.56';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.placeName, 'Taipei 101');
      });

      test('extracts URL-encoded place name from path', () {
        const text =
            'https://www.google.com/maps/place/%E5%8F%B0%E5%8C%97101/@25.03,121.56';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.placeName, '台北101');
      });

      test('prefers text before URL over URL path for place name', () {
        const text =
            '台北 101 觀景台\nhttps://www.google.com/maps/place/Taipei+101/@25.03,121.56';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.placeName, '台北 101 觀景台');
      });

      test('returns null coordinates for short link', () {
        const text = '台北101\nhttps://maps.app.goo.gl/abc123';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.latitude, isNull);
        expect(result.longitude, isNull);
      });

      test('handles empty text gracefully', () {
        const text = '';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.placeName, isNull);
        expect(result.url, isNull);
        expect(result.hasSearchQuery, isFalse);
      });

      test('handles text with no URL', () {
        const text = '台北101';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.placeName, '台北101');
        expect(result.url, isNull);
      });

      test('handles negative coordinates', () {
        const text =
            'https://www.google.com/maps/place/Test/@-33.8688,151.2093,15z';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.latitude, closeTo(-33.8688, 0.0001));
        expect(result.longitude, closeTo(151.2093, 0.0001));
      });

      test('handles URL with trailing whitespace', () {
        const text = '故宮博物院\nhttps://maps.app.goo.gl/xyz  \n';
        final result = GoogleMapsUrlParser.parse(text);

        expect(result.placeName, '故宮博物院');
        expect(result.url, 'https://maps.app.goo.gl/xyz');
      });
    });
  });
}
