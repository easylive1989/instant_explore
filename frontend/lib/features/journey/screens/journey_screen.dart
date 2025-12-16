import 'package:context_app/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/journey/widgets/timeline_entry.dart'; // New import for extracted widget

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passportAsyncValue = ref.watch(myPassportProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(
          'passport.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: passportAsyncValue.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text(
                'passport.no_entries'.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return TimelineEntry(key: ValueKey(entry.id), entry: entry);
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
      ),
    );
  }
}
