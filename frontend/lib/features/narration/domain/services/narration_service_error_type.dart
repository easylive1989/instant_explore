/// 導覽服務錯誤類型
///
/// 定義與 AI 服務呼叫相關的錯誤類型
/// 這些錯誤不屬於 UseCase 的業務邏輯錯誤
enum NarrationServiceErrorType {
  /// AI 配額已超過限制
  aiQuotaExceeded,

  /// 網路連線錯誤
  networkError,

  /// API 配置錯誤（API key 無效或缺失）
  configurationError,

  /// 伺服器錯誤（API 伺服器內部錯誤）
  serverError,

  /// 地理位置不支援
  unsupportedLocation,

  /// 未知錯誤
  unknown,
}
