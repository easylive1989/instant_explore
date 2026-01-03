import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/narration/domain/errors/narration_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/services/narration_service.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// 測試用的假導覽服務
///
/// 回傳預設的導覽文字，模擬 Gemini API
class FakeNarrationService implements NarrationService {
  /// 預設的測試導覽內容
  static const defaultNarrationText = '''
歡迎來到這個美麗的景點。

這是第一段導覽內容，介紹這個地方的基本資訊。這裡有許多值得探索的歷史和文化背景。

接下來是第二段，讓我們深入了解這個地方的特色。無論是建築風格還是文化意涵，都非常值得細細品味。

最後一段，我們來總結今天的導覽。希望您在這裡度過愉快的時光，也歡迎您繼續探索更多景點。
''';

  /// 可自訂的回傳內容（用於特定測試場景）
  String? customNarrationText;

  /// 模擬延遲時間（毫秒）
  int delayMs;

  /// 是否模擬錯誤
  bool shouldThrowError;

  FakeNarrationService({
    this.customNarrationText,
    this.delayMs = 200,
    this.shouldThrowError = false,
  });

  @override
  Future<String> generateNarration({
    required Place place,
    required NarrationAspect aspect,
    required Language language,
  }) async {
    // 模擬網路延遲
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    if (shouldThrowError) {
      throw const AppError(
        type: NarrationError.unknown,
        message: 'Fake error for testing',
      );
    }

    return customNarrationText ?? defaultNarrationText;
  }
}
