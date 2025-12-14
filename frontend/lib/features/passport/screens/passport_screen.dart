import 'package:context_app/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/passport/providers.dart';
import 'package:context_app/features/passport/models/passport_entry.dart';
import 'package:context_app/features/places/models/place.dart';

class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});

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
              return TimelineEntry(entry: entry);
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

class TimelineEntry extends StatelessWidget {
  final PassportEntry entry;

  const TimelineEntry({super.key, required this.entry});

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
                dateFormat.format(entry.createdAt),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeFormat.format(entry.createdAt),
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
                    onTap: () {
                      // Construct a partial Place object
                      final place = Place(
                        id: entry.placeId,
                        name: entry.placeName,
                        formattedAddress: entry.placeAddress,
                        location: PlaceLocation(latitude: 0, longitude: 0),
                        types: [],
                        photos: [],
                      );

                      context.pushNamed(
                        'player',
                        extra: {
                          'place': place,
                          'narrationStyle': entry.narrationStyle,
                          'initialContent': entry.narrationText,
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
                          Text(
                            entry.placeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.placeAddress,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          if (entry.placeImageUrl != null &&
                              entry.placeImageUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: entry.placeImageUrl!,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.narrationStyle.name,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            entry.narrationText,
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
