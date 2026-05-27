import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/data/narration_api_client.dart';
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
    final result = await client.fetchNarration(
      placeName: place.name,
      location: place.address,
      wikipediaTitle: place.name,
      language: language.code,
      hook: hook,
    );
    return (text: result.text, grounding: null);
  }
}
