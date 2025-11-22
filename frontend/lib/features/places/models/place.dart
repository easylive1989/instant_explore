import 'package:travel_diary/features/places/models/place_photo.dart';

/// Google Places API 地點資料模型
///
/// 用於儲存從 Places API 回傳的地點資訊
class Place {
  final String id;
  final String name;
  final String formattedAddress;
  final PlaceLocation location;
  final double? rating;
  final int? priceLevel;
  final List<String> types;
  final List<PlacePhoto> photos;
  final String? internationalPhoneNumber;
  final String? websiteUri;
  final bool? currentOpeningHours;

  Place({
    required this.id,
    required this.name,
    required this.formattedAddress,
    required this.location,
    this.rating,
    this.priceLevel,
    required this.types,
    required this.photos,
    this.internationalPhoneNumber,
    this.websiteUri,
    this.currentOpeningHours,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] ?? '',
      name: _extractDisplayName(json['displayName']) ?? json['name'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      location: PlaceLocation.fromJson(json['location'] ?? {}),
      rating: json['rating']?.toDouble(),
      priceLevel: _parsePriceLevel(json['priceLevel']),
      types: _extractTypes(json['types']),
      photos:
          (json['photos'] as List?)
              ?.map((photo) => PlacePhoto.fromJson(photo))
              .toList() ??
          [],
      internationalPhoneNumber: json['internationalPhoneNumber'],
      websiteUri: json['websiteUri'],
      currentOpeningHours: json['currentOpeningHours']?['openNow'],
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

  /// 解析價格等級
  static int? _parsePriceLevel(dynamic priceLevel) {
    if (priceLevel == null) return null;
    if (priceLevel is String) {
      switch (priceLevel) {
        case 'PRICE_LEVEL_FREE':
          return 0;
        case 'PRICE_LEVEL_INEXPENSIVE':
          return 1;
        case 'PRICE_LEVEL_MODERATE':
          return 2;
        case 'PRICE_LEVEL_EXPENSIVE':
          return 3;
        case 'PRICE_LEVEL_VERY_EXPENSIVE':
          return 4;
        default:
          return null;
      }
    }
    return priceLevel is int ? priceLevel : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'formattedAddress': formattedAddress,
      'location': location.toJson(),
      'rating': rating,
      'priceLevel': priceLevel,
      'types': types,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'internationalPhoneNumber': internationalPhoneNumber,
      'websiteUri': websiteUri,
      'currentOpeningHours': currentOpeningHours,
    };
  }

  /// 取得價格等級顯示文字
  String get priceRangeText {
    if (priceLevel == null) return '價格未知';
    switch (priceLevel!) {
      case 0:
        return '免費';
      case 1:
        return '\$';
      case 2:
        return '\$\$';
      case 3:
        return '\$\$\$';
      case 4:
        return '\$\$\$\$';
      default:
        return '價格未知';
    }
  }

  /// 取得評分顯示文字
  String get ratingText {
    if (rating == null) return '無評分';
    return '${rating!.toStringAsFixed(1)} ⭐';
  }

  /// 判斷是否為餐廳
  bool get isRestaurant {
    return types.any(
      (type) =>
          type.contains('restaurant') ||
          type.contains('food') ||
          type.contains('meal_takeaway') ||
          type.contains('meal_delivery'),
    );
  }

  /// 取得第一張照片（如果有的話）
  PlacePhoto? get primaryPhoto {
    return photos.isNotEmpty ? photos.first : null;
  }

  @override
  String toString() {
    return 'Place(id: $id, name: $name, rating: $rating, priceLevel: $priceLevel)';
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
