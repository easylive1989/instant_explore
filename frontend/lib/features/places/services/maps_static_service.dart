/// Google Maps Static API 服務
///
/// 用於產生靜態地圖圖片 URL
class MapsStaticService {
  /// 產生靜態地圖 URL
  ///
  /// [apiKey] Google Maps API 金鑰
  /// [latitude] 緯度
  /// [longitude] 經度
  /// [zoom] 縮放等級 (預設 15)
  /// [width] 圖片寬度 (預設 400)
  /// [height] 圖片高度 (預設 400)
  /// [markerColor] 標記顏色 (預設紅色)
  static String generateStaticMapUrl({
    required String apiKey,
    required double latitude,
    required double longitude,
    int zoom = 15,
    int width = 400,
    int height = 400,
    String markerColor = 'red',
  }) {
    final center = '$latitude,$longitude';
    final marker = 'color:$markerColor|$center';

    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$center'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&markers=$marker'
        '&key=$apiKey';
  }

  /// 產生縮圖 URL (90x90)
  ///
  /// [apiKey] Google Maps API 金鑰
  /// [latitude] 緯度
  /// [longitude] 經度
  static String generateThumbnailUrl({
    required String apiKey,
    required double latitude,
    required double longitude,
  }) {
    return generateStaticMapUrl(
      apiKey: apiKey,
      latitude: latitude,
      longitude: longitude,
      zoom: 15,
      width: 180, // 2x for retina display
      height: 180,
      markerColor: 'red',
    );
  }
}
