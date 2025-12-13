import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/passport/application/get_my_passport_use_case.dart';
import 'package:context_app/features/passport/models/passport_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:context_app/features/passport/data/supabase_passport_repository.dart';
export 'package:context_app/features/passport/application/get_my_passport_use_case.dart';
export 'package:context_app/features/passport/application/save_narration_to_passport_use_case.dart';

final myPassportProvider = FutureProvider.autoDispose<List<PassportEntry>>((
  ref,
) async {
  final useCase = ref.watch(getMyPassportUseCaseProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  return useCase.execute(userId);
});
