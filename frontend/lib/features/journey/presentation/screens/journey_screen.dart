import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/journey/domain/models/journey_item.dart';
import 'package:context_app/features/journey/presentation/widgets/quick_guide_timeline_entry.dart';
import 'package:context_app/features/journey/presentation/widgets/timeline_entry.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'passport.title'.tr(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(child: _buildJourneyList(ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyList(WidgetRef ref) {
    final asyncItems = ref.watch(allJourneyItemsProvider);

    return asyncItems.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'passport.no_entries'.tr(),
              style: const TextStyle(color: Colors.white70),
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
