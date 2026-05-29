import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/data/narration_api_client.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/narration/domain/models/grounding_info.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart'
    as app_lang;

/// Backend-backed implementation of [NarrationService].
///
/// Sends place + optional hook to the backend `/narration` endpoint and
/// joins the returned 3-paragraph story for the App display & TTS.
/// Grounding info is no longer surfaced — the backend grounds on
/// Wikipedia, so we return null for the optional [GroundingInfo].
class NarrationApiService implements NarrationService {
  final NarrationApiClient client;

  NarrationApiService(this.client);

  @override
  Future<NarrationGenerationResult> generateNarration({
    required Place place,
    required app_lang.Language language,
    StoryHook? hook,
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
    final result = await client.fetchNarration(
      placeName: place.name,
      location: place.address,
      wikidataId: wikidataId,
      language: language.code,
      hook: hook,
    );
    if (result.insufficientSource) {
      throw const AppError(
        type: NarrationError.insufficientSource,
        message: '這個景點目前沒有足夠的歷史資料可講故事',
      );
    }
    return (text: result.text, grounding: null);
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
