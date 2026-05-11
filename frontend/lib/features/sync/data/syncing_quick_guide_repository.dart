import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/quick_guide/domain/repositories/quick_guide_repository.dart';
import 'package:context_app/features/sync/domain/services/sync_engine.dart';
import 'package:context_app/features/sync/domain/services/sync_session.dart';

class SyncingQuickGuideRepository implements QuickGuideRepository {
  SyncingQuickGuideRepository({
    required this.local,
    required this.engine,
    required this.session,
  });

  final QuickGuideRepository local;
  final SyncEngine<QuickGuideEntry> engine;
  final SyncSession Function() session;

  @override
  Future<List<QuickGuideEntry>> getAll() => local.getAll();

  @override
  Future<void> save(QuickGuideEntry entry) async {
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
