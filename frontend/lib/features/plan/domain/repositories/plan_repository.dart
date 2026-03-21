import 'package:context_app/features/plan/domain/models/plan.dart';

/// Repository interface for persisting and retrieving [Plan] objects.
abstract class PlanRepository {
  /// Returns all saved plans, sorted newest first.
  Future<List<Plan>> getAll();

  /// Saves or updates a plan. Uses [Plan.id] as the key.
  Future<void> save(Plan plan);

  /// Deletes the plan with the given [id]. Does nothing if not found.
  Future<void> delete(String id);
}
