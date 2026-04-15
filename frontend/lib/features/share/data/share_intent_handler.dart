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

    // Candidate search queries, tried in order until one hits.
    final candidates = <String>{};
    if (shareData.hasSearchQuery) {
      _addQueryCandidates(candidates, shareData.placeName!);
    }
    if (shareData.url != null) {
      final nameFromUrl = _extractFallbackQuery(shareData.url!);
      if (nameFromUrl != null) {
        _addQueryCandidates(candidates, nameFromUrl);
      }
    }

    for (final query in candidates) {
      _log.fine('Searching for place: $query');
      final results = await _placesRepository.searchPlaces(
        query,
        language: language,
      );
      if (results.isNotEmpty) {
        return results.first;
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
  /// Tries `/place/NAME/` first, then falls back to a free-text
  /// `?q=NAME` parameter.
  String? _extractFallbackQuery(String url) {
    final placeMatch = RegExp(r'/place/([^/@]+)').firstMatch(url);
    if (placeMatch != null) {
      return _decodeQueryComponent(placeMatch.group(1)!);
    }

    final qMatch = RegExp(r'[?&]q=([^&]+)').firstMatch(url);
    if (qMatch != null) {
      final decoded = _decodeQueryComponent(qMatch.group(1)!);
      // Skip pure coordinate pairs.
      if (!RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(decoded)) {
        return decoded;
      }
    }

    return null;
  }

  /// Adds [raw] and useful variants to [candidates] in the order
  /// they should be tried.
  ///
  /// Google Maps' `?q=` often arrives as `ZIP + full address + name`
  /// (e.g. `406臺中市北屯區太順路77號尋嚐人家`), which Places Text
  /// Search fails to match. We fall back to stripping a leading
  /// digit block (Taiwan ZIP), and to the trailing non-numeric
  /// segment (typically the store name) when present.
  void _addQueryCandidates(Set<String> candidates, String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    candidates.add(trimmed);

    // Strip a leading 3- or 5-digit ZIP-like prefix.
    final zipStripped = trimmed.replaceFirst(RegExp(r'^\d{3,6}(?=\D)'), '');
    if (zipStripped.isNotEmpty && zipStripped != trimmed) {
      candidates.add(zipStripped);
    }

    // Trailing non-digit block: works when the store name sits
    // after the last number (e.g. `...77號尋嚐人家` → `尋嚐人家`).
    final tailMatch = RegExp(r'[^\d\s號巷弄樓號之-]+$').firstMatch(trimmed);
    if (tailMatch != null) {
      final tail = tailMatch.group(0)!.trim();
      if (tail.isNotEmpty && tail.length >= 2 && tail != trimmed) {
        candidates.add(tail);
      }
    }
  }

  String _decodeQueryComponent(String raw) {
    try {
      return Uri.decodeComponent(raw).replaceAll('+', ' ');
    } catch (_) {
      return raw.replaceAll('+', ' ');
    }
  }
}
