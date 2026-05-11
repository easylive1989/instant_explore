import 'package:context_app/features/sync/domain/services/sync_engine.dart';
import 'package:context_app/features/sync/domain/services/sync_session.dart';
import 'package:context_app/features/trip/domain/models/trip.dart';
import 'package:context_app/features/trip/domain/repositories/trip_repository.dart';

class SyncingTripRepository implements TripRepository {
  SyncingTripRepository({
    required this.local,
    required this.engine,
    required this.session,
  });

  final TripRepository local;
  final SyncEngine<Trip> engine;
  final SyncSession Function() session;

  @override
  Future<List<Trip>> getAll() => local.getAll();

  @override
  Future<Trip?> getById(String id) => local.getById(id);

  @override
  Future<void> save(Trip trip) async {
    await local.save(trip);
    if (session().isActive) {
      await engine.push(trip);
    }
  }

  @override
  Future<void> delete(String id) async {
    await local.delete(id);
    if (session().isActive) {
      await engine.deleteRemote(id);
    }
  }
}
