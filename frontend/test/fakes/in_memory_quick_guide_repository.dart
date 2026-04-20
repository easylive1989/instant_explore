import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/quick_guide/domain/repositories/quick_guide_repository.dart';

/// In-memory [QuickGuideRepository] used by widget tests.
class InMemoryQuickGuideRepository implements QuickGuideRepository {
  final Map<String, QuickGuideEntry> _entries = {};

  @override
  Future<List<QuickGuideEntry>> getAll() async {
    final list = _entries.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> save(QuickGuideEntry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<void> delete(String id) async {
    _entries.remove(id);
  }
}
