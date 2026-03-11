import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/usage/domain/errors/usage_error.dart';
import 'package:context_app/features/usage/domain/models/usage_status.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNarrationService extends Mock implements NarrationService {}

class MockUsageRepository extends Mock implements UsageRepository {}

class FakePlace extends Fake implements Place {}

class FakeLanguage extends Fake implements Language {}

void main() {
  late CreateNarrationUseCase useCase;
  late MockNarrationService mockNarrationService;
  late MockUsageRepository mockUsageRepository;

  setUpAll(() {
    registerFallbackValue(FakePlace());
    registerFallbackValue(NarrationAspect.historicalBackground);
    registerFallbackValue(FakeLanguage());
  });

  setUp(() {
    mockNarrationService = MockNarrationService();
    mockUsageRepository = MockUsageRepository();
    useCase = CreateNarrationUseCase(mockNarrationService, mockUsageRepository);

    // 預設：有剩餘額度
    when(() => mockUsageRepository.getUsageStatus()).thenAnswer(
      (_) async => const UsageStatus(usedToday: 0, dailyFreeLimit: 1),
    );
    when(() => mockUsageRepository.consumeUsage()).thenAnswer((_) async {});
  });

  const testPlace = Place(
    id: 'test-place-id',
    name: 'Test Place',
    formattedAddress: '123 Test St, Test City',
    location: PlaceLocation(latitude: 25.0, longitude: 121.0),
    types: ['tourist_attraction'],
    photos: [],
    category: PlaceCategory.historicalCultural,
  );

  const testGeneratedText = '''
這是一個測試地點。這裡有豐富的歷史。
許多遊客來到這裡參觀。這是一個著名的景點。
''';

  test('成功生成導覽', () async {
    when(
      () => mockNarrationService.generateNarration(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => testGeneratedText);

    final narrationContent = await useCase.execute(
      place: testPlace,
      aspect: NarrationAspect.historicalBackground,
      language: Language.traditionalChinese,
    );

    expect(
      narrationContent,
      equals(
        NarrationContent.create(
          testGeneratedText,
          language: Language.traditionalChinese,
        ),
      ),
    );
  });

  test('有剩餘次數時消耗額度', () async {
    when(
      () => mockNarrationService.generateNarration(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => testGeneratedText);

    await useCase.execute(
      place: testPlace,
      aspect: NarrationAspect.historicalBackground,
      language: Language.traditionalChinese,
    );

    verify(() => mockUsageRepository.consumeUsage()).called(1);
  });

  test('額度用完時拋出 UsageError.dailyQuotaExceeded', () async {
    when(() => mockUsageRepository.getUsageStatus()).thenAnswer(
      (_) async => const UsageStatus(usedToday: 1, dailyFreeLimit: 1),
    );

    expect(
      () => useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: Language.traditionalChinese,
      ),
      throwsA(
        isA<AppError>().having(
          (e) => e.type,
          'error type',
          UsageError.dailyQuotaExceeded,
        ),
      ),
    );

    verifyNever(
      () => mockNarrationService.generateNarration(
        place: any(named: 'place'),
        aspect: any(named: 'aspect'),
        language: any(named: 'language'),
      ),
    );
  });

  test('看廣告後有 bonus 可用時成功生成', () async {
    when(() => mockUsageRepository.getUsageStatus()).thenAnswer(
      (_) async =>
          const UsageStatus(usedToday: 1, dailyFreeLimit: 1, bonusFromAds: 1),
    );
    when(
      () => mockNarrationService.generateNarration(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => testGeneratedText);

    final narrationContent = await useCase.execute(
      place: testPlace,
      aspect: NarrationAspect.historicalBackground,
      language: Language.traditionalChinese,
    );

    expect(narrationContent, isNotNull);
    verify(() => mockUsageRepository.consumeUsage()).called(1);
  });

  test('剩餘次數為 1 時成功生成並消耗最後一次', () async {
    when(() => mockUsageRepository.getUsageStatus()).thenAnswer(
      (_) async => const UsageStatus(usedToday: 0, dailyFreeLimit: 1),
    );
    when(
      () => mockNarrationService.generateNarration(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => testGeneratedText);

    await useCase.execute(
      place: testPlace,
      aspect: NarrationAspect.historicalBackground,
      language: Language.traditionalChinese,
    );

    verify(() => mockUsageRepository.consumeUsage()).called(1);
  });
}
