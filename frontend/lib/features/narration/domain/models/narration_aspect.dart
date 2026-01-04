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
}
