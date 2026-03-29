import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/use_cases/search_nearby_places_use_case.dart';
import 'package:context_app/features/plan/domain/models/plan.dart';
import 'package:context_app/features/plan/domain/repositories/plan_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state for the plan list screen.
class PlanListState {
  final List<Plan> plans;
  final bool isLoading;

  const PlanListState({this.plans = const [], this.isLoading = false});

  PlanListState copyWith({List<Plan>? plans, bool? isLoading}) => PlanListState(
    plans: plans ?? this.plans,
    isLoading: isLoading ?? this.isLoading,
  );
}

class PlanListController extends StateNotifier<PlanListState> {
  final PlanRepository _repository;
  final SearchNearbyPlacesUseCase _searchNearbyPlacesUseCase;

  PlanListController(this._repository, this._searchNearbyPlacesUseCase)
    : super(const PlanListState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final plans = await _repository.getAll();
    state = state.copyWith(plans: plans, isLoading: false);
  }

  /// 重新從 Hive 載入列表（例如新增 Plan 後呼叫）
  Future<void> reload() => _load();

  /// 搜尋附近景點以供路線規劃使用。
  Future<List<Place>> findNearbyPlaces(Language language) =>
      _searchNearbyPlacesUseCase.execute(language: language);

  /// 刪除 Plan 並更新列表。失敗時還原狀態。
  Future<void> deletePlan(String id) async {
    final previous = state.plans;
    state = state.copyWith(plans: previous.where((p) => p.id != id).toList());
    try {
      await _repository.delete(id);
    } catch (_) {
      state = state.copyWith(plans: previous);
    }
  }
}
