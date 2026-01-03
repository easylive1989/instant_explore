import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/subscription/domain/errors/subscription_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/subscription/domain/models/pass_type.dart';
import 'package:context_app/features/subscription/domain/models/user_entitlement.dart';
import 'package:context_app/features/subscription/domain/repositories/entitlement_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockNarrationService extends Mock implements NarrationService {}

class MockEntitlementRepository extends Mock implements EntitlementRepository {}

// Fake class for Place (required for mocktail any() matcher)
class FakePlace extends Fake implements Place {}

// Fake class for Language
class FakeLanguage extends Fake implements Language {}

void main() {
  late CreateNarrationUseCase useCase;
  late MockNarrationService mockNarrationService;
  late MockEntitlementRepository mockEntitlementRepository;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakePlace());
    registerFallbackValue(NarrationAspect.historicalBackground);
    registerFallbackValue(FakeLanguage());
  });

  setUp(() {
    mockNarrationService = MockNarrationService();
    mockEntitlementRepository = MockEntitlementRepository();
    useCase = CreateNarrationUseCase(
      mockNarrationService,
      mockEntitlementRepository,
    );

    // 預設權益為免費用戶（有剩餘次數）
    when(
      () => mockEntitlementRepository.getEntitlement(),
    ).thenAnswer((_) async => UserEntitlement.free(dailyFreeLimit: 3));
    when(
      () => mockEntitlementRepository.consumeFreeUsage(),
    ).thenAnswer((_) async {});
  });

  group('StartNarrationUseCase', () {
    final testPlace = Place(
      id: 'test-place-id',
      name: 'Test Place',
      formattedAddress: '123 Test St, Test City',
      location: PlaceLocation(latitude: 25.0, longitude: 121.0),
      types: const ['tourist_attraction'],
      photos: const [],
      category: PlaceCategory.historicalCultural,
    );

    const testGeneratedText = '''
這是一個測試地點。這裡有豐富的歷史。
許多遊客來到這裡參觀。這是一個著名的景點。
''';

    test(
      'should successfully generate narration and create NarrationContent',
      () async {
        // Arrange - Service now returns String
        when(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.historicalBackground,
            language: any(named: 'language'),
          ),
        ).thenAnswer((_) async => testGeneratedText);

        // Act
        final result = await useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: Language.traditionalChinese,
        );

        // Assert
        expect(result, isA<NarrationContent>());
        expect(result.text, equals(testGeneratedText));
        expect(result.segments.length, greaterThan(0));

        // Verify method calls
        verify(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.historicalBackground,
            language: any(named: 'language'),
          ),
        ).called(1);
      },
    );

    test(
      'should successfully generate narration with architecture aspect',
      () async {
        // Arrange
        when(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.architecture,
            language: any(named: 'language'),
          ),
        ).thenAnswer((_) async => testGeneratedText);

        // Act
        final result = await useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.architecture,
          language: Language.english,
        );

        // Assert
        expect(result, isA<NarrationContent>());

        verify(
          () => mockNarrationService.generateNarration(
            place: testPlace,
            aspect: NarrationAspect.architecture,
            language: any(named: 'language'),
          ),
        ).called(1);
      },
    );

    test('should throw NarrationException when text is empty', () async {
      // Arrange
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => '');

      // Act & Assert
      expect(
        () => useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: Language.traditionalChinese,
        ),
        throwsA(isA<AppError>()),
      );
    });

    test('should throw NarrationException when text is too short', () async {
      // Arrange
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => '短');

      // Act & Assert
      expect(
        () => useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: Language.traditionalChinese,
        ),
        throwsA(isA<AppError>()),
      );
    });

    test('should rethrow AppError with correct error type', () async {
      // Arrange
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenThrow(
        const AppError(
          type: NarrationError.unsupportedLocation,
          message: 'Location not supported',
        ),
      );

      // Act & Assert
      try {
        await useCase.execute(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: Language.traditionalChinese,
        );
        fail('Should have thrown');
      } on AppError catch (e) {
        expect(e.type, equals(NarrationError.unsupportedLocation));
      }
    });

    test('should correctly split text into segments', () async {
      // Arrange
      const textWithMultipleSegments = '''
第一句話。第二句話！第三句話？
第四句話。
''';

      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => textWithMultipleSegments);

      // Act
      final result = await useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: Language.traditionalChinese,
      );

      // Assert
      expect(result.segments.length, equals(4));
      expect(result.segments[0].text, equals('第一句話。'));
      expect(result.segments[1].text, equals('第二句話！'));
      expect(result.segments[2].text, equals('第三句話？'));
      expect(result.segments[3].text, equals('第四句話。'));
    });
  });

  group('CreateNarrationUseCase - 非付費用戶情境', () {
    final testPlace = Place(
      id: 'test-place-id',
      name: 'Test Place',
      formattedAddress: '123 Test St, Test City',
      location: PlaceLocation(latitude: 25.0, longitude: 121.0),
      types: const ['tourist_attraction'],
      photos: const [],
      category: PlaceCategory.historicalCultural,
    );

    const testGeneratedText = '''
這是一個測試地點。這裡有豐富的歷史。
許多遊客來到這裡參觀。這是一個著名的景點。
''';

    test('免費用戶有剩餘次數時，應成功生成導覽並消耗免費次數', () async {
      // Arrange - 免費用戶有剩餘次數
      when(() => mockEntitlementRepository.getEntitlement()).thenAnswer(
        (_) async => const UserEntitlement(
          hasActivePass: false,
          remainingFreeUsage: 2,
          dailyFreeLimit: 3,
        ),
      );
      when(
        () => mockEntitlementRepository.consumeFreeUsage(),
      ).thenAnswer((_) async {});
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => testGeneratedText);

      // Act
      final result = await useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: Language.traditionalChinese,
      );

      // Assert
      expect(result, isA<NarrationContent>());
      verify(() => mockEntitlementRepository.consumeFreeUsage()).called(1);
    });

    test('免費用戶額度用完時，應拋出 AppError with freeQuotaExceeded', () async {
      // Arrange - 免費用戶額度已用完
      when(() => mockEntitlementRepository.getEntitlement()).thenAnswer(
        (_) async => const UserEntitlement(
          hasActivePass: false,
          remainingFreeUsage: 0,
          dailyFreeLimit: 3,
        ),
      );

      // Act & Assert
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
            SubscriptionError.freeQuotaExceeded,
          ),
        ),
      );

      // 確認不會呼叫 generateNarration
      verifyNever(
        () => mockNarrationService.generateNarration(
          place: any(named: 'place'),
          aspect: any(named: 'aspect'),
          language: any(named: 'language'),
        ),
      );
    });

    test('付費用戶應成功生成導覽且不消耗免費次數', () async {
      // Arrange - 付費用戶
      when(() => mockEntitlementRepository.getEntitlement()).thenAnswer(
        (_) async => UserEntitlement.premium(
          passType: PassType.dayPass,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      );
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => testGeneratedText);

      // Act
      final result = await useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: Language.traditionalChinese,
      );

      // Assert
      expect(result, isA<NarrationContent>());
      // 確認不會呼叫 consumeFreeUsage
      verifyNever(() => mockEntitlementRepository.consumeFreeUsage());
    });

    test('免費用戶剩餘次數為 1 時，應成功生成並消耗最後一次', () async {
      // Arrange - 免費用戶只剩最後一次
      when(() => mockEntitlementRepository.getEntitlement()).thenAnswer(
        (_) async => const UserEntitlement(
          hasActivePass: false,
          remainingFreeUsage: 1,
          dailyFreeLimit: 3,
        ),
      );
      when(
        () => mockEntitlementRepository.consumeFreeUsage(),
      ).thenAnswer((_) async {});
      when(
        () => mockNarrationService.generateNarration(
          place: testPlace,
          aspect: NarrationAspect.historicalBackground,
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => testGeneratedText);

      // Act
      final result = await useCase.execute(
        place: testPlace,
        aspect: NarrationAspect.historicalBackground,
        language: Language.traditionalChinese,
      );

      // Assert
      expect(result, isA<NarrationContent>());
      verify(() => mockEntitlementRepository.consumeFreeUsage()).called(1);
    });
  });
}
