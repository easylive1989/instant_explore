import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/route/domain/models/route_stop.dart';
import 'package:context_app/features/route/domain/models/tour_route.dart';
import 'package:context_app/features/route/domain/use_cases/create_route_use_case.dart';
import 'package:context_app/features/route/presentation/controllers/route_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateRouteUseCase extends Mock implements CreateRouteUseCase {}

Place _createPlace(String id, {double lat = 25.0, double lng = 121.5}) {
  return Place(
    id: id,
    name: 'Place $id',
    formattedAddress: 'Address $id',
    location: PlaceLocation(latitude: lat, longitude: lng),
    types: const ['tourist_attraction'],
    photos: const [],
    category: PlaceCategory.historicalCultural,
  );
}

void main() {
  late RouteController controller;
  late MockCreateRouteUseCase mockUseCase;

  final place1 = _createPlace('1', lat: 25.037, lng: 121.500);
  final place2 = _createPlace('2', lat: 25.038, lng: 121.502);
  final place3 = _createPlace('3', lat: 25.042, lng: 121.508);

  TourRoute createRouteWith3Stops() {
    return TourRoute(
      title: '測試路線',
      stops: [
        RouteStop(
          place: place1,
          overview: '概覽1',
          distanceToNext: 300,
          walkingTimeToNext: 4,
        ),
        RouteStop(
          place: place2,
          overview: '概覽2',
          distanceToNext: 500,
          walkingTimeToNext: 6,
        ),
        RouteStop(place: place3, overview: '概覽3'),
      ],
    );
  }

  setUp(() {
    mockUseCase = MockCreateRouteUseCase();
    controller = RouteController(mockUseCase);
  });

  group('編輯操作', () {
    test('removeStop 移除停靠站並重新計算距離', () {
      final route = createRouteWith3Stops();
      controller.state = RouteState(route: route);

      controller.removeStop(1); // 移除 place_2

      final newRoute = controller.state.route!;
      expect(newRoute.stops.length, 2);
      expect(newRoute.stops[0].place.id, '1');
      expect(newRoute.stops[1].place.id, '3');
      // 距離已重新計算
      expect(newRoute.stops[0].distanceToNext, isNotNull);
      expect(newRoute.stops[0].distanceToNext, isNot(300));
      expect(newRoute.stops[1].distanceToNext, isNull);
    });

    test('removeStop 不能少於 2 站', () {
      final route = TourRoute(
        title: '測試',
        stops: [
          RouteStop(place: place1, distanceToNext: 300, walkingTimeToNext: 4),
          RouteStop(place: place2),
        ],
      );
      controller.state = RouteState(route: route);

      controller.removeStop(0); // 嘗試移除，但只剩 2 站

      expect(controller.state.route!.stops.length, 2);
    });

    test('addStop 新增停靠站到最後並計算距離', () {
      final route = TourRoute(
        title: '測試',
        stops: [
          RouteStop(place: place1, distanceToNext: 300, walkingTimeToNext: 4),
          RouteStop(place: place2),
        ],
      );
      controller.state = RouteState(route: route);

      controller.addStop(place3);

      final newRoute = controller.state.route!;
      expect(newRoute.stops.length, 3);
      expect(newRoute.stops[2].place.id, '3');
      // 新增後 place_2 應有 distanceToNext
      expect(newRoute.stops[1].distanceToNext, isNotNull);
      // 最後一站無 distanceToNext
      expect(newRoute.stops[2].distanceToNext, isNull);
    });

    test('reorderStops 調整順序並重新計算距離', () {
      final route = createRouteWith3Stops();
      controller.state = RouteState(route: route);

      controller.reorderStops(2, 0); // 把第 3 站移到最前面

      final newRoute = controller.state.route!;
      expect(newRoute.stops[0].place.id, '3');
      expect(newRoute.stops[1].place.id, '1');
      expect(newRoute.stops[2].place.id, '2');
      // 距離已重新計算
      expect(newRoute.stops[0].distanceToNext, isNotNull);
      expect(newRoute.stops[1].distanceToNext, isNotNull);
      expect(newRoute.stops[2].distanceToNext, isNull);
    });
  });

  group('導覽進度', () {
    test('goToNextStop 前進一站', () {
      final route = createRouteWith3Stops();
      controller.state = RouteState(route: route, currentStopIndex: 0);

      controller.goToNextStop();
      expect(controller.state.currentStopIndex, 1);

      controller.goToNextStop();
      expect(controller.state.currentStopIndex, 2);
    });

    test('goToNextStop 不超過最後一站', () {
      final route = createRouteWith3Stops();
      controller.state = RouteState(route: route, currentStopIndex: 2);

      controller.goToNextStop();
      expect(controller.state.currentStopIndex, 2);
    });

    test('goToPreviousStop 回到上一站', () {
      final route = createRouteWith3Stops();
      controller.state = RouteState(route: route, currentStopIndex: 2);

      controller.goToPreviousStop();
      expect(controller.state.currentStopIndex, 1);
    });

    test('goToPreviousStop 不低於 0', () {
      final route = createRouteWith3Stops();
      controller.state = RouteState(route: route, currentStopIndex: 0);

      controller.goToPreviousStop();
      expect(controller.state.currentStopIndex, 0);
    });
  });

  group('reset', () {
    test('重置所有狀態', () {
      final route = createRouteWith3Stops();
      controller.state = RouteState(
        route: route,
        currentStopIndex: 2,
        candidatePlaces: [place1, place2, place3],
      );

      controller.reset();

      expect(controller.state.route, isNull);
      expect(controller.state.currentStopIndex, 0);
      expect(controller.state.candidatePlaces, isEmpty);
      expect(controller.state.isLoading, false);
      expect(controller.state.error, isNull);
    });
  });
}
