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
              padding: const EdgeInsets.symmetric(
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
