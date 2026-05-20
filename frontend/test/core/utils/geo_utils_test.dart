import 'package:context_app/core/utils/geo_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateHaversineDistance', () {
    test('台北車站到龍山寺約 2.3 km', () {
      final distance = calculateHaversineDistance(
        fromLatitude: 25.0478,
        fromLongitude: 121.5170,
        toLatitude: 25.0373,
        toLongitude: 121.4998,
      );

      // 實際距離約 2.0-2.3 km，允許 10% 誤差
      expect(distance, greaterThan(1800));
      expect(distance, lessThan(2500));
    });

    test('同一點距離為 0', () {
      final distance = calculateHaversineDistance(
        fromLatitude: 25.0,
        fromLongitude: 121.5,
        toLatitude: 25.0,
        toLongitude: 121.5,
      );

      expect(distance, 0);
    });

    test('短距離計算（約 100m）', () {
      final distance = calculateHaversineDistance(
        fromLatitude: 25.0478,
        fromLongitude: 121.5170,
        // 大約往東 100m
        toLatitude: 25.0478,
        toLongitude: 121.5181,
      );

      expect(distance, greaterThan(80));
      expect(distance, lessThan(130));
    });
  });

  group('estimateWalkingMinutes', () {
    test('同一點步行時間為 0', () {
      final minutes = estimateWalkingMinutes(
        fromLatitude: 25.0478,
        fromLongitude: 121.5170,
        toLatitude: 25.0478,
        toLongitude: 121.5170,
      );

      expect(minutes, 0);
    });

    test('步行時間與距離成正比', () {
      final nearMinutes = estimateWalkingMinutes(
        fromLatitude: 25.0478,
        fromLongitude: 121.5170,
        toLatitude: 25.0488,
        toLongitude: 121.5170,
      );
      final farMinutes = estimateWalkingMinutes(
        fromLatitude: 25.0478,
        fromLongitude: 121.5170,
        toLatitude: 25.0508,
        toLongitude: 121.5170,
      );

      expect(farMinutes, greaterThan(nearMinutes));
    });
  });
}
