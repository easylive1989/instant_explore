import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/route/domain/models/route_stop.dart';

/// 儲存在 Plan 中的單一站點資料
class PlanStop {
  final String placeId;
  final String placeName;
  final String placeAddress;
  final double latitude;
  final double longitude;
  final double? placeRating;

  /// PlaceCategory.name — 用於反序列化回 PlaceCategory enum
  final String placeCategory;
  final String? overview;
  final double? distanceToNext;
  final double? walkingTimeToNext;

  const PlanStop({
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    required this.latitude,
    required this.longitude,
    this.placeRating,
    required this.placeCategory,
    this.overview,
    this.distanceToNext,
    this.walkingTimeToNext,
  });

  factory PlanStop.fromRouteStop(RouteStop stop) => PlanStop(
    placeId: stop.place.id,
    placeName: stop.place.name,
    placeAddress: stop.place.formattedAddress,
    latitude: stop.place.location.latitude,
    longitude: stop.place.location.longitude,
    placeRating: stop.place.rating,
    placeCategory: stop.place.category.name,
    overview: stop.overview,
    distanceToNext: stop.distanceToNext,
    walkingTimeToNext: stop.walkingTimeToNext,
  );

  /// 還原為 RouteStop。photos 和 types 為空列表（導覽畫面不使用）。
  RouteStop toRouteStop() => RouteStop(
    place: Place(
      id: placeId,
      name: placeName,
      formattedAddress: placeAddress,
      location: PlaceLocation(latitude: latitude, longitude: longitude),
      rating: placeRating,
      category: PlaceCategory.values.byName(placeCategory),
      types: const [],
      photos: const [],
    ),
    overview: overview,
    distanceToNext: distanceToNext,
    walkingTimeToNext: walkingTimeToNext,
  );

  Map<String, dynamic> toJson() => {
    'placeId': placeId,
    'placeName': placeName,
    'placeAddress': placeAddress,
    'latitude': latitude,
    'longitude': longitude,
    'placeRating': placeRating,
    'placeCategory': placeCategory,
    'overview': overview,
    'distanceToNext': distanceToNext,
    'walkingTimeToNext': walkingTimeToNext,
  };

  factory PlanStop.fromJson(Map<String, dynamic> json) => PlanStop(
    placeId: json['placeId'] as String,
    placeName: json['placeName'] as String,
    placeAddress: json['placeAddress'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    placeRating: (json['placeRating'] as num?)?.toDouble(),
    placeCategory: json['placeCategory'] as String,
    overview: json['overview'] as String?,
    distanceToNext: (json['distanceToNext'] as num?)?.toDouble(),
    walkingTimeToNext: (json['walkingTimeToNext'] as num?)?.toDouble(),
  );
}
