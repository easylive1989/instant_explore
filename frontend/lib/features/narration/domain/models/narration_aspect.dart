import 'package:context_app/features/explore/domain/models/place_category.dart';

/// 導覽介紹面向
enum NarrationAspect {
  /// 歷史背景 - 講述「人」的故事
  historicalBackground('historical_background'),

  /// 建築細節 - 解讀肉眼看不到的象徵意義
  architecture('architecture'),

  /// 文化禁忌與習俗 - 告訴遊客該怎麼做、為什麼這麼做
  customs('customs'),

  /// 地理成因 - 用簡單的比喻解釋地貌形成
  geology('geology'),

  /// 傳說故事 - 賦予山水靈性
  myths('myths');

  const NarrationAspect(this.key);

  /// 用於序列化與 API 通訊的識別鍵值
  final String key;

  /// 從字串還原為 [NarrationAspect]，找不到時回傳 null
  static NarrationAspect? fromKey(String value) {
    for (final aspect in values) {
      if (aspect.key == value) return aspect;
    }
    return null;
  }

  /// 所有景點類型皆支援所有介紹面向
  static List<NarrationAspect> getAspectsForCategory(PlaceCategory category) =>
      NarrationAspect.values;
}
