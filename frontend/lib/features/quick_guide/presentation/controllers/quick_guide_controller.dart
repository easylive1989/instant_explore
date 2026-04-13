import 'dart:typed_data';

import 'package:context_app/features/quick_guide/domain/use_cases/generate_quick_guide_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The lifecycle of a quick-guide session.
enum QuickGuideStatus {
  /// Waiting for the user to take a photo.
  idle,

  /// AI is analysing the image and saving to journey.
  analyzing,

  /// Description is ready and entry has been saved to the journey.
  success,

  /// Daily usage quota has been exceeded.
  quotaExceeded,

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
  bool get isQuotaExceeded => status == QuickGuideStatus.quotaExceeded;

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
///
/// 僅負責 UI 狀態管理，業務邏輯委派給 [GenerateQuickGuideUseCase]。
class QuickGuideController extends StateNotifier<QuickGuideState> {
  final GenerateQuickGuideUseCase _useCase;

  QuickGuideController(this._useCase) : super(const QuickGuideState());

  /// Sends [imageBytes] to the AI service via use case.
  ///
  /// Sets [QuickGuideStatus.quotaExceeded] when the daily limit is reached.
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
      final result = await _useCase.execute(
        imageBytes: imageBytes,
        mimeType: mimeType,
        language: language,
      );

      switch (result) {
        case GenerateQuickGuideQuotaExceeded():
          state = const QuickGuideState(
            status: QuickGuideStatus.quotaExceeded,
          );
        case GenerateQuickGuideSuccess(:final entry):
          state = state.copyWith(
            status: QuickGuideStatus.success,
            aiDescription: entry.aiDescription,
          );
      }
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
