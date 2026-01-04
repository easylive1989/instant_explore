import 'package:context_app/features/narration/domain/models/narration_aspect.dart';

/// NarrationAspect 的資料轉換器
class NarrationAspectMapper {
  /// 從字串解析
  static NarrationAspect? fromString(String value) {
    switch (value) {
      // 人文古蹟類
      case 'historical_background':
        return NarrationAspect.historicalBackground;
      case 'architecture':
        return NarrationAspect.architecture;
      case 'customs':
        return NarrationAspect.customs;
      // 自然景觀類
      case 'geology':
        return NarrationAspect.geology;
      case 'flora_fauna':
        return NarrationAspect.floraFauna;
      case 'myths':
        return NarrationAspect.myths;
      // 現代地標與城市類
      case 'design_concept':
        return NarrationAspect.designConcept;
      case 'statistics':
        return NarrationAspect.statistics;
      case 'status':
        return NarrationAspect.status;
      // 在地美食與夜市類
      case 'ingredients':
        return NarrationAspect.ingredients;
      case 'etiquette':
        return NarrationAspect.etiquette;
      case 'brand_story':
        return NarrationAspect.brandStory;
      default:
        return null;
    }
  }

  /// 轉換為 API 字串
  static String toApiString(NarrationAspect aspect) {
    switch (aspect) {
      // 人文古蹟類
      case NarrationAspect.historicalBackground:
        return 'historical_background';
      case NarrationAspect.architecture:
        return 'architecture';
      case NarrationAspect.customs:
        return 'customs';
      // 自然景觀類
      case NarrationAspect.geology:
        return 'geology';
      case NarrationAspect.floraFauna:
        return 'flora_fauna';
      case NarrationAspect.myths:
        return 'myths';
      // 現代地標與城市類
      case NarrationAspect.designConcept:
        return 'design_concept';
      case NarrationAspect.statistics:
        return 'statistics';
      case NarrationAspect.status:
        return 'status';
      // 在地美食與夜市類
      case NarrationAspect.ingredients:
        return 'ingredients';
      case NarrationAspect.etiquette:
        return 'etiquette';
      case NarrationAspect.brandStory:
        return 'brand_story';
    }
  }
}
