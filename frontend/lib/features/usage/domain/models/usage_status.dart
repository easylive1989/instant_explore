/// 每日使用額度狀態
///
/// 追蹤使用者當日已使用次數、免費額度與廣告獎勵額度
class UsageStatus {
  final int usedToday;
  final int dailyFreeLimit;
  final int bonusFromAds;

  const UsageStatus({
    required this.usedToday,
    this.dailyFreeLimit = 1,
    this.bonusFromAds = 0,
  });

  /// 今日可用總次數（免費 + 廣告獎勵）
  int get totalAvailable => dailyFreeLimit + bonusFromAds;

  /// 今日剩餘次數
  int get remaining => (totalAvailable - usedToday).clamp(0, totalAvailable);

  /// 是否還可以使用導覽
  bool get canUseNarration => remaining > 0;
}
