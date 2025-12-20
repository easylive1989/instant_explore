import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

abstract class NarrationService {
  /// 生成導覽內容
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [language] 語言
  /// 返回導覽內容值對象
  Future<NarrationContent> generateNarration({
    required Place place,
    required NarrationAspect aspect,
    required Language language,
  });
}
