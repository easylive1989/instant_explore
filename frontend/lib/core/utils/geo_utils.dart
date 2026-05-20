import 'dart:math';

/// 計算兩點之間的直線距離（Haversine 公式）
///
/// 接受純經緯度（度），回傳距離（公尺）。core 層保持框架與
/// feature 無關，呼叫端負責從自家的位置模型取出座標。
double calculateHaversineDistance({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  const earthRadiusMeters = 6371000.0;

  final lat1Rad = fromLatitude * pi / 180;
  final lat2Rad = toLatitude * pi / 180;
  final deltaLat = (toLatitude - fromLatitude) * pi / 180;
  final deltaLon = (toLongitude - fromLongitude) * pi / 180;

  final a =
      sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusMeters * c;
}

/// 估算兩點之間的步行時間
///
/// 假設步行速度 1.4 m/s（約 5 km/h），回傳分鐘數。
double estimateWalkingMinutes({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  const walkingSpeedMPerSecond = 1.4;
  final distanceMeters = calculateHaversineDistance(
    fromLatitude: fromLatitude,
    fromLongitude: fromLongitude,
    toLatitude: toLatitude,
    toLongitude: toLongitude,
  );
  return distanceMeters / walkingSpeedMPerSecond / 60;
}
