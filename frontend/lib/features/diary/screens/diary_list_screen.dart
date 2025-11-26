import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/providers/diary_list_provider.dart';
import 'package:travel_diary/features/diary/utils/diary_date_grouper.dart';
import 'package:travel_diary/features/diary/screens/diary_create_screen.dart';
import 'package:travel_diary/features/diary/screens/widgets/timeline_group_widget.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryListProvider);
    final notifier = ref.read(diaryListProvider.notifier);
    final imageUploadService = ImageUploadService();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => notifier.loadDiaries(),
          child: _buildScrollView(state, notifier, imageUploadService),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateDiary(notifier),
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.primary,
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
        CupertinoSliverNavigationBar(
          largeTitle: Text('app.name'.tr()),
          trailing: _buildNavigationBarActions(state),
          backgroundColor: ThemeConfig.neutralLight,
        ),
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
                  return Center(
                    child: Text('${'diary.loadFailed'.tr()}: ${state.error}'),
                  );
                }

                if (state.entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/empty_diary_state.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'diary.emptyHint'.tr(),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: ThemeConfig.neutralText.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Arrow pointing to FAB
                          CustomPaint(
                            size: const Size(100, 60),
                            painter: CurledArrowPainter(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildNavigationBarActions(DiaryListState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.allTags.isNotEmpty)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showTagFilterDialog(),
            child: state.selectedTagIds.isNotEmpty
                ? Badge(
                    label: Text('${state.selectedTagIds.length}'),
                    child: const Icon(
                      CupertinoIcons.slider_horizontal_3,
                      color: ThemeConfig.neutralText,
                    ),
                  )
                : const Icon(
                    CupertinoIcons.slider_horizontal_3,
                    color: ThemeConfig.neutralText,
                  ),
          ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _navigateToSettings(),
          child: const Icon(
            CupertinoIcons.settings,
            color: ThemeConfig.neutralText,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(DiaryListState state, DiaryListNotifier notifier) {
    // 如果沒有選中任何標籤，返回空白
    if (state.selectedTagIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: 8,
        children: [
          ActionChip(
            label: Text('diary.clearFilter'.tr()),
            avatar: const Icon(Icons.close, size: 16),
            onPressed: () => notifier.clearTagFilters(),
          ),
          ...state.allTags
              .where((tag) => state.selectedTagIds.contains(tag.id))
              .map((tag) => Chip(label: Text(tag.name))),
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

class CurledArrowPainter extends CustomPainter {
  final Color color;

  CurledArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Start from top left (near the text)
    path.moveTo(size.width * 0.2, 0);

    // Draw a curled line to bottom right
    path.cubicTo(
      size.width * 0.5,
      size.height * 0.2, // Control point 1
      size.width * 0.1,
      size.height * 0.8, // Control point 2 (loop back)
      size.width * 0.8,
      size.height * 0.8, // End point
    );

    canvas.drawPath(path, paint);

    // Draw arrow head
    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.8, size.height * 0.8);
    arrowPath.relativeLineTo(-10, -5);
    arrowPath.moveTo(size.width * 0.8, size.height * 0.8);
    arrowPath.relativeLineTo(-10, 5);

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
