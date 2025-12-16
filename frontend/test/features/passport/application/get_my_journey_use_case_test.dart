import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/journey/application/get_my_journey_use_case.dart';
import 'package:context_app/features/journey/domain/journey_repository.dart';
import 'package:context_app/features/journey/models/journey_entry.dart';
import 'package:context_app/features/narration/models/narration_style.dart';

class MockPassportRepository extends Mock implements JourneyRepository {}

void main() {
  late MockPassportRepository mockRepository;
  late GetMyJourneyUseCase useCase;

  setUp(() {
    mockRepository = MockPassportRepository();
    useCase = GetMyJourneyUseCase(mockRepository);
  });

  final testEntry = JourneyEntry(
    id: '1',
    userId: 'user-1',
    placeId: 'place-1',
    placeName: 'Place 1',
    placeAddress: 'Address 1',
    placeImageUrl: 'http://example.com/image.jpg',
    narrationText: 'Text',
    narrationStyle: NarrationStyle.brief,
    createdAt: DateTime.now(),
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
