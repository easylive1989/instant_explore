/// 導覽錯誤類型
///
/// 定義所有可能的導覽生成和播放錯誤類型
enum NarrationErrorType {
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

  /// 內容生成失敗（生成的內容為空或無效）
  contentGenerationFailed,

  /// TTS 播放錯誤
  ttsPlaybackError,

  /// 未知錯誤
  unknown,
}

/// NarrationErrorType 擴展 - 提供錯誤訊息 mapping
extension NarrationErrorTypeExtension on NarrationErrorType {
  /// 取得用戶友善的錯誤訊息（繁體中文）
  String get message {
    switch (this) {
      case NarrationErrorType.aiQuotaExceeded:
        return '您已達到每日 AI 使用額度上限。請稍後再試。';
      case NarrationErrorType.networkError:
        return '網路連線失敗，請檢查您的網路連線後重試。';
      case NarrationErrorType.configurationError:
        return '應用程式配置錯誤，請聯絡技術支援。';
      case NarrationErrorType.serverError:
        return '伺服器暫時無法處理您的請求，請稍後再試。';
      case NarrationErrorType.unsupportedLocation:
        return '很抱歉，此服務在您所在的地區尚未開放。';
      case NarrationErrorType.contentGenerationFailed:
        return '無法生成導覽內容，請重試或選擇其他地點。';
      case NarrationErrorType.ttsPlaybackError:
        return '語音播放失敗，請檢查設備設定。';
      case NarrationErrorType.unknown:
        return '發生未預期的錯誤，請重試。';
    }
  }

  /// 是否為可重試的錯誤
  bool get isRetryable {
    switch (this) {
      case NarrationErrorType.aiQuotaExceeded:
      case NarrationErrorType.networkError:
      case NarrationErrorType.serverError:
      case NarrationErrorType.contentGenerationFailed:
        return true;
      default:
        return false;
    }
  }

  /// 建議的重試等待時間（秒）
  int? get suggestedRetryDelay {
    switch (this) {
      case NarrationErrorType.aiQuotaExceeded:
        return 900; // 15 分鐘
      case NarrationErrorType.networkError:
        return 5;
      case NarrationErrorType.serverError:
        return 30;
      case NarrationErrorType.contentGenerationFailed:
        return 3;
      default:
        return null;
    }
  }

  /// 是否需要顯示特殊對話框
  bool get requiresSpecialDialog {
    return this == NarrationErrorType.aiQuotaExceeded;
  }
}
