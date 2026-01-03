import 'package:context_app/core/errors/app_error_type.dart';

/// 訂閱與權益功能錯誤類型
enum SubscriptionError implements AppErrorType {
  /// 免費配額已用完
  freeQuotaExceeded,

  /// 載入權益失敗
  loadEntitlementFailed,

  /// 購買失敗
  purchaseFailed,

  /// 恢復購買失敗
  restoreFailed,

  /// 權益驗證失敗
  verificationFailed,

  /// 網路連線錯誤
  networkError,

  /// 未知錯誤
  unknown;

  @override
  String get code => 'SUBSCRIPTION_${name.toUpperCase()}';
}
