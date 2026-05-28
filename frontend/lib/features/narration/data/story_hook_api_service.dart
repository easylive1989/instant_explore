import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/data/narration_api_client.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:context_app/features/narration/domain/services/story_hook_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// Backend-backed implementation of [StoryHookService].
///
/// `insufficient_source: true` from the backend is mapped to an
/// [AppError] of type [NarrationError.insufficientSource] so callers
/// can show a distinct UX ("nothing to tell about this place")
/// instead of the generic empty-list fallback ("we'll just play one").
class StoryHookApiService implements StoryHookService {
  final NarrationApiClient client;

  StoryHookApiService(this.client);

  @override
  Future<List<StoryHook>> generateHooks({
    required Place place,
    required Language language,
  }) async {
    final result = await client.fetchHooks(
      placeName: place.name,
      location: place.address,
      wikipediaTitle: place.name,
      language: language.code,
    );
    if (result.insufficientSource) {
      throw const AppError(
        type: NarrationError.insufficientSource,
        message: '這個景點目前沒有足夠的歷史資料可講故事',
      );
    }
    return result.hooks;
  }
}
