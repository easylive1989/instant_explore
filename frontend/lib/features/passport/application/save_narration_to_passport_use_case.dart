import 'package:context_app/features/passport/domain/passport_repository.dart';
import 'package:context_app/features/passport/models/passport_entry.dart';
import 'package:context_app/features/player/models/narration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:context_app/features/passport/data/supabase_passport_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:context_app/core/config/api_config.dart';

class SaveNarrationToPassportUseCase {
  final PassportRepository _repository;
  final ApiConfig _apiConfig;
  final Uuid _uuid;

  SaveNarrationToPassportUseCase(this._repository, this._apiConfig)
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

    final entry = PassportEntry(
      id: _uuid.v4(),
      userId: userId,
      placeId: narration.place.id,
      placeName: narration.place.name,
      placeAddress: narration.place.formattedAddress,
      placeImageUrl: imageUrl,
      narrationText: narration.content!.text,
      narrationStyle: narration.style,
      createdAt: DateTime.now(),
    );

    await _repository.addPassportEntry(entry);
  }
}

final saveNarrationToPassportUseCaseProvider =
    Provider<SaveNarrationToPassportUseCase>((ref) {
      final repository = ref.watch(passportRepositoryProvider);
      final apiConfig = ref.watch(apiConfigProvider);
      return SaveNarrationToPassportUseCase(repository, apiConfig);
    });
