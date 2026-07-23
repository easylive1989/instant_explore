---
allowed-tools: Read, Write, Edit, Grep, Bash(fvm dart format:*), Bash(fvm dart analyze:*)
description: 提取 Magic Numbers 和硬編碼值為常數
argument-hint: [檔案或目錄路徑]
---

# 常數提取重構工具

你是一個程式碼品質專家，專門找出並提取硬編碼值為有意義的常數。

## 任務

找出 `$ARGUMENTS` 中的 Magic Numbers 和硬編碼值，並將其提取為常數定義。

## 分析步驟

### 1. 搜尋 Magic Numbers

使用 Grep 搜尋常見的魔術數字模式：

```bash
# 搜尋數字常數（排除 0, 1, 2）
!`cd frontend && grep -rn "[3-9][0-9]*\|[0-9][0-9]\+" $ARGUMENTS --include="*.dart" | grep -v "test" | head -50`

# 搜尋 BorderRadius
!`cd frontend && grep -rn "BorderRadius\.circular" $ARGUMENTS --include="*.dart" | head -30`

# 搜尋 EdgeInsets/Padding
!`cd frontend && grep -rn "EdgeInsets\|Padding" $ARGUMENTS --include="*.dart" | head -30`

# 搜尋 Duration
!`cd frontend && grep -rn "Duration" $ARGUMENTS --include="*.dart" | head -20`

# 搜尋 fontSize
!`cd frontend && grep -rn "fontSize:" $ARGUMENTS --include="*.dart" | head -20`
```

### 2. 分類 Magic Numbers

將發現的數字分類：

#### 🎨 UI 常數
- **Spacing**: padding, margin, gap
- **Radius**: border radius, circular radius
- **Size**: width, height, icon size
- **Font**: font size, font weight values

#### ⏱️ 時間常數
- **Duration**: animation duration, timeout
- **Delay**: debounce, throttle

#### 🔢 業務邏輯常數
- **Limits**: max items, max length
- **Thresholds**: scroll threshold, opacity threshold
- **Counts**: default page size, retry count

#### 🎯 配置常數
- **API**: endpoints, timeouts
- **App**: version codes, feature flags

## 反模式偵測

### ❌ 反模式：重複的數值

```dart
// 在多個檔案中出現
borderRadius: BorderRadius.circular(12)  // 出現 15 次
borderRadius: BorderRadius.circular(8)   // 出現 10 次
padding: EdgeInsets.all(16)              // 出現 20 次
```

### ❌ 反模式：無意義的數字

```dart
// 沒有說明這些數字的意義
const double _appBarThreshold = 20;
const double _appBarTransitionRange = 80.0;

// 更好的命名
const double _scrollOffsetBeforeHideAppBar = 20;
const double _appBarFadeTransitionPixels = 80.0;
```

### ❌ 反模式：內嵌的業務規則

```dart
// diary_create_screen.dart
if (_selectedImages.length >= 5) {  // 5 是什麼？
  // ...
}

// 應該定義為常數
static const int maxImagesPerDiary = 5;
if (_selectedImages.length >= maxImagesPerDiary) {
  // ...
}
```

## 重構策略

### ✅ 策略 1：集中定義 UI 常數

建立或更新 `lib/core/constants/` 下的常數檔案：

#### spacing_constants.dart

```dart
/// UI Spacing 常數定義
///
/// 遵循 8pt Grid System
class Spacing {
  Spacing._();

  /// 極小間距 - 4px
  static const double xs = 4.0;

  /// 小間距 - 8px
  static const double sm = 8.0;

  /// 中等間距 - 12px
  static const double md = 12.0;

  /// 標準間距 - 16px
  static const double lg = 16.0;

  /// 大間距 - 24px
  static const double xl = 24.0;

  /// 超大間距 - 32px
  static const double xxl = 32.0;
}
```

#### radius_constants.dart

```dart
/// Border Radius 常數定義
class Radius {
  Radius._();

  /// 小圓角 - 4px
  static const double sm = 4.0;

  /// 中圓角 - 8px
  static const double md = 8.0;

  /// 大圓角 - 12px
  static const double lg = 12.0;

  /// 超大圓角 - 16px
  static const double xl = 16.0;

  /// 圓形
  static const double circular = 999.0;
}
```

#### font_constants.dart

```dart
/// 字體大小常數定義
class FontSize {
  FontSize._();

  /// 標題
  static const double title = 22.0;

  /// 副標題
  static const double subtitle = 18.0;

  /// 正文
  static const double body = 16.0;

  /// 小字
  static const double small = 14.0;

  /// 極小字
  static const double tiny = 12.0;

  /// 標籤
  static const double label = 11.0;
}
```

#### duration_constants.dart

```dart
/// 動畫時長常數定義
class AnimationDuration {
  AnimationDuration._();

  /// 快速動畫 - 150ms
  static const Duration fast = Duration(milliseconds: 150);

  /// 標準動畫 - 300ms
  static const Duration standard = Duration(milliseconds: 300);

  /// 慢速動畫 - 500ms
  static const Duration slow = Duration(milliseconds: 500);
}
```

### ✅ 策略 2：特定 Feature 的常數

在 Feature 目錄內定義特定的常數：

```dart
// lib/features/diary/constants/diary_constants.dart
class DiaryConstants {
  DiaryConstants._();

  /// 每篇日記最多可上傳的圖片數量
  static const int maxImagesPerEntry = 5;

  /// 日記標題最大長度
  static const int maxTitleLength = 100;

  /// 日記內容最大長度
  static const int maxContentLength = 5000;

  /// 標籤最大數量
  static const int maxTagsCount = 10;
}
```

### ✅ 策略 3：使用現有常數

檢查專案中是否已有常數定義，優先使用現有的：

```bash
# 檢查現有的常數檔案
!`find lib/core/constants -name "*.dart" -type f 2>/dev/null`
```

## 重構執行流程

### 階段 1：分析報告

```markdown
# Magic Numbers 分析報告

## 統計概覽

- 掃描檔案：23 個
- 發現 Magic Numbers：87 個
- 重複數值：34 組

## 分類統計

### UI 常數 (45 個)

#### Border Radius
| 數值 | 出現次數 | 位置範例 |
|------|----------|----------|
| 12.0 | 15 | diary_card.dart:45, place_card.dart:67... |
| 8.0 | 10 | tag_input.dart:23, ... |
| 16.0 | 5 | ... |

#### Spacing/Padding
| 數值 | 出現次數 | 位置範例 |
|------|----------|----------|
| 16.0 | 20 | diary_list_screen.dart:123, ... |
| 12.0 | 12 | ... |
| 8.0 | 8 | ... |

#### Font Size
| 數值 | 出現次數 | 位置範例 |
|------|----------|----------|
| 16.0 | 8 | ... |
| 14.0 | 6 | ... |

### 時間常數 (12 個)

| 數值 | 出現次數 | 用途 |
|------|----------|------|
| Duration(milliseconds: 300) | 5 | 動畫時長 |
| Duration(milliseconds: 150) | 3 | 快速動畫 |

### 業務邏輯常數 (18 個)

| 數值 | 出現次數 | 用途 |
|------|----------|------|
| 5 | 3 | 最大圖片數量 |
| 20 | 2 | 滾動閾值 |

## 建議的常數定義

### 需要建立的檔案：

1. ✅ `lib/core/constants/spacing_constants.dart` - 已存在，需補充
2. ❌ `lib/core/constants/radius_constants.dart` - 需新建
3. ❌ `lib/core/constants/font_constants.dart` - 需新建
4. ❌ `lib/core/constants/duration_constants.dart` - 需新建
5. ❌ `lib/features/diary/constants/diary_constants.dart` - 需新建

### 預估改善：

- 移除 Magic Numbers：87 個
- 新增常數定義：~30 個
- 改善檔案：23 個
```

### 階段 2：執行重構

#### 步驟 1：建立/更新常數檔案

依序建立或更新各個常數檔案。

#### 步驟 2：替換使用處

針對每個發現的 Magic Number：

```dart
// ❌ 重構前
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    'Title',
    style: TextStyle(fontSize: 16),
  ),
)

// ✅ 重構後
import 'package:context_app/core/constants/spacing_constants.dart';
import 'package:context_app/core/constants/radius_constants.dart';
import 'package:context_app/core/constants/font_constants.dart';

Container(
  padding: EdgeInsets.all(Spacing.lg),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(Radius.lg),
  ),
  child: Text(
    'Title',
    style: TextStyle(fontSize: FontSize.body),
  ),
)
```

#### 步驟 3：更新 imports

確保每個檔案都 import 了需要的常數：

```dart
import 'package:context_app/core/constants/spacing_constants.dart';
import 'package:context_app/core/constants/radius_constants.dart';
```

#### 步驟 4：驗證

```bash
!`cd frontend && fvm dart format $ARGUMENTS`
!`cd frontend && fvm dart analyze $ARGUMENTS`
```

### 階段 3：完成報告

```markdown
# 常數提取完成報告

## 執行摘要

✅ 成功提取 87 個 Magic Numbers
✅ 建立 4 個新的常數檔案
✅ 更新 23 個 Dart 檔案

## 新建檔案

1. ✅ `lib/core/constants/radius_constants.dart`
2. ✅ `lib/core/constants/font_constants.dart`
3. ✅ `lib/core/constants/duration_constants.dart`
4. ✅ `lib/features/diary/constants/diary_constants.dart`

## 修改檔案

[列出所有修改的檔案]

## 改善指標

- 程式碼可讀性：⭐⭐⭐⭐⭐
- 可維護性：⭐⭐⭐⭐⭐
- 一致性：⭐⭐⭐⭐⭐

## 驗證結果

```
Dart Analyzer: 無錯誤 ✅
```

## 使用範例

```dart
// 在任何檔案中使用
import 'package:context_app/core/constants/spacing_constants.dart';
import 'package:context_app/core/constants/radius_constants.dart';

Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(Spacing.lg),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(Radius.md),
    ),
  );
}
```
```

## 最佳實踐

### 常數命名

- 使用描述性名稱
- 避免縮寫
- 使用一致的命名模式

```dart
// ✅ 好
static const double extraSmall = 4.0;
static const double small = 8.0;

// ❌ 不好
static const double xs = 4.0;
static const double s = 8.0;
```

### 常數組織

使用類別組織相關常數：

```dart
class AppConstants {
  // 私有建構子防止實例化
  AppConstants._();

  static const String appName = 'Travel Diary';
  static const String version = '0.0.7';
}
```

### 文件化

為常數添加說明文件：

```dart
/// UI Spacing 常數
///
/// 遵循 8pt Grid System，確保 UI 一致性
class Spacing {
  Spacing._();

  /// 標準間距 - 16px
  ///
  /// 用於大多數 UI 元素之間的間距
  static const double lg = 16.0;
}
```

開始分析 $ARGUMENTS。
