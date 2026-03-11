import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:equatable/equatable.dart';

/// 路線中的一個停靠站
class RouteStop extends Equatable {
  final Place place;

  /// AI 生成的簡短概覽，手動新增的景點為 null
  final String? overview;

  /// 到下一站的距離（公尺），最後一站為 null
  final double? distanceToNext;

  /// 到下一站的步行時間（分鐘），最後一站為 null
  final double? walkingTimeToNext;

  const RouteStop({
    required this.place,
    this.overview,
    this.distanceToNext,
    this.walkingTimeToNext,
  });

  RouteStop copyWith({
    Place? place,
    String? overview,
    double? distanceToNext,
    double? walkingTimeToNext,
  }) {
    return RouteStop(
      place: place ?? this.place,
      overview: overview ?? this.overview,
      distanceToNext: distanceToNext ?? this.distanceToNext,
      walkingTimeToNext: walkingTimeToNext ?? this.walkingTimeToNext,
    );
  }

  /// 建立一個清除 distanceToNext 和 walkingTimeToNext 的副本
  RouteStop clearDistances() {
    return RouteStop(place: place, overview: overview);
  }

  @override
  List<Object?> get props => [
    place,
    overview,
    distanceToNext,
    walkingTimeToNext,
  ];
}
