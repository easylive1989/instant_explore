import 'dart:typed_data';

import 'package:context_app/features/quick_guide/data/quick_guide_ai_service.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/quick_guide/domain/repositories/quick_guide_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The lifecycle of a quick-guide session.
enum QuickGuideStatus {
  /// Waiting for the user to take a photo.
  idle,

  /// AI is analysing the image and saving to journey.
  analyzing,

  /// Description is ready and entry has been saved to the journey.
  success,

  /// An error occurred.
  error,
}

/// Immutable state for [QuickGuideController].
class QuickGuideState {
  final QuickGuideStatus status;
  final Uint8List? imageBytes;
  final String? aiDescription;
  final String? errorMessage;

  const QuickGuideState({
    this.status = QuickGuideStatus.idle,
    this.imageBytes,
    this.aiDescription,
    this.errorMessage,
  });

  bool get isLoading => status == QuickGuideStatus.analyzing;

  bool get hasError => status == QuickGuideStatus.error;
  bool get isSuccess => status == QuickGuideStatus.success;

  QuickGuideState copyWith({
    QuickGuideStatus? status,
    Uint8List? imageBytes,
    String? aiDescription,
    String? errorMessage,
  }) => QuickGuideState(
    status: status ?? this.status,
    imageBytes: imageBytes ?? this.imageBytes,
    aiDescription: aiDescription ?? this.aiDescription,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

/// Manages the quick-guide capture → describe → save flow.
class QuickGuideController extends StateNotifier<QuickGuideState> {
  final QuickGuideAiService _aiService;
  final QuickGuideRepository _repository;

  QuickGuideController(this._aiService, this._repository)
    : super(const QuickGuideState());

  /// Sends [imageBytes] to the AI service, then automatically saves the
  /// result to the journey.
  Future<void> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
    required String language,
  }) async {
    state = QuickGuideState(
      status: QuickGuideStatus.analyzing,
      imageBytes: imageBytes,
    );

    try {
      final description = await _aiService.describeImage(
        imageBytes: imageBytes,
        mimeType: mimeType,
        language: language,
      );

      final entry = QuickGuideEntry.create(
        imageBytes: imageBytes,
        aiDescription: description,
        language: Language(language),
      );
      await _repository.save(entry);

      state = state.copyWith(
        status: QuickGuideStatus.success,
        aiDescription: description,
      );
    } catch (e) {
      state = state.copyWith(
        status: QuickGuideStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Resets to the idle state, clearing any captured image or description.
  void reset() => state = const QuickGuideState();
}
