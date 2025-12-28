import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';

class GetMyJourneyUseCase {
  final JourneyRepository _repository;

  GetMyJourneyUseCase(this._repository);

  Future<List<JourneyEntry>> execute(String userId) {
    return _repository.getJourneyEntries(userId);
  }
}
