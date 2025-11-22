/// Places API 基礎異常
abstract class PlacesException implements Exception {
  final String message;
  final int? statusCode;

  PlacesException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'PlacesException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// API 金鑰錯誤
class ApiKeyException extends PlacesException {
  ApiKeyException([String? message])
    : super(message ?? 'Google Places API Key 未設定或無效', 401);
}

/// 網路錯誤
class NetworkException extends PlacesException {
  NetworkException([String? message]) : super(message ?? '無法連接到伺服器，請檢查網路連線');
}

/// 請求超時
class TimeoutException extends PlacesException {
  TimeoutException([String? message]) : super(message ?? '請求超時，請稍後再試');
}

/// 配額超限
class QuotaExceededException extends PlacesException {
  QuotaExceededException() : super('API 請求超過限額，請稍後再試', 429);
}

/// API 回應錯誤
class ApiResponseException extends PlacesException {
  ApiResponseException(super.message, [super.statusCode]);
}
