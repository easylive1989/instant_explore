import 'package:context_app/features/journey/domain/models/journey_entry.dart';

abstract class JourneyRepository {
  Future<List<JourneyEntry>> getAll();
  Future<void> save(JourneyEntry entry);
  Future<void> delete(String id);
}
