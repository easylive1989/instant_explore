import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/core/domain/models/language.dart';

class GenerateNarrationUseCase {
  final NarrationService _narrationService;

  GenerateNarrationUseCase(this._narrationService);

  Future<NarrationContent> execute({
    required Place place,
    required NarrationAspect aspect,
    required Language language,
  }) {
    return _narrationService.generateNarration(
      place: place,
      aspect: aspect,
      language: language,
    );
  }
}
