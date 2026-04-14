import 'dart:async';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/share/domain/services/google_maps_url_parser.dart';
import 'package:logging/logging.dart';

/// Resolves shared text from Google Maps into a [Place] domain model.
///
/// Uses [GoogleMapsUrlParser] to extract the place name from the
/// shared text, then searches for it via [PlacesRepository].
class ShareIntentHandler {
  final PlacesRepository _placesRepository;
  static final _log = Logger('ShareIntentHandler');

  ShareIntentHandler(this._placesRepository);

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

    final shareData = GoogleMapsUrlParser.parse(sharedText);

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
