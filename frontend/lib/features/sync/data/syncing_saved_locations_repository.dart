import 'package:context_app/features/saved_locations/domain/models/saved_location_entry.dart';
import 'package:context_app/features/saved_locations/domain/repositories/saved_locations_repository.dart';
import 'package:context_app/features/sync/domain/services/sync_engine.dart';
import 'package:context_app/features/sync/domain/services/sync_session.dart';

class SyncingSavedLocationsRepository implements SavedLocationsRepository {
  SyncingSavedLocationsRepository({
    required this.local,
    required this.engine,
    required this.session,
  });

  final SavedLocationsRepository local;
  final SyncEngine<SavedLocationEntry> engine;
  final SyncSession Function() session;

  @override
  Future<List<SavedLocationEntry>> getAll() => local.getAll();

  @override
  Future<bool> isSaved(String placeId) => local.isSaved(placeId);

  @override
  Future<void> save(SavedLocationEntry entry) async {
    await local.save(entry);
    if (session().isActive) {
      await engine.push(entry);
    }
  }

  @override
  Future<void> delete(String placeId) async {
    await local.delete(placeId);
    if (session().isActive) {
      await engine.deleteRemote(placeId);
    }
  }
}
