import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/core/services/place_image_cache_manager.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';

class TimelineEntry extends ConsumerStatefulWidget {
  final JourneyEntry entry;
  final bool isLast;

  const TimelineEntry({super.key, required this.entry, this.isLast = false});

  @override
  ConsumerState<TimelineEntry> createState() => _TimelineEntryState();
}

class _TimelineEntryState extends ConsumerState<TimelineEntry> {
  bool _isDeleting = false;

  Future<void> _showDeleteConfirmDialog() async {
    if (_isDeleting) return; // Prevent multiple clicks

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('passport.delete_title'.tr()),
        content: Text('passport.delete_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('passport.cancel'.tr()),
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
      setState(() {
        _isDeleting = true;
      });

      try {
        await ref.read(journeyRepositoryProvider).delete(widget.entry.id);
        ref.invalidate(myJourneyProvider);
        ref.invalidate(allJourneyItemsProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'common.error_prefix'.tr()}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
          // Only reset deleting state if error occurred (if success, widget might be removed)
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  void _navigateToPlayer() {
    if (_isDeleting) return;

    // Construct a partial Place object
    final place = Place(
      id: widget.entry.place.id,
      name: widget.entry.place.name,
      formattedAddress: widget.entry.place.address,
      location: const PlaceLocation(latitude: 0, longitude: 0),
      types: const [],
      photos: const [],
      category: PlaceCategory.modernUrban,
    );

    context.pushNamed(
      'player',
      extra: {
        'place': place,
        'narrationContent': widget.entry.narrationContent,
      },
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'passport.today'.tr();
    } else if (entryDate == yesterday) {
      return 'passport.yesterday'.tr();
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _navigateToPlayer,
      child: Container(
        padding: const EdgeInsets.only(left: 32, bottom: 40),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Connector Line
            if (!widget.isLast)
              Positioned(
                left: -21,
                top: 32,
                bottom: -40,
                child: Container(width: 2, color: colorScheme.outlineVariant),
              ),

            // Timeline Node
            Positioned(
              left: -32,
              top: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeFormat.format(widget.entry.createdAt),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.entry.place.name,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.entry.place.address,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Thumbnail
                    if (widget.entry.place.imageUrl != null &&
                        widget.entry.place.imageUrl!.isNotEmpty)
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: colorScheme.surfaceContainerHigh,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                          child: Opacity(
                            opacity: 0.8,
                            child: CachedNetworkImage(
                              imageUrl: widget.entry.place.imageUrl!,
                              fit: BoxFit.cover,
                              cacheManager: PlaceImageCacheManager.instance,
                              placeholder: (context, url) => Container(
                                color: colorScheme.surfaceContainerHigh,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image_not_supported,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Content Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.narrationContent.text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.outlineVariant,
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
                                _ActionButton(
                                  icon: Icons.delete_outline,
                                  label: 'passport.delete_confirm'.tr(),
                                  onTap: _showDeleteConfirmDialog,
                                ),
                            ],
                          ),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
