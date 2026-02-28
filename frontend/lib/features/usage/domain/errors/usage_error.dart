import 'package:context_app/core/errors/app_error_type.dart';

/// 使用額度相關錯誤類型
enum UsageError implements AppErrorType {
  /// 每日免費額度已用完
  dailyQuotaExceeded;

  @override
  String get code => 'USAGE_${name.toUpperCase()}';
}
