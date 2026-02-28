import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/auth/presentation/widgets/login_dialog.dart';
import 'package:context_app/features/auth/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/journey/presentation/widgets/timeline_entry.dart';

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);

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
      body: isSignedIn ? _buildJourneyList(ref) : _buildLoginPrompt(context),
    );
  }

  Widget _buildJourneyList(WidgetRef ref) {
    final journeyAsyncValue = ref.watch(myJourneyProvider);

    return journeyAsyncValue.when(
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
            final isLast = index == entries.length - 1;
            return TimelineEntry(
              key: ValueKey(entry.id),
              entry: entry,
              isLast: isLast,
            );
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

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'passport.login_required'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () => showLoginDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'auth.login'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
