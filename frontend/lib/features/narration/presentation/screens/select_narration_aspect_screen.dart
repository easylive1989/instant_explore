import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/core/services/place_image_cache_manager.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_generation_controller.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/shared/extensions/place_category_extension.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/presentation/controllers/extensions/narration_aspect_extension.dart';
import 'package:context_app/features/ads/presentation/widgets/watch_ad_dialog.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/usage/providers.dart';

class SelectNarrationAspectScreen extends ConsumerStatefulWidget {
  final Place place;
  final Uint8List? capturedImageBytes;

  const SelectNarrationAspectScreen({
    super.key,
    required this.place,
    this.capturedImageBytes,
  });

  @override
  ConsumerState<SelectNarrationAspectScreen> createState() =>
      _SelectNarrationAspectScreenState();
}

class _SelectNarrationAspectScreenState
    extends ConsumerState<SelectNarrationAspectScreen> {
  Language _currentLanguage() {
    final locale = EasyLocalization.of(context)?.locale.toLanguageTag();
    return Language(locale ?? 'zh-TW');
  }

  Future<void> _onStartPressed() async {
    final selectedAspects = ref.read(narrationAspectsProvider);
    if (selectedAspects.isEmpty) return;

    // Quota check before generation
    final usageRepo = ref.read(usageRepositoryProvider);
    final status = await usageRepo.getUsageStatus();
    if (!status.canUseNarration) {
      if (!mounted) return;
      final result = await showWatchAdDialog(context, ref);
      if (result == 'subscribe') {
        if (!mounted) return;
        context.pushNamed('subscription');
        return;
      }
      if (result != true || !mounted) return;
    }

    if (!mounted) return;

    // Start generation on this page
    ref
        .read(narrationGenerationControllerProvider.notifier)
        .generate(
          place: widget.place,
          aspects: selectedAspects,
          language: _currentLanguage(),
        );
  }

  void _navigateToPlayer(NarrationGenerationState genState) {
    ref.read(narrationGenerationControllerProvider.notifier).reset();
    context.pushNamed(
      'player',
      extra: {
        'place': widget.place,
        'narrationContent': genState.content,
        'autoPlay': true,
      },
    );
  }

  void _showErrorDialog(NarrationGenerationState genState) {
    ref.read(narrationGenerationControllerProvider.notifier).reset();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('config_screen.generation_error_title'.tr()),
        content: Text(
          genState.errorMessage ??
              'config_screen.generation_error_message'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('config_screen.generation_error_ok'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedAspects = ref.watch(narrationAspectsProvider);
    final generationState = ref.watch(narrationGenerationControllerProvider);

    // Listen for generation success / error
    ref.listen<NarrationGenerationState>(
      narrationGenerationControllerProvider,
      (previous, current) {
        if (previous?.isSuccess != true && current.isSuccess) {
          _navigateToPlayer(current);
        }
        if (previous?.hasError != true && current.hasError) {
          _showErrorDialog(current);
        }
      },
    );

    final availableAspects = NarrationAspect.getAspectsForCategory(
      widget.place.category,
    );

    final photoUrl = widget.place.primaryPhoto?.url;
    final isGenerating = generationState.isGenerating;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: _BackgroundImage(
              photoUrl: photoUrl,
              capturedImageBytes: widget.capturedImageBytes,
            ),
          ),

          // Top Navigation
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: isGenerating
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => context.pop(),
                    ),
            ),
          ),

          // Bottom Interaction Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Place Name
                    Text(
                      widget.place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Place Category Badge
                    _CategoryBadge(place: widget.place),
                    const SizedBox(height: 12),

                    // Place Address
                    _AddressRow(place: widget.place),
                    const SizedBox(height: 24),

                    // Content area: loading spinner or aspect options
                    if (isGenerating)
                      _GeneratingIndicator()
                    else ...[
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

                      // Aspect Options (scrollable)
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: availableAspects.map((aspect) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AspectOption(
                                  aspect: aspect,
                                  isSelected: selectedAspects.contains(aspect),
                                  onTap: () {
                                    final notifier = ref.read(
                                      narrationAspectsProvider.notifier,
                                    );
                                    final current = ref.read(
                                      narrationAspectsProvider,
                                    );
                                    if (current.contains(aspect)) {
                                      notifier.state = {...current}
                                        ..remove(aspect);
                                    } else {
                                      notifier.state = {...current, aspect};
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Start Button
                      ElevatedButton(
                        onPressed: selectedAspects.isEmpty
                            ? null
                            : _onStartPressed,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'config_screen.generating'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  final String? photoUrl;
  final Uint8List? capturedImageBytes;

  const _BackgroundImage({this.photoUrl, this.capturedImageBytes});

  @override
  Widget build(BuildContext context) {
    if (capturedImageBytes != null) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0x66000000),
          BlendMode.darken,
        ),
        child: Image.memory(
          capturedImageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    if (photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        fit: BoxFit.cover,
        color: const Color(0x66000000),
        colorBlendMode: BlendMode.darken,
        cacheManager: PlaceImageCacheManager.instance,
        placeholder: (context, url) => Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.black,
          child: const Icon(
            Icons.image_not_supported,
            size: 48,
            color: Colors.white54,
          ),
        ),
      );
    }

    return Container(color: Colors.black);
  }
}

class _CategoryBadge extends StatelessWidget {
  final Place place;

  const _CategoryBadge({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: place.category.color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: place.category.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(place.category.icon, size: 16, color: Colors.white),
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
    );
  }
}

class _AddressRow extends StatelessWidget {
  final Place place;

  const _AddressRow({required this.place});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            place.formattedAddress,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
              const Icon(Icons.check_box, color: AppColors.primary)
            else
              const Icon(Icons.check_box_outline_blank, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
