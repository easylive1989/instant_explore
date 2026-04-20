import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// Fake [NarrationService] that returns a seeded text result.
class FakeNarrationService implements NarrationService {
  final String text;
  final Exception? error;

  Place? lastPlace;
  Set<NarrationAspect>? lastAspects;
  Language? lastLanguage;

  FakeNarrationService({
    this.text =
        'This is a fake narration used for widget tests. '
        'It contains multiple sentences. How are you? Great!',
    this.error,
  });

  @override
  Future<NarrationGenerationResult> generateNarration({
    required Place place,
    required Set<NarrationAspect> aspects,
    required Language language,
  }) async {
    lastPlace = place;
    lastAspects = aspects;
    lastLanguage = language;
    if (error != null) throw error!;
    return (text: text, grounding: null);
  }
}
