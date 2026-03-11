import 'package:context_app/features/route/domain/models/route_stop.dart';
import 'package:equatable/equatable.dart';

/// AI 規劃的導覽路線
class TourRoute extends Equatable {
  /// AI 生成的路線主題名稱
  final String title;

  /// 有序的停靠站列表，順序由 index 決定
  final List<RouteStop> stops;

  const TourRoute({required this.title, required this.stops});

  /// 總距離（公尺），從各站的 distanceToNext 加總
  double get totalDistance {
    return stops.fold(0.0, (sum, stop) => sum + (stop.distanceToNext ?? 0));
  }

  /// 預估總步行時間（分鐘），從各站的 walkingTimeToNext 加總
  double get estimatedDuration {
    return stops.fold(0.0, (sum, stop) => sum + (stop.walkingTimeToNext ?? 0));
  }

  TourRoute copyWith({String? title, List<RouteStop>? stops}) {
    return TourRoute(title: title ?? this.title, stops: stops ?? this.stops);
  }

  @override
  List<Object?> get props => [title, stops];
}
