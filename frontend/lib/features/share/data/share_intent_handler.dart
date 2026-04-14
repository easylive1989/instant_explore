import 'dart:async';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/share/domain/services/google_maps_url_parser.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Resolves shared text from Google Maps into a [Place] domain model.
///
/// Uses [GoogleMapsUrlParser] to extract the place name from the
/// shared text, then searches for it via [PlacesRepository].
class ShareIntentHandler {
  final PlacesRepository _placesRepository;
  final http.Client _httpClient;
  static final _log = Logger('ShareIntentHandler');

  /// Short-link hosts that require a redirect follow to extract
  /// place info.
  static final _shortLinkPattern = RegExp(
    r'https?://(?:maps\.app\.goo\.gl|goo\.gl/maps)/\S+',
    caseSensitive: false,
  );

  ShareIntentHandler(this._placesRepository, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Resolves a shared text string into a [Place].
  ///
  /// Returns `null` if the text cannot be parsed or the place is
  /// not found.
  Future<Place?> resolveSharedText(
    String sharedText, {
    required Language language,
  }) async {
    if (!GoogleMapsUrlParser.isGoogleMapsShare(sharedText)) {
      _log.fine('Text is not a Google Maps share');
      return null;
    }

    // Expand short links (maps.app.goo.gl / goo.gl/maps) so the
    // parser can extract the place name / coordinates from the
    // full URL.
    final expandedText = await _expandShortLinks(sharedText);

    final shareData = GoogleMapsUrlParser.parse(expandedText);

    // Use the place name from the shared text as search query.
    if (shareData.hasSearchQuery) {
      _log.fine('Searching for place: ${shareData.placeName}');
      final results = await _placesRepository.searchPlaces(
        shareData.placeName!,
        language: language,
      );
      if (results.isNotEmpty) {
        return results.first;
      }
    }

    // Fallback: try the URL as a text query (may contain place name).
    if (shareData.url != null) {
      final nameFromUrl = _extractFallbackQuery(shareData.url!);
      if (nameFromUrl != null) {
        _log.fine('Fallback search with URL-derived name: $nameFromUrl');
        final results = await _placesRepository.searchPlaces(
          nameFromUrl,
          language: language,
        );
        if (results.isNotEmpty) {
          return results.first;
        }
      }
    }

    _log.warning('Could not resolve shared text to a place');
    return null;
  }

  /// Replaces any short Google Maps links in [text] with the URL
  /// they redirect to. Returns the original [text] on failure so
  /// the caller can still try a best-effort parse.
  Future<String> _expandShortLinks(String text) async {
    final match = _shortLinkPattern.firstMatch(text);
    if (match == null) return text;

    final shortUrl = match.group(0)!;
    try {
      final expanded = await _followRedirects(shortUrl);
      if (expanded == null || expanded == shortUrl) return text;
      _log.fine('Expanded $shortUrl -> $expanded');
      return text.replaceFirst(shortUrl, expanded);
    } catch (e, stack) {
      _log.warning('Failed to expand short link $shortUrl', e, stack);
      return text;
    }
  }

  /// Issues a manual-redirect GET and walks the `Location` chain
  /// to find the final URL. Caps at 5 hops to avoid loops.
  Future<String?> _followRedirects(String url) async {
    var current = Uri.parse(url);
    for (var hop = 0; hop < 5; hop++) {
      final request = http.Request('GET', current)..followRedirects = false;
      final streamed = await _httpClient
          .send(request)
          .timeout(const Duration(seconds: 5));
      // Drain body so the connection can be reused.
      unawaited(streamed.stream.drain<void>());

      final status = streamed.statusCode;
      if (status >= 300 && status < 400) {
        final location = streamed.headers['location'];
        if (location == null) return current.toString();
        current = current.resolve(location);
        continue;
      }
      return current.toString();
    }
    return current.toString();
  }

  /// Extracts a fallback query from a full Google Maps URL.
  ///
  /// Tries to pull the place name from the `/place/NAME/` segment.
  String? _extractFallbackQuery(String url) {
    final placeNamePattern = RegExp(r'/place/([^/@]+)');
    final match = placeNamePattern.firstMatch(url);
    if (match == null) return null;

    try {
      return Uri.decodeComponent(match.group(1)!).replaceAll('+', ' ');
    } catch (_) {
      return match.group(1)!.replaceAll('+', ' ');
    }
  }
}
