import 'dart:convert';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/data/mappers/wikidata_category_mapper.dart';
import 'package:context_app/features/explore/domain/errors/place_error.dart';
import 'package:http/http.dart' as http;

/// Resolves a free-text query (e.g. "New Zealand", "東京") to a list of
/// famous landmark Wikidata Q-ids contained within that region.
///
/// Combines two Wikidata APIs:
///   1. `wbsearchentities` to map the query string to a single Wikidata
///      entity (the most relevant match in the user's language).
///   2. The Wikidata Query Service (SPARQL) to find places located inside
///      that entity (via P17 country or P131 contained-administrative
///      entity), filtered by the same P31 landmark whitelist used by
///      [WikidataCategoryMapper] and ranked by Wikipedia sitelink count
///      as a global fame proxy.
///
/// Returns an empty list when the query cannot be resolved or when the
/// resolved entity has no qualifying landmarks.
class WikidataLandmarkQueryService {
  static const String _userAgent =
      'InstantExplore/1.0 (https://instant-explore.app;'
      ' support@instant-explore.app)';

  static const int _defaultLimit = 25;
  static const int _minSitelinks = 10;

  final http.Client _client;

  WikidataLandmarkQueryService({http.Client? client})
    : _client = client ?? http.Client();

  /// Returns landmark Q-ids ranked by global fame, or empty if [query]
  /// does not resolve to a region containing whitelisted landmarks.
  Future<List<String>> findLandmarkIdsForQuery(
    String query, {
    required String wikiLang,
    int limit = _defaultLimit,
  }) async {
    final regionId = await _resolveEntityId(query, wikiLang: wikiLang);
    if (regionId == null) return const [];
    return _findLandmarkIds(regionId, limit: limit);
  }

  Future<String?> _resolveEntityId(
    String query, {
    required String wikiLang,
  }) async {
    final uri = Uri.https('www.wikidata.org', '/w/api.php', {
      'action': 'wbsearchentities',
      'search': query,
      'language': wikiLang,
      'uselang': wikiLang,
      'type': 'item',
      'limit': '1',
      'format': 'json',
    });

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );
    if (response.statusCode != 200) {
      throw AppError(
        type: PlaceError.searchFailed,
        message: 'Wikidata wbsearchentities failed',
        context: {'status_code': response.statusCode},
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['search'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map) return null;
    final id = first['id'];
    return id is String ? id : null;
  }

  Future<List<String>> _findLandmarkIds(
    String regionQid, {
    required int limit,
  }) async {
    final uri = Uri.https('query.wikidata.org', '/sparql', {
      'query': _buildSparql(regionQid: regionQid, limit: limit),
      'format': 'json',
    });

    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/sparql-results+json',
      },
    );
    if (response.statusCode != 200) {
      throw AppError(
        type: PlaceError.searchFailed,
        message: 'Wikidata SPARQL query failed',
        context: {'status_code': response.statusCode},
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final bindings = (data['results'] as Map?)?['bindings'];
    if (bindings is! List) return const [];

    final ids = <String>[];
    for (final binding in bindings) {
      if (binding is! Map) continue;
      final place = binding['place'];
      if (place is! Map) continue;
      final value = place['value'];
      if (value is! String) continue;
      final qid = _extractQid(value);
      if (qid != null && !ids.contains(qid)) ids.add(qid);
    }
    return ids;
  }

  static String _buildSparql({required String regionQid, required int limit}) {
    final values = WikidataCategoryMapper.whitelistedClassIds
        .map((id) => 'wd:$id')
        .join(' ');
    return '''
SELECT ?place ?sitelinks WHERE {
  { ?place wdt:P17 wd:$regionQid . }
  UNION
  { ?place wdt:P131 wd:$regionQid . }
  ?place wdt:P31 ?p31 ;
         wdt:P625 ?coord ;
         wikibase:sitelinks ?sitelinks .
  VALUES ?p31 { $values }
  FILTER(?sitelinks >= $_minSitelinks)
}
ORDER BY DESC(?sitelinks)
LIMIT $limit
''';
  }

  static String? _extractQid(String entityUri) {
    final slash = entityUri.lastIndexOf('/');
    if (slash < 0 || slash == entityUri.length - 1) return null;
    final tail = entityUri.substring(slash + 1);
    return tail.startsWith('Q') ? tail : null;
  }
}
