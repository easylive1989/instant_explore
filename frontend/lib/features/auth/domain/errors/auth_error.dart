import 'package:context_app/core/errors/app_error_type.dart';

/// 認證功能錯誤類型
enum AuthError implements AppErrorType {
  /// 使用者未找到
  userNotFound,

  /// 密碼錯誤
  wrongPassword,

  /// Email 已被使用
  emailAlreadyInUse,

  /// Email 格式無效
  invalidEmail,

  /// 密碼太弱
  weakPassword,

  /// 登入失敗
  signInFailed,

  /// 登出失敗
  signOutFailed,

  /// 權限不足
  permissionDenied,

  /// 網路連線錯誤
  networkError,

  /// 未知錯誤
  unknown;

  @override
  String get code => 'AUTH_${name.toUpperCase()}';
}
