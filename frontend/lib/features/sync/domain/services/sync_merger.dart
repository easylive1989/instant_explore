/// Outcome of merging local and remote item lists by `updatedAt`.
///
/// * [merged] is the unified view (local + remote with the latest version
///   per id kept).
/// * [toPush] contains items where the local version is newer than the
///   remote one (or the remote is missing the item entirely), so they
///   need to be pushed up.
/// * [toApplyLocally] contains items where the remote version is newer
///   than the local one (or the local is missing the item entirely), so
///   they need to be written locally.
class SyncMergeResult<T> {
  final List<T> merged;
  final List<T> toPush;
  final List<T> toApplyLocally;

  const SyncMergeResult({
    required this.merged,
    required this.toPush,
    required this.toApplyLocally,
  });
}

/// Last-write-wins merge keyed by id, comparing `updatedAt` timestamps.
///
/// Soft deletes are out of scope at this milestone — disabling sync
/// keeps cloud data intact, and a delete is mirrored to both sides
/// while sync is active.
class SyncMerger {
  static SyncMergeResult<T> merge<T>({
    required List<T> local,
    required List<T> remote,
    required String Function(T item) idOf,
    required DateTime Function(T item) updatedAtOf,
  }) {
    final localById = {for (final item in local) idOf(item): item};
    final remoteById = {for (final item in remote) idOf(item): item};
    final allIds = {...localById.keys, ...remoteById.keys};

    final merged = <T>[];
    final toPush = <T>[];
    final toApplyLocally = <T>[];

    for (final id in allIds) {
      final localItem = localById[id];
      final remoteItem = remoteById[id];

      if (localItem == null && remoteItem != null) {
        merged.add(remoteItem);
        toApplyLocally.add(remoteItem);
        continue;
      }
      if (remoteItem == null && localItem != null) {
        merged.add(localItem);
        toPush.add(localItem);
        continue;
      }

      final localTs = updatedAtOf(localItem as T);
      final remoteTs = updatedAtOf(remoteItem as T);
      if (localTs.isAfter(remoteTs)) {
        merged.add(localItem);
        toPush.add(localItem);
      } else if (remoteTs.isAfter(localTs)) {
        merged.add(remoteItem);
        toApplyLocally.add(remoteItem);
      } else {
        merged.add(remoteItem);
      }
    }

    return SyncMergeResult<T>(
      merged: merged,
      toPush: toPush,
      toApplyLocally: toApplyLocally,
    );
  }
}
