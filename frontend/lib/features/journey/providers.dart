import 'package:context_app/features/journey/data/hive_journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return HiveJourneyRepository();
});

final myJourneyProvider = FutureProvider.autoDispose<List<JourneyEntry>>((ref) {
  return ref.watch(journeyRepositoryProvider).getAll();
});
