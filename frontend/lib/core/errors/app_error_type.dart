/// 應用程式錯誤類型基礎介面
///
/// 所有業務模組的錯誤 Enum 都應實作此介面
/// 提供統一的錯誤代碼格式
abstract class AppErrorType {
  /// 錯誤代碼，格式為 "MODULE_ERROR_NAME"
  /// 例如：AUTH_WRONG_PASSWORD, NARRATION_AI_QUOTA_EXCEEDED
  String get code;
}
