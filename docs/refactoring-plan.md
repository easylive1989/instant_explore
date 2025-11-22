# Travel Diary 重構計劃

**建立日期**：2025-01-22
**目標**：系統性地改善程式碼品質、可維護性和可測試性
**預估時程**：2-3 週
**重構範圍**：features/ 目錄下所有模組

---

## 目錄

1. [專案概覽](#專案概覽)
2. [重構原則](#重構原則)
3. [Diary 模組重構](#diary-模組重構)
4. [Places 模組重構](#places-模組重構)
5. [Auth 模組重構](#auth-模組重構)
6. [Images 模組重構](#images-模組重構)
7. [Core 模組重構](#core-模組重構)
8. [執行時間表](#執行時間表)
9. [完成檢查清單](#完成檢查清單)

---

## 專案概覽

### 當前狀態

- **總檔案數**：25 個 Dart 檔案
- **總程式碼行數**：4,759 行
- **發現問題**：23 個主要問題
- **Dart Analyzer 警告**：91 個

### 問題分布

| 優先級 | 數量 | 說明 |
|--------|------|------|
| 🔴 高 | 8 | 嚴重影響可維護性、效能或可測試性 |
| 🟡 中 | 10 | 需要近期處理的品質問題 |
| 🟢 低 | 5 | 長期改善項目 |

### 主要問題類型

1. **檔案過大**：2 個檔案超過 500 行
2. **依賴注入**：5 處直接實例化服務
3. **效能問題**：1 個 N+1 查詢問題
4. **Magic Numbers**：多處硬編碼數值
5. **Widget 嵌套**：部分 Widget 嵌套過深
6. **錯誤處理**：錯誤處理不夠完善
7. **程式碼重複**：多處重複邏輯
8. **Linter 警告**：91 個待修復警告

---

## 重構原則

本次重構遵循以下原則：

### SOLID 原則

- ✅ **S**ingle Responsibility - 單一職責原則
- ✅ **O**pen/Closed - 開放封閉原則
- ✅ **L**iskov Substitution - 里氏替換原則
- ✅ **I**nterface Segregation - 介面隔離原則
- ✅ **D**ependency Inversion - 依賴反轉原則

### 其他原則

- ✅ **KISS** - Keep It Simple, Stupid
- ✅ **DRY** - Don't Repeat Yourself
- ✅ **YAGNI** - You Aren't Gonna Need It

### 重構守則

1. **小步前進**：一次只重構一個問題
2. **保持功能**：重構不改變行為
3. **頻繁驗證**：每次修改後執行 `fvm dart analyze`
4. **及時提交**：每個獨立重構都要 commit

---

## Diary 模組重構

### 模組概覽

```
lib/features/diary/
├── models/              # 3 個檔案
├── screens/             # 3 個檔案 ⚠️ 需要重構
├── widgets/             # 4 個檔案
├── services/            # 2 個檔案 ⚠️ 需要重構
└── providers/           # 待建立 ⚠️
```

**發現問題**：12 個
**優先級分布**：🔴 6 個 | 🟡 4 個 | 🟢 2 個

---

### Task 1.1：拆分 diary_list_screen.dart

**優先級**：🔴 高
**預估時間**：3-4 小時
**檔案位置**：`lib/features/diary/screens/diary_list_screen.dart`

#### 問題描述

- 檔案大小：621 行（建議最大 300 行）
- 包含多個職責：
  - 狀態管理（DiaryListNotifier）
  - UI 渲染（DiaryListScreen）
  - 時間軸 UI 邏輯
  - 浮動 AppBar 動畫
  - 標籤篩選對話框

#### 違反原則

- ❌ 單一職責原則 (SRP)
- ❌ KISS 原則

#### 重構前結構

```dart
// diary_list_screen.dart (621 行)
class DiaryListState { ... }              // 47 行
class DiaryListNotifier { ... }           // 56 行
final diaryListProvider = ...             // 3 行
class DiaryListScreen { ... }             // 515 行
  - _buildScrollView                      // 40 行
  - _buildActions                         // 25 行
  - _buildHeaderSection                   // 28 行
  - _buildContentSection                  // 54 行
  - _groupEntriesByDate                   // 21 行
  - _buildTimelineGroup                   // 45 行
  - _buildTimelineItem                    // 60 行
  - _buildFloatingAppBar                  // 45 行
  - _showTagFilterDialog                  // 42 行
```

#### 重構後結構

```
lib/features/diary/
├── screens/
│   ├── diary_list_screen.dart           # 150 行 - 主畫面
│   └── widgets/
│       ├── timeline_group_widget.dart   # 100 行 - 時間軸群組
│       ├── timeline_item_widget.dart    # 80 行 - 時間軸項目
│       ├── floating_app_bar.dart        # 90 行 - 浮動標題列
│       └── tag_filter_dialog.dart       # 70 行 - 標籤篩選
├── providers/
│   └── diary_list_provider.dart         # 120 行 - 狀態管理
└── utils/
    └── diary_date_grouper.dart          # 50 行 - 日期分組邏輯
```

#### 詳細執行步驟

##### Step 1：建立 Provider 檔案

```bash
# 建立 providers 目錄
mkdir -p lib/features/diary/providers
```

建立檔案：`lib/features/diary/providers/diary_list_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/models/diary_tag.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';
import 'package:travel_diary/features/diary/services/diary_repository_impl.dart';

/// 日記列表畫面狀態
class DiaryListState {
  final List<DiaryEntry> entries;
  final List<DiaryTag> allTags;
  final List<String> selectedTagIds;
  final bool isLoading;
  final String? error;

  const DiaryListState({
    this.entries = const [],
    this.allTags = const [],
    this.selectedTagIds = const [],
    this.isLoading = false,
    this.error,
  });

  DiaryListState copyWith({
    List<DiaryEntry>? entries,
    List<DiaryTag>? allTags,
    List<String>? selectedTagIds,
    bool? isLoading,
    String? error,
  }) {
    return DiaryListState(
      entries: entries ?? this.entries,
      allTags: allTags ?? this.allTags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 日記列表狀態管理器
class DiaryListNotifier extends StateNotifier<DiaryListState> {
  final DiaryRepository _repository;

  DiaryListNotifier(this._repository) : super(const DiaryListState()) {
    loadDiaries();
  }

  /// 載入日記列表
  Future<void> loadDiaries() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entries = state.selectedTagIds.isEmpty
          ? await _repository.getAllDiaryEntries()
          : await _repository.getDiaryEntriesByTags(state.selectedTagIds);

      final tags = await _repository.getAllTags();

      state = state.copyWith(entries: entries, allTags: tags, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 切換標籤篩選
  void toggleTagFilter(String tagId) {
    final selectedTags = List<String>.from(state.selectedTagIds);

    if (selectedTags.contains(tagId)) {
      selectedTags.remove(tagId);
    } else {
      selectedTags.add(tagId);
    }

    state = state.copyWith(selectedTagIds: selectedTags);
    loadDiaries();
  }

  /// 清除所有標籤篩選
  void clearTagFilters() {
    state = state.copyWith(selectedTagIds: []);
    loadDiaries();
  }

  /// 刪除日記
  Future<void> deleteDiary(String diaryId) async {
    try {
      await _repository.deleteDiaryEntry(diaryId);
      await loadDiaries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Repository Provider（待 Task 1.2 建立）
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();
});

/// 日記列表 Provider
final diaryListProvider =
    StateNotifierProvider<DiaryListNotifier, DiaryListState>(
  (ref) => DiaryListNotifier(ref.read(diaryRepositoryProvider)),
);
```

##### Step 2：建立日期分組工具

建立目錄和檔案：`lib/features/diary/utils/diary_date_grouper.dart`

```dart
import 'package:intl/intl.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';

/// 日記日期分組工具
class DiaryDateGrouper {
  /// 按日期分組日記條目
  ///
  /// 返回格式：[{date: '2025-01-22', entries: [...]}, ...]
  /// 日期從新到舊排序
  static List<Map<String, dynamic>> groupByDate(List<DiaryEntry> entries) {
    final Map<String, List<DiaryEntry>> grouped = {};

    // 按日期分組
    for (final entry in entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.visitDate);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    // 轉換為列表並排序
    final List<Map<String, dynamic>> result = [];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 降序：最新在前

    for (final key in sortedKeys) {
      // 同一天內按時間降序排序
      final entriesInDay = grouped[key]!;
      entriesInDay.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      result.add({'date': key, 'entries': entriesInDay});
    }

    return result;
  }

  /// 取得星期名稱（中文）
  static String getWeekdayName(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${weekdays[weekday - 1]}';
  }
}
```

##### Step 3：提取時間軸群組 Widget

建立檔案：`lib/features/diary/screens/widgets/timeline_group_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/providers/diary_list_provider.dart';
import 'package:travel_diary/features/diary/utils/diary_date_grouper.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'timeline_item_widget.dart';

/// 時間軸日期分組 Widget
///
/// 顯示一個日期下的所有日記條目
class TimelineGroupWidget extends StatelessWidget {
  const TimelineGroupWidget({
    super.key,
    required this.date,
    required this.entries,
    required this.notifier,
    required this.imageUploadService,
  });

  final String date; // 格式：'yyyy-MM-dd'
  final List<DiaryEntry> entries;
  final DiaryListNotifier notifier;
  final ImageUploadService imageUploadService;

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.parse(date);
    final displayDate = DateFormat('yyyy年MM月dd日').format(dateTime);
    final weekday = DiaryDateGrouper.getWeekdayName(dateTime.weekday);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期標頭
          _buildDateHeader(context, displayDate, weekday),

          // 時間軸上的日記卡片
          ...entries.map(
            (entry) => TimelineItemWidget(
              entry: entry,
              notifier: notifier,
              imageUploadService: imageUploadService,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立日期標頭
  Widget _buildDateHeader(
    BuildContext context,
    String displayDate,
    String weekday,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.timelineCardIndent,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
        top: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            displayDate,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ThemeConfig.neutralText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            weekday,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeConfig.neutralText.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}
```

##### Step 4：提取時間軸項目 Widget

建立檔案：`lib/features/diary/screens/widgets/timeline_item_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';
import 'package:travel_diary/features/diary/providers/diary_list_provider.dart';
import 'package:travel_diary/features/diary/widgets/diary_card.dart';
import 'package:travel_diary/features/diary/screens/diary_detail_screen.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';

/// 時間軸單一項目 Widget
///
/// 包含時間軸節點、時間標籤和日記卡片
class TimelineItemWidget extends StatelessWidget {
  const TimelineItemWidget({
    super.key,
    required this.entry,
    required this.notifier,
    required this.imageUploadService,
  });

  final DiaryEntry entry;
  final DiaryListNotifier notifier;
  final ImageUploadService imageUploadService;

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('HH:mm').format(entry.visitDate);

    return Stack(
      children: [
        // 時間軸垂直線
        _buildTimelineLine(),

        // 時間軸節點（圓點）
        _buildTimelineDot(),

        // 時間標籤
        _buildTimeLabel(context, timeText),

        // 日記卡片
        _buildDiaryCard(context),
      ],
    );
  }

  /// 建立時間軸垂直線
  Widget _buildTimelineLine() {
    return Positioned(
      left: AppSpacing.lg,
      top: 0,
      bottom: 0,
      child: Container(
        width: AppSpacing.timelineLineWidth,
        color: ThemeConfig.neutralBorder,
      ),
    );
  }

  /// 建立時間軸節點
  Widget _buildTimelineDot() {
    return Positioned(
      left: AppSpacing.lg - (AppSpacing.timelineDotSize / 2) + 1,
      top: 0,
      child: Container(
        width: AppSpacing.timelineDotSize,
        height: AppSpacing.timelineDotSize,
        decoration: BoxDecoration(
          color: ThemeConfig.accentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  /// 建立時間標籤
  Widget _buildTimeLabel(BuildContext context, String timeText) {
    return Positioned(
      left: AppSpacing.lg + AppSpacing.timelineDotSize + AppSpacing.xs,
      top: -1,
      child: Text(
        timeText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeConfig.accentColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
      ),
    );
  }

  /// 建立日記卡片
  Widget _buildDiaryCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: AppSpacing.xl, top: AppSpacing.lg),
      child: DiaryCard(
        entry: entry,
        imageUploadService: imageUploadService,
        onTap: () => _navigateToDiaryDetail(context),
      ),
    );
  }

  /// 導航到日記詳情
  Future<void> _navigateToDiaryDetail(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(entry: entry),
      ),
    );

    if (result == true) {
      notifier.loadDiaries();
    }
  }
}
```

##### Step 5：提取浮動 AppBar Widget

建立檔案：`lib/features/diary/screens/widgets/floating_app_bar.dart`

```dart
import 'package:flutter/material.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/diary/providers/diary_list_provider.dart';

/// 浮動 AppBar Widget
///
/// 在列表滾動時顯示的固定標題列
class FloatingAppBar extends StatelessWidget {
  const FloatingAppBar({
    super.key,
    required this.offset,
    required this.opacity,
    required this.state,
    required this.notifier,
    required this.onFilterTap,
    required this.onSettingsTap,
  });

  final double offset;
  final double opacity;
  final DiaryListState state;
  final DiaryListNotifier notifier;
  final VoidCallback onFilterTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: offset,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '旅食日記',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.neutralText,
                          ),
                    ),
                  ),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 建立操作按鈕列表
  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 標籤篩選按鈕
        if (state.allTags.isNotEmpty)
          IconButton(
            icon: Badge(
              isLabelVisible: state.selectedTagIds.isNotEmpty,
              label: Text('${state.selectedTagIds.length}'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: onFilterTap,
          ),
        // 設定按鈕
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: onSettingsTap,
        ),
      ],
    );
  }
}
```

##### Step 6：提取標籤篩選對話框

建立檔案：`lib/features/diary/screens/widgets/tag_filter_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/providers/diary_list_provider.dart';

/// 標籤篩選對話框
///
/// 讓使用者選擇要篩選的標籤
class TagFilterDialog extends ConsumerWidget {
  const TagFilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryListProvider);
    final notifier = ref.read(diaryListProvider.notifier);

    return AlertDialog(
      title: const Text('標籤篩選'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: state.allTags.map((tag) {
            final isSelected = state.selectedTagIds.contains(tag.id);
            return CheckboxListTile(
              title: Text(tag.name),
              value: isSelected,
              onChanged: (value) {
                notifier.toggleTagFilter(tag.id);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        if (state.selectedTagIds.isNotEmpty)
          TextButton(
            onPressed: () {
              notifier.clearTagFilters();
              Navigator.of(context).pop();
            },
            child: const Text('清除篩選'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    );
  }
}
```

##### Step 7：重構主畫面

修改檔案：`lib/features/diary/screens/diary_list_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/providers/diary_list_provider.dart';
import 'package:travel_diary/features/diary/utils/diary_date_grouper.dart';
import 'package:travel_diary/features/diary/screens/diary_create_screen.dart';
import 'package:travel_diary/features/diary/screens/widgets/timeline_group_widget.dart';
import 'package:travel_diary/features/diary/screens/widgets/floating_app_bar.dart';
import 'package:travel_diary/features/diary/screens/widgets/tag_filter_dialog.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'package:travel_diary/features/home/screens/settings_screen.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';

/// 日記列表畫面
class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  final ScrollController _scrollController = ScrollController();
  double _appBarOffset = -100.0;
  double _appBarOpacity = 0.0;
  static const double _appBarThreshold = 20;
  static const double _appBarTransitionRange = 80.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;

    // 計算進度：offset 從 80 到 160 之間，progress 從 0.0 到 1.0
    final progress = ((offset - _appBarThreshold) / _appBarTransitionRange)
        .clamp(0.0, 1.0);

    // 計算 app bar 的位移：從 -100 到 0
    final newOffset = -100.0 + (100.0 * progress);

    // 計算透明度：從 0.0 到 1.0
    final newOpacity = progress;

    if (newOffset != _appBarOffset || newOpacity != _appBarOpacity) {
      setState(() {
        _appBarOffset = newOffset;
        _appBarOpacity = newOpacity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryListProvider);
    final notifier = ref.read(diaryListProvider.notifier);
    final imageUploadService = ImageUploadService();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => notifier.loadDiaries(),
              child: _buildScrollView(state, notifier, imageUploadService),
            ),
            FloatingAppBar(
              offset: _appBarOffset,
              opacity: _appBarOpacity,
              state: state,
              notifier: notifier,
              onFilterTap: () => _showTagFilterDialog(),
              onSettingsTap: () => _navigateToSettings(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateDiary(notifier),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScrollView(
    DiaryListState state,
    DiaryListNotifier notifier,
    ImageUploadService imageUploadService,
  ) {
    // 處理載入、錯誤、空狀態
    if (state.isLoading && state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorView(state.error!, notifier);
    }

    // 使用 CustomScrollView
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 固定標題區塊
        _buildHeaderSection(state, notifier),
        // 列表內容
        _buildContentSection(state, notifier, imageUploadService),
      ],
    );
  }

  Widget _buildErrorView(String error, DiaryListNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('載入失敗: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => notifier.loadDiaries(),
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    DiaryListState state,
    DiaryListNotifier notifier,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '旅食日記',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.neutralText,
                    ),
              ),
            ),
            // 標籤篩選按鈕
            if (state.allTags.isNotEmpty)
              IconButton(
                icon: Badge(
                  isLabelVisible: state.selectedTagIds.isNotEmpty,
                  label: Text('${state.selectedTagIds.length}'),
                  child: const Icon(Icons.filter_list),
                ),
                onPressed: () => _showTagFilterDialog(),
              ),
            // 設定按鈕
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _navigateToSettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(
    DiaryListState state,
    DiaryListNotifier notifier,
    ImageUploadService imageUploadService,
  ) {
    if (state.entries.isEmpty) {
      return _buildEmptyView(state);
    }

    // 按日期分組日記
    final groupedEntries = DiaryDateGrouper.groupByDate(state.entries);

    return SliverPadding(
      padding: EdgeInsets.only(bottom: 80 + AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= groupedEntries.length) return null;
            final dateGroup = groupedEntries[index];
            return TimelineGroupWidget(
              date: dateGroup['date'] as String,
              entries: dateGroup['entries'] as List,
              notifier: notifier,
              imageUploadService: imageUploadService,
            );
          },
          childCount: groupedEntries.length,
        ),
      ),
    );
  }

  Widget _buildEmptyView(DiaryListState state) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              state.selectedTagIds.isEmpty ? '還沒有日記' : '沒有符合篩選條件的日記',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.selectedTagIds.isEmpty ? '點擊下方按鈕開始記錄你的旅程' : '試試調整篩選條件',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateDiary(DiaryListNotifier notifier) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const DiaryCreateScreen()),
    );

    if (result == true) {
      notifier.loadDiaries();
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showTagFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const TagFilterDialog(),
    );
  }
}
```

#### 驗證步驟

```bash
# 1. 執行 Dart Analyzer
cd frontend
fvm dart analyze lib/features/diary/screens/
fvm dart analyze lib/features/diary/providers/
fvm dart analyze lib/features/diary/utils/

# 2. 格式化程式碼
fvm dart format lib/features/diary/

# 3. 執行應用程式測試（手動）
fvm flutter run

# 4. 確認功能正常
# - 日記列表顯示正常
# - 時間軸顯示正常
# - 浮動 AppBar 動畫正常
# - 標籤篩選功能正常
# - 刷新功能正常
```

#### 完成標準

- [ ] 所有新檔案建立完成
- [ ] diary_list_screen.dart 重構為 150 行左右
- [ ] Dart Analyzer 無錯誤
- [ ] 應用程式執行正常
- [ ] 所有功能正常運作
- [ ] Git commit 完成

---

### Task 1.2：建立 Diary Repository Provider

**優先級**：🔴 高
**預估時間**：1 小時
**相關檔案**：
- `lib/features/diary/services/diary_repository.dart`
- `lib/features/diary/services/diary_repository_impl.dart`
- `lib/features/diary/providers/diary_providers.dart`（新建）

#### 問題描述

目前直接在 provider 中實例化 `DiaryRepositoryImpl()`，違反依賴反轉原則。

#### 重構前

```dart
// diary_list_provider.dart
final diaryListProvider = StateNotifierProvider<DiaryListNotifier, DiaryListState>(
  (ref) => DiaryListNotifier(DiaryRepositoryImpl()),  // ❌ 直接實例化
);
```

#### 重構後

建立檔案：`lib/features/diary/providers/diary_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';
import 'package:travel_diary/features/diary/services/diary_repository_impl.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';

/// Diary Repository Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();
});

/// Image Upload Service Provider
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService();
});
```

更新 `diary_list_provider.dart`：

```dart
import 'package:travel_diary/features/diary/providers/diary_providers.dart';

final diaryListProvider = StateNotifierProvider<DiaryListNotifier, DiaryListState>(
  (ref) => DiaryListNotifier(ref.read(diaryRepositoryProvider)),  // ✅ 依賴注入
);
```

#### 驗證步驟

```bash
fvm dart analyze lib/features/diary/providers/
```

---

### Task 1.3：拆分 diary_detail_screen.dart

**優先級**：🔴 高
**預估時間**：2-3 小時
**檔案位置**：`lib/features/diary/screens/diary_detail_screen.dart`

#### 問題描述

- 檔案大小：543 行
- 包含多個 UI 區塊，建議拆分為獨立 Widget

#### 重構後結構

```
lib/features/diary/screens/
├── diary_detail_screen.dart         # 200 行 - 主畫面
└── widgets/
    ├── diary_detail_header.dart     # 120 行 - 頭部（圖片+標題）
    ├── diary_info_section.dart      # 100 行 - 資訊區塊
    ├── diary_content_section.dart   # 80 行 - 內容區塊
    └── diary_photo_grid.dart        # 80 行 - 照片網格
```

#### 執行步驟

（步驟類似 Task 1.1，提取各區塊為獨立 Widget）

---

### Task 1.4：修復 N+1 查詢問題

**優先級**：🔴 高（效能影響）
**預估時間**：2 小時
**檔案位置**：`lib/features/diary/services/diary_repository_impl.dart`

#### 問題描述

在 `getAllDiaryEntries` 和 `getDiaryEntriesByTags` 中，對每個日記條目都執行額外的查詢來載入標籤和圖片，造成 N+1 查詢問題。

#### 重構前

```dart
@override
Future<List<DiaryEntry>> getAllDiaryEntries() async {
  // ...查詢日記...

  // ❌ N+1 問題：對每個 entry 執行 2 次額外查詢
  for (var entry in entries) {
    final tags = await getTagsForDiary(entry.id);      // N 次
    final images = await getImagesForDiary(entry.id);  // N 次

    entries[entries.indexOf(entry)] = entry.copyWith(
      tags: tags.map((tag) => tag.name).toList(),
      imagePaths: images.map((img) => img.storagePath).toList(),
    );
  }

  return entries;
}
```

#### 重構後

```dart
@override
Future<List<DiaryEntry>> getAllDiaryEntries() async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('User not authenticated');

  // ✅ 使用 JOIN 一次性查詢所有資料
  final response = await _supabase
      .from('diary_entries')
      .select('''
        *,
        diary_entry_tags(tag_id, diary_tags(id, name)),
        diary_images(storage_path, display_order)
      ''')
      .eq('user_id', userId)
      .order('visit_date', ascending: false);

  return (response as List).map((json) {
    // 解析關聯資料
    final tags = (json['diary_entry_tags'] as List?)
        ?.map((t) => (t['diary_tags'] as Map<String, dynamic>)['name'] as String)
        .toList() ?? [];

    final images = (json['diary_images'] as List?)
        ?.map((i) => i['storage_path'] as String)
        .toList() ?? [];

    // 移除關聯欄位，避免 fromJson 解析錯誤
    final entryJson = Map<String, dynamic>.from(json);
    entryJson.remove('diary_entry_tags');
    entryJson.remove('diary_images');

    final entry = DiaryEntry.fromJson(entryJson);
    return entry.copyWith(tags: tags, imagePaths: images);
  }).toList();
}

@override
Future<List<DiaryEntry>> getDiaryEntriesByTags(List<String> tagIds) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('User not authenticated');

  if (tagIds.isEmpty) {
    return getAllDiaryEntries();
  }

  // 先查詢有指定標籤的日記 ID
  final tagResponse = await _supabase
      .from('diary_entry_tags')
      .select('diary_entry_id')
      .inFilter('tag_id', tagIds);

  final diaryIds = (tagResponse as List)
      .map((e) => e['diary_entry_id'] as String)
      .toSet()
      .toList();

  if (diaryIds.isEmpty) return [];

  // ✅ 使用 JOIN 查詢日記和關聯資料
  final response = await _supabase
      .from('diary_entries')
      .select('''
        *,
        diary_entry_tags(tag_id, diary_tags(id, name)),
        diary_images(storage_path, display_order)
      ''')
      .inFilter('id', diaryIds)
      .eq('user_id', userId)
      .order('visit_date', ascending: false);

  return (response as List).map((json) {
    final tags = (json['diary_entry_tags'] as List?)
        ?.map((t) => (t['diary_tags'] as Map<String, dynamic>)['name'] as String)
        .toList() ?? [];

    final images = (json['diary_images'] as List?)
        ?.map((i) => i['storage_path'] as String)
        .toList() ?? [];

    final entryJson = Map<String, dynamic>.from(json);
    entryJson.remove('diary_entry_tags');
    entryJson.remove('diary_images');

    final entry = DiaryEntry.fromJson(entryJson);
    return entry.copyWith(tags: tags, imagePaths: images);
  }).toList();
}

@override
Future<DiaryEntry?> getDiaryEntryById(String id) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('User not authenticated');

  // ✅ 同樣使用 JOIN
  final response = await _supabase
      .from('diary_entries')
      .select('''
        *,
        diary_entry_tags(tag_id, diary_tags(id, name)),
        diary_images(storage_path, display_order)
      ''')
      .eq('id', id)
      .eq('user_id', userId)
      .maybeSingle();

  if (response == null) return null;

  final tags = (response['diary_entry_tags'] as List?)
      ?.map((t) => (t['diary_tags'] as Map<String, dynamic>)['name'] as String)
      .toList() ?? [];

  final images = (response['diary_images'] as List?)
      ?.map((i) => i['storage_path'] as String)
      .toList() ?? [];

  final entryJson = Map<String, dynamic>.from(response);
  entryJson.remove('diary_entry_tags');
  entryJson.remove('diary_images');

  final entry = DiaryEntry.fromJson(entryJson);
  return entry.copyWith(tags: tags, imagePaths: images);
}
```

#### 驗證步驟

```bash
# 1. Dart Analyze
fvm dart analyze lib/features/diary/services/

# 2. 測試效能（可選）
# 在 Supabase Dashboard 查看 SQL 查詢次數
# 重構前：1 + N + N 次查詢（N = 日記數量）
# 重構後：1 次查詢
```

---

### Task 1.5：提取 Magic Numbers 為常數

**優先級**：🔴 高
**預估時間**：1 小時
**影響檔案**：
- `lib/features/diary/screens/diary_list_screen.dart`
- `lib/core/constants/animation_constants.dart`（新建）

#### 問題描述

浮動 AppBar 動畫相關的數值硬編碼在程式碼中。

#### 重構前

```dart
class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  double _appBarOffset = -100.0;              // ❌ Magic Number
  double _appBarOpacity = 0.0;                // ❌ Magic Number
  static const double _appBarThreshold = 20;   // ❌ Magic Number
  static const double _appBarTransitionRange = 80.0;  // ❌ Magic Number
}
```

#### 重構後

建立檔案：`lib/core/constants/animation_constants.dart`

```dart
/// 動畫相關常數
class AnimationConstants {
  AnimationConstants._(); // 私有建構子，防止實例化

  // === 浮動 AppBar 動畫 ===

  /// AppBar 初始 Y 軸位移（隱藏狀態）
  static const double appBarInitialOffset = -100.0;

  /// AppBar 初始透明度
  static const double appBarInitialOpacity = 0.0;

  /// AppBar 開始顯示的滾動閾值（像素）
  static const double appBarScrollThreshold = 20.0;

  /// AppBar 顯示動畫的過渡範圍（像素）
  static const double appBarTransitionRange = 80.0;

  // === 通用動畫時長 ===

  /// 快速動畫時長
  static const Duration fastDuration = Duration(milliseconds: 200);

  /// 標準動畫時長
  static const Duration standardDuration = Duration(milliseconds: 300);

  /// 慢速動畫時長
  static const Duration slowDuration = Duration(milliseconds: 500);
}
```

更新 `diary_list_screen.dart`：

```dart
import 'package:travel_diary/core/constants/animation_constants.dart';

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  double _appBarOffset = AnimationConstants.appBarInitialOffset;
  double _appBarOpacity = AnimationConstants.appBarInitialOpacity;

  void _onScroll() {
    final offset = _scrollController.offset;

    final progress = ((offset - AnimationConstants.appBarScrollThreshold) /
        AnimationConstants.appBarTransitionRange).clamp(0.0, 1.0);

    final newOffset = AnimationConstants.appBarInitialOffset +
        (100.0 * progress);

    // ...
  }
}
```

---

### Task 1.6：diary_create_screen.dart 改用 Provider

**優先級**：🔴 高
**預估時間**：1.5 小時
**檔案位置**：`lib/features/diary/screens/diary_create_screen.dart`

#### 問題描述

直接實例化服務，違反依賴注入原則。

#### 重構前

```dart
class _DiaryCreateScreenState extends ConsumerState<DiaryCreateScreen> {
  late final DiaryRepository _repository;
  late final ImagePickerService _imagePickerService;
  late final ImageUploadService _imageUploadService;

  @override
  void initState() {
    super.initState();
    _repository = DiaryRepositoryImpl();          // ❌
    _imagePickerService = ImagePickerService();   // ❌
    _imageUploadService = ImageUploadService();   // ❌
    // ...
  }
}
```

#### 重構後

首先，在 `lib/features/images/providers/image_providers.dart` 建立 Provider：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/images/services/image_picker_service.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';

/// Image Picker Service Provider
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

/// Image Upload Service Provider
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService();
});
```

更新 `diary_create_screen.dart`：

```dart
import 'package:travel_diary/features/diary/providers/diary_providers.dart';
import 'package:travel_diary/features/images/providers/image_providers.dart';

class _DiaryCreateScreenState extends ConsumerState<DiaryCreateScreen> {
  // ✅ 移除 late final 欄位
  // late final DiaryRepository _repository;
  // late final ImagePickerService _imagePickerService;
  // late final ImageUploadService _imageUploadService;

  @override
  void initState() {
    super.initState();
    // ✅ 移除實例化
    _contentController = QuillController.basic();
    _isEditing = widget.existingEntry != null;
    if (_isEditing) {
      _loadExistingEntry();
    }
  }

  Future<void> _pickImages() async {
    try {
      // ✅ 使用 ref.read() 取得服務
      final imagePickerService = ref.read(imagePickerServiceProvider);

      final images = await imagePickerService.pickMultipleImagesFromGallery(
        maxImages: 5 - _selectedImages.length,
      );
      // ...
    } catch (e) {
      // ...
    }
  }

  Future<void> _saveDiary() async {
    // ...

    try {
      // ✅ 使用 ref.read() 取得服務
      final repository = ref.read(diaryRepositoryProvider);
      final imageUploadService = ref.read(imageUploadServiceProvider);

      // ...原有邏輯...

      DiaryEntry savedEntry;
      if (_isEditing) {
        savedEntry = await repository.updateDiaryEntry(diaryData);
      } else {
        savedEntry = await repository.createDiaryEntry(diaryData);
      }

      // 上傳圖片
      if (_selectedImages.isNotEmpty) {
        final uploadedPaths = await imageUploadService.uploadMultipleImages(
          imageFiles: _selectedImages,
          diaryId: savedEntry.id,
        );

        // 將圖片記錄到資料庫
        for (int i = 0; i < uploadedPaths.length; i++) {
          await repository.addImageToDiary(
            diaryId: savedEntry.id,
            storagePath: uploadedPaths[i],
            displayOrder: i,
          );
        }
      }

      // 處理標籤
      for (final tagName in _tags) {
        final tag = await repository.createTag(tagName);
        await repository.addTagToDiary(savedEntry.id, tag.id);
      }

      // ...
    } catch (e) {
      // ...
    }
  }
}
```

---

### Task 1.7：diary_detail_screen.dart 改用 Provider

**優先級**：🟡 中
**預估時間**：1 小時
**檔案位置**：`lib/features/diary/screens/diary_detail_screen.dart`

（步驟類似 Task 1.6）

---

### Task 1.8：改善標籤篩選對話框

**優先級**：🟡 中
**預估時間**：1 小時
**檔案位置**：`lib/features/diary/screens/widgets/tag_filter_dialog.dart`

#### 問題描述

目前每次點選標籤都會關閉並重新開啟對話框，使用者體驗不佳。

#### 重構方案

已在 Task 1.1 的 `tag_filter_dialog.dart` 中使用 `ConsumerWidget` 和 `ref.watch()` 解決，無需額外修改。

---

### Task 1.9：建立共用 UI 工具方法

**優先級**：🟡 中
**預估時間**：0.5 小時

#### 建立檔案

`lib/core/utils/ui_utils.dart`

```dart
import 'package:flutter/material.dart';

/// UI 相關工具方法
class UiUtils {
  UiUtils._(); // 私有建構子

  /// 顯示錯誤訊息 SnackBar
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '關閉',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 顯示成功訊息 SnackBar
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 顯示一般訊息 SnackBar
  static void showInfoSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 顯示載入對話框
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message ?? '載入中...'),
            ],
          ),
        ),
      ),
    );
  }

  /// 顯示確認對話框
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '確定',
    String cancelText = '取消',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
```

#### 使用範例

在各個畫面中替換 SnackBar 顯示：

```dart
// ❌ 重構前
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('儲存失敗: $e')),
);

// ✅ 重構後
UiUtils.showErrorSnackBar(context, '儲存失敗: $e');
```

---

### Task 1.10：修復 Dart Analyzer 警告（Diary 模組）

**優先級**：🟡 中
**預估時間**：0.5 小時

#### 執行步驟

```bash
# 1. 自動修復
cd frontend
fvm dart fix --apply lib/features/diary/

# 2. 手動檢查剩餘警告
fvm dart analyze lib/features/diary/

# 3. 主要修復項目：
# - 將相對 import 改為 package import
# - 加上 const constructors
```

#### 修復範例

```dart
// ❌ 重構前
import '../models/diary_entry.dart';
SizedBox(height: AppSpacing.md)

// ✅ 重構後
import 'package:travel_diary/features/diary/models/diary_entry.dart';
const SizedBox(height: AppSpacing.md)
```

---

### Task 1.11：提取深層嵌套 Widget

**優先級**：🟢 低
**預估時間**：1 小時
**檔案位置**：`lib/features/diary/screens/diary_detail_screen.dart`

（已在 Task 1.3 中處理）

---

### Task 1.12：加上詳細註解

**優先級**：🟢 低
**預估時間**：1 小時

#### 範例

```dart
/// 查詢使用者的所有日記，並載入關聯的標籤和圖片
///
/// 使用 JOIN 查詢避免 N+1 問題。
/// 返回的日記按 visit_date 降序排列（最新在前）。
///
/// 如果使用者未登入，會拋出 [Exception]。
@override
Future<List<DiaryEntry>> getAllDiaryEntries() async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('User not authenticated');

  // 使用 Supabase 的關聯查詢功能，一次取得所有資料
  final response = await _supabase
      .from('diary_entries')
      .select('''
        *,
        diary_entry_tags(tag_id, diary_tags(id, name)),
        diary_images(storage_path, display_order)
      ''')
      .eq('user_id', userId)
      .order('visit_date', ascending: false);

  // ...
}
```

---

## Places 模組重構

### 模組概覽

```
lib/features/places/
├── models/              # 4 個檔案
├── screens/             # 1 個檔案 ⚠️
└── services/            # 1 個檔案 ⚠️
```

**發現問題**：5 個
**優先級分布**：🔴 1 個 | 🟡 3 個 | 🟢 1 個

---

### Task 2.1：建立 Places Provider

**優先級**：🔴 高
**預估時間**：0.5 小時

#### 建立檔案

`lib/features/places/providers/places_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/places/services/places_service.dart';
import 'package:travel_diary/core/config/api_config.dart';

/// Places Service Provider
///
/// 提供 Google Places API 服務實例
final placesServiceProvider = Provider<PlacesService>((ref) {
  final apiConfig = ref.watch(apiConfigProvider);
  return PlacesService(apiConfig);
});
```

**注意**：places_service.dart 第 364 行已經有 Provider 定義，需要移動到專用檔案。

---

### Task 2.2：改善 PlacesService 錯誤處理

**優先級**：🟡 中
**預估時間**：1.5 小時
**檔案位置**：`lib/features/places/services/places_service.dart`

#### 問題描述

錯誤處理不夠詳細，無法區分不同類型的錯誤。

#### 重構方案

建立檔案：`lib/features/places/exceptions/places_exceptions.dart`

```dart
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
  NetworkException([String? message])
      : super(message ?? '無法連接到伺服器，請檢查網路連線');
}

/// 請求超時
class TimeoutException extends PlacesException {
  TimeoutException([String? message])
      : super(message ?? '請求超時，請稍後再試');
}

/// 配額超限
class QuotaExceededException extends PlacesException {
  QuotaExceededException()
      : super('API 請求超過限額，請稍後再試', 429);
}

/// API 回應錯誤
class ApiResponseException extends PlacesException {
  ApiResponseException(String message, [int? statusCode])
      : super(message, statusCode);
}
```

更新 `places_service.dart`：

```dart
import 'dart:io';
import 'dart:async';
import 'package:travel_diary/features/places/exceptions/places_exceptions.dart';

class PlacesService {
  // ...

  Future<List<Place>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radius = 2000,
    int maxResults = 20,
  }) async {
    if (_apiKey.isEmpty) {
      throw ApiKeyException();
    }

    final url = Uri.parse('$_baseUrl/places:searchNearby');

    // ...

    try {
      final response = await http
          .post(url, headers: headers, body: json.encode(requestBody))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // ...
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw ApiKeyException('API 金鑰無效或權限不足');
      } else if (response.statusCode == 429) {
        throw QuotaExceededException();
      } else {
        throw ApiResponseException(
          '搜尋失敗: ${response.body}',
          response.statusCode,
        );
      }
    } on TimeoutException {
      throw PlacesException('請求超時');
    } on SocketException {
      throw NetworkException();
    } on PlacesException {
      rethrow;
    } catch (e) {
      throw ApiResponseException('未知錯誤: $e');
    }
  }

  // 其他方法也套用相同的錯誤處理模式
}
```

---

### Task 2.3：place_picker_screen.dart 狀態管理優化

**優先級**：🟡 中
**預估時間**：2 小時
**檔案位置**：`lib/features/places/screens/place_picker_screen.dart`

#### 問題描述

- 使用 StatefulWidget 直接管理狀態
- 多個狀態變數散落各處
- 建議改用 StateNotifier

#### 重構方案

建立狀態類別：`lib/features/places/providers/place_picker_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travel_diary/features/places/models/place.dart';
import 'package:travel_diary/features/places/models/place_suggestion.dart';
import 'package:travel_diary/features/places/services/places_service.dart';
import 'package:travel_diary/core/services/location_service.dart';

/// 地點選擇器狀態
class PlacePickerState {
  final LatLng? currentLocation;
  final List<Place> places;
  final List<PlaceSuggestion> suggestions;
  final Place? selectedPlace;
  final bool isLoading;
  final bool isSearching;
  final bool isLoadingSuggestion;
  final String? error;

  const PlacePickerState({
    this.currentLocation,
    this.places = const [],
    this.suggestions = const [],
    this.selectedPlace,
    this.isLoading = false,
    this.isSearching = false,
    this.isLoadingSuggestion = false,
    this.error,
  });

  PlacePickerState copyWith({
    LatLng? currentLocation,
    List<Place>? places,
    List<PlaceSuggestion>? suggestions,
    Place? selectedPlace,
    bool? isLoading,
    bool? isSearching,
    bool? isLoadingSuggestion,
    String? error,
    bool clearSelectedPlace = false,
  }) {
    return PlacePickerState(
      currentLocation: currentLocation ?? this.currentLocation,
      places: places ?? this.places,
      suggestions: suggestions ?? this.suggestions,
      selectedPlace: clearSelectedPlace ? null : (selectedPlace ?? this.selectedPlace),
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isLoadingSuggestion: isLoadingSuggestion ?? this.isLoadingSuggestion,
      error: error,
    );
  }
}

/// 地點選擇器狀態管理器
class PlacePickerNotifier extends StateNotifier<PlacePickerState> {
  final PlacesService _placesService;
  final LocationService _locationService;

  PlacePickerNotifier(this._placesService, this._locationService)
      : super(const PlacePickerState()) {
    _initializeLocation();
  }

  /// 初始化位置
  Future<void> _initializeLocation() async {
    state = state.copyWith(isLoading: true);

    try {
      final position = await _locationService.getCurrentPosition();
      final location = LatLng(position!.latitude, position.longitude);

      state = state.copyWith(
        currentLocation: location,
        isLoading: false,
      );

      // 自動搜尋附近地點
      await searchNearbyPlaces();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '無法取得位置: $e',
      );
    }
  }

  /// 搜尋附近地點
  Future<void> searchNearbyPlaces() async {
    if (state.currentLocation == null) return;

    state = state.copyWith(isSearching: true, error: null);

    try {
      final places = await _placesService.searchNearbyRestaurants(
        latitude: state.currentLocation!.latitude,
        longitude: state.currentLocation!.longitude,
        radius: 5000,
        maxResults: 20,
      );

      state = state.copyWith(places: places, isSearching: false);
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: '搜尋失敗: $e',
      );
    }
  }

  /// 搜尋自動完成建議
  Future<void> searchAutocomplete(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: [], isLoadingSuggestion: false);
      return;
    }

    state = state.copyWith(isLoadingSuggestion: true, error: null);

    try {
      final suggestions = await _placesService.searchPlacesAutocomplete(
        input: query,
        latitude: state.currentLocation?.latitude,
        longitude: state.currentLocation?.longitude,
      );

      state = state.copyWith(
        suggestions: suggestions,
        isLoadingSuggestion: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingSuggestion: false,
        error: '搜尋失敗: $e',
      );
    }
  }

  /// 選擇建議的地點
  Future<void> selectSuggestion(PlaceSuggestion suggestion) async {
    state = state.copyWith(isLoading: true);

    try {
      final placeDetails = await _placesService.getPlaceDetails(
        suggestion.placeId,
      );

      final place = Place(
        id: placeDetails.id,
        name: placeDetails.name,
        formattedAddress: placeDetails.formattedAddress,
        location: placeDetails.location,
        rating: placeDetails.rating,
        priceLevel: placeDetails.priceLevel,
        types: placeDetails.types,
        photos: placeDetails.photos,
        internationalPhoneNumber: placeDetails.internationalPhoneNumber,
        websiteUri: placeDetails.websiteUri,
        currentOpeningHours: placeDetails.currentOpeningHours,
      );

      state = state.copyWith(
        selectedPlace: place,
        suggestions: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '取得地點詳細資訊失敗: $e',
      );
    }
  }

  /// 選擇地點
  void selectPlace(Place place) {
    state = state.copyWith(selectedPlace: place);
  }

  /// 清除選擇
  void clearSelection() {
    state = state.copyWith(clearSelectedPlace: true);
  }

  /// 清除搜尋建議
  void clearSuggestions() {
    state = state.copyWith(suggestions: []);
  }
}

/// Place Picker Provider
final placePickerProvider =
    StateNotifierProvider<PlacePickerNotifier, PlacePickerState>((ref) {
  return PlacePickerNotifier(
    ref.read(placesServiceProvider),
    ref.read(locationServiceProvider),
  );
});
```

重構 `place_picker_screen.dart` 為 `ConsumerWidget`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/places/providers/place_picker_provider.dart';
import 'package:travel_diary/features/places/models/place.dart';
import 'dart:async';

/// 地點選擇畫面
class PlacePickerScreen extends ConsumerStatefulWidget {
  const PlacePickerScreen({super.key});

  @override
  ConsumerState<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends ConsumerState<PlacePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      ref.read(placePickerProvider.notifier).clearSuggestions();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(placePickerProvider.notifier).searchAutocomplete(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placePickerProvider);
    final notifier = ref.read(placePickerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: state.selectedPlace != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => notifier.clearSelection(),
              )
            : null,
        title: const Text('選擇地點'),
        actions: [
          if (state.selectedPlace != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(state.selectedPlace),
              child: const Text('確定'),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 搜尋框
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜尋地點...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _debounce?.cancel();
                                notifier.clearSuggestions();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

                // 地點列表、搜尋建議或地圖顯示
                Expanded(
                  child: _buildContent(state, notifier),
                ),
              ],
            ),
    );
  }

  Widget _buildContent(PlacePickerState state, PlacePickerNotifier notifier) {
    if (state.currentLocation == null) {
      return const Center(child: Text('正在取得位置...'));
    }

    if (state.selectedPlace != null) {
      return _buildMapView(state.selectedPlace!);
    }

    if (_searchController.text.isNotEmpty) {
      return _buildSuggestionsList(state, notifier);
    }

    return _buildPlacesList(state, notifier);
  }

  // ... 其他 UI 方法保持不變 ...
}
```

---

### Task 2.4：修復 Dart Analyzer 警告（Places 模組）

**優先級**：🟡 中
**預估時間**：0.5 小時

```bash
cd frontend
fvm dart fix --apply lib/features/places/
fvm dart analyze lib/features/places/
```

---

### Task 2.5：加上詳細註解（Places 模組）

**優先級**：🟢 低
**預估時間**：0.5 小時

---

## Auth 模組重構

### 模組概覽

```
lib/features/auth/
├── models/              # 0 個檔案
├── screens/             # 1 個檔案
├── services/            # 1 個檔案
└── providers/           # 1 個檔案
```

**發現問題**：2 個
**優先級分布**：🟡 2 個

---

### Task 3.1：修復 Dart Analyzer 警告（Auth 模組）

**優先級**：🟡 中
**預估時間**：0.5 小時

```bash
fvm dart fix --apply lib/features/auth/
```

---

### Task 3.2：加上詳細註解（Auth 模組）

**優先級**：🟡 中
**預估時間**：0.5 小時

---

## Images 模組重構

### 模組概覽

```
lib/features/images/
└── services/            # 2 個檔案
```

**發現問題**：2 個
**優先級分布**：🔴 1 個 | 🟡 1 個

---

### Task 4.1：建立 Images Provider

**優先級**：🔴 高
**預估時間**：0.5 小時

（已在 Task 1.6 中完成）

---

### Task 4.2：加上詳細註解（Images 模組）

**優先級**：🟡 中
**預估時間**：0.5 小時

---

## Core 模組重構

### Task 5.1：建立動畫常數檔案

**優先級**：🔴 高
**預估時間**：0.5 小時

（已在 Task 1.5 中完成）

---

### Task 5.2：建立 UI 工具方法

**優先級**：🟡 中
**預估時間**：0.5 小時

（已在 Task 1.9 中完成）

---

## 執行時間表

### 第 1 週：Diary 模組（高優先級）

#### Day 1-2（6-8 小時）
- [x] Task 1.1：拆分 diary_list_screen.dart（3-4 小時）
- [x] Task 1.2：建立 Diary Repository Provider（1 小時）
- [x] Task 1.5：提取 Magic Numbers 為常數（1 小時）
- [x] Task 5.1：建立動畫常數檔案（0.5 小時）

#### Day 3-4（6-8 小時）
- [ ] Task 1.4：修復 N+1 查詢問題（2 小時）
- [ ] Task 1.3：拆分 diary_detail_screen.dart（2-3 小時）
- [ ] Task 1.6：diary_create_screen.dart 改用 Provider（1.5 小時）
- [ ] Task 4.1：建立 Images Provider（0.5 小時）

#### Day 5（4 小時）
- [ ] Task 1.7：diary_detail_screen.dart 改用 Provider（1 小時）
- [ ] Task 1.9：建立共用 UI 工具方法（0.5 小時）
- [ ] Task 1.10：修復 Dart Analyzer 警告（Diary 模組）（0.5 小時）
- [ ] Task 5.2：建立 UI 工具方法（0.5 小時）
- [ ] 測試與驗證（1.5 小時）

---

### 第 2 週：Places 模組（中優先級）

#### Day 6-7（6-8 小時）
- [ ] Task 2.1：建立 Places Provider（0.5 小時）
- [ ] Task 2.2：改善 PlacesService 錯誤處理（1.5 小時）
- [ ] Task 2.3：place_picker_screen.dart 狀態管理優化（2 小時）
- [ ] Task 2.4：修復 Dart Analyzer 警告（Places 模組）（0.5 小時）
- [ ] 測試與驗證（2 小時）

---

### 第 3 週：Auth、Images 模組與最終整理

#### Day 8（2 小時）
- [ ] Task 3.1：修復 Dart Analyzer 警告（Auth 模組）（0.5 小時）
- [ ] Task 3.2：加上詳細註解（Auth 模組）（0.5 小時）
- [ ] Task 4.2：加上詳細註解（Images 模組）（0.5 小時）

#### Day 9-10（4-6 小時）
- [ ] Task 1.11：提取深層嵌套 Widget（1 小時）
- [ ] Task 1.12：加上詳細註解（Diary 模組）（1 小時）
- [ ] Task 2.5：加上詳細註解（Places 模組）（0.5 小時）
- [ ] 全專案最終驗證（2 小時）
- [ ] 文件更新（1 小時）

---

## 完成檢查清單

### Diary 模組

#### Task 1.1：拆分 diary_list_screen.dart
- [ ] providers/diary_list_provider.dart 建立完成
- [ ] utils/diary_date_grouper.dart 建立完成
- [ ] screens/widgets/timeline_group_widget.dart 建立完成
- [ ] screens/widgets/timeline_item_widget.dart 建立完成
- [ ] screens/widgets/floating_app_bar.dart 建立完成
- [ ] screens/widgets/tag_filter_dialog.dart 建立完成
- [ ] diary_list_screen.dart 重構完成（約 150 行）
- [ ] Dart Analyzer 無錯誤
- [ ] 應用程式執行正常
- [ ] Git commit 完成

#### Task 1.2：建立 Diary Repository Provider
- [ ] providers/diary_providers.dart 建立完成
- [ ] diary_list_provider.dart 更新完成
- [ ] Dart Analyzer 無錯誤
- [ ] Git commit 完成

#### Task 1.3：拆分 diary_detail_screen.dart
- [ ] screens/widgets/diary_detail_header.dart 建立完成
- [ ] screens/widgets/diary_info_section.dart 建立完成
- [ ] screens/widgets/diary_content_section.dart 建立完成
- [ ] screens/widgets/diary_photo_grid.dart 建立完成
- [ ] diary_detail_screen.dart 重構完成（約 200 行）
- [ ] Dart Analyzer 無錯誤
- [ ] 應用程式執行正常
- [ ] Git commit 完成

#### Task 1.4：修復 N+1 查詢問題
- [ ] getAllDiaryEntries 改用 JOIN 查詢
- [ ] getDiaryEntriesByTags 改用 JOIN 查詢
- [ ] getDiaryEntryById 改用 JOIN 查詢
- [ ] Dart Analyzer 無錯誤
- [ ] 功能測試通過
- [ ] 效能改善確認
- [ ] Git commit 完成

#### Task 1.5：提取 Magic Numbers 為常數
- [ ] core/constants/animation_constants.dart 建立完成
- [ ] diary_list_screen.dart 更新完成
- [ ] Dart Analyzer 無錯誤
- [ ] Git commit 完成

#### Task 1.6：diary_create_screen.dart 改用 Provider
- [ ] images/providers/image_providers.dart 建立完成
- [ ] diary_create_screen.dart 更新完成
- [ ] Dart Analyzer 無錯誤
- [ ] 功能測試通過
- [ ] Git commit 完成

#### Task 1.7：diary_detail_screen.dart 改用 Provider
- [ ] diary_detail_screen.dart 更新完成
- [ ] Dart Analyzer 無錯誤
- [ ] 功能測試通過
- [ ] Git commit 完成

#### Task 1.8：改善標籤篩選對話框
- [ ] 功能已在 Task 1.1 完成
- [ ] 驗證完成

#### Task 1.9：建立共用 UI 工具方法
- [ ] core/utils/ui_utils.dart 建立完成
- [ ] 各畫面更新使用 UiUtils
- [ ] Dart Analyzer 無錯誤
- [ ] Git commit 完成

#### Task 1.10：修復 Dart Analyzer 警告（Diary 模組）
- [ ] dart fix --apply 執行完成
- [ ] 手動修復剩餘警告
- [ ] Dart Analyzer 無警告
- [ ] Git commit 完成

#### Task 1.11：提取深層嵌套 Widget
- [ ] 已在 Task 1.3 完成
- [ ] 驗證完成

#### Task 1.12：加上詳細註解
- [ ] 所有 public API 加上註解
- [ ] 複雜邏輯加上說明
- [ ] Git commit 完成

### Places 模組

#### Task 2.1：建立 Places Provider
- [ ] providers/places_providers.dart 建立完成
- [ ] 移動現有 Provider 定義
- [ ] Dart Analyzer 無錯誤
- [ ] Git commit 完成

#### Task 2.2：改善 PlacesService 錯誤處理
- [ ] exceptions/places_exceptions.dart 建立完成
- [ ] PlacesService 更新完成
- [ ] 所有方法套用新錯誤處理
- [ ] Dart Analyzer 無錯誤
- [ ] 功能測試通過
- [ ] Git commit 完成

#### Task 2.3：place_picker_screen.dart 狀態管理優化
- [ ] providers/place_picker_provider.dart 建立完成
- [ ] place_picker_screen.dart 重構為 ConsumerWidget
- [ ] Dart Analyzer 無錯誤
- [ ] 功能測試通過
- [ ] Git commit 完成

#### Task 2.4：修復 Dart Analyzer 警告（Places 模組）
- [ ] dart fix --apply 執行完成
- [ ] Dart Analyzer 無警告
- [ ] Git commit 完成

#### Task 2.5：加上詳細註解（Places 模組）
- [ ] 所有 public API 加上註解
- [ ] Git commit 完成

### Auth 模組

#### Task 3.1：修復 Dart Analyzer 警告（Auth 模組）
- [ ] dart fix --apply 執行完成
- [ ] Dart Analyzer 無警告
- [ ] Git commit 完成

#### Task 3.2：加上詳細註解（Auth 模組）
- [ ] 所有 public API 加上註解
- [ ] Git commit 完成

### Images 模組

#### Task 4.1：建立 Images Provider
- [ ] 已在 Task 1.6 完成
- [ ] 驗證完成

#### Task 4.2：加上詳細註解（Images 模組）
- [ ] 所有 public API 加上註解
- [ ] Git commit 完成

### Core 模組

#### Task 5.1：建立動畫常數檔案
- [ ] 已在 Task 1.5 完成
- [ ] 驗證完成

#### Task 5.2：建立 UI 工具方法
- [ ] 已在 Task 1.9 完成
- [ ] 驗證完成

### 最終驗證

- [ ] 所有 Dart Analyzer 警告已修復
- [ ] 所有功能測試通過
- [ ] 效能改善確認
- [ ] 程式碼品質提升確認
- [ ] 文件更新完成
- [ ] refactoring-guide.md 更新
- [ ] README.md 更新

---

## 附錄

### Git Commit 訊息格式

```
refactor(模組): 簡短描述

- 詳細說明 1
- 詳細說明 2

Refs: #issue-number
```

範例：

```
refactor(diary): split diary_list_screen into multiple files

- Extract DiaryListNotifier to providers/diary_list_provider.dart
- Extract TimelineGroupWidget to screens/widgets/timeline_group_widget.dart
- Extract FloatingAppBar to screens/widgets/floating_app_bar.dart
- Reduce diary_list_screen.dart from 621 to 150 lines

Refs: #23
```

### 驗證命令

```bash
# Dart Analyzer
fvm dart analyze lib/features/

# Dart Format
fvm dart format lib/features/

# 執行應用程式
fvm flutter run

# 清理快取（如需要）
fvm flutter clean
fvm flutter pub get
```

---

**結語**

本重構計劃旨在系統性地改善程式碼品質，預計在 2-3 週內完成。請按照優先級和時間表執行，並在每個 Task 完成後進行驗證和 Git commit。

祝重構順利！🚀
