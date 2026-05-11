import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/sync/domain/services/sync_engine.dart';
import 'package:context_app/features/sync/domain/services/sync_session.dart';

/// Decorates a local [JourneyRepository] with optional write-through to
/// Supabase whenever sync is active.
class SyncingJourneyRepository implements JourneyRepository {
  SyncingJourneyRepository({
    required this.local,
    required this.engine,
    required this.session,
  });

  final JourneyRepository local;
  final SyncEngine<JourneyEntry> engine;
  final SyncSession Function() session;

  @override
  Future<List<JourneyEntry>> getAll() => local.getAll();

  @override
  Future<void> save(JourneyEntry entry) async {
    await local.save(entry);
    if (session().isActive) {
      await engine.push(entry);
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
