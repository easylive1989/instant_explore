import 'package:context_app/features/explore/providers.dart';
import 'package:context_app/features/plan/data/hive_plan_repository.dart';
import 'package:context_app/features/plan/domain/repositories/plan_repository.dart';
import 'package:context_app/features/plan/presentation/controllers/plan_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return HivePlanRepository();
});

final planListControllerProvider =
    StateNotifierProvider<PlanListController, PlanListState>((ref) {
      return PlanListController(
        ref.read(planRepositoryProvider),
        ref.read(searchNearbyPlacesUseCaseProvider),
      );
    });
