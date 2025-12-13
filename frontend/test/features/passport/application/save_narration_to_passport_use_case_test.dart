import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/passport/application/save_narration_to_passport_use_case.dart';
import 'package:context_app/features/passport/domain/passport_repository.dart';
import 'package:context_app/features/passport/models/passport_entry.dart';
import 'package:context_app/features/places/models/place.dart';
import 'package:context_app/features/player/models/narration.dart';
import 'package:context_app/features/player/models/narration_content.dart';
import 'package:context_app/features/player/models/narration_style.dart';
import 'package:context_app/features/player/models/playback_state.dart';
import 'package:context_app/core/config/api_config.dart';

class MockPassportRepository extends Mock implements PassportRepository {}

class MockApiConfig extends Mock implements ApiConfig {}

class FakePassportEntry extends Fake implements PassportEntry {}

void main() {
  late MockPassportRepository mockRepository;
  late MockApiConfig mockApiConfig;
  late SaveNarrationToPassportUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakePassportEntry());
  });

  setUp(() {
    mockRepository = MockPassportRepository();
    mockApiConfig = MockApiConfig();
    useCase = SaveNarrationToPassportUseCase(mockRepository, mockApiConfig);

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
      content: NarrationContent(
        text: 'Narration text',
        segments: [],
        estimatedDuration: 10,
      ),
    );

    when(() => mockRepository.addPassportEntry(any())).thenAnswer((_) async {});

    await useCase.execute(userId: 'user-1', narration: narration);

    verify(() => mockRepository.addPassportEntry(any())).called(1);
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
    verifyNever(() => mockRepository.addPassportEntry(any()));
  });
}