import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 故事鉤子載入狀態。
///
/// `empty` 與 `insufficientSource` 是兩種不同的「沒結果」：
/// - `empty` — 後端找到資料但挑不出明確角度；仍可嘗試「直接聽故事」
/// - `insufficientSource` — 後端 Wikipedia 內容根本不足；不該再勸使用者重試
enum StoryHookStatus { loading, success, empty, insufficientSource, error }

class StoryHookState {
  final StoryHookStatus status;
  final List<StoryHook> hooks;
  final String? errorMessage;

  const StoryHookState({
    required this.status,
    this.hooks = const [],
    this.errorMessage,
  });

  factory StoryHookState.loading() =>
      const StoryHookState(status: StoryHookStatus.loading);

  bool get isLoading => status == StoryHookStatus.loading;
  bool get isSuccess => status == StoryHookStatus.success;
  bool get isEmpty => status == StoryHookStatus.empty;
  bool get isInsufficientSource => status == StoryHookStatus.insufficientSource;
  bool get hasError => status == StoryHookStatus.error;
}

/// 為單一景點載入故事鉤子。
class StoryHookController
    extends AutoDisposeFamilyNotifier<StoryHookState, StoryHookArgs> {
  @override
  StoryHookState build(StoryHookArgs arg) {
    _load(arg.place, arg.language);
    return StoryHookState.loading();
  }

  /// 重新載入當前 [arg] 對應的故事鉤子。
  Future<void> load() => _load(arg.place, arg.language);

  Future<void> _load(Place place, Language language) async {
    state = StoryHookState.loading();
    try {
      final hooks = await ref
          .read(storyHookServiceProvider)
          .generateHooks(place: place, language: language);
      if (hooks.isEmpty) {
        state = const StoryHookState(status: StoryHookStatus.empty);
        return;
      }
      state = StoryHookState(status: StoryHookStatus.success, hooks: hooks);
    } on AppError catch (e) {
      if (e.type == NarrationError.insufficientSource) {
        state = StoryHookState(
          status: StoryHookStatus.insufficientSource,
          errorMessage: e.message,
        );
        return;
      }
      state = StoryHookState(
        status: StoryHookStatus.error,
        errorMessage: e.message,
      );
    }
  }
}
