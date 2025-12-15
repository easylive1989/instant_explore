import 'package:context_app/features/journey/domain/journey_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/journey/data/supabase_journey_repository.dart';

class DeleteJourneyEntryUseCase {
  final JourneyRepository _repository;

  DeleteJourneyEntryUseCase(this._repository);

  Future<void> execute(String id) {
    return _repository.deleteJourneyEntry(id);
  }
}

final deleteJourneyEntryUseCaseProvider = Provider<DeleteJourneyEntryUseCase>((
  ref,
) {
  final repository = ref.watch(passportRepositoryProvider);
  return DeleteJourneyEntryUseCase(repository);
});
