import 'package:logging/logging.dart';

/// Parsed result from a Google Maps shared text.
class GoogleMapsShareData {
  /// The place name extracted from the shared text (if available).
  final String? placeName;

  /// The Google Maps URL found in the shared text.
  final String? url;

  /// Latitude extracted from the URL (if available).
  final double? latitude;

  /// Longitude extracted from the URL (if available).
  final double? longitude;

  const GoogleMapsShareData({
    this.placeName,
    this.url,
    this.latitude,
    this.longitude,
  });

  /// Whether a usable search query can be derived.
  bool get hasSearchQuery => placeName != null && placeName!.isNotEmpty;
}

/// Parses shared text from Google Maps to extract place information.
///
/// Google Maps shares text in formats like:
/// ```
/// 台北101
/// https://maps.app.goo.gl/xxxxx
/// ```
/// or a full URL:
/// ```
/// https://www.google.com/maps/place/台北101/@25.03,121.56,...
/// ```
class GoogleMapsUrlParser {
  static final _log = Logger('GoogleMapsUrlParser');

  /// Known Google Maps URL patterns.
  static final _mapsUrlPattern = RegExp(
    r'https?://(?:maps\.app\.goo\.gl|'
    r'(?:www\.)?google\.com/maps|'
    r'maps\.google\.com|'
    r'goo\.gl/maps)'
    r'[/\S]*',
    caseSensitive: false,
  );

  /// Pattern for coordinates in Google Maps URLs: @lat,lng
  static final _coordPattern = RegExp(
    r'@(-?\d+\.?\d*),(-?\d+\.?\d*)',
  );

  /// Pattern for query parameters: ?q=lat,lng or &q=lat,lng
  static final _queryCoordPattern = RegExp(
    r'[?&]q=(-?\d+\.?\d*),(-?\d+\.?\d*)',
  );

  /// Pattern for place name in URL path: /place/PlaceName/
  static final _placeNamePattern = RegExp(
    r'/place/([^/@]+)',
  );

  GoogleMapsUrlParser._();

  /// Returns `true` if the [text] looks like a Google Maps share.
  static bool isGoogleMapsShare(String text) {
    return _mapsUrlPattern.hasMatch(text);
  }

  /// Parses shared text from Google Maps.
  ///
  /// Extracts the place name (text before the URL) and any
  /// coordinates embedded in the URL.
  static GoogleMapsShareData parse(String text) {
    final trimmed = text.trim();

    final urlMatch = _mapsUrlPattern.firstMatch(trimmed);
    if (urlMatch == null) {
      _log.fine('No Google Maps URL found in shared text');
      return GoogleMapsShareData(placeName: _cleanPlaceName(trimmed));
    }

    final url = urlMatch.group(0)!;

    // Text before the URL is typically the place name.
    final beforeUrl = trimmed.substring(0, urlMatch.start).trim();
    String? placeName = _cleanPlaceName(beforeUrl);

    // Try to extract place name from URL path if not in text.
    if (placeName == null || placeName.isEmpty) {
      placeName = _extractPlaceNameFromUrl(url);
    }

    // Try to extract coordinates.
    double? lat;
    double? lng;

    final coordMatch = _coordPattern.firstMatch(url);
    if (coordMatch != null) {
      lat = double.tryParse(coordMatch.group(1)!);
      lng = double.tryParse(coordMatch.group(2)!);
    }

    if (lat == null || lng == null) {
      final queryMatch = _queryCoordPattern.firstMatch(url);
      if (queryMatch != null) {
        lat = double.tryParse(queryMatch.group(1)!);
        lng = double.tryParse(queryMatch.group(2)!);
      }
    }

    _log.fine(
      'Parsed share: name=$placeName, '
      'lat=$lat, lng=$lng, url=$url',
    );

    return GoogleMapsShareData(
      placeName: placeName,
      url: url,
      latitude: lat,
      longitude: lng,
    );
  }

  /// Extracts a place name from the URL path segment `/place/Name/`.
  static String? _extractPlaceNameFromUrl(String url) {
    final match = _placeNamePattern.firstMatch(url);
    if (match == null) return null;

    final encoded = match.group(1)!;
    try {
      return Uri.decodeComponent(encoded).replaceAll('+', ' ');
    } catch (_) {
      return encoded.replaceAll('+', ' ');
    }
  }

  /// Cleans up a potential place name string.
  ///
  /// Removes leading/trailing whitespace and newlines.
  /// Returns `null` if the result is empty.
  static String? _cleanPlaceName(String raw) {
    final cleaned = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' ')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}
