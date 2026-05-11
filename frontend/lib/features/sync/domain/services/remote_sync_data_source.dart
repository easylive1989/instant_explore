/// Generic remote source for a single entity type.
///
/// Implementations are responsible for scoping queries by the
/// currently-signed-in user.
abstract class RemoteSyncDataSource<T> {
  Future<List<T>> fetchAll();
  Future<void> upsert(T item);
  Future<void> delete(String id);
}
