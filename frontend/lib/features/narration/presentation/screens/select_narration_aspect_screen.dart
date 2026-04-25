import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/app/config/app_colors.dart';
import 'package:context_app/core/services/place_image_cache_manager.dart';
import 'package:context_app/features/ads/presentation/widgets/watch_ad_dialog.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/presentation/controllers/extensions/narration_aspect_extension.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_generation_controller.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:context_app/shared/extensions/place_category_extension.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:context_app/shared/widgets/midnight/midnight.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    showAdaptiveAlertDialog<void>(
      context: context,
      title: 'config_screen.generation_error_title'.tr(),
      content:
          genState.errorMessage ??
          'config_screen.generation_error_message'.tr(),
      actions: [
        AdaptiveDialogAction<void>(
          label: 'config_screen.generation_error_ok'.tr(),
          isDefault: true,
        ),
      ],
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
                  : AdaptiveIconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: Theme.of(context).colorScheme.onSurface,
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.8),
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
                      style: Theme.of(context).textTheme.displayMedium,
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
                      const _GeneratingIndicator()
                    else ...[
                      // Title
                      Text(
                        'config_screen.select_aspect_title'.tr(),
                        style: Theme.of(context).textTheme.headlineMedium,
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
                      PillButton(
                        label: 'config_screen.start_button'.tr(),
                        icon: Icons.play_arrow,
                        fullWidth: true,
                        onPressed: selectedAspects.isEmpty
                            ? null
                            : _onStartPressed,
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
  const _GeneratingIndicator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AdaptiveProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'config_screen.generating'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
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
        placeholder: (context, url) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: const Center(child: AdaptiveProgressIndicator()),
        ),
        errorWidget: (context, url, error) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: const Icon(
            Icons.image_not_supported,
            size: 48,
            color: Colors.white54,
          ),
        ),
      );
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final color = place.category.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(place.category.icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              place.category.translationKey.tr().toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.location_on, color: cs.onSurfaceVariant, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            place.formattedAddress,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
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
    final cs = Theme.of(context).colorScheme;

    return PressScale(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primaryContainer
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cs.primary : cs.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : cs.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      aspect.icon,
                      color: isSelected ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aspect.translationKey.tr(),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          aspect.descriptionKey.tr(),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: isSelected
                                    ? cs.onPrimaryContainer
                                    : cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
