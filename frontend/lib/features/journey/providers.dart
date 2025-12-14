import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/journey/application/get_my_journey_use_case.dart';
import 'package:context_app/features/journey/models/journey_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:context_app/features/journey/data/supabase_journey_repository.dart';
export 'package:context_app/features/journey/application/get_my_journey_use_case.dart';
export 'package:context_app/features/journey/application/save_narration_to_journey_use_case.dart';

final myPassportProvider = FutureProvider.autoDispose<List<JourneyEntry>>((
  ref,
) async {
  final useCase = ref.watch(getMyPassportUseCaseProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  return useCase.execute(userId);
});
