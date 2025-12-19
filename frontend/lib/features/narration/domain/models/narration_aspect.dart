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

  /// 今昔對比 - 連結現代生活，讓遊客產生共鳴
  relevance,

  // ========== 自然景觀類 (Natural Landscapes) ==========
  /// 地理成因 - 用簡單的比喻解釋地貌形成
  geology,

  /// 最佳拍攝點 - 告訴遊客哪裡拍最美
  photoSpots,

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

  /// 周邊生活機能 - 哪裡好逛、哪裡是在地人去的
  lifestyle,

  // ========== 博物館與藝術展覽類 (Museums & Arts) ==========
  /// 鎮館之寶 - 先帶大家看最重要的
  highlights,

  /// 作品背後的情感 - 藝術家創作時的心情或處境
  emotion,

  /// 引導觀察 - 教遊客「怎麼看」
  guidance,

  /// 策展脈絡 - 為什麼這些東西被擺在一起
  context,

  // ========== 在地美食與夜市類 (Local Food & Night Markets) ==========
  /// 食材與產地 - 為什麼這裡的好吃
  ingredients,

  /// 正確吃法 - 展現道地行家的吃法
  etiquette,

  /// 店家的故事 - 老店的堅持或傳承
  brandStory,

  /// 口感描述 - 用形容詞預告味道
  sensory;

  /// 根據景點類型取得可用的介紹面向
  static List<NarrationAspect> getAspectsForCategory(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.historicalCultural:
        return [
          NarrationAspect.historicalBackground,
          NarrationAspect.architecture,
          NarrationAspect.customs,
          NarrationAspect.relevance,
        ];
      case PlaceCategory.naturalLandscape:
        return [
          NarrationAspect.geology,
          NarrationAspect.photoSpots,
          NarrationAspect.floraFauna,
          NarrationAspect.myths,
        ];
      case PlaceCategory.modernUrban:
        return [
          NarrationAspect.designConcept,
          NarrationAspect.statistics,
          NarrationAspect.status,
          NarrationAspect.lifestyle,
        ];
      case PlaceCategory.museumArt:
        return [
          NarrationAspect.highlights,
          NarrationAspect.emotion,
          NarrationAspect.guidance,
          NarrationAspect.context,
        ];
      case PlaceCategory.foodMarket:
        return [
          NarrationAspect.ingredients,
          NarrationAspect.etiquette,
          NarrationAspect.brandStory,
          NarrationAspect.sensory,
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
      case 'relevance':
        return NarrationAspect.relevance;
      // 自然景觀類
      case 'geology':
        return NarrationAspect.geology;
      case 'photo_spots':
        return NarrationAspect.photoSpots;
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
      case 'lifestyle':
        return NarrationAspect.lifestyle;
      // 博物館與藝術展覽類
      case 'highlights':
        return NarrationAspect.highlights;
      case 'emotion':
        return NarrationAspect.emotion;
      case 'guidance':
        return NarrationAspect.guidance;
      case 'context':
        return NarrationAspect.context;
      // 在地美食與夜市類
      case 'ingredients':
        return NarrationAspect.ingredients;
      case 'etiquette':
        return NarrationAspect.etiquette;
      case 'brand_story':
        return NarrationAspect.brandStory;
      case 'sensory':
        return NarrationAspect.sensory;
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
      case NarrationAspect.relevance:
        return 'relevance';
      // 自然景觀類
      case NarrationAspect.geology:
        return 'geology';
      case NarrationAspect.photoSpots:
        return 'photo_spots';
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
      case NarrationAspect.lifestyle:
        return 'lifestyle';
      // 博物館與藝術展覽類
      case NarrationAspect.highlights:
        return 'highlights';
      case NarrationAspect.emotion:
        return 'emotion';
      case NarrationAspect.guidance:
        return 'guidance';
      case NarrationAspect.context:
        return 'context';
      // 在地美食與夜市類
      case NarrationAspect.ingredients:
        return 'ingredients';
      case NarrationAspect.etiquette:
        return 'etiquette';
      case NarrationAspect.brandStory:
        return 'brand_story';
      case NarrationAspect.sensory:
        return 'sensory';
    }
  }
}
