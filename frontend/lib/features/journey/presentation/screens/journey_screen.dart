import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/journey/presentation/widgets/quick_guide_timeline_entry.dart';
import 'package:context_app/features/journey/presentation/widgets/timeline_entry.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/trip/presentation/widgets/trip_grid.dart';
import 'package:context_app/features/trip/providers/trip_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final viewMode = ref.watch(journeyViewModeProvider);
    final isTimeline = viewMode == JourneyViewMode.timeline;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with search toggle (only in timeline mode)
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
                  if (isTimeline)
                    IconButton(
                      onPressed: _toggleSearch,
                      icon: Icon(
                        _showSearch ? Icons.close : Icons.search,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => context.push('/trip/edit'),
                      tooltip: 'trip.create_action'.tr(),
                      icon: Icon(
                        Icons.add,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // Current trip banner
            const _CurrentTripBanner(),

            // View mode segmented control
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ViewModeToggle(viewMode: viewMode),
            ),

            // Search bar (timeline mode only)
            if (isTimeline)
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
                            ref
                                    .read(journeySearchQueryProvider.notifier)
                                    .state =
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

            // Filter chips (timeline mode only)
            if (isTimeline) _FilterChips(),

            // Main content
            Expanded(
              child: isTimeline ? _JourneyList() : const _TripGridView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewModeToggle extends ConsumerWidget {
  final JourneyViewMode viewMode;

  const _ViewModeToggle({required this.viewMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildSegment(
            context: context,
            ref: ref,
            label: 'passport.view_timeline'.tr(),
            selected: viewMode == JourneyViewMode.timeline,
            target: JourneyViewMode.timeline,
            colorScheme: colorScheme,
          ),
          _buildSegment(
            context: context,
            ref: ref,
            label: 'passport.view_by_trip'.tr(),
            selected: viewMode == JourneyViewMode.byTrip,
            target: JourneyViewMode.byTrip,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required bool selected,
    required JourneyViewMode target,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(journeyViewModeProvider.notifier).state = target,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentTripBanner extends ConsumerWidget {
  const _CurrentTripBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTripId = ref.watch(currentTripIdProvider);
    if (currentTripId == null) return const SizedBox.shrink();

    final tripAsync = ref.watch(tripByIdProvider(currentTripId));
    return tripAsync.maybeWhen(
      data: (trip) {
        if (trip == null) return const SizedBox.shrink();
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/trip/${trip.id}'),
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.85),
                      AppColors.primary.withValues(alpha: 0.65),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'trip.current_badge'.tr(),
                              style: TextStyle(
                                color: colorScheme.onPrimary.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              trip.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(currentTripIdProvider.notifier).clear(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'trip.end_current'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _TripGridView extends ConsumerWidget {
  const _TripGridView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTrips = ref.watch(tripsProvider);
    final asyncCounts = ref.watch(tripItemCountsProvider);
    final currentTripId = ref.watch(currentTripIdProvider);

    return asyncTrips.when(
      data: (trips) {
        final counts = asyncCounts.asData?.value ?? const <String?, int>{};
        return TripGrid(
          trips: trips,
          counts: counts,
          currentTripId: currentTripId,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          '${'trip.load_error'.tr()}: $error',
          style: const TextStyle(color: AppColors.error),
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
