import 'package:context_app/features/trip/domain/models/trip.dart';

abstract class TripRepository {
  Future<List<Trip>> getAll();
  Future<Trip?> getById(String id);
  Future<void> save(Trip trip);
  Future<void> delete(String id);
}
