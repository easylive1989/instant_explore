/// 獎勵廣告服務介面
///
/// 管理獎勵廣告的載入、顯示和生命週期
abstract class RewardedAdService {
  /// 預先載入廣告
  Future<void> loadAd();

  /// 顯示廣告，回傳使用者是否完整觀看
  Future<bool> showAd();

  /// 廣告是否已準備好可以播放
  bool get isAdReady;

  /// 釋放資源
  void dispose();
}
