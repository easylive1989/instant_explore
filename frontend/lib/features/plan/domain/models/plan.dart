import 'package:context_app/features/plan/domain/models/plan_stop.dart';
import 'package:context_app/features/route/domain/models/tour_route.dart';
import 'package:uuid/uuid.dart';

/// 持久化的路線規劃
class Plan {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<PlanStop> stops;
  final double totalDistance;
  final double estimatedDuration;

  const Plan({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.stops,
    required this.totalDistance,
    required this.estimatedDuration,
  });

  factory Plan.fromTourRoute(TourRoute route) => Plan(
    id: const Uuid().v4(),
    title: route.title,
    createdAt: DateTime.now(),
    stops: route.stops.map(PlanStop.fromRouteStop).toList(),
    totalDistance: route.totalDistance,
    estimatedDuration: route.estimatedDuration,
  );

  TourRoute toTourRoute() => TourRoute(
    title: title,
    stops: stops.map((s) => s.toRouteStop()).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'stops': stops.map((s) => s.toJson()).toList(),
    'totalDistance': totalDistance,
    'estimatedDuration': estimatedDuration,
  };

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    stops: (json['stops'] as List)
        .map((s) => PlanStop.fromJson(s as Map<String, dynamic>))
        .toList(),
    totalDistance: (json['totalDistance'] as num).toDouble(),
    estimatedDuration: (json['estimatedDuration'] as num).toDouble(),
  );
}
