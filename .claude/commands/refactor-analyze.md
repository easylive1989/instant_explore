---
allowed-tools: Read, Glob, Grep, Bash(find:*), Bash(wc:*), Bash(fvm dart analyze:*)
description: 深度分析程式碼品質，產生詳細報告（不執行修改）
argument-hint: [檔案或目錄路徑]
---

# 程式碼品質深度分析

你是一個專業的程式碼品質分析專家，專注於 Flutter/Dart 專案。

## 任務

對 `$ARGUMENTS` 進行深度程式碼品質分析，產生詳細的診斷報告，但**不進行任何修改**。

## 分析流程

### 1. 專案概覽

收集基本統計資訊：

```bash
# 計算 Dart 檔案數量
!`find $ARGUMENTS -name "*.dart" -type f 2>/dev/null | wc -l`

# 計算總程式碼行數
!`find $ARGUMENTS -name "*.dart" -type f -exec wc -l {} + 2>/dev/null | tail -1`

# 列出最大的 10 個檔案
!`find $ARGUMENTS -name "*.dart" -type f -exec wc -l {} + 2>/dev/null | sort -rn | head -10`
```

### 2. 檔案結構分析

使用 Glob 列出所有 Dart 檔案並分類：
- Screens (畫面)
- Widgets (元件)
- Models (資料模型)
- Services (服務)
- Providers (狀態管理)
- Repositories (資料存取)

### 3. 程式碼品質指標

針對每個檔案計算：

#### 檔案大小評分
- ✅ 0-200 行：優良
- ⚠️ 201-300 行：可接受
- ❌ 301+ 行：需要重構

#### 複雜度評估
檢查以下模式：
- 嵌套層數 (if/for/while 深度)
- 方法數量
- 類別數量
- 參數數量

#### 依賴關係
- Import 數量
- 外部套件依賴
- 內部模組依賴

### 4. 設計原則評估

#### SOLID 評分

**單一職責 (SRP)**：
- 檢查檔案是否包含多個不相關的類別
- 檢查類別是否有多個修改原因
- 評分：1-5 分

**開放封閉 (OCP)**：
- 檢查是否使用抽象和介面
- 檢查擴展點設計
- 評分：1-5 分

**里氏替換 (LSP)**：
- 檢查繼承使用是否正確
- 檢查是否濫用繼承
- 評分：1-5 分

**介面隔離 (ISP)**：
- 檢查介面是否過於龐大
- 檢查是否有不必要的依賴
- 評分：1-5 分

**依賴反轉 (DIP)**：
- 檢查是否依賴抽象而非實作
- 檢查 Provider 使用情況
- 評分：1-5 分

#### 其他原則評分

**KISS (Keep It Simple)**：
- 檢查程式碼複雜度
- 評分：1-5 分

**DRY (Don't Repeat Yourself)**：
- 檢查重複程式碼模式
- 評分：1-5 分

**YAGNI (You Aren't Gonna Need It)**：
- 檢查是否有未使用的程式碼
- 檢查是否過度設計
- 評分：1-5 分

### 5. Flutter 特定分析

#### Widget 最佳實踐
- [ ] 使用 const constructors
- [ ] Widget 大小適中（< 200 行）
- [ ] build() 方法簡潔（< 50 行）
- [ ] 正確拆分 Widget
- [ ] 避免不必要的 rebuild

#### State 管理評估
- [ ] 統一使用 Riverpod
- [ ] 避免混用 setState
- [ ] Provider 設計合理
- [ ] State 不可變性

#### 效能考量
- [ ] 使用 ListView.builder
- [ ] 圖片快取
- [ ] 避免在 build 中執行耗時操作
- [ ] 適當使用 const

### 6. 執行 Dart Analyzer

```bash
!`cd frontend && fvm dart analyze $ARGUMENTS`
```

收集所有警告和錯誤。

### 7. 反模式偵測

偵測常見的反模式：

#### ❌ God Object (神物件)
```dart
// 檔案超過 500 行，包含過多職責
```

#### ❌ 直接實例化服務
```dart
// ❌ 不好
final service = MyService();

// ✅ 好
final service = ref.read(myServiceProvider);
```

#### ❌ Magic Numbers
```dart
// ❌ 不好
padding: EdgeInsets.all(16)

// ✅ 好
padding: EdgeInsets.all(Spacing.medium)
```

#### ❌ 深層嵌套
```dart
// 超過 5 層的 if/for 嵌套
```

#### ❌ 長參數列表
```dart
// 超過 5 個參數的方法
```

#### ❌ 重複的程式碼
```dart
// 相同或相似的程式碼片段出現多次
```

## 輸出報告格式

```markdown
# 📊 程式碼品質深度分析報告

生成時間：[當前時間]
分析範圍：$ARGUMENTS

---

## 1. 專案概覽

| 指標 | 數值 | 評估 |
|------|------|------|
| Dart 檔案總數 | X | ✅/⚠️/❌ |
| 總程式碼行數 | Y | ✅/⚠️/❌ |
| 平均檔案大小 | Z 行 | ✅/⚠️/❌ |
| 最大檔案大小 | N 行 | ✅/⚠️/❌ |
| Widget 數量 | W | ✅/⚠️/❌ |
| Service 數量 | S | ✅/⚠️/❌ |

---

## 2. 檔案大小分布

### 超大檔案 (>500 行) ❌
1. `path/to/file1.dart` - 621 行
2. `path/to/file2.dart` - 543 行

### 大檔案 (301-500 行) ⚠️
1. `path/to/file3.dart` - 382 行
2. `path/to/file4.dart` - 365 行

### 適中檔案 (201-300 行) ✅
...

### 小檔案 (0-200 行) ✅
...

---

## 3. 設計原則評分

### SOLID 原則
| 原則 | 評分 | 說明 |
|------|------|------|
| Single Responsibility | 3/5 | 部分檔案職責過多 |
| Open/Closed | 4/5 | 大部分使用抽象設計 |
| Liskov Substitution | 5/5 | 繼承使用正確 |
| Interface Segregation | 4/5 | 介面設計良好 |
| Dependency Inversion | 3/5 | 部分直接實例化服務 |

**SOLID 總分**：19/25 (76%) ⚠️

### 其他原則
| 原則 | 評分 | 說明 |
|------|------|------|
| KISS | 3/5 | 部分程式碼過於複雜 |
| DRY | 3/5 | 存在重複程式碼 |
| YAGNI | 4/5 | 設計適度 |

**總體評分**：10/15 (67%) ⚠️

---

## 4. 問題清單

### 🔴 嚴重問題 (5 個)

#### 1. God Object - diary_list_screen.dart
- **位置**：`lib/features/diary/screens/diary_list_screen.dart`
- **程式碼行數**：621 行
- **違反原則**：SRP, KISS
- **影響**：可維護性、可測試性
- **建議**：拆分為 5-6 個獨立檔案

#### 2. 直接實例化服務 - diary_create_screen.dart:45
- **位置**：`lib/features/diary/screens/diary_create_screen.dart:45`
- **違反原則**：DIP
- **影響**：可測試性、依賴管理
- **建議**：使用 Riverpod Provider

...

### 🟡 警告問題 (12 個)

...

### 🟢 建議改善 (8 個)

...

---

## 5. 反模式統計

| 反模式 | 出現次數 | 位置 |
|--------|----------|------|
| God Object | 2 | diary_list_screen.dart, diary_detail_screen.dart |
| 直接實例化 | 5 | [檔案列表] |
| Magic Numbers | 15 | [檔案列表] |
| 深層嵌套 | 3 | [檔案列表] |
| 長參數列表 | 2 | [檔案列表] |
| 重複程式碼 | 8 | [檔案列表] |

---

## 6. Flutter 最佳實踐檢查

### Widget 設計
- ✅ 使用 const constructors：60%
- ⚠️ Widget 大小適中：70%
- ⚠️ build() 方法簡潔：65%
- ✅ 正確拆分 Widget：80%

### State 管理
- ⚠️ 統一使用 Riverpod：60%
- ⚠️ 避免混用 setState：70%
- ✅ Provider 設計合理：85%

### 效能
- ✅ 使用 ListView.builder：100%
- ✅ 圖片快取：100%
- ✅ 避免耗時操作：90%

---

## 7. Dart Analyzer 結果

```
[Analyzer 輸出]
```

**總結**：
- 錯誤：0 個 ✅
- 警告：3 個 ⚠️
- 提示：12 個

---

## 8. 重構優先級建議

### 🚨 立即處理 (本週)

1. **拆分 diary_list_screen.dart**
   - 影響：高
   - 工作量：4-6 小時
   - 命令：`/refactor-split-file lib/features/diary/screens/diary_list_screen.dart`

2. **轉換服務為 Providers**
   - 影響：中
   - 工作量：2-3 小時
   - 命令：`/refactor-providers lib/features/diary`

3. **提取常數定義**
   - 影響：中
   - 工作量：1-2 小時
   - 命令：`/refactor-constants lib/features`

### ⚠️ 近期處理 (本月)

4. 建立共用工具類別
5. 統一錯誤處理
6. 改善測試覆蓋率

### 📝 長期改善 (下季度)

7. 引入 freezed + json_serializable
8. 增強型別安全
9. 效能優化

---

## 9. 總體健康度評估

```
程式碼健康度：⭐⭐⭐⚡⚡ (3/5)

✅ 優點：
- Feature-First 架構清晰
- 使用現代化技術棧
- 環境變數管理良好
- UI 設計優秀

⚠️ 需要改善：
- 部分檔案過大
- 依賴注入不一致
- 缺少測試覆蓋率
- 存在重複程式碼

建議：
優先處理檔案拆分和依賴注入問題，
這將大幅提升程式碼的可維護性和可測試性。
```

---

## 10. 下一步行動

### 本週行動項目
- [ ] 執行 `/refactor-split-file` 拆分大檔案
- [ ] 執行 `/refactor-providers` 轉換服務
- [ ] 執行 `/refactor-constants` 提取常數

### 本月行動項目
- [ ] 建立單元測試框架
- [ ] 統一錯誤處理機制
- [ ] 編寫重構指南文件

### 本季行動項目
- [ ] 提升測試覆蓋率至 70%
- [ ] 引入 freezed 管理資料模型
- [ ] 效能優化和監控

---

## 📚 參考資源

- [SOLID 原則指南](docs/refactoring-guide.md#solid)
- [Flutter 最佳實踐](docs/refactoring-guide.md#flutter)
- [Riverpod 模式](docs/refactoring-guide.md#riverpod)

```

立即開始分析 $ARGUMENTS。
