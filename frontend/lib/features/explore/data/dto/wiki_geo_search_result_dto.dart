class WikiGeoSearchResultDto {
  final int pageId;
  final String title;
  final double? lat;
  final double? lon;
  final String? thumbnailUrl;
  final int? thumbnailWidth;
  final int? thumbnailHeight;
  final String? wikidataId;

  const WikiGeoSearchResultDto({
    required this.pageId,
    required this.title,
    this.lat,
    this.lon,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
    this.wikidataId,
  });

  /// Parses a single page entry from a Wikipedia API response.
  ///
  /// Returns null when neither coordinates nor a Wikidata ID is present,
  /// since the place cannot be located or enriched. When coordinates are
  /// missing but a Wikidata ID exists, [lat] and [lon] are null and the
  /// caller is expected to resolve coordinates from Wikidata P625.
  static WikiGeoSearchResultDto? fromPage(Map<String, dynamic> page) {
    final coords = page['coordinates'];
    double? lat, lon;
    if (coords is List && coords.isNotEmpty && coords.first is Map) {
      final first = coords.first as Map;
      final parsedLat = (first['lat'] as num?)?.toDouble();
      final parsedLon = (first['lon'] as num?)?.toDouble();
      if (parsedLat != null && parsedLon != null) {
        lat = parsedLat;
        lon = parsedLon;
      }
    }

    final thumb = page['thumbnail'];
    final pageProps = page['pageprops'];
    final wikidataId = pageProps is Map
        ? pageProps['wikibase_item'] as String?
        : null;

    if (lat == null && wikidataId == null) return null;

    return WikiGeoSearchResultDto(
      pageId: (page['pageid'] as num).toInt(),
      title: page['title'] as String,
      lat: lat,
      lon: lon,
      thumbnailUrl: thumb is Map ? thumb['source'] as String? : null,
      thumbnailWidth: thumb is Map ? (thumb['width'] as num?)?.toInt() : null,
      thumbnailHeight: thumb is Map ? (thumb['height'] as num?)?.toInt() : null,
      wikidataId: wikidataId,
    );
  }
}
