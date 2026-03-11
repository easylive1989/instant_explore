import 'dart:math';

import 'package:context_app/features/explore/domain/models/place_location.dart';

/// 計算兩點之間的直線距離（Haversine 公式）
///
/// 回傳距離（公尺）
double calculateHaversineDistance(PlaceLocation from, PlaceLocation to) {
  const earthRadiusMeters = 6371000.0;

  final lat1Rad = from.latitude * pi / 180;
  final lat2Rad = to.latitude * pi / 180;
  final deltaLat = (to.latitude - from.latitude) * pi / 180;
  final deltaLon = (to.longitude - from.longitude) * pi / 180;

  final a =
      sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusMeters * c;
}

/// 估算兩點之間的步行時間
///
/// 假設步行速度 1.4 m/s（約 5 km/h），回傳分鐘數
double estimateWalkingMinutes(PlaceLocation from, PlaceLocation to) {
  const walkingSpeedMPerSecond = 1.4;
  final distanceMeters = calculateHaversineDistance(from, to);
  return distanceMeters / walkingSpeedMPerSecond / 60;
}
