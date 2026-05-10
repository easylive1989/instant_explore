import 'package:equatable/equatable.dart';

/// 地點照片 Domain Model
///
/// 純粹的業務模型，不包含 API 相關邏輯
class PlacePhoto extends Equatable {
  /// 照片 URL (已產生)
  final String url;

  /// 照片寬度 (像素)
  final int width;

  /// 照片高度 (像素)
  final int height;

  /// 作者歸屬資訊
  final List<String> attributions;

  const PlacePhoto({
    required this.url,
    required this.width,
    required this.height,
    required this.attributions,
  });

  @override
  List<Object?> get props => [url, width, height, attributions];
}
