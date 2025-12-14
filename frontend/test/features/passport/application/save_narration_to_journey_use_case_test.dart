import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/journey/application/save_narration_to_journey_use_case.dart';
import 'package:context_app/features/journey/domain/journey_repository.dart';
import 'package:context_app/features/journey/models/journey_entry.dart';
import 'package:context_app/features/explore/models/place.dart';
import 'package:context_app/features/narration/models/narration.dart';
import 'package:context_app/features/narration/models/narration_content.dart';
import 'package:context_app/features/narration/models/narration_style.dart';
import 'package:context_app/features/narration/models/playback_state.dart';
import 'package:context_app/core/config/api_config.dart';

class MockPassportRepository extends Mock implements JourneyRepository {}

class MockApiConfig extends Mock implements ApiConfig {}

class FakePassportEntry extends Fake implements JourneyEntry {}

void main() {
  late MockPassportRepository mockRepository;
  late MockApiConfig mockApiConfig;
  late SaveNarrationToJourenyUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakePassportEntry());
  });

  setUp(() {
    mockRepository = MockPassportRepository();
    mockApiConfig = MockApiConfig();
    useCase = SaveNarrationToJourenyUseCase(mockRepository, mockApiConfig);

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
  );

  test('execute saves entry successfully', () async {
    final narration = Narration(
      id: '1',
      place: place,
      style: NarrationStyle.brief,
      state: PlaybackState.ready,
      content: NarrationContent.fromText('Narration text'),
    );

    when(() => mockRepository.addJourneyEntry(any())).thenAnswer((_) async {});

    await useCase.execute(userId: 'user-1', narration: narration);

    verify(() => mockRepository.addJourneyEntry(any())).called(1);
  });

  test('execute throws exception if narration content is null', () async {
    final narration = Narration(
      id: '1',
      place: place,
      style: NarrationStyle.brief,
      state: PlaybackState.loading,
      content: null,
    );

    expect(
      () => useCase.execute(userId: 'user-1', narration: narration),
      throwsException,
    );
    verifyNever(() => mockRepository.addJourneyEntry(any()));
  });
}