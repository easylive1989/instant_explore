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

  /// 生成的內容為空
  emptyContent,

  /// 未知錯誤
  unknown,
}

/// NarrationServiceErrorType 擴展
extension NarrationServiceErrorTypeExtension on NarrationServiceErrorType {
  /// 取得用戶友善的錯誤訊息（繁體中文）
  String get message {
    switch (this) {
      case NarrationServiceErrorType.aiQuotaExceeded:
        return '您已達到每日 AI 使用額度上限。請稍後再試。';
      case NarrationServiceErrorType.networkError:
        return '網路連線失敗，請檢查您的網路連線後重試。';
      case NarrationServiceErrorType.configurationError:
        return '應用程式配置錯誤，請聯絡技術支援。';
      case NarrationServiceErrorType.serverError:
        return '伺服器暫時無法處理您的請求，請稍後再試。';
      case NarrationServiceErrorType.unsupportedLocation:
        return '很抱歉，此服務在您所在的地區尚未開放。';
      case NarrationServiceErrorType.emptyContent:
        return '無法生成導覽內容，請重試或選擇其他地點。';
      case NarrationServiceErrorType.unknown:
        return '發生未預期的錯誤，請重試。';
    }
  }

  /// 是否為可重試的錯誤
  bool get isRetryable {
    switch (this) {
      case NarrationServiceErrorType.aiQuotaExceeded:
      case NarrationServiceErrorType.networkError:
      case NarrationServiceErrorType.serverError:
      case NarrationServiceErrorType.emptyContent:
        return true;
      default:
        return false;
    }
  }

  /// 建議的重試等待時間（秒）
  int? get suggestedRetryDelay {
    switch (this) {
      case NarrationServiceErrorType.aiQuotaExceeded:
        return 900; // 15 分鐘
      case NarrationServiceErrorType.networkError:
        return 5;
      case NarrationServiceErrorType.serverError:
        return 30;
      case NarrationServiceErrorType.emptyContent:
        return 3;
      default:
        return null;
    }
  }

  /// 是否需要顯示特殊對話框
  bool get requiresSpecialDialog {
    return this == NarrationServiceErrorType.aiQuotaExceeded;
  }
}
