import 'package:context_app/features/explore/domain/models/place_category.dart';

/// 導覽介紹面向
enum NarrationAspect {
  /// 歷史背景 - 講述「人」的故事
  historicalBackground,

  /// 建築細節 - 解讀肉眼看不到的象徵意義
  architecture,

  /// 文化禁忌與習俗 - 告訴遊客該怎麼做、為什麼這麼做
  customs,

  /// 地理成因 - 用簡單的比喻解釋地貌形成
  geology,

  /// 傳說故事 - 賦予山水靈性
  myths;

  /// 所有景點類型皆支援所有介紹面向
  static List<NarrationAspect> getAspectsForCategory(PlaceCategory category) =>
      NarrationAspect.values;
}
