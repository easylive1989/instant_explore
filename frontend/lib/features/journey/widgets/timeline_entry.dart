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
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() {
        _isDeleting = true;
      });

      try {
        await ref
            .read(deleteJourneyEntryUseCaseProvider)
            .execute(widget.entry.id);
        // 刷新列表
        ref.invalidate(myPassportProvider);
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
      location: PlaceLocation(latitude: 0, longitude: 0),
      types: [],
      photos: [],
      category: PlaceCategory.fromPlaceTypes([]),
    );

    context.pushNamed(
      'player',
      extra: {
        'place': place,
        'narrationContent': widget.entry.narrationContent,
        'enableSave': false,
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
                child: Container(
                  width: 2,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
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
                  border: Border.all(color: AppColors.backgroundDark, width: 3),
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
                // Location Header with Thumbnail
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Date, Time, Name, Address
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date & Time
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
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Place Name
                          Text(
                            widget.entry.place.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Address
                          Text(
                            widget.entry.place.address,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: Thumbnail (grayscale, desaturated)
                    if (widget.entry.place.imageUrl != null &&
                        widget.entry.place.imageUrl!.isNotEmpty)
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
                            child: CachedNetworkImage(
                              imageUrl: widget.entry.place.imageUrl!,
                              fit: BoxFit.cover,
                              cacheManager: PlaceImageCacheManager.instance,
                              placeholder: (context, url) => Container(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image_not_supported,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Q&A Card
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
                      // Content text
                      Text(
                        widget.entry.narrationContent.text,
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

                      // Action Bar
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
                          children: [
                            _ActionButton(
                              icon: Icons.mic_outlined,
                              label: 'passport.replay'.tr(),
                              onTap: _navigateToPlayer,
                            ),
                            const Spacer(),
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
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          Text(
            label,
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
