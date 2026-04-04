import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';

/// Abstract repository for persisting [QuickGuideEntry] records.
abstract class QuickGuideRepository {
  /// Returns all entries sorted newest first.
  Future<List<QuickGuideEntry>> getAll();

  /// Persists [entry], overwriting any existing entry with the same id.
  Future<void> save(QuickGuideEntry entry);

  /// Removes the entry with [id]. Does nothing if the id is unknown.
  Future<void> delete(String id);
}
