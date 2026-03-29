import 'package:context_app/features/narration/domain/models/narration_aspect.dart';

/// NarrationAspect 的資料轉換器
class NarrationAspectMapper {
  /// 從字串解析
  static NarrationAspect? fromString(String value) {
    switch (value) {
      case 'historical_background':
        return NarrationAspect.historicalBackground;
      case 'architecture':
        return NarrationAspect.architecture;
      case 'customs':
        return NarrationAspect.customs;
      case 'geology':
        return NarrationAspect.geology;
      case 'myths':
        return NarrationAspect.myths;
      default:
        return null;
    }
  }

  /// 轉換為 API 字串
  static String toApiString(NarrationAspect aspect) {
    switch (aspect) {
      case NarrationAspect.historicalBackground:
        return 'historical_background';
      case NarrationAspect.architecture:
        return 'architecture';
      case NarrationAspect.customs:
        return 'customs';
      case NarrationAspect.geology:
        return 'geology';
      case NarrationAspect.myths:
        return 'myths';
    }
  }
}
