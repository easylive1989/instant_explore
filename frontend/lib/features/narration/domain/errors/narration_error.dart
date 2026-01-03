import 'package:context_app/core/errors/app_error_type.dart';

/// 導覽功能錯誤類型
enum NarrationError implements AppErrorType {
  /// 免費使用額度已用完（訂閱層面）
  freeQuotaExceeded,

  /// 網路連線錯誤
  networkError,

  /// API 配置錯誤（API key 無效或缺失）
  configurationError,

  /// 伺服器錯誤（API 內部錯誤）
  serverError,

  /// 地理位置不支援
  unsupportedLocation,

  /// 內容生成失敗（生成的內容為空或無效）
  contentGenerationFailed,

  /// TTS 播放錯誤
  ttsPlaybackError,

  /// 未知錯誤
  unknown;

  @override
  String get code => 'NARRATION_${name.toUpperCase()}';
}
