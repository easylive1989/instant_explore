import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/journey/presentation/widgets/quick_guide_timeline_entry.dart';
import 'package:context_app/features/journey/presentation/widgets/timeline_entry.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(journeySearchQueryProvider.notifier).state = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with search toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'passport.title'.tr(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleSearch,
                    icon: Icon(
                      _showSearch ? Icons.close : Icons.search,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar (animated)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _showSearch
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (value) {
                          setState(() {});
                          ref.read(journeySearchQueryProvider.notifier).state =
                              value;
                        },
                        decoration: InputDecoration(
                          hintText: 'passport.search_hint'.tr(),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                    ref
                                            .read(
                                              journeySearchQueryProvider
                                                  .notifier,
                                            )
                                            .state =
                                        '';
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Filter chips
            _FilterChips(),

            // Journey list
            Expanded(child: _JourneyList()),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(journeyFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          _buildChip(
            context: context,
            label: 'passport.filter_all'.tr(),
            selected: currentFilter == JourneyFilter.all,
            colorScheme: colorScheme,
            onTap: () => ref.read(journeyFilterProvider.notifier).state =
                JourneyFilter.all,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'passport.filter_narration'.tr(),
            selected: currentFilter == JourneyFilter.narration,
            colorScheme: colorScheme,
            onTap: () => ref.read(journeyFilterProvider.notifier).state =
                JourneyFilter.narration,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'passport.filter_quick_guide'.tr(),
            selected: currentFilter == JourneyFilter.quickGuide,
            colorScheme: colorScheme,
            onTap: () => ref.read(journeyFilterProvider.notifier).state =
                JourneyFilter.quickGuide,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _JourneyList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(filteredJourneyItemsProvider);
    final query = ref.watch(journeySearchQueryProvider).trim();
    final filter = ref.watch(journeyFilterProvider);
    final hasActiveFilter = query.isNotEmpty || filter != JourneyFilter.all;

    return asyncItems.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasActiveFilter ? Icons.search_off : Icons.explore_outlined,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasActiveFilter
                        ? 'passport.no_results'.tr()
                        : 'passport.no_entries'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isLast = index == items.length - 1;

            return switch (item) {
              NarrationJourneyItem(:final entry) => TimelineEntry(
                key: ValueKey(item.id),
                entry: entry,
                isLast: isLast,
              ),
              QuickGuideJourneyItem(:final entry) => QuickGuideTimelineEntry(
                key: ValueKey(item.id),
                entry: entry,
                isLast: isLast,
              ),
            };
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          '${'passport.load_error'.tr()}: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
