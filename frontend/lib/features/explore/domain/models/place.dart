import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';

/// Google Places API 地點資料模型
///
/// 用於儲存從 Places API 回傳的地點資訊
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

  factory Place.fromJson(Map<String, dynamic> json) {
    final types = _extractTypes(json['types']);
    return Place(
      id: json['id'] ?? '',
      name: _extractDisplayName(json['displayName']) ?? json['name'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      location: PlaceLocation.fromJson(json['location'] ?? {}),
      rating: json['rating']?.toDouble(),
      types: types,
      photos:
          (json['photos'] as List?)
              ?.map((photo) => PlacePhoto.fromJson(photo))
              .toList() ??
          [],
      category: PlaceCategory.fromPlaceTypes(types),
    );
  }

  /// 提取顯示名稱
  static String? _extractDisplayName(dynamic displayName) {
    if (displayName == null) return null;

    // 如果是字串，直接返回
    if (displayName is String) return displayName;

    // 如果是物件，提取 text 欄位
    if (displayName is Map<String, dynamic>) {
      final text = displayName['text'];
      if (text != null) {
        return text.toString();
      }
    }

    // 最後嘗試轉換為字串
    return displayName.toString();
  }

  /// 提取地點類型
  static List<String> _extractTypes(dynamic types) {
    if (types == null) return [];
    if (types is List) {
      return types.map((type) => type.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'formattedAddress': formattedAddress,
      'location': location.toJson(),
      'rating': rating,
      'types': types,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'category': category.toApiString(),
    };
  }

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

/// 地點位置資料模型
class PlaceLocation {
  final double latitude;
  final double longitude;

  PlaceLocation({required this.latitude, required this.longitude});

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  @override
  String toString() {
    return 'PlaceLocation(latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceLocation &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
