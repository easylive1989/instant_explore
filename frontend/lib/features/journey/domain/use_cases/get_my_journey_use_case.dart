import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/journey/data/supabase_journey_repository.dart';

class GetMyJourneyUseCase {
  final JourneyRepository _repository;

  GetMyJourneyUseCase(this._repository);

  Future<List<JourneyEntry>> execute(String userId) {
    return _repository.getJourneyEntries(userId);
  }
}

final getMyPassportUseCaseProvider = Provider<GetMyJourneyUseCase>((ref) {
  final repository = ref.watch(passportRepositoryProvider);
  return GetMyJourneyUseCase(repository);
});
