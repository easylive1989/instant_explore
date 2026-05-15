import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// 根據景點產生 2-3 個歷史故事鉤子的服務。
///
/// 每個鉤子包含一個吸睛的標題與一句吊胃口的開頭，
/// 使用者挑選後再以該鉤子展開完整的歷史 narration。
abstract class StoryHookService {
  /// 為指定地點產生故事鉤子清單。
  ///
  /// 失敗時拋出 [AppError]（NarrationError）。回傳清單可能為空，
  /// 由呼叫端決定如何顯示 fallback。
  Future<List<StoryHook>> generateHooks({
    required Place place,
    required Language language,
  });
}
