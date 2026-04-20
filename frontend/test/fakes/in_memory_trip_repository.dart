import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/domain/repositories/trip_repository.dart';

/// In-memory [TripRepository] used by widget tests.
class InMemoryTripRepository implements TripRepository {
  final Map<String, Trip> _trips = {};

  @override
  Future<List<Trip>> getAll() async {
    final list = _trips.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Trip?> getById(String id) async => _trips[id];

  @override
  Future<void> save(Trip trip) async {
    _trips[trip.id] = trip;
  }

  @override
  Future<void> delete(String id) async {
    _trips.remove(id);
  }
}
