import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

abstract class NarrationService {
  /// 生成導覽內容文本
  ///
  /// [place] 地點資訊
  /// [aspect] 導覽介紹面向
  /// [language] 語言
  /// 返回生成的導覽文本
  /// 拋出 NarrationServiceException 如果服務呼叫失敗
  Future<String> generateNarration({
    required Place place,
    required NarrationAspect aspect,
    required Language language,
  });
}
