import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 使用者位置（原點）
  const userLocation = PlaceLocation(latitude: 0.0, longitude: 0.0);

  /// 建立距離使用者指定公尺遠的 Place（沿緯度方向）
  Place createPlace({required String id, required String name, required double distanceMeters}) {
    // 1 degree latitude ≈ 111,111 m
    final latOffset = distanceMeters / 111111.0;
    return Place(
      id: id,
      name: name,
      formattedAddress: 'Test Address',
      location: PlaceLocation(latitude: latOffset, longitude: 0.0),
      types: const ['tourist_attraction'],
      photos: const [],
      category: PlaceCategory.modernUrban,
    );
  }

  ProviderContainer buildContainer({
    required List<Place> places,
    double? maxDistance,
    PlaceLocation? location,
  }) {
    return ProviderContainer(
      overrides: [
        placesControllerProvider.overrideWith(() => _FakePlacesController(places)),
        if (maxDistance != null)
          maxDistanceProvider.overrideWith((ref) => maxDistance),
        if (location != null)
          userLocationProvider.overrideWith((ref) => location),
      ],
    );
  }

  group('filteredPlacesProvider', () {
    test('預設 maxDistance 為 10000', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final max = container.read(maxDistanceProvider);
      expect(max, 10000.0);
    });

    test('userLocation 為 null 時顯示全部地點', () {
      final container = buildContainer(
        places: [
          createPlace(id: '1', name: 'Near', distanceMeters: 100),
          createPlace(id: '2', name: 'Far', distanceMeters: 10000),
        ],
        maxDistance: 500.0,
        // userLocation 不設定，保持 null
      );
      addTearDown(container.dispose);

      final filtered = container.read(filteredPlacesProvider);
      filtered.whenData((places) {
        expect(places.length, 2);
      });
    });

    test('只顯示在 maxDistance 範圍內的地點', () {
      final container = buildContainer(
        places: [
          createPlace(id: '1', name: 'Near', distanceMeters: 200),
          createPlace(id: '2', name: 'Far', distanceMeters: 800),
        ],
        maxDistance: 500.0,
        location: userLocation,
      );
      addTearDown(container.dispose);

      final filtered = container.read(filteredPlacesProvider);
      filtered.whenData((places) {
        expect(places.length, 1);
        expect(places.first.name, 'Near');
      });
    });

    test('maxDistance 30000 時顯示全部地點', () {
      final container = buildContainer(
        places: [
          createPlace(id: '1', name: 'A', distanceMeters: 500),
          createPlace(id: '2', name: 'B', distanceMeters: 2000),
          createPlace(id: '3', name: 'C', distanceMeters: 4000),
        ],
        maxDistance: 30000.0,
        location: userLocation,
      );
      addTearDown(container.dispose);

      final filtered = container.read(filteredPlacesProvider);
      filtered.whenData((places) {
        expect(places.length, 3);
      });
    });

    test('剛好在邊界上的地點應通過過濾', () {
      final container = buildContainer(
        places: [
          createPlace(id: '1', name: 'Boundary', distanceMeters: 1000),
        ],
        maxDistance: 1000.0,
        location: userLocation,
      );
      addTearDown(container.dispose);

      final filtered = container.read(filteredPlacesProvider);
      filtered.whenData((places) {
        expect(places.length, 1);
      });
    });
  });
}

class _FakePlacesController extends PlacesController {
  final List<Place> _places;

  _FakePlacesController(this._places);

  @override
  Future<List<Place>> build() async => _places;
}
