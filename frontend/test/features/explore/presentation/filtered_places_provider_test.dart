import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// 建立測試用 Place
  Place createPlace({
    required String id,
    required String name,
    int? userRatingCount,
  }) {
    return Place(
      id: id,
      name: name,
      formattedAddress: 'Test Address',
      location: const PlaceLocation(latitude: 0, longitude: 0),
      types: const ['tourist_attraction'],
      photos: const [],
      category: PlaceCategory.modernUrban,
      userRatingCount: userRatingCount,
    );
  }

  group('filteredPlacesProvider', () {
    test('預設門檻為 100', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final minCount = container.read(minReviewCountProvider);
      expect(minCount, 100);
    });

    test('應根據 minReviewCountProvider 過濾地點', () {
      final container = ProviderContainer(
        overrides: [
          placesControllerProvider.overrideWith(() {
            return _FakePlacesController([
              createPlace(id: '1', name: 'Many', userRatingCount: 500),
              createPlace(id: '2', name: 'Some', userRatingCount: 50),
              createPlace(id: '3', name: 'Few', userRatingCount: 5),
              createPlace(id: '4', name: 'None', userRatingCount: null),
            ]);
          }),
        ],
      );
      addTearDown(container.dispose);

      // 預設門檻 100：只有 500 通過
      var filtered = container.read(filteredPlacesProvider);
      filtered.whenData((places) {
        expect(places.length, 1);
        expect(places.first.name, 'Many');
      });

      // 調整門檻為 50：500 和 50 通過
      container.read(minReviewCountProvider.notifier).state = 50;
      filtered = container.read(filteredPlacesProvider);
      filtered.whenData((places) {
        expect(places.length, 2);
      });

      // 調整門檻為 0：除了 null 以外都通過
      container.read(minReviewCountProvider.notifier).state = 0;
      filtered = container.read(filteredPlacesProvider);
      filtered.whenData((places) {
        expect(places.length, 3);
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
