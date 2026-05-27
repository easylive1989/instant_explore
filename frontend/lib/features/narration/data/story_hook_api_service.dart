import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/data/narration_api_client.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:context_app/features/narration/domain/services/story_hook_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// Backend-backed implementation of [StoryHookService].
class StoryHookApiService implements StoryHookService {
  final NarrationApiClient client;

  StoryHookApiService(this.client);

  @override
  Future<List<StoryHook>> generateHooks({
    required Place place,
    required Language language,
  }) {
    return client.fetchHooks(
      placeName: place.name,
      location: place.address,
      wikipediaTitle: place.name,
      language: language.code,
    );
  }
}
