import 'package:context_app/features/explore/domain/models/place_category.dart';

/// 導覽介紹面向
///
/// 根據景點類型提供不同的介紹面向選擇
enum NarrationAspect {
  // ========== 人文古蹟類 (Historical & Cultural Sites) ==========
  /// 歷史背景 - 講述「人」的故事
  historicalBackground,

  /// 建築細節 - 解讀肉眼看不到的象徵意義
  architecture,

  /// 文化禁忌與習俗 - 告訴遊客該怎麼做、為什麼這麼做
  customs,

  // ========== 自然景觀類 (Natural Landscapes) ==========
  /// 地理成因 - 用簡單的比喻解釋地貌形成
  geology,

  /// 生態觀察 - 介紹特有動植物
  floraFauna,

  /// 傳說故事 - 賦予山水靈性
  myths,

  // ========== 現代地標與城市類 (Modern Landmarks & Urban) ==========
  /// 設計理念 - 建築師想表達什麼
  designConcept,

  /// 數據震撼 - 用具體的數字創造驚奇感
  statistics,

  /// 經濟與社會地位 - 這裡代表了這座城市的什麼地位
  status,

  // ========== 在地美食與夜市類 (Local Food & Night Markets) ==========
  /// 食材與產地 - 為什麼這裡的好吃
  ingredients,

  /// 正確吃法 - 展現道地行家的吃法
  etiquette,

  /// 店家的故事 - 老店的堅持或傳承
  brandStory;

  /// 根據景點類型取得可用的介紹面向
  static List<NarrationAspect> getAspectsForCategory(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.historicalCultural:
        return [
          NarrationAspect.historicalBackground,
          NarrationAspect.architecture,
          NarrationAspect.customs,
        ];
      case PlaceCategory.naturalLandscape:
        return [
          NarrationAspect.geology,
          NarrationAspect.floraFauna,
          NarrationAspect.myths,
        ];
      case PlaceCategory.modernUrban:
        return [
          NarrationAspect.designConcept,
          NarrationAspect.statistics,
          NarrationAspect.status,
        ];
      case PlaceCategory.museumArt:
        // 博物館類使用人文古蹟類的面向
        return [
          NarrationAspect.historicalBackground,
          NarrationAspect.architecture,
          NarrationAspect.customs,
        ];
      case PlaceCategory.foodMarket:
        return [
          NarrationAspect.ingredients,
          NarrationAspect.etiquette,
          NarrationAspect.brandStory,
        ];
    }
  }

  /// 取得預設的介紹面向（每個類型的第一個）
  static NarrationAspect getDefaultAspectForCategory(PlaceCategory category) {
    return getAspectsForCategory(category).first;
  }

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
  String toApiString() {
    switch (this) {
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
