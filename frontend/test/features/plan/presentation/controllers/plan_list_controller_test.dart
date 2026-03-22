import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/use_cases/search_nearby_places_use_case.dart';
import 'package:context_app/features/plan/domain/models/plan.dart';
import 'package:context_app/features/plan/domain/repositories/plan_repository.dart';
import 'package:context_app/features/plan/presentation/controllers/plan_list_controller.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlanRepository extends Mock implements PlanRepository {}

class MockSearchNearbyPlacesUseCase extends Mock
    implements SearchNearbyPlacesUseCase {}

Plan _makePlan(String id, {DateTime? createdAt}) => Plan(
  id: id,
  title: 'Plan $id',
  createdAt: createdAt ?? DateTime(2026, 1, 1),
  stops: const [],
  totalDistance: 0,
  estimatedDuration: 0,
);

void main() {
  late PlanListController controller;
  late MockPlanRepository mockRepo;
  late MockSearchNearbyPlacesUseCase mockSearchUseCase;

  setUp(() {
    mockRepo = MockPlanRepository();
    mockSearchUseCase = MockSearchNearbyPlacesUseCase();
    when(() => mockRepo.getAll()).thenAnswer((_) async => []);
    controller = PlanListController(mockRepo, mockSearchUseCase);
  });

  test('initial state is loading then loads plans', () async {
    final plan = _makePlan('1');
    when(() => mockRepo.getAll()).thenAnswer((_) async => [plan]);

    controller = PlanListController(mockRepo, mockSearchUseCase);
    await Future.delayed(Duration.zero); // let async init complete

    expect(controller.state.isLoading, false);
    expect(controller.state.plans.length, 1);
    expect(controller.state.plans.first.id, '1');
  });

  test('reload refreshes plan list from repository', () async {
    when(() => mockRepo.getAll()).thenAnswer((_) async => [
      _makePlan('A'),
      _makePlan('B'),
    ]);

    await controller.reload();

    expect(controller.state.plans.length, 2);
    verify(() => mockRepo.getAll()).called(greaterThan(1));
  });

  test('deletePlan removes plan from state and calls repository', () async {
    when(() => mockRepo.getAll()).thenAnswer((_) async => [
      _makePlan('keep'),
      _makePlan('remove'),
    ]);
    when(() => mockRepo.delete(any())).thenAnswer((_) async {});
    await controller.reload();

    await controller.deletePlan('remove');

    expect(controller.state.plans.length, 1);
    expect(controller.state.plans.first.id, 'keep');
    verify(() => mockRepo.delete('remove')).called(1);
  });

  test('findNearbyPlaces delegates to use case', () async {
    final places = <Place>[];
    when(
      () => mockSearchUseCase.execute(language: Language.english),
    ).thenAnswer((_) async => places);

    final result = await controller.findNearbyPlaces(Language.english);

    expect(result, places);
    verify(
      () => mockSearchUseCase.execute(language: Language.english),
    ).called(1);
  });

  test('deletePlan rolls back state when repository throws', () async {
    when(() => mockRepo.getAll()).thenAnswer((_) async => [
      _makePlan('keep'),
      _makePlan('fail'),
    ]);
    when(() => mockRepo.delete('fail')).thenThrow(Exception('Hive error'));
    await controller.reload();

    await controller.deletePlan('fail');

    // List is restored — both plans still present
    expect(controller.state.plans.length, 2);
  });
}
