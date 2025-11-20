import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/diary_entry.dart';
import '../models/diary_tag.dart';
import '../services/diary_repository.dart';
import '../services/diary_repository_impl.dart';
import '../widgets/diary_card.dart';
import '../../images/services/image_upload_service.dart';
import 'diary_create_screen.dart';
import 'diary_detail_screen.dart';

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
class DiaryListScreen extends ConsumerWidget {
  const DiaryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diaryListProvider);
    final notifier = ref.read(diaryListProvider.notifier);
    final imageUploadService = ImageUploadService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('旅食日記'),
        actions: [
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadDiaries(),
        child: _buildBody(context, state, notifier, imageUploadService),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateDiary(context, notifier),
        icon: const Icon(Icons.add),
        label: const Text('新增日記'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DiaryListState state,
    DiaryListNotifier notifier,
    ImageUploadService imageUploadService,
  ) {
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

    if (state.entries.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: state.entries.length,
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        return DiaryCard(
          entry: entry,
          imageUploadService: imageUploadService,
          onTap: () => _navigateToDiaryDetail(context, entry, notifier),
        );
      },
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
