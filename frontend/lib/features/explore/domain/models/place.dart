import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:equatable/equatable.dart';

/// 地點 Domain Model
///
/// 純粹的業務模型，不包含 API 相關邏輯
class Place extends Equatable {
  final String id;
  final String name;
  final String formattedAddress;
  final PlaceLocation location;
  final double? rating;
  final int? userRatingCount;
  final List<String> types;
  final List<PlacePhoto> photos;
  final PlaceCategory category;

  const Place({
    required this.id,
    required this.name,
    required this.formattedAddress,
    required this.location,
    this.rating,
    this.userRatingCount,
    required this.types,
    required this.photos,
    required this.category,
  });

  /// 取得第一張照片（如果有的話）
  PlacePhoto? get primaryPhoto {
    return photos.isNotEmpty ? photos.first : null;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    formattedAddress,
    location,
    rating,
    userRatingCount,
    types,
    photos,
    category,
  ];
}
