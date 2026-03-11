import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/route/data/route_prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Place> candidates;
  const userLocation = PlaceLocation(latitude: 25.0478, longitude: 121.5170);

  setUp(() {
    candidates = [
      const Place(
        id: 'place_1',
        name: '龍山寺',
        formattedAddress: '台北市萬華區廣州街211號',
        location: PlaceLocation(latitude: 25.0373, longitude: 121.4998),
        rating: 4.6,
        types: ['tourist_attraction', 'place_of_worship'],
        photos: [],
        category: PlaceCategory.historicalCultural,
      ),
      const Place(
        id: 'place_2',
        name: '剝皮寮歷史街區',
        formattedAddress: '台北市萬華區康定路173巷',
        location: PlaceLocation(latitude: 25.0375, longitude: 121.5020),
        rating: 4.4,
        types: ['tourist_attraction', 'museum'],
        photos: [],
        category: PlaceCategory.historicalCultural,
      ),
    ];
  });

  group('RoutePromptBuilder', () {
    test('prompt 包含所有候選景點的 ID', () {
      final builder = RoutePromptBuilder(
        candidatePlaces: candidates,
        userLocation: userLocation,
        language: 'zh-TW',
      );

      final prompt = builder.build();

      expect(prompt, contains('place_1'));
      expect(prompt, contains('place_2'));
    });

    test('prompt 包含景點名稱和地址', () {
      final builder = RoutePromptBuilder(
        candidatePlaces: candidates,
        userLocation: userLocation,
        language: 'zh-TW',
      );

      final prompt = builder.build();

      expect(prompt, contains('龍山寺'));
      expect(prompt, contains('台北市萬華區廣州街211號'));
      expect(prompt, contains('剝皮寮歷史街區'));
    });

    test('prompt 包含 JSON schema 範例', () {
      final builder = RoutePromptBuilder(
        candidatePlaces: candidates,
        userLocation: userLocation,
        language: 'zh-TW',
      );

      final prompt = builder.build();

      expect(prompt, contains('"placeId"'));
      expect(prompt, contains('"overview"'));
      expect(prompt, contains('"title"'));
      expect(prompt, contains('"stops"'));
    });

    test('中文語言指令正確', () {
      final builder = RoutePromptBuilder(
        candidatePlaces: candidates,
        userLocation: userLocation,
        language: 'zh-TW',
      );

      final prompt = builder.build();

      expect(prompt, contains('繁體中文'));
    });

    test('英文語言指令正確', () {
      final builder = RoutePromptBuilder(
        candidatePlaces: candidates,
        userLocation: userLocation,
        language: 'en-US',
      );

      final prompt = builder.build();

      expect(prompt, contains('English'));
    });

    test('prompt 包含使用者位置座標', () {
      final builder = RoutePromptBuilder(
        candidatePlaces: candidates,
        userLocation: userLocation,
        language: 'zh-TW',
      );

      final prompt = builder.build();

      expect(prompt, contains('25.0478'));
      expect(prompt, contains('121.517'));
    });

    test('prompt 包含評分資訊', () {
      final builder = RoutePromptBuilder(
        candidatePlaces: candidates,
        userLocation: userLocation,
        language: 'zh-TW',
      );

      final prompt = builder.build();

      expect(prompt, contains('4.6/5.0'));
      expect(prompt, contains('4.4/5.0'));
    });
  });
}
