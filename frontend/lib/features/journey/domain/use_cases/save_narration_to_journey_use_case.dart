import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/journey/data/supabase_journey_repository.dart';
import 'package:uuid/uuid.dart';

class SaveNarrationToJourneyUseCase {
  final JourneyRepository _repository;
  final Uuid _uuid;

  SaveNarrationToJourneyUseCase(this._repository) : _uuid = const Uuid();

  Future<void> execute({
    required String userId,
    required Place place,
    required NarrationAspect aspect,
    required NarrationContent content,
    required Language language,
  }) async {
    String? imageUrl;
    if (place.primaryPhoto != null) {
      imageUrl = place.primaryPhoto!.url;
    }

    final savedPlace = SavedPlace(
      id: place.id,
      name: place.name,
      address: place.formattedAddress,
      imageUrl: imageUrl,
    );

    final entry = JourneyEntry(
      id: _uuid.v4(),
      userId: userId,
      place: savedPlace,
      narrationContent: content,
      createdAt: DateTime.now(),
      language: language,
    );

    await _repository.addJourneyEntry(entry);
  }
}

final saveNarrationToPassportUseCaseProvider =
    Provider<SaveNarrationToJourneyUseCase>((ref) {
      final repository = ref.watch(passportRepositoryProvider);
      return SaveNarrationToJourneyUseCase(repository);
    });
