import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../models/diary_tag.dart';
import '../services/diary_repository.dart';
import '../services/diary_repository_impl.dart';
import '../widgets/diary_card.dart';
import '../../images/services/image_upload_service.dart';
import 'diary_create_screen.dart';
import 'diary_detail_screen.dart';
import '../../../core/constants/spacing_constants.dart';
import '../../../core/config/theme_config.dart';
import '../../home/screens/settings_screen.dart';

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

/// Provider 定義
final diaryListProvider =
    StateNotifierProvider<DiaryListNotifier, DiaryListState>(
      (ref) => DiaryListNotifier(DiaryRepositoryImpl()),
    );

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
              child: _buildScrollView(
                context,
                state,
                notifier,
                imageUploadService,
              ),
            ),
            _buildFloatingAppBar(context, state, notifier),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateDiary(context, notifier),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScrollView(
    BuildContext context,
    DiaryListState state,
    DiaryListNotifier notifier,
    ImageUploadService imageUploadService,
  ) {
    // 處理載入、錯誤、空狀態
    if (state.isLoading && state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('載入失敗: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.loadDiaries(),
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    // 使用 CustomScrollView
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 固定標題區塊
        _buildHeaderSection(context, state, notifier),
        // 列表內容
        _buildContentSection(context, state, notifier, imageUploadService),
      ],
    );
  }

  /// 建立 AppBar 與固定標題的 actions
  List<Widget> _buildActions(
    BuildContext context,
    DiaryListState state,
    DiaryListNotifier notifier,
  ) {
    return [
      // 標籤篩選按鈕
      if (state.allTags.isNotEmpty)
        IconButton(
          icon: Badge(
            isLabelVisible: state.selectedTagIds.isNotEmpty,
            label: Text('${state.selectedTagIds.length}'),
            child: const Icon(Icons.filter_list),
          ),
          onPressed: () => _showTagFilterDialog(context, state, notifier),
        ),
      // 設定按鈕
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => _navigateToSettings(context),
      ),
    ];
  }

  /// 建立固定標題區塊
  Widget _buildHeaderSection(
    BuildContext context,
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
            ..._buildActions(context, state, notifier),
          ],
        ),
      ),
    );
  }

  /// 建立內容區塊
  Widget _buildContentSection(
    BuildContext context,
    DiaryListState state,
    DiaryListNotifier notifier,
    ImageUploadService imageUploadService,
  ) {
    if (state.entries.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
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

    // 按日期分組日記
    final groupedEntries = _groupEntriesByDate(state.entries);

    return SliverPadding(
      padding: EdgeInsets.only(bottom: 80 + AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= groupedEntries.length) return null;
          final dateGroup = groupedEntries[index];
          return _buildTimelineGroup(
            context,
            dateGroup['date'] as String,
            dateGroup['entries'] as List<DiaryEntry>,
            notifier,
            imageUploadService,
          );
        }, childCount: groupedEntries.length),
      ),
    );
  }

  /// 按日期分組日記條目
  List<Map<String, dynamic>> _groupEntriesByDate(List<DiaryEntry> entries) {
    final Map<String, List<DiaryEntry>> grouped = {};

    for (final entry in entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.visitDate);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    // 將分組轉換為列表並按日期排序（最新在前）
    final List<Map<String, dynamic>> result = [];
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    for (final key in sortedKeys) {
      result.add({'date': key, 'entries': grouped[key]!});
    }

    return result;
  }

  /// 取得星期名稱
  String _getWeekdayName(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${weekdays[weekday - 1]}';
  }

  /// 建立時間軸分組
  Widget _buildTimelineGroup(
    BuildContext context,
    String date,
    List<DiaryEntry> entries,
    DiaryListNotifier notifier,
    ImageUploadService imageUploadService,
  ) {
    final dateTime = DateTime.parse(date);
    final displayDate = DateFormat('yyyy年MM月dd日').format(dateTime);
    final weekday = _getWeekdayName(dateTime.weekday);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期標頭
          Padding(
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
          ),
          // 時間軸上的日記卡片
          ...entries.map(
            (entry) => _buildTimelineItem(
              context,
              entry,
              notifier,
              imageUploadService,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立時間軸項目
  Widget _buildTimelineItem(
    BuildContext context,
    DiaryEntry entry,
    DiaryListNotifier notifier,
    ImageUploadService imageUploadService,
  ) {
    return Stack(
      children: [
        // 時間軸垂直線
        Positioned(
          left: AppSpacing.lg,
          top: 0,
          bottom: 0,
          child: Container(
            width: AppSpacing.timelineLineWidth,
            color: ThemeConfig.neutralBorder,
          ),
        ),
        // 時間軸節點
        Positioned(
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
        ),
        // 日記卡片
        Padding(
          padding: EdgeInsets.only(left: AppSpacing.xl),
          child: DiaryCard(
            entry: entry,
            imageUploadService: imageUploadService,
            onTap: () => _navigateToDiaryDetail(context, entry, notifier),
          ),
        ),
      ],
    );
  }

  void _navigateToCreateDiary(
    BuildContext context,
    DiaryListNotifier notifier,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const DiaryCreateScreen()),
    );

    if (result == true) {
      notifier.loadDiaries();
    }
  }

  void _navigateToDiaryDetail(
    BuildContext context,
    DiaryEntry entry,
    DiaryListNotifier notifier,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => DiaryDetailScreen(entry: entry)),
    );

    if (result == true) {
      notifier.loadDiaries();
    }
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  /// 建立浮動的 AppBar
  Widget _buildFloatingAppBar(
    BuildContext context,
    DiaryListState state,
    DiaryListNotifier notifier,
  ) {
    return Positioned(
      top: _appBarOffset,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: _appBarOpacity,
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
                  ..._buildActions(context, state, notifier),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTagFilterDialog(
    BuildContext context,
    DiaryListState state,
    DiaryListNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  Navigator.of(context).pop();
                  _showTagFilterDialog(context, state, notifier);
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
      ),
    );
  }
}
