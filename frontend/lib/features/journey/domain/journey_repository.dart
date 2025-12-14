import 'package:context_app/features/journey/models/journey_entry.dart';

abstract class JourneyRepository {
  Future<List<JourneyEntry>> getJourneyEntries(String userId);
  Future<void> addJourneyEntry(JourneyEntry entry);
  Future<void> deleteJourneyEntry(String id);
}
