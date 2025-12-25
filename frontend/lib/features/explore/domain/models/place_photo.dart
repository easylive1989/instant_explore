/// 地點照片 Domain Model
///
/// 純粹的業務模型，不包含 API 相關邏輯
class PlacePhoto {
  /// 照片 URL (已產生)
  final String url;

  /// 照片寬度 (像素)
  final int widthPx;

  /// 照片高度 (像素)
  final int heightPx;

  /// 作者歸屬資訊
  final List<String> authorAttributions;

  PlacePhoto({
    required this.url,
    required this.widthPx,
    required this.heightPx,
    required this.authorAttributions,
  });

  @override
  String toString() {
    return 'PlacePhoto(url: $url, widthPx: $widthPx, heightPx: $heightPx)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlacePhoto && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
