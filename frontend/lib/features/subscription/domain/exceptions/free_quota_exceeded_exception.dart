/// 免費額度已用完例外
///
/// 當免費用戶的每日使用次數已達上限時拋出
class FreeQuotaExceededException implements Exception {
  final String message;

  FreeQuotaExceededException([this.message = '已達今日免費使用上限']);

  @override
  String toString() => message;
}
