import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/journey/domain/use_cases/get_my_journey_use_case.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/core/domain/models/language.dart';

class MockPassportRepository extends Mock implements JourneyRepository {}

void main() {
  late MockPassportRepository mockRepository;
  late GetMyJourneyUseCase useCase;

  setUp(() {
    mockRepository = MockPassportRepository();
    useCase = GetMyJourneyUseCase(mockRepository);
  });

  const testPlace = SavedPlace(
    id: 'place-1',
    name: 'Place 1',
    address: 'Address 1',
    imageUrl: 'http://example.com/image.jpg',
  );

  final testEntry = JourneyEntry(
    id: '1',
    userId: 'user-1',
    place: testPlace,
    narrationContent: NarrationContent.fromText('Text'),
    createdAt: DateTime.now(),
    language: Language.fromString('zh-TW'),
  );

  test('execute returns list of passport entries', () async {
    when(
      () => mockRepository.getJourneyEntries('user-1'),
    ).thenAnswer((_) async => [testEntry]);

    final result = await useCase.execute('user-1');

    expect(result, [testEntry]);
    verify(() => mockRepository.getJourneyEntries('user-1')).called(1);
  });

  test('execute returns empty list when no entries found', () async {
    when(
      () => mockRepository.getJourneyEntries('user-1'),
    ).thenAnswer((_) async => []);

    final result = await useCase.execute('user-1');

    expect(result, isEmpty);
    verify(() => mockRepository.getJourneyEntries('user-1')).called(1);
  });
}
