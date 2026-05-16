import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/app/config/app_colors.dart';
import 'package:context_app/core/services/place_image_cache_manager.dart';
import 'package:context_app/features/ads/presentation/widgets/watch_ad_dialog.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_generation_controller.dart';
import 'package:context_app/features/narration/presentation/controllers/story_hook_controller.dart';
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

/// 「挑一段歷史故事」選擇頁。
///
/// 開啟時自動呼叫 [StoryHookService] 為景點產生 2-3 個歷史故事鉤子，
/// 使用者挑一張卡片後再展開為完整 narration。
/// 若鉤子產生失敗或為空，顯示「直接聽故事」fallback 按鈕。
class SelectStoryHookScreen extends ConsumerStatefulWidget {
  final Place place;
  final Uint8List? capturedImageBytes;

  const SelectStoryHookScreen({
    super.key,
    required this.place,
    this.capturedImageBytes,
  });

  @override
  ConsumerState<SelectStoryHookScreen> createState() =>
      _SelectStoryHookScreenState();
}

class _SelectStoryHookScreenState extends ConsumerState<SelectStoryHookScreen> {
  Language _currentLanguage() {
    final locale = EasyLocalization.of(context)?.locale.toLanguageTag();
    return Language(locale ?? 'zh-TW');
  }

  Future<void> _onHookSelected(StoryHook? hook) async {
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

    ref
        .read(narrationGenerationControllerProvider.notifier)
        .generate(
          place: widget.place,
          language: _currentLanguage(),
          hook: hook,
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
    final language = _currentLanguage();
    final hookArgs = StoryHookArgs(place: widget.place, language: language);
    final hookState = ref.watch(storyHookControllerProvider(hookArgs));
    final generationState = ref.watch(narrationGenerationControllerProvider);

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

    final photoUrl = widget.place.primaryPhoto?.url;
    final isGenerating = generationState.isGenerating;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _BackgroundImage(
              photoUrl: photoUrl,
              capturedImageBytes: widget.capturedImageBytes,
            ),
          ),
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
                    Text(
                      widget.place.name,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    _CategoryBadge(place: widget.place),
                    const SizedBox(height: 24),
                    if (isGenerating)
                      const _GeneratingIndicator()
                    else
                      _HookContent(
                        state: hookState,
                        onHookTap: _onHookSelected,
                        onListenDefault: () => _onHookSelected(null),
                      ),
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

class _HookContent extends StatelessWidget {
  final StoryHookState state;
  final void Function(StoryHook hook) onHookTap;
  final VoidCallback onListenDefault;

  const _HookContent({
    required this.state,
    required this.onHookTap,
    required this.onListenDefault,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      StoryHookStatus.loading => const _HookLoadingState(),
      StoryHookStatus.success => _HookListState(
        hooks: state.hooks,
        onTap: onHookTap,
      ),
      StoryHookStatus.empty ||
      StoryHookStatus.error => _HookFallbackState(onListen: onListenDefault),
    };
  }
}

class _HookLoadingState extends StatelessWidget {
  const _HookLoadingState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveProgressIndicator(color: cs.primary),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'story_hook.loading'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _HookListState extends StatelessWidget {
  final List<StoryHook> hooks;
  final void Function(StoryHook hook) onTap;

  const _HookListState({required this.hooks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'story_hook.title'.tr(),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: hooks
                  .map(
                    (hook) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StoryHookCard(
                        hook: hook,
                        onTap: () => onTap(hook),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _HookFallbackState extends StatelessWidget {
  final VoidCallback onListen;
  const _HookFallbackState({required this.onListen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'story_hook.fallback_title'.tr(),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'story_hook.fallback_body'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        PillButton(
          label: 'story_hook.listen_default_button'.tr(),
          icon: Icons.play_arrow,
          fullWidth: true,
          onPressed: onListen,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class StoryHookCard extends StatelessWidget {
  final StoryHook hook;
  final VoidCallback onTap;

  const StoryHookCard({super.key, required this.hook, required this.onTap});

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
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_stories,
                      color: cs.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hook.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hook.teaser,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratingIndicator extends StatelessWidget {
  const _GeneratingIndicator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveProgressIndicator(color: cs.primary),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'config_screen.generating'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
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
