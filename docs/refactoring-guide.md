# Flutter/Dart 程式碼重構指南

本指南針對 Travel Diary (旅食日記) 專案，提供系統化的程式碼重構原則和實踐方法。

---

## 目錄

1. [設計原則](#設計原則)
2. [程式碼組織](#程式碼組織)
3. [Flutter 最佳實踐](#flutter-最佳實踐)
4. [Riverpod 模式](#riverpod-模式)
5. [常見重構模式](#常見重構模式)
6. [反模式與解決方案](#反模式與解決方案)
7. [重構工具使用](#重構工具使用)

---

## 設計原則

### SOLID 原則

#### S - 單一職責原則 (Single Responsibility Principle)

**定義**：一個類別應該只有一個改變的理由。

**範例**：

```dart
// ❌ 違反 SRP：一個 Screen 類別負責太多事情
class DiaryListScreen extends StatefulWidget {
  // 1. UI 渲染
  // 2. 狀態管理
  // 3. 資料獲取
  // 4. 日期分組邏輯
  // 5. 動畫處理
}

// ✅ 遵循 SRP：職責分離
class DiaryListScreen extends ConsumerWidget {
  // 只負責 UI 組合和佈局
}

class DiaryListNotifier extends StateNotifier<DiaryListState> {
  // 只負責狀態管理和資料獲取
}

class DiaryDateGrouper {
  // 只負責日期分組邏輯
}

class TimelineAnimationController {
  // 只負責動畫處理
}
```

**檢查清單**：
- [ ] 這個類別的職責可以用一句話描述嗎？
- [ ] 修改這個類別的原因只有一個嗎？
- [ ] 能夠將職責拆分為更小的類別嗎？

#### O - 開放封閉原則 (Open/Closed Principle)

**定義**：對擴展開放，對修改封閉。

**範例**：

```dart
// ❌ 每次新增類型都要修改
String getIconForEntryType(String type) {
  if (type == 'food') return 'restaurant';
  if (type == 'travel') return 'flight';
  if (type == 'note') return 'note';
  // 新增類型需要修改此函式
}

// ✅ 使用多型和策略模式
abstract class DiaryEntryType {
  String get icon;
  Color get color;
}

class FoodEntry implements DiaryEntryType {
  @override
  String get icon => 'restaurant';

  @override
  Color get color => Colors.orange;
}

class TravelEntry implements DiaryEntryType {
  @override
  String get icon => 'flight';

  @override
  Color get color => Colors.blue;
}

// 新增類型不需要修改現有程式碼
```

#### L - 里氏替換原則 (Liskov Substitution Principle)

**定義**：子類別應該能夠替換父類別。

**範例**：

```dart
// ❌ 違反 LSP：子類別限制了父類別的行為
abstract class DiaryRepository {
  Future<DiaryEntry> getEntry(String id);
}

class CachedDiaryRepository extends DiaryRepository {
  @override
  Future<DiaryEntry> getEntry(String id) {
    // 只在有網路時才能工作，限制了父類別的承諾
    if (!hasNetwork) throw Exception('No network');
    return super.getEntry(id);
  }
}

// ✅ 遵循 LSP：子類別增強但不限制父類別
class CachedDiaryRepository extends DiaryRepository {
  @override
  Future<DiaryEntry> getEntry(String id) async {
    // 先嘗試快取，失敗時 fallback 到網路
    try {
      return await _cache.get(id);
    } catch (_) {
      return await super.getEntry(id);
    }
  }
}
```

#### I - 介面隔離原則 (Interface Segregation Principle)

**定義**：不應該強迫客戶端依賴它們不使用的方法。

**範例**：

```dart
// ❌ 違反 ISP：介面過於龐大
abstract class DiaryRepository {
  Future<DiaryEntry> getEntry(String id);
  Future<List<DiaryEntry>> getAll();
  Future<void> create(DiaryEntry entry);
  Future<void> update(DiaryEntry entry);
  Future<void> delete(String id);
  Future<List<DiaryEntry>> search(String query);
  Future<void> sync();
  Future<void> backup();
  // 太多方法...
}

// ✅ 遵循 ISP：拆分為多個小介面
abstract class DiaryReader {
  Future<DiaryEntry> getEntry(String id);
  Future<List<DiaryEntry>> getAll();
}

abstract class DiaryWriter {
  Future<void> create(DiaryEntry entry);
  Future<void> update(DiaryEntry entry);
  Future<void> delete(String id);
}

abstract class DiarySearcher {
  Future<List<DiaryEntry>> search(String query);
}

// 實作類別可以選擇實作需要的介面
class DiaryRepositoryImpl implements DiaryReader, DiaryWriter, DiarySearcher {
  // ...
}
```

#### D - 依賴反轉原則 (Dependency Inversion Principle)

**定義**：高層模組不應該依賴低層模組，兩者都應該依賴抽象。

**範例**：

```dart
// ❌ 違反 DIP：直接依賴具體實作
class DiaryListScreen extends StatefulWidget {
  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  late final DiaryRepositoryImpl _repository;

  @override
  void initState() {
    super.initState();
    _repository = DiaryRepositoryImpl();  // 依賴具體類別
  }
}

// ✅ 遵循 DIP：依賴抽象
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();  // 在這裡決定具體實作
});

class DiaryListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(diaryRepositoryProvider);  // 依賴抽象
    // ...
  }
}
```

### 其他重要原則

#### KISS (Keep It Simple, Stupid)

**定義**：保持簡單。

```dart
// ❌ 過度複雜
Future<List<DiaryEntry>> getFilteredEntries(
  List<DiaryEntry> entries,
  {DateTime? startDate,
  DateTime? endDate,
  List<String>? tags,
  String? searchQuery,
  bool? hasImages}) async {
  return entries.where((entry) {
    if (startDate != null && entry.date.isBefore(startDate)) return false;
    if (endDate != null && entry.date.isAfter(endDate)) return false;
    if (tags != null && !tags.any((tag) => entry.tags.contains(tag))) return false;
    if (searchQuery != null && !entry.content.contains(searchQuery)) return false;
    if (hasImages != null && (entry.images.isEmpty == hasImages)) return false;
    return true;
  }).toList();
}

// ✅ 簡單明瞭
Future<List<DiaryEntry>> getEntriesByDateRange(
  DateTime start,
  DateTime end,
) async {
  return entries.where((e) => e.date.isAfter(start) && e.date.isBefore(end)).toList();
}

Future<List<DiaryEntry>> getEntriesByTags(List<String> tags) async {
  return entries.where((e) => tags.any((tag) => e.tags.contains(tag))).toList();
}
```

#### DRY (Don't Repeat Yourself)

**定義**：不要重複自己。

```dart
// ❌ 重複程式碼
// 在 diary_card.dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('日記已儲存')),
);

// 在 diary_create_screen.dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('日記已儲存')),
);

// 在 diary_edit_screen.dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('日記已儲存')),
);

// ✅ 提取為共用方法
class UiHelper {
  static void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

#### YAGNI (You Aren't Gonna Need It)

**定義**：不要實作你還不需要的功能。

```dart
// ❌ 過度設計
abstract class DiaryRepository {
  Future<DiaryEntry> getEntry(String id);
  Future<void> create(DiaryEntry entry);

  // 以下方法目前都不需要
  Future<void> bulkCreate(List<DiaryEntry> entries);
  Future<void> bulkUpdate(List<DiaryEntry> entries);
  Future<void> bulkDelete(List<String> ids);
  Future<List<DiaryEntry>> getEntriesPaginated(int page, int size);
  Future<Map<String, dynamic>> getStatistics();
  Future<void> exportToCsv(String path);
  Future<void> exportToJson(String path);
  Future<void> importFromCsv(String path);
}

// ✅ 只實作需要的
abstract class DiaryRepository {
  Future<DiaryEntry> getEntry(String id);
  Future<List<DiaryEntry>> getAll();
  Future<void> create(DiaryEntry entry);
  Future<void> update(DiaryEntry entry);
  Future<void> delete(String id);
}
```

---

## 程式碼組織

### Feature-First 架構

本專案採用 Feature-First 架構，按功能模組組織程式碼。

```
lib/
├── app.dart                    # 應用程式主設定
├── main.dart                   # 入口點
├── core/                       # 核心共用功能
│   ├── config/                 # 配置
│   ├── constants/              # 常數
│   ├── services/               # 核心服務
│   ├── utils/                  # 工具函式
│   └── exceptions/             # 基礎異常
├── shared/                     # 共用元件
│   ├── widgets/                # 共用 UI 元件
│   └── models/                 # 跨 feature 的資料模型
└── features/                   # 功能模組
    ├── auth/                   # 認證功能
    │   ├── models/
    │   ├── screens/
    │   ├── widgets/
    │   ├── services/
    │   ├── providers/
    │   └── exceptions/
    ├── diary/                  # 日記功能
    │   ├── models/
    │   ├── screens/
    │   │   ├── diary_list_screen.dart
    │   │   └── widgets/        # Screen 專用 widgets
    │   ├── widgets/            # Feature 共用 widgets
    │   ├── services/
    │   ├── providers/
    │   └── constants/
    └── places/                 # 地點功能
        └── ...
```

### 檔案大小指南

| 檔案類型 | 建議大小 | 最大限制 |
|----------|----------|----------|
| Screen | 100-200 行 | 300 行 |
| Widget | 50-150 行 | 200 行 |
| Service | 100-300 行 | 400 行 |
| Model | 30-100 行 | 150 行 |
| Provider | 50-200 行 | 250 行 |
| Util/Helper | 50-200 行 | 300 行 |

**原則**：當檔案超過建議大小，考慮重構；超過最大限制，必須重構。

---

## Flutter 最佳實踐

### Widget 設計

#### 1. 使用 const Constructors

```dart
// ❌ 不使用 const
class MyWidget extends StatelessWidget {
  MyWidget({Key? key}) : super(key: key);
}

// ✅ 使用 const
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
}
```

#### 2. 拆分大型 Widget

```dart
// ❌ build 方法過長
class DiaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      // 100+ 行的 Widget 樹
      child: Column(
        children: [
          // 大量嵌套...
        ],
      ),
    );
  }
}

// ✅ 拆分為多個小 Widget
class DiaryCard extends StatelessWidget {
  const DiaryCard({super.key, required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _Header(entry: entry),
          _Content(entry: entry),
          _Footer(entry: entry),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    // 簡潔的 UI 實作
  }
}
```

#### 3. 優先使用 StatelessWidget

```dart
// ❌ 不必要的 StatefulWidget
class DiaryTitle extends StatefulWidget {
  const DiaryTitle({super.key, required this.title});

  final String title;

  @override
  State<DiaryTitle> createState() => _DiaryTitleState();
}

class _DiaryTitleState extends State<DiaryTitle> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.title);  // 沒有任何狀態
  }
}

// ✅ 使用 StatelessWidget
class DiaryTitle extends StatelessWidget {
  const DiaryTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}
```

### 效能最佳化

#### 1. 使用 ListView.builder

```dart
// ❌ 一次性建立所有 item
ListView(
  children: entries.map((entry) => DiaryCard(entry: entry)).toList(),
)

// ✅ 懶加載
ListView.builder(
  itemCount: entries.length,
  itemBuilder: (context, index) => DiaryCard(entry: entries[index]),
)
```

#### 2. 避免在 build 方法中執行耗時操作

```dart
// ❌ 在 build 中執行耗時操作
class DiaryList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(diaryListProvider);
    final groupedEntries = _groupByDate(entries);  // 每次 rebuild 都執行
    return ListView(...);
  }

  List<DateGroup> _groupByDate(List<DiaryEntry> entries) {
    // 耗時的分組操作
  }
}

// ✅ 在 Provider/Notifier 中預處理
class DiaryListNotifier extends StateNotifier<DiaryListState> {
  Future<void> loadEntries() async {
    final entries = await _repository.getAll();
    final grouped = DiaryDateGrouper.groupByDate(entries);  // 只在載入時執行一次
    state = state.copyWith(groups: grouped);
  }
}
```

---

## Riverpod 模式

### Provider 類型選擇

| Provider 類型 | 使用情境 | 範例 |
|---------------|----------|------|
| `Provider` | 不會改變的服務或物件 | Repository, Service |
| `StateProvider` | 簡單的狀態 | 主題模式, 語言設定 |
| `StateNotifierProvider` | 複雜的狀態邏輯 | 日記列表, 認證狀態 |
| `FutureProvider` | 非同步資料 | 初始化資料 |
| `StreamProvider` | 串流資料 | Realtime 更新 |

### Provider 定義範例

```dart
// lib/features/diary/providers/diary_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/diary_repository.dart';
import '../services/diary_repository_impl.dart';

// Service Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();
});

// State Notifier Provider
final diaryListNotifierProvider =
    StateNotifierProvider<DiaryListNotifier, DiaryListState>((ref) {
  return DiaryListNotifier(ref.read(diaryRepositoryProvider));
});

// Future Provider
final recentDiariesProvider = FutureProvider<List<DiaryEntry>>((ref) async {
  final repository = ref.read(diaryRepositoryProvider);
  return repository.getRecent(limit: 10);
});
```

### 使用 ref.watch vs ref.read

```dart
class DiaryListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 在 build 中使用 ref.watch 監聽變化
    final state = ref.watch(diaryListNotifierProvider);

    return ListView.builder(
      itemCount: state.entries.length,
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        return DiaryCard(
          entry: entry,
          onTap: () {
            // ✅ 在事件處理中使用 ref.read
            ref.read(diaryListNotifierProvider.notifier).selectEntry(entry);
          },
        );
      },
    );
  }
}
```

---

## 常見重構模式

### 1. 提取方法

```dart
// ❌ 重構前：長方法
Widget build(BuildContext context) {
  return Container(
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.person),
            SizedBox(width: 8),
            Text(user.name),
            // ...20 行
          ],
        ),
        Row(
          children: [
            Icon(Icons.email),
            SizedBox(width: 8),
            Text(user.email),
            // ...20 行
          ],
        ),
      ],
    ),
  );
}

// ✅ 重構後：提取方法
Widget build(BuildContext context) {
  return Container(
    child: Column(
      children: [
        _buildUserInfo(user.name, Icons.person),
        _buildUserInfo(user.email, Icons.email),
      ],
    ),
  );
}

Widget _buildUserInfo(String text, IconData icon) {
  return Row(
    children: [
      Icon(icon),
      const SizedBox(width: 8),
      Text(text),
    ],
  );
}
```

### 2. 提取 Widget

```dart
// ❌ 重構前：方法返回 Widget
Widget _buildUserInfo(String text, IconData icon) {
  return Row(...);
}

// ✅ 重構後：獨立 Widget 類別
class _UserInfo extends StatelessWidget {
  const _UserInfo({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(...);
  }
}
```

### 3. 引入參數物件

```dart
// ❌ 重構前：過多參數
Widget buildCard(
  String title,
  String subtitle,
  String imageUrl,
  DateTime date,
  List<String> tags,
  VoidCallback onTap,
) {
  // ...
}

// ✅ 重構後：使用資料類別
class CardData {
  final String title;
  final String subtitle;
  final String imageUrl;
  final DateTime date;
  final List<String> tags;

  const CardData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.date,
    required this.tags,
  });
}

Widget buildCard(CardData data, VoidCallback onTap) {
  // ...
}
```

---

## 反模式與解決方案

### 1. God Object (神物件)

**問題**：一個類別負責太多職責。

```dart
// ❌ God Object
class DiaryListScreen extends StatefulWidget {
  // 600+ 行程式碼
  // 負責：UI、狀態、網路請求、資料處理、動畫...
}

// ✅ 解決方案：職責分離
class DiaryListScreen extends ConsumerWidget {
  // 100 行 - 只負責 UI 組合
}

class DiaryListNotifier extends StateNotifier<DiaryListState> {
  // 150 行 - 只負責狀態管理
}

class TimelineGroupWidget extends StatelessWidget {
  // 80 行 - 只負責時間軸群組顯示
}
```

**重構命令**：`/refactor-split-file lib/path/to/file.dart`

### 2. Magic Numbers

**問題**：硬編碼的數字缺乏意義。

```dart
// ❌ Magic Numbers
Container(
  padding: EdgeInsets.all(16),
  child: Text('Title', style: TextStyle(fontSize: 18)),
)

// ✅ 使用常數
import 'package:instant_explore/core/constants/spacing_constants.dart';
import 'package:instant_explore/core/constants/font_constants.dart';

Container(
  padding: EdgeInsets.all(Spacing.lg),
  child: Text('Title', style: TextStyle(fontSize: FontSize.title)),
)
```

**重構命令**：`/refactor-constants lib/path/to/directory`

### 3. 直接實例化服務

**問題**：違反依賴注入原則。

```dart
// ❌ 直接實例化
class DiaryScreen extends StatefulWidget {
  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late final DiaryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = DiaryRepositoryImpl();  // ❌
  }
}

// ✅ 使用 Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();
});

class DiaryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(diaryRepositoryProvider);  // ✅
    // ...
  }
}
```

**重構命令**：`/refactor-providers lib/path/to/directory`

---

## 重構工具使用

### 可用的重構命令

| 命令 | 用途 | 使用範例 |
|------|------|----------|
| `/refactor` | 全面分析和重構 | `/refactor lib/features/diary` |
| `/refactor-analyze` | 深度分析（不修改） | `/refactor-analyze lib/` |
| `/refactor-extract-widget` | 提取 Widget | `/refactor-extract-widget lib/features/diary/screens/diary_list_screen.dart` |
| `/refactor-providers` | 轉換為 Provider | `/refactor-providers lib/features/diary` |
| `/refactor-split-file` | 拆分大檔案 | `/refactor-split-file lib/features/diary/screens/diary_list_screen.dart` |
| `/refactor-constants` | 提取常數 | `/refactor-constants lib/features` |
| `/refactor-error-handling` | 改善錯誤處理 | `/refactor-error-handling lib/features/diary/services` |

### 重構工作流程

#### 1. 分析階段

```bash
# 先進行全面分析
/refactor-analyze lib/features/diary
```

這會產生詳細的分析報告，包含優先級建議。

#### 2. 規劃階段

根據分析報告，決定重構順序：

1. **高優先級**：立即影響程式碼品質和可維護性
   - 拆分超大檔案
   - 轉換為 Provider
   - 提取重複程式碼

2. **中優先級**：近期處理
   - 提取常數
   - 改善錯誤處理
   - Widget 重構

3. **低優先級**：長期改善
   - 命名優化
   - 註解完善
   - 效能優化

#### 3. 執行階段

**原則**：
- 一次只重構一個問題
- 每次重構後執行測試
- 每個重構提交一次 git commit

**範例流程**：

```bash
# Step 1: 拆分大檔案
/refactor-split-file lib/features/diary/screens/diary_list_screen.dart

# 驗證
cd frontend && fvm dart analyze

# 提交
git add .
git commit -m "refactor(diary): split diary_list_screen into multiple files"

# Step 2: 轉換為 Provider
/refactor-providers lib/features/diary

# 驗證
cd frontend && fvm dart analyze

# 提交
git add .
git commit -m "refactor(diary): convert services to use Riverpod providers"

# Step 3: 提取常數
/refactor-constants lib/features/diary

# 驗證和提交...
```

---

## 測試策略

### 重構時的測試

重構的黃金規則：**重構不改變行為**

#### 重構前

1. 確保現有測試通過（如果有）
2. 如果沒有測試，先寫測試

#### 重構中

1. 小步前進
2. 頻繁執行測試
3. 保持測試通過

#### 重構後

1. 所有測試應該仍然通過
2. 考慮增加新的測試

### 建議的測試覆蓋率目標

| 層級 | 目標覆蓋率 |
|------|-----------|
| Service/Repository | 80%+ |
| State Notifier | 70%+ |
| Widget | 50%+ |
| Util/Helper | 90%+ |

---

## 附錄

### 參考資源

- [Effective Dart](https://dart.dev/effective-dart)
- [Flutter Best Practices](https://docs.flutter.dev/testing/best-practices)
- [Riverpod Documentation](https://riverpod.dev/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)

### 常用快捷鍵

- **Dart Analyzer**: `cd frontend && fvm dart analyze`
- **Dart Format**: `cd frontend && fvm dart format lib/`
- **Flutter Test**: `cd frontend && fvm flutter test`

---

**最後更新**：2025-01-22

本指南會隨著專案演進持續更新。如有疑問或建議，請在專案中提出 issue。
