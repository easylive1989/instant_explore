import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/journey/domain/use_cases/save_narration_to_journey_use_case.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/narration/domain/models/narration.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/core/config/api_config.dart';

class MockPassportRepository extends Mock implements JourneyRepository {}

class MockApiConfig extends Mock implements ApiConfig {}

class FakePassportEntry extends Fake implements JourneyEntry {}

void main() {
  late MockPassportRepository mockRepository;
  late MockApiConfig mockApiConfig;
  late SaveNarrationToJourneyUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakePassportEntry());
  });

  setUp(() {
    mockRepository = MockPassportRepository();
    mockApiConfig = MockApiConfig();
    useCase = SaveNarrationToJourneyUseCase(mockRepository, mockApiConfig);

    // Default mock behavior
    when(() => mockApiConfig.isPlacesConfigured).thenReturn(false);
  });

  final place = Place(
    id: 'place-1',
    name: 'Test Place',
    formattedAddress: 'Address',
    location: PlaceLocation(latitude: 0, longitude: 0),
    types: [],
    photos: [],
    category: PlaceCategory.modernUrban,
  );

  test('execute saves entry successfully', () async {
    final narration = Narration(
      id: '1',
      place: place,
      aspect: NarrationAspect.historicalBackground,
      content: NarrationContent.fromText('Narration text'),
    );

    when(() => mockRepository.addJourneyEntry(any())).thenAnswer((_) async {});

    await useCase.execute(userId: 'user-1', narration: narration);

    verify(() => mockRepository.addJourneyEntry(any())).called(1);
  });

  test('execute creates journey entry with correct data', () async {
    final narration = Narration(
      id: '1',
      place: place,
      aspect: NarrationAspect.architecture,
      content: NarrationContent.fromText('Architecture narration'),
    );

    JourneyEntry? capturedEntry;
    when(() => mockRepository.addJourneyEntry(any())).thenAnswer((invocation) async {
      capturedEntry = invocation.positionalArguments[0] as JourneyEntry;
    });

    await useCase.execute(userId: 'user-1', narration: narration);

    expect(capturedEntry, isNotNull);
    expect(capturedEntry!.userId, equals('user-1'));
    expect(capturedEntry!.placeId, equals('place-1'));
    expect(capturedEntry!.placeName, equals('Test Place'));
    expect(capturedEntry!.narrationText, equals('Architecture narration'));
  });
}
