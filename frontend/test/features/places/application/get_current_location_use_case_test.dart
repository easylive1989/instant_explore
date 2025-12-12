import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/places/application/get_current_location_use_case.dart';
import 'package:context_app/features/places/domain/services/location_service.dart';
import 'package:context_app/features/places/models/place.dart';

class MockLocationService extends Mock implements LocationService {}

void main() {
  late GetCurrentLocationUseCase useCase;
  late MockLocationService mockLocationService;

  setUp(() {
    mockLocationService = MockLocationService();
    useCase = GetCurrentLocationUseCase(mockLocationService);
  });

  final testLocation = PlaceLocation(latitude: 12.34, longitude: 56.78);

  test('should get location from the location service', () async {
    // arrange
    when(() => mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => testLocation);
    // act
    final result = await useCase.execute();
    // assert
    expect(result, testLocation);
    verify(() => mockLocationService.getCurrentLocation());
    verifyNoMoreInteractions(mockLocationService);
  });

  test('should throw an exception when location service fails', () async {
    // arrange
    final exception = Exception('Location service failed');
    when(() => mockLocationService.getCurrentLocation())
        .thenThrow(exception);
    // act
    final call = useCase.execute;
    // assert
    expect(() => call(), throwsA(isA<Exception>()));
  });
}
