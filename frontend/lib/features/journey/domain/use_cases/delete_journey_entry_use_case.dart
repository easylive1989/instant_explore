import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';

class DeleteJourneyEntryUseCase {
  final JourneyRepository _repository;

  DeleteJourneyEntryUseCase(this._repository);

  Future<void> execute(String id) {
    return _repository.deleteJourneyEntry(id);
  }
}
