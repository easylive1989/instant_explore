/// 通行證類型
///
/// 定義可購買的通行證類型及其相關屬性
/// 價格從 RevenueCat 動態取得，不在此硬編碼
enum PassType {
  /// 一日券 - 24 小時有效
  dayPass('contexture_day_pass', Duration(hours: 24)),

  /// 一週券 - 7 天有效
  tripPass('contexture_trip_pass', Duration(days: 7));

  const PassType(this.productId, this.duration);

  /// 商店產品 ID（Google Play / App Store）
  final String productId;

  /// 有效期間
  final Duration duration;

  /// 根據產品 ID 取得對應的 PassType
  static PassType? fromProductId(String productId) {
    for (final type in PassType.values) {
      if (type.productId == productId) {
        return type;
      }
    }
    return null;
  }
}
