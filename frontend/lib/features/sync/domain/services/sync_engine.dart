import 'package:context_app/features/sync/domain/services/remote_sync_data_source.dart';
import 'package:context_app/features/sync/domain/services/sync_merger.dart';
import 'package:logging/logging.dart';

/// Per-entity descriptor that explains how to identify and order items.
class SyncEntityDescriptor<T> {
  final String name;
  final String Function(T item) idOf;
  final DateTime Function(T item) updatedAtOf;

  const SyncEntityDescriptor({
    required this.name,
    required this.idOf,
    required this.updatedAtOf,
  });
}

/// Orchestrates push/pull of a single entity type between the local
/// store (represented by callbacks) and a [RemoteSyncDataSource].
///
/// Callbacks keep the engine framework-agnostic so it can wrap any
/// repository abstraction.
class SyncEngine<T> {
  SyncEngine({
    required this.descriptor,
    required this.remote,
    required this.loadLocal,
    required this.saveLocal,
  });

  static final _log = Logger('SyncEngine');

  final SyncEntityDescriptor<T> descriptor;
  final RemoteSyncDataSource<T> remote;
  final Future<List<T>> Function() loadLocal;
  final Future<void> Function(T item) saveLocal;

  /// Pull from remote, merge with local by `updatedAt`, then write back
  /// local-only or newer items to both sides.
  Future<SyncMergeResult<T>> fullSync() async {
    final local = await loadLocal();
    final remoteItems = await remote.fetchAll();

    final result = SyncMerger.merge<T>(
      local: local,
      remote: remoteItems,
      idOf: descriptor.idOf,
      updatedAtOf: descriptor.updatedAtOf,
    );

    for (final item in result.toApplyLocally) {
      try {
        await saveLocal(item);
      } catch (e, stack) {
        _log.warning(
          'Failed to apply ${descriptor.name} locally',
          e,
          stack,
        );
      }
    }
    for (final item in result.toPush) {
      try {
        await remote.upsert(item);
      } catch (e, stack) {
        _log.warning('Failed to push ${descriptor.name}', e, stack);
      }
    }
    return result;
  }

  /// Best-effort single-item push. Errors are logged, not thrown.
  Future<void> push(T item) async {
    try {
      await remote.upsert(item);
    } catch (e, stack) {
      _log.warning('Failed to push ${descriptor.name}', e, stack);
    }
  }

  /// Best-effort single-item delete. Errors are logged, not thrown.
  Future<void> deleteRemote(String id) async {
    try {
      await remote.delete(id);
    } catch (e, stack) {
      _log.warning('Failed to delete ${descriptor.name} remotely', e, stack);
    }
  }
}
