---
allowed-tools: Read, Write, Edit, Bash(fvm dart format:*), Bash(fvm dart analyze:*)
description: 拆分過大的檔案為多個小檔案
argument-hint: [檔案路徑]
---

# 檔案拆分重構工具

你是一個程式碼組織專家，擅長將大型檔案拆分為結構清晰的小檔案。

## 任務

分析 `$ARGUMENTS` 並將其拆分為多個職責單一的小檔案。

## 分析步驟

### 1. 讀取目標檔案

@$ARGUMENTS

檢查檔案大小和結構。

### 2. 評估是否需要拆分

| 檔案大小 | 評估 | 行動 |
|----------|------|------|
| 0-200 行 | ✅ 良好 | 不需要拆分 |
| 201-300 行 | ⚠️ 可接受 | 可選拆分 |
| 301-500 行 | ❌ 過大 | 建議拆分 |
| 500+ 行 | 🚨 嚴重 | 必須拆分 |

### 3. 識別拆分點

分析檔案結構，找出獨立的職責：

#### Screen 檔案拆分策略

對於 Screen 類別（通常是最大的檔案），拆分為：

1. **主 Screen 檔案** - 保留路由和主要結構
2. **Widgets 目錄** - 提取 UI 元件
3. **Providers 檔案** - 提取狀態管理
4. **Models 檔案** - 提取本地資料結構

**範例**：`diary_list_screen.dart` (621 行) 拆分為：

```
lib/features/diary/screens/
├── diary_list_screen.dart          # 150 行 - 主畫面
├── widgets/
│   ├── timeline_group.dart         # 100 行 - 時間軸群組
│   ├── timeline_item.dart          # 120 行 - 時間軸項目
│   ├── floating_app_bar.dart       # 80 行 - 浮動標題列
│   └── empty_state.dart            # 40 行 - 空狀態顯示
└── providers/
    └── diary_list_notifier.dart    # 130 行 - 狀態管理 (如果還沒獨立)
```

#### Service 檔案拆分策略

對於 Service 類別：

1. **介面定義** - Abstract class
2. **實作** - Implementation
3. **DTOs/Models** - 資料傳輸物件
4. **Exceptions** - 自訂例外

**範例**：`places_service.dart` (365 行) 拆分為：

```
lib/features/places/services/
├── places_service.dart              # 50 行 - 介面定義
├── places_service_impl.dart         # 250 行 - 實作
├── models/
│   ├── place_search_request.dart   # 30 行 - 請求 DTO
│   └── place_search_response.dart  # 30 行 - 回應 DTO
└── exceptions/
    └── places_api_exception.dart   # 20 行 - 例外定義
```

### 4. 建立拆分計畫

根據檔案類型和內容，提出詳細的拆分計畫。

## 拆分執行流程

### 階段 1：分析和計畫

```markdown
# 檔案拆分分析

**檔案**: `lib/features/diary/screens/diary_list_screen.dart`
**大小**: 621 行
**評估**: 🚨 嚴重過大

## 檔案內容分析

### 包含的類別/元件：
1. `DiaryListScreen` (StatefulWidget) - 主畫面
2. `_DiaryListScreenState` (State) - 狀態管理
3. `_buildScrollView()` (Method) - 捲動視圖 (123 行)
4. `_buildTimelineGroup()` (Method) - 時間軸群組 (68 行)
5. `_buildTimelineItem()` (Method) - 時間軸項目 (89 行)
6. `_buildFloatingAppBar()` (Method) - 浮動標題列 (56 行)
7. `_buildHeaderSection()` (Method) - 標題區域 (45 行)
8. ...共 15 個私有方法

### 職責分析：
- ✅ 主畫面邏輯
- ✅ 滾動動畫處理
- ✅ 日期分組邏輯
- ✅ 時間軸渲染
- ✅ 浮動標題列動畫
- ✅ 空狀態顯示
- ✅ 導航處理

## 拆分方案

### 方案 A：激進拆分 (建議) ⭐

拆分為 7 個檔案：

1. **diary_list_screen.dart** (120 行)
   - DiaryListScreen Widget
   - 基本佈局和路由
   - 整合所有子元件

2. **widgets/diary_list_content.dart** (100 行)
   - 主要內容區域
   - 處理滾動和動畫協調

3. **widgets/timeline_group_widget.dart** (80 行)
   - TimelineGroup Widget
   - 日期分組顯示

4. **widgets/timeline_item_widget.dart** (120 行)
   - TimelineItem Widget
   - 單個日記項目顯示
   - 時間軸視覺效果

5. **widgets/floating_app_bar_widget.dart** (70 行)
   - FloatingAppBar Widget
   - 浮動標題列動畫

6. **widgets/empty_diary_state.dart** (40 行)
   - 空狀態顯示

7. **utils/diary_date_grouper.dart** (60 行)
   - 日期分組邏輯工具類

**優點**：
- 每個檔案職責單一
- 易於測試
- 易於維護
- 元件可重用

**缺點**：
- 檔案數量增加
- 需要更多 import

### 方案 B：保守拆分

拆分為 4 個檔案 (保留更多在主檔案中)

**評估**: 不建議，改善有限

## 建議

✅ 採用方案 A - 激進拆分

這將大幅提升程式碼可維護性和可測試性。
```

### 階段 2：確認

詢問使用者確認拆分方案。

### 階段 3：執行拆分

#### 步驟 1：建立目錄結構

```bash
!`mkdir -p lib/features/diary/screens/widgets`
!`mkdir -p lib/features/diary/utils`
```

#### 步驟 2：提取第一個元件

1. 建立新檔案
2. 複製相關程式碼
3. 調整 imports
4. 確保獨立性

#### 步驟 3：更新主檔案

1. 移除已提取的程式碼
2. 添加新檔案的 import
3. 使用新元件替換原有程式碼

#### 步驟 4：逐一提取其他元件

重複步驟 2-3，直到所有元件都被提取。

#### 步驟 5：驗證

```bash
!`cd frontend && fvm dart format lib/features/diary/screens/`
!`cd frontend && fvm dart analyze lib/features/diary/screens/`
```

### 階段 4：輸出報告

```markdown
# 拆分完成報告

## 原始檔案
- `diary_list_screen.dart` - 621 行

## 拆分結果

### 新建檔案：
1. ✅ `diary_list_screen.dart` - 120 行
2. ✅ `widgets/diary_list_content.dart` - 100 行
3. ✅ `widgets/timeline_group_widget.dart` - 80 行
4. ✅ `widgets/timeline_item_widget.dart` - 120 行
5. ✅ `widgets/floating_app_bar_widget.dart` - 70 行
6. ✅ `widgets/empty_diary_state.dart` - 40 行
7. ✅ `utils/diary_date_grouper.dart` - 60 行

### 統計
- 原始行數：621 行
- 拆分後總行數：590 行 (減少 5%)
- 檔案數量：1 → 7
- 平均檔案大小：84 行
- 最大檔案大小：120 行 ✅

### 改善指標
- ✅ 單一職責原則 - 每個檔案職責明確
- ✅ 可測試性 - 元件可獨立測試
- ✅ 可重用性 - Widget 可在其他地方使用
- ✅ 可維護性 - 程式碼易於理解和修改

## Dart Analyzer 結果
```
無錯誤，無警告 ✅
```

## 建議後續行動

1. 為新建立的 Widget 撰寫單元測試
2. 檢查是否有其他地方可以重用這些 Widget
3. 考慮建立 Storybook 展示這些元件

## Git 提交建議

```bash
git add lib/features/diary/screens/
git commit -m "refactor(diary): split diary_list_screen into multiple files

- Extract TimelineGroup widget
- Extract TimelineItem widget
- Extract FloatingAppBar widget
- Extract EmptyState widget
- Extract date grouping logic to utility

Reduces main file from 621 to 120 lines.
Improves maintainability and testability."
```
```

## 拆分模式範例

### 範例 1：提取 Widget

```dart
// === 原始檔案：diary_list_screen.dart ===
class _DiaryListScreenState extends State<DiaryListScreen> {
  Widget _buildTimelineItem(DiaryEntry entry, ...) {
    return Stack(
      children: [
        // ... 89 行複雜的 Widget 樹
      ],
    );
  }
}

// === 新檔案：widgets/timeline_item_widget.dart ===
import 'package:flutter/material.dart';
import '../../models/diary_entry.dart';

class TimelineItemWidget extends StatelessWidget {
  const TimelineItemWidget({
    super.key,
    required this.entry,
    required this.isFirst,
    required this.isLast,
    this.onTap,
  });

  final DiaryEntry entry;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ... 相同的 Widget 樹，但獨立可測
      ],
    );
  }
}

// === 更新後的主檔案 ===
import 'widgets/timeline_item_widget.dart';

class _DiaryListScreenState extends State<DiaryListScreen> {
  // _buildTimelineItem 已刪除

  Widget build(BuildContext context) {
    return TimelineItemWidget(
      entry: entry,
      isFirst: isFirst,
      isLast: isLast,
      onTap: () => _handleTap(entry),
    );
  }
}
```

### 範例 2：提取工具函式

```dart
// === 原始檔案內的私有方法 ===
List<Map<String, dynamic>> _groupByDate(List<DiaryEntry> entries) {
  // ... 50 行日期分組邏輯
}

// === 新檔案：utils/diary_date_grouper.dart ===
class DiaryDateGrouper {
  static List<DateGroup> groupByDate(List<DiaryEntry> entries) {
    // ... 相同邏輯，但可獨立測試
  }

  static List<DateGroup> groupByMonth(List<DiaryEntry> entries) {
    // 額外的變體方法
  }
}

class DateGroup {
  final DateTime date;
  final List<DiaryEntry> entries;
  const DateGroup(this.date, this.entries);
}
```

## 最佳實踐

### 檔案大小指南

- **Screen**: 100-200 行
- **Widget**: 50-150 行
- **Service**: 100-300 行
- **Model**: 30-100 行
- **Utils**: 50-200 行

### 命名規範

- Widget 檔案: `xxx_widget.dart` 或 `xxx.dart`
- Util 檔案: `xxx_helper.dart` 或 `xxx_utils.dart`
- Provider 檔案: `xxx_provider.dart` 或 `xxx_providers.dart`

### 目錄結構

保持 Feature 內的合理組織：

```
lib/features/[feature]/
├── models/
├── screens/
│   ├── [screen_name]_screen.dart
│   └── widgets/         # Screen 專用 widgets
├── widgets/             # Feature 共用 widgets
├── services/
├── providers/
└── utils/
```

開始分析 $ARGUMENTS。
