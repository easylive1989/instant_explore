import 'package:equatable/equatable.dart';

/// 地點照片 Domain Model
///
/// 純粹的業務模型，不包含 API 相關邏輯
class PlacePhoto extends Equatable {
  /// 照片 URL (已產生)
  final String url;

  /// 照片寬度 (像素)
  final int widthPx;

  /// 照片高度 (像素)
  final int heightPx;

  /// 作者歸屬資訊
  final List<String> authorAttributions;

  const PlacePhoto({
    required this.url,
    required this.widthPx,
    required this.heightPx,
    required this.authorAttributions,
  });

  @override
  List<Object?> get props => [url, widthPx, heightPx, authorAttributions];

  @override
  String toString() {
    return 'PlacePhoto(url: $url, widthPx: $widthPx, heightPx: $heightPx)';
  }
}
