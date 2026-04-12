import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Timeline entry widget for a [QuickGuideEntry].
class QuickGuideTimelineEntry extends ConsumerStatefulWidget {
  final QuickGuideEntry entry;
  final bool isLast;

  const QuickGuideTimelineEntry({
    super.key,
    required this.entry,
    this.isLast = false,
  });

  @override
  ConsumerState<QuickGuideTimelineEntry> createState() =>
      _QuickGuideTimelineEntryState();
}

class _QuickGuideTimelineEntryState
    extends ConsumerState<QuickGuideTimelineEntry> {
  bool _isDeleting = false;

  void _navigateToPlayer() {
    if (_isDeleting) return;

    final NarrationContent content;
    try {
      content = NarrationContent.create(
        widget.entry.aiDescription,
        language: widget.entry.language,
      );
    } catch (_) {
      return;
    }

    final place = Place(
      id: 'quick-guide-${widget.entry.id}',
      name: 'quick_guide.title'.tr(),
      formattedAddress: '',
      location: const PlaceLocation(latitude: 0, longitude: 0),
      types: const [],
      photos: const [],
      category: PlaceCategory.modernUrban,
    );

    context.push<void>(
      '/player',
      extra: {'place': place, 'narrationContent': content, 'autoPlay': true},
    );
  }

  Future<void> _showDeleteConfirmDialog() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'passport.delete_title'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'passport.delete_message'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'passport.cancel'.tr(),
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'passport.delete_confirm'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isDeleting = true);

      try {
        await ref.read(quickGuideRepositoryProvider).delete(widget.entry.id);
        ref.invalidate(quickGuideEntriesProvider);
        ref.invalidate(allJourneyItemsProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'common.error_prefix'.tr()}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) return 'passport.today'.tr();
    if (entryDate == yesterday) return 'passport.yesterday'.tr();
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return GestureDetector(
      onTap: _navigateToPlayer,
      child: Container(
        padding: const EdgeInsets.only(left: 32, bottom: 40),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!widget.isLast)
              Positioned(
                left: -21,
                top: 32,
                bottom: -40,
                child: Container(
                  width: 2,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),

            // Timeline node (camera icon instead of plain dot)
            Positioned(
              left: -32,
              top: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A7AE4),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.backgroundDark, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 11),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatDateLabel(
                                  widget.entry.createdAt,
                                ).toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF2A7AE4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeFormat.format(widget.entry.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'quick_guide.title'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Thumbnail from captured image
                    Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.saturation,
                        ),
                        child: Opacity(
                          opacity: 0.8,
                          child: Image.memory(
                            widget.entry.imageBytes,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.aiDescription,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 15,
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_isDeleting)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            else
                              _DeleteButton(onTap: _showDeleteConfirmDialog),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline,
            size: 16,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 6),
          Text(
            'passport.delete_confirm'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
