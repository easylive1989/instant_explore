/// 景點類型分類
///
/// 用於將 Google Places API 的原始類型對應到五種主要景點類型
enum PlaceCategory {
  /// 人文古蹟類 (Historical & Cultural Sites)
  /// 如：寺廟、古城、皇宮、故居
  historicalCultural,

  /// 自然景觀類 (Natural Landscapes)
  /// 如：高山、湖泊、峽谷、國家公園
  naturalLandscape,

  /// 現代地標與城市類 (Modern Landmarks & Urban)
  /// 如：摩天大樓、購物區、地標建築
  modernUrban,

  /// 博物館與藝術展覽類 (Museums & Arts)
  /// 如：博物館、美術館、畫廊
  museumArt,

  /// 在地美食與夜市類 (Local Food & Night Markets)
  /// 如：夜市、美食街、特色餐廳
  foodMarket,
}
