import 'package:context_app/core/errors/app_error_type.dart';

/// 定位相關錯誤，供探索頁依狀態顯示不同引導。
enum LocationError implements AppErrorType {
  /// 系統定位服務關閉（非 App 權限問題）。
  serviceDisabled,

  /// App 定位權限被拒，但仍可再次請求。
  permissionDenied,

  /// App 定位權限永久被拒，需到設定手動開啟。
  permissionDeniedForever;

  @override
  String get code => 'LOCATION_${name.toUpperCase()}';
}
