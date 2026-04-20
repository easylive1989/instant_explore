import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';

/// In-memory [JourneyRepository] used by widget tests.
class InMemoryJourneyRepository implements JourneyRepository {
  final Map<String, JourneyEntry> _entries = {};

  @override
  Future<List<JourneyEntry>> getAll() async {
    final list = _entries.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> save(JourneyEntry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<void> delete(String id) async {
    _entries.remove(id);
  }
}
