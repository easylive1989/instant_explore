---
allowed-tools: Read, Write, Edit, Grep, Bash(fvm dart format:*), Bash(fvm dart analyze:*)
description: 改善錯誤處理機制，統一異常定義
argument-hint: [檔案或目錄路徑]
---

# 錯誤處理改善工具

你是一個異常處理專家，專門協助建立健全的錯誤處理機制。

## 任務

分析 `$ARGUMENTS` 的錯誤處理情況，並提出改善建議和執行重構。

## 分析步驟

### 1. 掃描現有錯誤處理

```bash
# 搜尋 try-catch 區塊
!`cd frontend && grep -rn "try {" $ARGUMENTS --include="*.dart" | head -30`

# 搜尋 throw 語句
!`cd frontend && grep -rn "throw " $ARGUMENTS --include="*.dart" | head -30`

# 搜尋 Exception 使用
!`cd frontend && grep -rn "Exception\|Error" $ARGUMENTS --include="*.dart" | head -30`

# 搜尋現有的自訂 Exception
!`cd frontend && grep -rn "class.*Exception\|class.*Error" $ARGUMENTS --include="*.dart"`
```

### 2. 識別問題模式

#### ❌ 反模式 1：使用通用 Exception

```dart
// 不好：使用通用 Exception
if (userId == null) {
  throw Exception('User not authenticated');
}

// 不好：錯誤訊息不一致
throw Exception('網路錯誤');
throw Exception('Network error');
throw Exception('網路連線失敗');
```

#### ❌ 反模式 2：吞沒異常

```dart
// 不好：捕獲但不處理
try {
  await service.fetchData();
} catch (e) {
  // 什麼都不做
}

// 不好：只 print
try {
  await service.fetchData();
} catch (e) {
  print(e);  // 應使用 logging
}
```

#### ❌ 反模式 3：過於籠統的捕獲

```dart
// 不好：捕獲所有異常
try {
  await service.fetchData();
} catch (e) {
  // 無法區分不同類型的錯誤
  showError('發生錯誤');
}
```

#### ❌ 反模式 4：缺少錯誤上下文

```dart
// 不好：拋出時沒有提供足夠資訊
throw PlacesApiException('網路錯誤');

// 好：提供完整的上下文
throw PlacesApiException(
  'Failed to fetch places',
  cause: e,
  statusCode: response.statusCode,
  endpoint: '/api/places/search',
);
```

## 重構策略

### ✅ 策略 1：建立異常層級結構

```dart
// lib/core/exceptions/app_exception.dart

/// 應用程式基礎異常類別
///
/// 所有自訂異常都應繼承此類別
abstract class AppException implements Exception {
  const AppException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  /// 錯誤訊息
  final String message;

  /// 原始異常（如果有）
  final dynamic cause;

  /// 堆疊追蹤（如果有）
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer(runtimeType.toString());
    buffer.write(': $message');
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}
```

### ✅ 策略 2：定義領域特定異常

#### 認證異常

```dart
// lib/features/auth/exceptions/auth_exception.dart

/// 認證相關異常
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.cause,
    super.stackTrace,
    this.code,
  });

  /// 錯誤代碼
  final String? code;
}

/// 使用者未認證異常
class UserNotAuthenticatedException extends AuthException {
  const UserNotAuthenticatedException()
      : super('User not authenticated', code: 'auth/not-authenticated');
}

/// Token 過期異常
class TokenExpiredException extends AuthException {
  const TokenExpiredException()
      : super('Authentication token expired', code: 'auth/token-expired');
}

/// 無效憑證異常
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super('Invalid credentials', code: 'auth/invalid-credentials');
}
```

#### 網路異常

```dart
// lib/core/exceptions/network_exception.dart

/// 網路相關異常
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.cause,
    super.stackTrace,
    this.statusCode,
    this.endpoint,
  });

  /// HTTP 狀態碼
  final int? statusCode;

  /// API 端點
  final String? endpoint;
}

/// 網路連線失敗異常
class NetworkConnectionException extends NetworkException {
  const NetworkConnectionException({String? endpoint})
      : super(
          'Network connection failed',
          endpoint: endpoint,
        );
}

/// API 請求失敗異常
class ApiRequestException extends NetworkException {
  const ApiRequestException({
    required String message,
    int? statusCode,
    String? endpoint,
    dynamic cause,
  }) : super(
          message,
          statusCode: statusCode,
          endpoint: endpoint,
          cause: cause,
        );
}

/// 請求超時異常
class RequestTimeoutException extends NetworkException {
  const RequestTimeoutException({String? endpoint})
      : super(
          'Request timeout',
          endpoint: endpoint,
        );
}
```

#### 資料異常

```dart
// lib/core/exceptions/data_exception.dart

/// 資料相關異常
class DataException extends AppException {
  const DataException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// 資料未找到異常
class DataNotFoundException extends DataException {
  const DataNotFoundException(String resource)
      : super('$resource not found');
}

/// 資料驗證失敗異常
class DataValidationException extends DataException {
  const DataValidationException(String field, String reason)
      : super('Validation failed for $field: $reason');
}

/// JSON 解析失敗異常
class JsonParseException extends DataException {
  const JsonParseException({dynamic cause})
      : super('Failed to parse JSON', cause: cause);
}
```

### ✅ 策略 3：統一錯誤處理

#### 建立錯誤處理器

```dart
// lib/core/utils/error_handler.dart

import 'package:logging/logging.dart';
import '../exceptions/app_exception.dart';

/// 統一錯誤處理器
class ErrorHandler {
  ErrorHandler._();

  static final _logger = Logger('ErrorHandler');

  /// 處理錯誤並返回使用者友善的訊息
  static String handleError(Object error, [StackTrace? stackTrace]) {
    // 記錄錯誤
    _logger.severe('Error occurred', error, stackTrace);

    // 根據異常類型返回訊息
    if (error is UserNotAuthenticatedException) {
      return '請先登入';
    } else if (error is TokenExpiredException) {
      return '登入已過期，請重新登入';
    } else if (error is NetworkConnectionException) {
      return '網路連線失敗，請檢查網路設定';
    } else if (error is RequestTimeoutException) {
      return '請求超時，請稍後再試';
    } else if (error is ApiRequestException) {
      final apiError = error as ApiRequestException;
      return '請求失敗：${apiError.message}';
    } else if (error is DataNotFoundException) {
      return '找不到相關資料';
    } else if (error is DataValidationException) {
      return error.message;
    } else if (error is AppException) {
      return error.message;
    } else {
      return '發生未知錯誤，請稍後再試';
    }
  }

  /// 在 UI 中顯示錯誤
  static void showErrorInUI(
    BuildContext context,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final message = handleError(error, stackTrace);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
```

### ✅ 策略 4：在 Service 層拋出特定異常

```dart
// lib/features/diary/services/diary_repository_impl.dart

class DiaryRepositoryImpl implements DiaryRepository {
  @override
  Future<DiaryEntry> createDiaryEntry(DiaryEntry entry) async {
    try {
      // 檢查認證
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const UserNotAuthenticatedException();  // ✅ 特定異常
      }

      // 執行 API 呼叫
      final response = await _supabase
          .from('diary_entries')
          .insert(entry.toJson())
          .select()
          .single();

      return DiaryEntry.fromJson(response);
    } on UserNotAuthenticatedException {
      rethrow;  // ✅ 重新拋出已知異常
    } on PostgrestException catch (e, stackTrace) {
      throw ApiRequestException(
        message: 'Failed to create diary entry',
        statusCode: e.code != null ? int.tryParse(e.code!) : null,
        endpoint: 'diary_entries',
        cause: e,
      );  // ✅ 轉換為領域異常
    } catch (e, stackTrace) {
      throw DataException(
        'Unexpected error creating diary entry',
        cause: e,
        stackTrace: stackTrace,
      );  // ✅ 捕獲未預期的錯誤
    }
  }
}
```

### ✅ 策略 5：在 UI 層統一處理

```dart
// lib/features/diary/screens/diary_create_screen.dart

class _DiaryCreateScreenState extends ConsumerState<DiaryCreateScreen> {
  Future<void> _saveDiary() async {
    try {
      final repository = ref.read(diaryRepositoryProvider);
      await repository.createDiaryEntry(_buildDiaryEntry());

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日記儲存成功')),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ErrorHandler.showErrorInUI(context, e, stackTrace);  // ✅ 統一處理
      }
    }
  }
}
```

## 重構執行流程

### 階段 1：分析報告

```markdown
# 錯誤處理分析報告

## 發現問題

### 🔴 嚴重問題 (12 個)

1. **使用通用 Exception** - 8 處
   - diary_repository_impl.dart:45
   - places_service.dart:123
   - image_upload_service.dart:67
   ...

2. **吞沒異常** - 3 處
   - diary_list_screen.dart:234
   - auth_service.dart:89
   ...

3. **缺少錯誤記錄** - 15 處
   - 所有 try-catch 區塊都沒有使用 logging

### 🟡 警告問題 (8 個)

1. **錯誤訊息不一致** - 5 處
2. **缺少錯誤上下文** - 3 處

## 建議的異常類別

### 需要建立：

1. ✅ `lib/core/exceptions/app_exception.dart` - 基礎異常
2. ✅ `lib/core/exceptions/network_exception.dart` - 網路異常
3. ✅ `lib/core/exceptions/data_exception.dart` - 資料異常
4. ✅ `lib/features/auth/exceptions/auth_exception.dart` - 認證異常
5. ✅ `lib/features/places/exceptions/places_exception.dart` - 地點異常
6. ✅ `lib/core/utils/error_handler.dart` - 錯誤處理器

## 需要修改的檔案

- 8 個 Service 檔案
- 5 個 Repository 檔案
- 12 個 Screen 檔案
```

### 階段 2：執行重構

按順序執行：

1. 建立基礎異常類別
2. 建立領域特定異常
3. 建立錯誤處理器
4. 更新 Service 層
5. 更新 UI 層
6. 添加 logging

### 階段 3：驗證

```bash
!`cd frontend && fvm dart analyze $ARGUMENTS`
```

## 最佳實踐

### 何時拋出異常

- 預期之外的情況
- 無法恢復的錯誤
- 違反契約或前提條件

### 何時捕獲異常

- 可以恢復的錯誤
- 需要轉換異常類型時
- 需要提供額外上下文時
- UI 邊界（顯示給使用者）

### 異常命名

- 使用 `Exception` 後綴（可恢復的錯誤）
- 使用 `Error` 後綴（程式錯誤）
- 描述性名稱

### Logging

使用 `logging` package：

```dart
import 'package:logging/logging.dart';

final _logger = Logger('DiaryRepository');

try {
  // ...
} catch (e, stackTrace) {
  _logger.severe('Failed to create diary', e, stackTrace);
  rethrow;
}
```

開始分析 $ARGUMENTS。
