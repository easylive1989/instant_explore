import 'package:context_app/features/passport/domain/passport_repository.dart';
import 'package:context_app/features/passport/models/passport_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/passport/data/supabase_passport_repository.dart';

class GetMyPassportUseCase {
  final PassportRepository _repository;

  GetMyPassportUseCase(this._repository);

  Future<List<PassportEntry>> execute(String userId) {
    return _repository.getPassportEntries(userId);
  }
}

final getMyPassportUseCaseProvider = Provider<GetMyPassportUseCase>((ref) {
  final repository = ref.watch(passportRepositoryProvider);
  return GetMyPassportUseCase(repository);
});
