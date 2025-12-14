import 'package:context_app/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/core/config/api_config.dart';
import 'package:context_app/features/explore/models/place.dart';
import 'package:context_app/features/narration/models/narration_style.dart';
import 'package:context_app/features/narration/providers.dart';

class SelectNarrationStyleScreen extends ConsumerWidget {
  final Place place;

  const SelectNarrationStyleScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiConfig = ref.watch(apiConfigProvider);
    final selectedStyle = ref.watch(narrationStyleProvider);

    final photoUrl = place.primaryPhoto?.getPhotoUrl(
      maxWidth: 800,
      apiKey: apiConfig.googleMapsApiKey,
    );

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
                    'config_screen.title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Brief Option
                  ConfigOption(
                    style: NarrationStyle.brief,
                    isSelected: selectedStyle == NarrationStyle.brief,
                    onTap: () {
                      ref.read(narrationStyleProvider.notifier).state =
                          NarrationStyle.brief;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Deep Dive Option
                  ConfigOption(
                    style: NarrationStyle.deepDive,
                    isSelected: selectedStyle == NarrationStyle.deepDive,
                    onTap: () {
                      ref.read(narrationStyleProvider.notifier).state =
                          NarrationStyle.deepDive;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Start Button
                  ElevatedButton(
                    onPressed: () {
                      context.pushNamed(
                        'player',
                        extra: {
                          'place': place,
                          'narrationStyle': selectedStyle,
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

class ConfigOption extends StatelessWidget {
  final NarrationStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const ConfigOption({
    super.key,
    required this.style,
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
                : Colors.white.withAlpha(0x1A),
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
                    : Colors.white.withAlpha(0x1A),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.translationKey.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style.descriptionKey.tr(),
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
