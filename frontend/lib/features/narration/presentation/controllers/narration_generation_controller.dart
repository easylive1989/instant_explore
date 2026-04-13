import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/core/errors/app_error_type.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/use_cases/create_narration_use_case.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/usage/domain/errors/usage_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// The lifecycle of a narration generation session.
enum NarrationGenerationStatus {
  /// Waiting for the user to press "Start".
  idle,

  /// AI is generating the narration content.
  generating,

  /// Narration content is ready.
  success,

  /// An error occurred during generation.
  error,
}

/// Immutable state for [NarrationGenerationController].
class NarrationGenerationState {
  final NarrationGenerationStatus status;
  final NarrationContent? content;
  final NarrationGenerationErrorType? errorType;
  final String? errorMessage;

  const NarrationGenerationState({
    this.status = NarrationGenerationStatus.idle,
    this.content,
    this.errorType,
    this.errorMessage,
  });

  bool get isIdle => status == NarrationGenerationStatus.idle;
  bool get isGenerating => status == NarrationGenerationStatus.generating;
  bool get isSuccess => status == NarrationGenerationStatus.success;
  bool get hasError => status == NarrationGenerationStatus.error;
}

/// Error types for narration generation.
enum NarrationGenerationErrorType {
  network,
  server,
  configurationError,
  contentGenerationFailed,
  unknown;

  bool get isRetryable => switch (this) {
    network || server => true,
    _ => false,
  };
}

/// Manages the narration generation flow on the config screen.
///
/// Similar to [QuickGuideController], this controller handles
/// AI generation before navigating to the player screen.
class NarrationGenerationController
    extends StateNotifier<NarrationGenerationState> {
  final CreateNarrationUseCase _createNarrationUseCase;
  final JourneyRepository _journeyRepository;

  NarrationGenerationController(
    this._createNarrationUseCase,
    this._journeyRepository,
  ) : super(const NarrationGenerationState());

  /// Generates narration content for the given place and aspect.
  ///
  /// On success, auto-saves to journey and sets state to [success].
  /// On error, sets state to [error] with the appropriate error type.
  Future<void> generate({
    required Place place,
    required NarrationAspect aspect,
    required Language language,
  }) async {
    state = const NarrationGenerationState(
      status: NarrationGenerationStatus.generating,
    );

    try {
      final content = await _createNarrationUseCase.execute(
        place: place,
        aspect: aspect,
        language: language,
      );

      await _autoSaveToJourney(place, aspect, content, language);

      state = NarrationGenerationState(
        status: NarrationGenerationStatus.success,
        content: content,
      );
    } on AppError catch (e) {
      state = NarrationGenerationState(
        status: NarrationGenerationStatus.error,
        errorType: _mapAppError(e.type),
        errorMessage: e.message,
      );
    }
  }

  /// Resets to the idle state.
  void reset() => state = const NarrationGenerationState();

  NarrationGenerationErrorType _mapAppError(AppErrorType type) {
    if (type is NarrationError) {
      return switch (type) {
        NarrationError.networkError => NarrationGenerationErrorType.network,
        NarrationError.serverError => NarrationGenerationErrorType.server,
        NarrationError.configurationError =>
          NarrationGenerationErrorType.configurationError,
        NarrationError.contentGenerationFailed =>
          NarrationGenerationErrorType.contentGenerationFailed,
        _ => NarrationGenerationErrorType.unknown,
      };
    }

    if (type is UsageError) {
      // Quota exceeded should not reach here because it's checked
      // before calling generate, but handle defensively.
      return NarrationGenerationErrorType.unknown;
    }

    return NarrationGenerationErrorType.unknown;
  }

  Future<void> _autoSaveToJourney(
    Place place,
    NarrationAspect aspect,
    NarrationContent content,
    Language language,
  ) async {
    try {
      final entry = JourneyEntry.create(
        id: const Uuid().v4(),
        place: place,
        aspect: aspect,
        content: content,
        language: language,
      );
      await _journeyRepository.save(entry);
    } catch (_) {
      // Fail silently - don't affect the generation flow.
    }
  }
}
