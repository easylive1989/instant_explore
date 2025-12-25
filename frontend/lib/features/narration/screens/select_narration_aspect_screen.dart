import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/presentation/extensions/place_category_extension.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/presentation/extensions/narration_aspect_extension.dart';
import 'package:context_app/features/narration/providers.dart';

class SelectNarrationAspectScreen extends ConsumerWidget {
  final Place place;

  const SelectNarrationAspectScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAspect = ref.watch(narrationAspectProvider);

    // 根據景點類型取得可用的介紹面向
    final availableAspects = NarrationAspect.getAspectsForCategory(
      place.category,
    );

    final photoUrl = place.primaryPhoto?.url;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: photoUrl != null
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    color: const Color(0x66000000),
                    colorBlendMode: BlendMode.darken,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.backgroundDark,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.backgroundDark,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.white54,
                        ),
                      );
                    },
                  )
                : Container(color: AppColors.backgroundDark),
          ),

          // Top Navigation
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),

          // Bottom Interaction Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.backgroundDark,
                    Color(0xCC101922),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Place Name
                  Text(
                    place.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Place Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: place.category.color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: place.category.color, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          place.category.icon,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          place.category.translationKey.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Place Address
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.formattedAddress,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'config_screen.select_aspect_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Aspect Options
                  ...availableAspects.map((aspect) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AspectOption(
                        aspect: aspect,
                        isSelected: selectedAspect == aspect,
                        onTap: () {
                          ref.read(narrationAspectProvider.notifier).state =
                              aspect;
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Start Button
                  ElevatedButton(
                    onPressed: () {
                      context.pushNamed(
                        'player',
                        extra: {
                          'place': place,
                          'narrationAspect': selectedAspect,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'config_screen.start_button'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AspectOption extends StatelessWidget {
  final NarrationAspect aspect;
  final bool isSelected;
  final VoidCallback onTap;

  const AspectOption({
    super.key,
    required this.aspect,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1A137FEC) : const Color(0xCC192633),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(aspect.icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aspect.translationKey.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    aspect.descriptionKey.tr(),
                    style: TextStyle(
                      color: isSelected ? Colors.blue[200] : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary)
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
