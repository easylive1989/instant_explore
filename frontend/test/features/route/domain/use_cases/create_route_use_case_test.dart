import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/route/data/route_ai_service.dart';
import 'package:context_app/features/route/domain/errors/route_error.dart';
import 'package:context_app/features/route/domain/models/route_stop.dart';
import 'package:context_app/features/route/domain/models/tour_route.dart';
import 'package:context_app/features/route/domain/use_cases/create_route_use_case.dart';
import 'package:context_app/features/usage/domain/errors/usage_error.dart';
import 'package:context_app/features/usage/domain/models/usage_status.dart';
import 'package:context_app/features/usage/domain/repositories/usage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRouteAiService extends Mock implements RouteAiService {}

class MockUsageRepository extends Mock implements UsageRepository {}

class FakePlaceLocation extends Fake implements PlaceLocation {}

Place _createPlace(String id) {
  return Place(
    id: id,
    name: 'Place $id',
    formattedAddress: 'Address $id',
    location: const PlaceLocation(latitude: 25.0, longitude: 121.5),
    types: const ['tourist_attraction'],
    photos: const [],
    category: PlaceCategory.historicalCultural,
  );
}

void main() {
  late CreateRouteUseCase useCase;
  late MockRouteAiService mockAiService;
  late MockUsageRepository mockUsageRepository;

  final candidates = [_createPlace('1'), _createPlace('2'), _createPlace('3')];
  const userLocation = PlaceLocation(latitude: 25.0478, longitude: 121.517);
  const language = 'zh-TW';

  final testRoute = TourRoute(
    title: '測試路線',
    stops: [
      RouteStop(place: candidates[0], overview: '概覽 1'),
      RouteStop(place: candidates[1], overview: '概覽 2'),
    ],
  );

  setUpAll(() {
    registerFallbackValue(FakePlaceLocation());
    registerFallbackValue(<Place>[]);
  });

  setUp(() {
    mockAiService = MockRouteAiService();
    mockUsageRepository = MockUsageRepository();
    useCase = CreateRouteUseCase(mockAiService, mockUsageRepository);
  });

  group('CreateRouteUseCase', () {
    test('成功時：呼叫 AI 服務並消耗額度', () async {
      when(
        () => mockUsageRepository.getUsageStatus(),
      ).thenAnswer((_) async => const UsageStatus(usedToday: 0));
      when(
        () => mockAiService.generateRoute(
          candidatePlaces: any(named: 'candidatePlaces'),
          userLocation: any(named: 'userLocation'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => testRoute);
      when(() => mockUsageRepository.consumeUsage()).thenAnswer((_) async {});

      final result = await useCase.execute(
        candidatePlaces: candidates,
        userLocation: userLocation,
        language: language,
      );

      expect(result.title, '測試路線');
      expect(result.stops.length, 2);
      verify(() => mockUsageRepository.consumeUsage()).called(1);
    });

    test('額度用完時：拋出 dailyQuotaExceeded，不呼叫 AI', () async {
      when(() => mockUsageRepository.getUsageStatus()).thenAnswer(
        (_) async => const UsageStatus(usedToday: 1, dailyFreeLimit: 1),
      );

      expect(
        () => useCase.execute(
          candidatePlaces: candidates,
          userLocation: userLocation,
          language: language,
        ),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            UsageError.dailyQuotaExceeded,
          ),
        ),
      );

      verifyNever(
        () => mockAiService.generateRoute(
          candidatePlaces: any(named: 'candidatePlaces'),
          userLocation: any(named: 'userLocation'),
          language: any(named: 'language'),
        ),
      );
    });

    test('AI 失敗時：不消耗額度', () async {
      when(
        () => mockUsageRepository.getUsageStatus(),
      ).thenAnswer((_) async => const UsageStatus(usedToday: 0));
      when(
        () => mockAiService.generateRoute(
          candidatePlaces: any(named: 'candidatePlaces'),
          userLocation: any(named: 'userLocation'),
          language: any(named: 'language'),
        ),
      ).thenThrow(
        const AppError(
          type: RouteError.aiParsingFailed,
          message: 'parse error',
        ),
      );

      expect(
        () => useCase.execute(
          candidatePlaces: candidates,
          userLocation: userLocation,
          language: language,
        ),
        throwsA(isA<AppError>()),
      );

      verifyNever(() => mockUsageRepository.consumeUsage());
    });
  });
}
