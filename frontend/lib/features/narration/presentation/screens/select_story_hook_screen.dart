import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/core/services/place_image_cache_manager.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:context_app/features/narration/presentation/controllers/narration_generation_controller.dart';
import 'package:context_app/features/narration/presentation/controllers/story_hook_controller.dart';
import 'package:context_app/features/narration/providers.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/features/usage/providers.dart';
import 'package:context_app/features/explore/presentation/extensions/place_category_extension.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/journal/category_tag.dart';
import 'package:context_app/shared/widgets/midnight/_press_scale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fallback warm card shadow (design token `e1`).
const List<BoxShadow> _kCardShadow = [
  BoxShadow(color: Color(0x0F281E12), offset: Offset(0, 1), blurRadius: 2),
];

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
      context.pushNamed('subscription');
      return;
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
    final isInsufficient =
        genState.errorType == NarrationGenerationErrorType.insufficientSource;
    final title = isInsufficient
        ? 'config_screen.generation_insufficient_source_title'.tr()
        : 'config_screen.generation_error_title'.tr();
    final content = isInsufficient
        ? 'config_screen.generation_insufficient_source_message'.tr()
        : (genState.errorMessage ??
              'config_screen.generation_error_message'.tr());
    showAdaptiveAlertDialog<void>(
      context: context,
      title: title,
      content: content,
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
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
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
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Color(0x66000000), blurRadius: 16),
                            ],
                          ),
                    ),
                    const SizedBox(height: 10),
                    CategoryTag(
                      category: widget.place.category.journalCategory,
                      onPhoto: true,
                    ),
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
      StoryHookStatus.insufficientSource =>
        const _HookInsufficientSourceState(),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: AdaptiveProgressIndicator(
                  color: cs.primary,
                  strokeWidth: 2.4,
                ),
              ),
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
          const SizedBox(height: 18),
          const _SkeletonLine(widthFactor: 0.92),
          const SizedBox(height: 12),
          const _SkeletonLine(widthFactor: 0.78),
          const SizedBox(height: 12),
          const _SkeletonLine(widthFactor: 0.85),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const SizedBox(height: 14),
        ),
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
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < hooks.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StoryHookCard(
                      hook: hooks[i],
                      index: i + 1,
                      onTap: () => onTap(hooks[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Shown when the backend reports `insufficient_source: true` — the
/// place has no Wikipedia-backed historical content. We deliberately
/// do NOT offer a "listen anyway" button here: the follow-up
/// /narration call would just hit the same dead-end. The user should
/// pick a different place via the back button.
class _HookInsufficientSourceState extends StatelessWidget {
  const _HookInsufficientSourceState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_outlined, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'story_hook.insufficient_source_title'.tr(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'story_hook.insufficient_source_body'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onListen,
            icon: const Icon(Icons.play_arrow, size: 20),
            label: Text('story_hook.listen_default_button'.tr()),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class StoryHookCard extends StatelessWidget {
  final StoryHook hook;
  final int index;
  final VoidCallback onTap;

  const StoryHookCard({
    super.key,
    required this.hook,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final ink3 = tokens?.ink3 ?? cs.onSurfaceVariant;

    return PressScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens?.rLg ?? 16),
          border: Border.fromBorderSide(BorderSide(color: cs.outlineVariant)),
          boxShadow: tokens?.e1 ?? _kCardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(tokens?.rLg ?? 16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hook.title,
                          style: GoogleFonts.notoSerifTc(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hook.teaser,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.55,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.chevron_right, color: ink3, size: 20),
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
