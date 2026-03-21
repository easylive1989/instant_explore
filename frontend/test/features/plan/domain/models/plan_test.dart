import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/plan/domain/models/plan.dart';
import 'package:context_app/features/plan/domain/models/plan_stop.dart';
import 'package:context_app/features/route/domain/models/route_stop.dart';
import 'package:context_app/features/route/domain/models/tour_route.dart';
import 'package:flutter_test/flutter_test.dart';

Place _place(String id) => Place(
  id: id,
  name: 'Place $id',
  formattedAddress: 'Addr $id',
  location: PlaceLocation(latitude: 25.0, longitude: 121.5),
  rating: 4.5,
  category: PlaceCategory.historicalCultural,
  types: const ['tourist_attraction'],
  photos: const [],
);

TourRoute _route() => TourRoute(
  title: 'Test Route',
  stops: [
    RouteStop(
      place: _place('A'),
      overview: 'Overview A',
      distanceToNext: 300,
      walkingTimeToNext: 4,
    ),
    RouteStop(place: _place('B'), overview: 'Overview B'),
  ],
);

void main() {
  group('PlanStop', () {
    test('fromRouteStop captures all fields', () {
      final stop = RouteStop(
        place: _place('X'),
        overview: 'desc',
        distanceToNext: 500,
        walkingTimeToNext: 6,
      );
      final planStop = PlanStop.fromRouteStop(stop);

      expect(planStop.placeId, 'X');
      expect(planStop.placeName, 'Place X');
      expect(planStop.placeAddress, 'Addr X');
      expect(planStop.latitude, 25.0);
      expect(planStop.longitude, 121.5);
      expect(planStop.placeRating, 4.5);
      expect(planStop.placeCategory, 'historicalCultural');
      expect(planStop.overview, 'desc');
      expect(planStop.distanceToNext, 500);
      expect(planStop.walkingTimeToNext, 6);
    });

    test('toRouteStop restores place and distances', () {
      final original = RouteStop(
        place: _place('Y'),
        overview: 'ov',
        distanceToNext: 200,
        walkingTimeToNext: 3,
      );
      final restored = PlanStop.fromRouteStop(original).toRouteStop();

      expect(restored.place.id, 'Y');
      expect(restored.place.name, 'Place Y');
      expect(restored.place.category, PlaceCategory.historicalCultural);
      expect(restored.overview, 'ov');
      expect(restored.distanceToNext, 200);
      expect(restored.walkingTimeToNext, 3);
      expect(restored.place.types, isEmpty);
      expect(restored.place.photos, isEmpty);
    });

    test('fromJson(toJson()) round-trips correctly', () {
      final stop = PlanStop.fromRouteStop(RouteStop(
        place: _place('Z'),
        overview: 'ov2',
        distanceToNext: 100,
        walkingTimeToNext: 2,
      ));
      final restored = PlanStop.fromJson(stop.toJson());

      expect(restored.placeId, stop.placeId);
      expect(restored.placeRating, stop.placeRating);
      expect(restored.distanceToNext, stop.distanceToNext);
      expect(restored.placeCategory, stop.placeCategory);
    });

    test('fromJson handles null optional fields', () {
      final stop = PlanStop.fromRouteStop(RouteStop(place: _place('W')));
      final restored = PlanStop.fromJson(stop.toJson());

      expect(restored.overview, isNull);
      expect(restored.distanceToNext, isNull);
      expect(restored.walkingTimeToNext, isNull);
      expect(restored.placeRating, 4.5);
    });

    test('null placeRating round-trips through JSON', () {
      final placeWithoutRating = Place(
        id: 'NR',
        name: 'Place NR',
        formattedAddress: 'Addr NR',
        location: PlaceLocation(latitude: 25.0, longitude: 121.5),
        rating: null,
        category: PlaceCategory.historicalCultural,
        types: const [],
        photos: const [],
      );
      final stop = PlanStop.fromRouteStop(
        RouteStop(place: placeWithoutRating),
      );
      final restored = PlanStop.fromJson(stop.toJson());

      expect(stop.placeRating, isNull);
      expect(restored.placeRating, isNull);
    });
  });

  group('Plan', () {
    test('fromTourRoute captures title, stops, distance, duration', () {
      final route = _route();
      final plan = Plan.fromTourRoute(route);

      expect(plan.title, 'Test Route');
      expect(plan.stops.length, 2);
      expect(plan.stops[0].placeId, 'A');
      expect(plan.id, isNotEmpty);
      expect(plan.createdAt, isNotNull);
      expect(plan.totalDistance, 300.0);
      expect(plan.estimatedDuration, 4.0);
    });

    test('toTourRoute restores route with correct stops', () {
      final plan = Plan.fromTourRoute(_route());
      final restored = plan.toTourRoute();

      expect(restored.title, 'Test Route');
      expect(restored.stops.length, 2);
      expect(restored.stops[0].place.id, 'A');
      expect(restored.stops[1].place.id, 'B');
    });

    test('fromJson(toJson()) round-trips id, title, createdAt, stops', () {
      final plan = Plan.fromTourRoute(_route());
      final restored = Plan.fromJson(plan.toJson());

      expect(restored.id, plan.id);
      expect(restored.title, plan.title);
      expect(restored.createdAt, plan.createdAt);
      expect(restored.stops.length, 2);
      expect(restored.totalDistance, plan.totalDistance);
      expect(restored.estimatedDuration, plan.estimatedDuration);
    });

    test('each Plan.fromTourRoute generates a unique id', () {
      final route = _route();
      final id1 = Plan.fromTourRoute(route).id;
      final id2 = Plan.fromTourRoute(route).id;

      expect(id1, isNot(id2));
    });
  });
}
