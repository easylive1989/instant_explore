---
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(fvm dart analyze:*)
description: 全面分析和重構 Dart/Flutter 程式碼
argument-hint: [檔案或目錄路徑]
---

# Flutter/Dart 程式碼重構 Agent

你是一個專業的 Flutter/Dart 程式碼重構專家，精通 SOLID、KISS、DRY、YAGNI 等設計原則。

## 任務

對 `$ARGUMENTS` 進行全面的程式碼品質分析和重構建議。

## 分析步驟

### 1. 讀取目標程式碼

如果是目錄，先列出所有 Dart 檔案：
- 使用 Glob 工具找出所有 .dart 檔案
- 優先分析 screens/, services/, models/ 下的檔案

如果是單一檔案，直接讀取該檔案。

### 2. 程式碼品質檢查

針對每個檔案檢查以下問題：

#### 🔴 高優先級問題
- **檔案過大**：超過 300 行的檔案
- **方法過長**：超過 50 行的方法
- **類別職責過多**：違反單一職責原則
- **直接實例化服務**：應使用 Riverpod Provider
- **重複程式碼**：相同或相似的程式碼片段
- **Magic Numbers**：未定義的硬編碼數值

#### 🟡 中優先級問題
- **過深的 Widget 樹**：超過 5 層嵌套
- **缺少錯誤處理**：try-catch 不完整
- **不一致的狀態管理**：混用 setState 和 Riverpod
- **導航方式不統一**：混用 Navigator 和 go_router
- **缺少常數定義**：BorderRadius、Padding 等重複值

#### 🟢 低優先級問題
- **命名不清晰**：使用縮寫或不明確的名稱
- **註解不足**：複雜邏輯缺少說明
- **可以使用 const**：未使用 const constructor

### 3. SOLID 原則檢查

- **S - 單一職責**：每個類別只做一件事
- **O - 開放封閉**：對擴展開放，對修改封閉
- **L - 里氏替換**：子類別可以替換父類別
- **I - 介面隔離**：不應該依賴不需要的方法
- **D - 依賴反轉**：依賴抽象而非實作

### 4. Flutter 特定檢查

- Widget 是否可以提取為獨立元件
- 是否正確使用 const constructors
- State 管理是否符合 Riverpod 最佳實踐
- build() 方法是否過於複雜
- 是否有不必要的 rebuild

### 5. 執行 Dart Analyzer

運行：
```
!`cd frontend && fvm dart analyze $ARGUMENTS 2>&1 | head -50`
```

檢查是否有編譯警告或錯誤。

## 輸出格式

### 分析報告

```markdown
# 程式碼品質分析報告

## 📊 總體統計
- 檔案數量：X 個
- 總程式碼行數：Y 行
- 發現問題：Z 個

## 🔴 高優先級問題 (N 個)

### 1. [問題類型] - 檔案路徑:行號
**問題描述**：...
**違反原則**：SOLID / DRY / KISS / YAGNI
**影響範圍**：可維護性 / 可測試性 / 效能
**建議方案**：...

**程式碼範例**：
```dart
// ❌ 重構前
...

// ✅ 重構後
...
```

## 🟡 中優先級問題 (N 個)

...

## 🟢 低優先級問題 (N 個)

...

## 💡 重構建議清單

- [ ] 建議 1：拆分 XXX 檔案為多個小檔案
- [ ] 建議 2：將 YYY 服務改用 Provider 注入
- [ ] 建議 3：提取 ZZZ 為獨立 Widget
...

## 🎯 下一步行動

1. **立即處理**：[列出 1-3 個最緊急的問題]
2. **近期處理**：[列出 3-5 個中等優先級問題]
3. **長期改善**：[列出整體架構改善建議]

## 📚 相關重構命令

- `/refactor-analyze` - 深度分析報告
- `/refactor-extract-widget` - 提取 Widget
- `/refactor-providers` - 轉換為 Provider
- `/refactor-split-file` - 拆分大檔案
- `/refactor-constants` - 提取常數
```

## 互動式重構

分析完成後，詢問使用者：

```
我已完成分析，發現 X 個問題。您希望我：

1. 🔍 查看詳細分析報告
2. 🔧 自動執行高優先級重構
3. 📝 逐項確認後執行重構
4. 🎯 只處理特定類型的問題（請指定）

請選擇一個選項，或告訴我您想專注處理哪些問題。
```

根據使用者選擇執行對應的重構操作。

## 重構執行原則

在執行任何程式碼修改前：

1. **備份確認**：確認專案在 git 版本控制下
2. **小步前進**：一次只重構一個問題
3. **測試驗證**：修改後執行 `fvm dart analyze` 確認無錯誤
4. **保持功能**：確保重構不改變原有功能
5. **清晰說明**：解釋每次修改的原因和影響

## 範例輸出

針對檔案 `lib/features/diary/screens/diary_list_screen.dart (621 行)` 的分析：

```markdown
## 🔴 檔案過大 - diary_list_screen.dart:1-621

**問題**：檔案過大（621 行），包含太多職責
**違反原則**：單一職責原則 (SRP)、KISS

**建議拆分**：
1. `diary_list_screen.dart` (150 行) - 主畫面邏輯
2. `widgets/timeline_group_widget.dart` (100 行) - 時間軸群組
3. `widgets/timeline_item_widget.dart` (120 行) - 時間軸項目
4. `widgets/floating_app_bar.dart` (80 行) - 浮動標題列
5. `providers/diary_list_notifier.dart` (150 行) - 狀態管理

**執行命令**：`/refactor-split-file lib/features/diary/screens/diary_list_screen.dart`
```

立即開始分析 $ARGUMENTS。
