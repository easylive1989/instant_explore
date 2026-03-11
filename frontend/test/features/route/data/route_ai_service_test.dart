import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/route/data/route_ai_service.dart';
import 'package:context_app/features/route/domain/errors/route_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GeminiRouteAiService service;
  late List<Place> candidates;

  setUp(() {
    service = GeminiRouteAiService();
    candidates = [
      const Place(
        id: 'place_1',
        name: '龍山寺',
        formattedAddress: '台北市萬華區廣州街211號',
        location: PlaceLocation(latitude: 25.0373, longitude: 121.4998),
        rating: 4.6,
        types: ['tourist_attraction'],
        photos: [],
        category: PlaceCategory.historicalCultural,
      ),
      const Place(
        id: 'place_2',
        name: '剝皮寮',
        formattedAddress: '台北市萬華區康定路173巷',
        location: PlaceLocation(latitude: 25.0375, longitude: 121.5020),
        rating: 4.4,
        types: ['tourist_attraction'],
        photos: [],
        category: PlaceCategory.historicalCultural,
      ),
      const Place(
        id: 'place_3',
        name: '西門紅樓',
        formattedAddress: '台北市萬華區成都路10號',
        location: PlaceLocation(latitude: 25.0420, longitude: 121.5080),
        rating: 4.3,
        types: ['tourist_attraction'],
        photos: [],
        category: PlaceCategory.modernUrban,
      ),
    ];
  });

  group('parseRouteResponse', () {
    test('正確解析有效的 JSON', () {
      const json = '''
{
  "title": "萬華歷史散步",
  "stops": [
    {"placeId": "place_1", "overview": "百年古廟"},
    {"placeId": "place_2", "overview": "歷史街區"}
  ]
}''';

      final route = service.parseRouteResponse(json, candidates);

      expect(route.title, '萬華歷史散步');
      expect(route.stops.length, 2);
      expect(route.stops[0].place.id, 'place_1');
      expect(route.stops[0].overview, '百年古廟');
      expect(route.stops[1].place.id, 'place_2');
      expect(route.stops[1].overview, '歷史街區');
    });

    test('計算站間距離', () {
      const json = '''
{
  "title": "測試",
  "stops": [
    {"placeId": "place_1", "overview": "A"},
    {"placeId": "place_3", "overview": "B"}
  ]
}''';

      final route = service.parseRouteResponse(json, candidates);

      // place_1 到 place_3 距離應大於 0
      expect(route.stops[0].distanceToNext, greaterThan(0));
      expect(route.stops[0].walkingTimeToNext, greaterThan(0));
      // 最後一站無下一站
      expect(route.stops[1].distanceToNext, isNull);
      expect(route.stops[1].walkingTimeToNext, isNull);
    });

    test('移除 markdown code fence', () {
      const json = '''```json
{
  "title": "測試",
  "stops": [
    {"placeId": "place_1", "overview": "A"},
    {"placeId": "place_2", "overview": "B"}
  ]
}
```''';

      final route = service.parseRouteResponse(json, candidates);

      expect(route.title, '測試');
      expect(route.stops.length, 2);
    });

    test('移除無語言標記的 code fence', () {
      const json = '''```
{
  "title": "測試",
  "stops": [
    {"placeId": "place_1", "overview": "A"}
  ]
}
```''';

      final route = service.parseRouteResponse(json, candidates);

      expect(route.stops.length, 1);
    });

    test('無效 JSON 拋出 aiParsingFailed', () {
      expect(
        () => service.parseRouteResponse('not json', candidates),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            RouteError.aiParsingFailed,
          ),
        ),
      );
    });

    test('空 stops 拋出 aiParsingFailed', () {
      const json = '{"title": "test", "stops": []}';

      expect(
        () => service.parseRouteResponse(json, candidates),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            RouteError.aiParsingFailed,
          ),
        ),
      );
    });

    test('不存在的 placeId 拋出 invalidPlaceId', () {
      const json = '''
{
  "title": "test",
  "stops": [{"placeId": "nonexistent", "overview": "A"}]
}''';

      expect(
        () => service.parseRouteResponse(json, candidates),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            RouteError.invalidPlaceId,
          ),
        ),
      );
    });

    test('null placeId 拋出 invalidPlaceId', () {
      const json = '''
{
  "title": "test",
  "stops": [{"overview": "A"}]
}''';

      expect(
        () => service.parseRouteResponse(json, candidates),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            RouteError.invalidPlaceId,
          ),
        ),
      );
    });
  });
}
