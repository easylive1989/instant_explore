import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/core/utils/geo_utils.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/route/domain/models/route_stop.dart';
import 'package:context_app/features/route/domain/models/tour_route.dart';
import 'package:context_app/features/route/domain/use_cases/create_route_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 路線規劃狀態
class RouteState {
  final TourRoute? route;
  final List<Place> candidatePlaces;
  final int currentStopIndex;
  final bool isLoading;
  final AppError? error;

  const RouteState({
    this.route,
    this.candidatePlaces = const [],
    this.currentStopIndex = 0,
    this.isLoading = false,
    this.error,
  });

  RouteState copyWith({
    TourRoute? route,
    List<Place>? candidatePlaces,
    int? currentStopIndex,
    bool? isLoading,
    AppError? error,
  }) {
    return RouteState(
      route: route ?? this.route,
      candidatePlaces: candidatePlaces ?? this.candidatePlaces,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 路線規劃控制器
class RouteController extends StateNotifier<RouteState> {
  final CreateRouteUseCase _createRouteUseCase;

  RouteController(this._createRouteUseCase) : super(const RouteState());

  /// 生成路線規劃
  Future<void> generateRoute({
    required List<Place> candidatePlaces,
    required PlaceLocation userLocation,
    required String language,
  }) async {
    state = state.copyWith(isLoading: true, candidatePlaces: candidatePlaces);

    try {
      final route = await _createRouteUseCase.execute(
        candidatePlaces: candidatePlaces,
        userLocation: userLocation,
        language: language,
      );
      state = state.copyWith(route: route, isLoading: false);
    } on AppError catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// 移除一個停靠站（最少保留 2 站）
  void removeStop(int index) {
    final route = state.route;
    if (route == null || route.stops.length <= 2) return;

    final newStops = List<RouteStop>.from(route.stops)..removeAt(index);
    state = state.copyWith(
      route: route.copyWith(stops: _recalculateDistances(newStops)),
    );
  }

  /// 新增一個停靠站
  void addStop(Place place) {
    final route = state.route;
    if (route == null) return;

    final newStop = RouteStop(place: place);
    final newStops = [...route.stops, newStop];
    state = state.copyWith(
      route: route.copyWith(stops: _recalculateDistances(newStops)),
    );
  }

  /// 重新排列停靠站
  void reorderStops(int oldIndex, int newIndex) {
    final route = state.route;
    if (route == null) return;

    final stops = List<RouteStop>.from(route.stops);
    final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = stops.removeAt(oldIndex);
    stops.insert(adjustedNew, item);

    state = state.copyWith(
      route: route.copyWith(stops: _recalculateDistances(stops)),
    );
  }

  /// 前往下一站
  void goToNextStop() {
    final route = state.route;
    if (route == null) return;
    if (state.currentStopIndex < route.stops.length - 1) {
      state = state.copyWith(currentStopIndex: state.currentStopIndex + 1);
    }
  }

  /// 回到上一站
  void goToPreviousStop() {
    if (state.currentStopIndex > 0) {
      state = state.copyWith(currentStopIndex: state.currentStopIndex - 1);
    }
  }

  /// 重置所有狀態
  void reset() {
    state = const RouteState();
  }

  /// 重新計算各站之間的距離和步行時間
  List<RouteStop> _recalculateDistances(List<RouteStop> stops) {
    final result = <RouteStop>[];

    for (var i = 0; i < stops.length; i++) {
      if (i < stops.length - 1) {
        final from = stops[i].place.location;
        final to = stops[i + 1].place.location;
        final distance = calculateHaversineDistance(from, to);
        final walkingTime = estimateWalkingMinutes(from, to);
        result.add(
          RouteStop(
            place: stops[i].place,
            overview: stops[i].overview,
            distanceToNext: distance,
            walkingTimeToNext: walkingTime,
          ),
        );
      } else {
        result.add(stops[i].clearDistances());
      }
    }

    return result;
  }
}
