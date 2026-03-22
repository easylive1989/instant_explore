import 'dart:io';

import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/plan/data/hive_plan_repository.dart';
import 'package:context_app/features/plan/domain/models/plan.dart';
import 'package:context_app/features/route/domain/models/route_stop.dart';
import 'package:context_app/features/route/domain/models/tour_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

TourRoute _makeRoute(String title) => TourRoute(
  title: title,
  stops: const [
    RouteStop(
      place: Place(
        id: 'p1',
        name: 'Place 1',
        formattedAddress: 'Addr 1',
        location: PlaceLocation(latitude: 25.0, longitude: 121.5),
        category: PlaceCategory.modernUrban,
        types: [],
        photos: [],
      ),
    ),
    RouteStop(
      place: Place(
        id: 'p2',
        name: 'Place 2',
        formattedAddress: 'Addr 2',
        location: PlaceLocation(latitude: 25.01, longitude: 121.51),
        category: PlaceCategory.naturalLandscape,
        types: [],
        photos: [],
      ),
    ),
  ],
);

void main() {
  late HivePlanRepository repo;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync();
    Hive.init(dir.path);
    repo = HivePlanRepository();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('getAll returns empty list when no plans saved', () async {
    final result = await repo.getAll();
    expect(result, isEmpty);
  });

  test('save then getAll returns the saved plan', () async {
    final plan = Plan.fromTourRoute(_makeRoute('Morning Walk'));
    await repo.save(plan);

    final result = await repo.getAll();
    expect(result.length, 1);
    expect(result.first.id, plan.id);
    expect(result.first.title, 'Morning Walk');
  });

  test('getAll returns plans sorted newest first', () async {
    final old = Plan(
      id: 'old',
      title: 'Old',
      createdAt: DateTime(2026, 1, 1),
      stops: const [],
      totalDistance: 0,
      estimatedDuration: 0,
    );
    final recent = Plan(
      id: 'recent',
      title: 'Recent',
      createdAt: DateTime(2026, 3, 1),
      stops: const [],
      totalDistance: 0,
      estimatedDuration: 0,
    );

    await repo.save(old);
    await repo.save(recent);

    final result = await repo.getAll();
    expect(result.first.id, 'recent');
    expect(result.last.id, 'old');
  });

  test('delete removes the plan', () async {
    final plan = Plan.fromTourRoute(_makeRoute('Route'));
    await repo.save(plan);
    await repo.delete(plan.id);

    final result = await repo.getAll();
    expect(result, isEmpty);
  });

  test('delete non-existent id does nothing', () async {
    await repo.save(Plan.fromTourRoute(_makeRoute('Keep')));
    await repo.delete('non-existent');

    final result = await repo.getAll();
    expect(result.length, 1);
  });

  test('save preserves all fields through round-trip', () async {
    final plan = Plan.fromTourRoute(_makeRoute('Full Route'));
    await repo.save(plan);

    final result = await repo.getAll();
    final restored = result.first;

    expect(restored.id, plan.id);
    expect(restored.title, plan.title);
    expect(restored.stops.length, 2);
    expect(restored.stops.first.placeId, 'p1');
    expect(restored.stops.first.placeCategory, 'modernUrban');
  });
}
