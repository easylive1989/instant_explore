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
    final wikidataId = _extractWikidataId(place.id);
    if (wikidataId == null) {
      // Defensive: the Explore flow always emits `wikidata:`-prefixed ids.
      // Landing here indicates an upstream bug; degrade gracefully with the
      // same UX as a backend insufficient_source response.
      throw const AppError(
        type: NarrationError.insufficientSource,
        message: '這個景點目前沒有足夠的歷史資料可講故事',
      );
    }
    final result = await client.fetchHooks(
      placeName: place.name,
      location: place.address,
      wikidataId: wikidataId,
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

/// Extracts the raw Wikidata Q-id from a `wikidata:`-prefixed place id.
///
/// Returns `null` when [placeId] does not carry the expected prefix,
/// signalling that the caller should degrade gracefully.
String? _extractWikidataId(String placeId) {
  const prefix = 'wikidata:';
  if (!placeId.startsWith(prefix)) return null;
  return placeId.substring(prefix.length);
}
