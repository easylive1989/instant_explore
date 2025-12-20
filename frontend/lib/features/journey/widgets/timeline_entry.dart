import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/journey/providers.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';

class TimelineEntry extends ConsumerStatefulWidget {
  final JourneyEntry entry;

  const TimelineEntry({super.key, required this.entry});

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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dateFormat.format(widget.entry.createdAt),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeFormat.format(widget.entry.createdAt),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.white24,
                        margin: const EdgeInsets.only(top: 4, bottom: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _isDeleting
                        ? null
                        : () {
                            // Construct a partial Place object
                            final place = Place(
                              id: widget.entry.place.id,
                              name: widget.entry.place.name,
                              formattedAddress: widget.entry.place.address,
                              location: PlaceLocation(
                                latitude: 0,
                                longitude: 0,
                              ),
                              types: [],
                              photos: [],
                              category: PlaceCategory.fromPlaceTypes([]),
                            );

                            context.pushNamed(
                              'player',
                              extra: {
                                'place': place,
                                'narrationContent':
                                    widget.entry.narrationContent,
                                'enableSave': false,
                              },
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.entry.place.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _isDeleting
                                    ? null
                                    : () => _showDeleteConfirmDialog(),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  color: Colors.transparent, // 擴大點擊區域
                                  child: _isDeleting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white38,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.entry.place.address,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          if (widget.entry.place.imageUrl != null &&
                              widget.entry.place.imageUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: widget.entry.place.imageUrl!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 150,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 150,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            widget.entry.narrationContent.text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
