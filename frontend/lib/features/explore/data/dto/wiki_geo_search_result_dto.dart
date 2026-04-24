class WikiGeoSearchResultDto {
  final int pageId;
  final String title;
  final double lat;
  final double lon;
  final String? thumbnailUrl;
  final int? thumbnailWidth;
  final int? thumbnailHeight;
  final String? wikidataId;

  const WikiGeoSearchResultDto({
    required this.pageId,
    required this.title,
    required this.lat,
    required this.lon,
    this.thumbnailUrl,
    this.thumbnailWidth,
    this.thumbnailHeight,
    this.wikidataId,
  });

  /// Parses a single page entry from the merged GeoSearch response.
  ///
  /// Returns null if the page lacks primary coordinates.
  static WikiGeoSearchResultDto? fromPage(Map<String, dynamic> page) {
    final coords = page['coordinates'];
    if (coords is! List || coords.isEmpty) return null;
    final first = coords.first;
    if (first is! Map) return null;

    final lat = (first['lat'] as num?)?.toDouble();
    final lon = (first['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final thumb = page['thumbnail'];
    final pageProps = page['pageprops'];

    return WikiGeoSearchResultDto(
      pageId: (page['pageid'] as num).toInt(),
      title: page['title'] as String,
      lat: lat,
      lon: lon,
      thumbnailUrl: thumb is Map ? thumb['source'] as String? : null,
      thumbnailWidth: thumb is Map ? (thumb['width'] as num?)?.toInt() : null,
      thumbnailHeight: thumb is Map ? (thumb['height'] as num?)?.toInt() : null,
      wikidataId: pageProps is Map
          ? pageProps['wikibase_item'] as String?
          : null,
    );
  }
}
