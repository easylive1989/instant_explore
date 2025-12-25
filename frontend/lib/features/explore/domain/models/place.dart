import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';

/// 地點 Domain Model
///
/// 純粹的業務模型，不包含 API 相關邏輯
class Place {
  final String id;
  final String name;
  final String formattedAddress;
  final PlaceLocation location;
  final double? rating;
  final List<String> types;
  final List<PlacePhoto> photos;
  final PlaceCategory category;

  Place({
    required this.id,
    required this.name,
    required this.formattedAddress,
    required this.location,
    this.rating,
    required this.types,
    required this.photos,
    required this.category,
  });

  /// 取得第一張照片（如果有的話）
  PlacePhoto? get primaryPhoto {
    return photos.isNotEmpty ? photos.first : null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Place && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
