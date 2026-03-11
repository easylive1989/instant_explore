import 'package:context_app/core/utils/geo_utils.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateHaversineDistance', () {
    test('台北車站到龍山寺約 2.3 km', () {
      const taipeiStation = PlaceLocation(
        latitude: 25.0478,
        longitude: 121.5170,
      );
      const longshanTemple = PlaceLocation(
        latitude: 25.0373,
        longitude: 121.4998,
      );

      final distance = calculateHaversineDistance(
        taipeiStation,
        longshanTemple,
      );

      // 實際距離約 2.0-2.3 km，允許 10% 誤差
      expect(distance, greaterThan(1800));
      expect(distance, lessThan(2500));
    });

    test('同一點距離為 0', () {
      const point = PlaceLocation(latitude: 25.0, longitude: 121.5);

      final distance = calculateHaversineDistance(point, point);

      expect(distance, 0);
    });

    test('短距離計算（約 100m）', () {
      const pointA = PlaceLocation(latitude: 25.0478, longitude: 121.5170);
      // 大約往東 100m
      const pointB = PlaceLocation(latitude: 25.0478, longitude: 121.5181);

      final distance = calculateHaversineDistance(pointA, pointB);

      expect(distance, greaterThan(80));
      expect(distance, lessThan(130));
    });
  });

  group('estimateWalkingMinutes', () {
    test('1400m 步行約 16.67 分鐘', () {
      // 1400m / 1.4 m/s = 1000s = 16.67 min
      // 使用兩個已知距離約 1400m 的點
      const pointA = PlaceLocation(latitude: 25.0478, longitude: 121.5170);
      const pointB = PlaceLocation(latitude: 25.0478, longitude: 121.5170);

      final minutes = estimateWalkingMinutes(pointA, pointB);

      // 同一點應為 0
      expect(minutes, 0);
    });

    test('步行時間與距離成正比', () {
      const origin = PlaceLocation(latitude: 25.0478, longitude: 121.5170);
      const near = PlaceLocation(latitude: 25.0488, longitude: 121.5170);
      const far = PlaceLocation(latitude: 25.0508, longitude: 121.5170);

      final nearMinutes = estimateWalkingMinutes(origin, near);
      final farMinutes = estimateWalkingMinutes(origin, far);

      expect(farMinutes, greaterThan(nearMinutes));
    });
  });
}
