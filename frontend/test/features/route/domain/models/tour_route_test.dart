import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/route/domain/models/route_stop.dart';
import 'package:context_app/features/route/domain/models/tour_route.dart';
import 'package:flutter_test/flutter_test.dart';

Place _createPlace(String id) {
  return Place(
    id: id,
    name: 'Place $id',
    formattedAddress: 'Address $id',
    location: const PlaceLocation(latitude: 25.0, longitude: 121.5),
    types: const ['tourist_attraction'],
    photos: const [],
    category: PlaceCategory.historicalCultural,
  );
}

void main() {
  group('TourRoute', () {
    test('totalDistance 加總所有站的 distanceToNext', () {
      final route = TourRoute(
        title: '測試路線',
        stops: [
          RouteStop(
            place: _createPlace('1'),
            distanceToNext: 300,
            walkingTimeToNext: 4,
          ),
          RouteStop(
            place: _createPlace('2'),
            distanceToNext: 500,
            walkingTimeToNext: 6,
          ),
          RouteStop(place: _createPlace('3')),
        ],
      );

      expect(route.totalDistance, 800);
    });

    test('estimatedDuration 加總所有站的 walkingTimeToNext', () {
      final route = TourRoute(
        title: '測試路線',
        stops: [
          RouteStop(
            place: _createPlace('1'),
            distanceToNext: 300,
            walkingTimeToNext: 4,
          ),
          RouteStop(
            place: _createPlace('2'),
            distanceToNext: 500,
            walkingTimeToNext: 6,
          ),
          RouteStop(place: _createPlace('3')),
        ],
      );

      expect(route.estimatedDuration, 10);
    });

    test('空路線的 totalDistance 和 estimatedDuration 為 0', () {
      const route = TourRoute(title: '空路線', stops: []);

      expect(route.totalDistance, 0);
      expect(route.estimatedDuration, 0);
    });

    test('最後一站 distanceToNext 為 null 時不影響加總', () {
      final route = TourRoute(
        title: '測試路線',
        stops: [
          RouteStop(
            place: _createPlace('1'),
            distanceToNext: 350,
            walkingTimeToNext: 4.2,
          ),
          RouteStop(place: _createPlace('2')),
        ],
      );

      expect(route.totalDistance, 350);
      expect(route.estimatedDuration, 4.2);
    });

    test('Equatable 相等性', () {
      final stops = [RouteStop(place: _createPlace('1'))];
      final route1 = TourRoute(title: '路線', stops: stops);
      final route2 = TourRoute(title: '路線', stops: stops);
      final route3 = TourRoute(title: '不同路線', stops: stops);

      expect(route1, equals(route2));
      expect(route1, isNot(equals(route3)));
    });

    test('copyWith 建立正確副本', () {
      final original = TourRoute(
        title: '原始',
        stops: [RouteStop(place: _createPlace('1'))],
      );
      final copied = original.copyWith(title: '修改後');

      expect(copied.title, '修改後');
      expect(copied.stops, original.stops);
    });
  });

  group('RouteStop', () {
    test('clearDistances 清除距離資訊', () {
      final stop = RouteStop(
        place: _createPlace('1'),
        overview: '概覽',
        distanceToNext: 300,
        walkingTimeToNext: 4,
      );

      final cleared = stop.clearDistances();

      expect(cleared.place, stop.place);
      expect(cleared.overview, '概覽');
      expect(cleared.distanceToNext, isNull);
      expect(cleared.walkingTimeToNext, isNull);
    });
  });
}
