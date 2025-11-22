import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/providers/diary_list_provider.dart';
import 'package:travel_diary/features/diary/utils/diary_date_grouper.dart';
import 'package:travel_diary/features/diary/screens/diary_create_screen.dart';
import 'package:travel_diary/features/diary/screens/widgets/timeline_group_widget.dart';
import 'package:travel_diary/features/diary/screens/widgets/floating_app_bar.dart';
import 'package:travel_diary/features/diary/screens/widgets/tag_filter_dialog.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'package:travel_diary/core/constants/spacing_constants.dart';
import 'package:travel_diary/core/config/theme_config.dart';
import 'package:travel_diary/features/settings/screens/settings_screen.dart';

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
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildHeaderSection(state, notifier)),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (state.isLoading && state.entries.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null && state.entries.isEmpty) {
                  return Center(child: Text('載入失敗: ${state.error}'));
                }

                if (state.entries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('尚無日記，點擊右下角新增'),
                    ),
                  );
                }

                final groupedEntries = DiaryDateGrouper.groupByDate(
                  state.entries,
                );
                if (index >= groupedEntries.length) return null;

                final group = groupedEntries[index];
                return TimelineGroupWidget(
                  date: group['date'],
                  entries: group['entries'],
                  notifier: notifier,
                  imageUploadService: imageUploadService,
                );
              },
              childCount: state.entries.isEmpty
                  ? 1
                  : DiaryDateGrouper.groupByDate(state.entries).length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(DiaryListState state, DiaryListNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '旅食日記',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.neutralText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '記錄美好的旅遊回憶',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeConfig.neutralText.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (state.allTags.isNotEmpty)
                    IconButton(
                      icon: Badge(
                        isLabelVisible: state.selectedTagIds.isNotEmpty,
                        label: Text('${state.selectedTagIds.length}'),
                        child: const Icon(Icons.filter_list),
                      ),
                      onPressed: () => _showTagFilterDialog(),
                    ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _navigateToSettings(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 顯示當前篩選狀態
          if (state.selectedTagIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('清除篩選'),
                    avatar: const Icon(Icons.close, size: 16),
                    onPressed: () => notifier.clearTagFilters(),
                  ),
                  ...state.allTags
                      .where((tag) => state.selectedTagIds.contains(tag.id))
                      .map((tag) => Chip(label: Text(tag.name))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showTagFilterDialog() {
    showDialog(context: context, builder: (context) => const TagFilterDialog());
  }

  void _navigateToSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  Future<void> _navigateToCreateDiary(DiaryListNotifier notifier) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const DiaryCreateScreen()),
    );

    if (result == true) {
      notifier.loadDiaries();
    }
  }
}
