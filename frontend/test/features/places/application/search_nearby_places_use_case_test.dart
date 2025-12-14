import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/explore/application/search_nearby_places_use_case.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:context_app/features/explore/models/place.dart';

class MockLocationService extends Mock implements LocationService {}

class MockPlacesRepository extends Mock implements PlacesRepository {}

class FakePlaceLocation extends Fake implements PlaceLocation {}

void main() {
  late SearchNearbyPlacesUseCase useCase;
  late MockLocationService mockLocationService;
  late MockPlacesRepository mockPlacesRepository;

  setUpAll(() {
    registerFallbackValue(FakePlaceLocation());
  });

  setUp(() {
    mockLocationService = MockLocationService();
    mockPlacesRepository = MockPlacesRepository();
    useCase = SearchNearbyPlacesUseCase(
      mockLocationService,
      mockPlacesRepository,
    );
  });

  test(
    'should get current location and return nearby places from the repository',
    () async {
      // arrange
      final testLocation = PlaceLocation(latitude: 12.34, longitude: 56.78);
      final testPlaces = [
        Place(
          id: '1',
          name: 'Test Place 1',
          formattedAddress: '',
          location: testLocation,
          types: [],
          photos: [],
        ),
        Place(
          id: '2',
          name: 'Test Place 2',
          formattedAddress: '',
          location: testLocation,
          types: [],
          photos: [],
        ),
      ];

      when(
        () => mockLocationService.getCurrentLocation(),
      ).thenAnswer((_) async => testLocation);
      when(
        () => mockPlacesRepository.getNearbyPlaces(testLocation),
      ).thenAnswer((_) async => testPlaces);

      // act
      final result = await useCase.execute();

      // assert
      expect(result, testPlaces);
    },
  );
}
