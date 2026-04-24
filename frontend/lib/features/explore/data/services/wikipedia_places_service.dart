import 'dart:convert';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/data/dto/wiki_geo_search_result_dto.dart';
import 'package:context_app/features/explore/data/dto/wikidata_entity_dto.dart';
import 'package:context_app/features/explore/domain/errors/place_error.dart';
import 'package:http/http.dart' as http;

/// Thin HTTP wrapper around the Wikipedia GeoSearch API.
///
/// Inject an [http.Client] for testing; production code uses the default.
class WikipediaPlacesService {
  static const String _userAgent =
      'InstantExplore/1.0 (https://instant-explore.app;'
      ' support@instant-explore.app)';
  static const int _thumbSize = 400;

  final http.Client _client;

  WikipediaPlacesService({http.Client? client})
    : _client = client ?? http.Client();

  /// Searches Wikipedia for articles near [lat]/[lon] within [radiusMeters].
  ///
  /// [wikiLang] selects the language edition (e.g. `'en'`, `'zh'`).
  /// Returns an empty list when no pages are found.
  /// Throws [AppError] with [PlaceError.searchFailed] on a non-200 response.
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

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );

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

  static const int _batchSize = 50;

  /// Batch-fetches Wikidata entities by id.
  ///
  /// Chunks requests of more than [_batchSize] ids into multiple calls.
  Future<Map<String, WikidataEntityDto>> fetchEntities(List<String> ids) async {
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

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );

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
}
