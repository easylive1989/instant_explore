import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/passport/application/get_my_passport_use_case.dart';
import 'package:context_app/features/passport/domain/passport_repository.dart';
import 'package:context_app/features/passport/models/passport_entry.dart';
import 'package:context_app/features/player/models/narration_style.dart';

class MockPassportRepository extends Mock implements PassportRepository {}

void main() {
  late MockPassportRepository mockRepository;
  late GetMyPassportUseCase useCase;

  setUp(() {
    mockRepository = MockPassportRepository();
    useCase = GetMyPassportUseCase(mockRepository);
  });

  final testEntry = PassportEntry(
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
      () => mockRepository.getPassportEntries('user-1'),
    ).thenAnswer((_) async => [testEntry]);

    final result = await useCase.execute('user-1');

    expect(result, [testEntry]);
    verify(() => mockRepository.getPassportEntries('user-1')).called(1);
  });

  test('execute returns empty list when no entries found', () async {
    when(
      () => mockRepository.getPassportEntries('user-1'),
    ).thenAnswer((_) async => []);

    final result = await useCase.execute('user-1');

    expect(result, isEmpty);
    verify(() => mockRepository.getPassportEntries('user-1')).called(1);
  });
}