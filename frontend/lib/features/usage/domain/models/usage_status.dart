/// 每日使用額度狀態
///
/// 追蹤使用者當日已使用次數與免費額度
class UsageStatus {
  final int usedToday;
  final int dailyFreeLimit;

  const UsageStatus({required this.usedToday, this.dailyFreeLimit = 1});

  /// 今日可用總次數
  int get totalAvailable => dailyFreeLimit;

  /// 今日剩餘次數
  int get remaining => (totalAvailable - usedToday).clamp(0, totalAvailable);

  /// 是否還可以使用導覽
  bool get canUseNarration => remaining > 0;

  /// 是否還可以使用（與 canUseNarration 相同，語意更通用）
  bool get canUse => remaining > 0;
}
