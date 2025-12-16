import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/narration/domain/models/narration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/journey/data/supabase_journey_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:context_app/core/config/api_config.dart';

class SaveNarrationToJourneyUseCase {
  final JourneyRepository _repository;
  final ApiConfig _apiConfig;
  final Uuid _uuid;

  SaveNarrationToJourneyUseCase(this._repository, this._apiConfig)
    : _uuid = const Uuid();

  Future<void> execute({
    required String userId,
    required Narration narration,
  }) async {
    if (narration.content == null) {
      throw Exception('Cannot save narration without content');
    }

    String? imageUrl;
    if (narration.place.primaryPhoto != null && _apiConfig.isPlacesConfigured) {
      imageUrl = narration.place.primaryPhoto!.getPhotoUrl(
        maxWidth: 400,
        apiKey: _apiConfig.googlePlacesApiKey,
      );
    }

    final entry = JourneyEntry(
      id: _uuid.v4(),
      userId: userId,
      placeId: narration.place.id,
      placeName: narration.place.name,
      placeAddress: narration.place.formattedAddress,
      placeImageUrl: imageUrl,
      narrationText: narration.content!.text,
      narrationAspect: narration.aspect,
      createdAt: DateTime.now(),
    );

    await _repository.addJourneyEntry(entry);
  }
}

final saveNarrationToPassportUseCaseProvider =
    Provider<SaveNarrationToJourneyUseCase>((ref) {
      final repository = ref.watch(passportRepositoryProvider);
      final apiConfig = ref.watch(apiConfigProvider);
      return SaveNarrationToJourneyUseCase(repository, apiConfig);
    });
