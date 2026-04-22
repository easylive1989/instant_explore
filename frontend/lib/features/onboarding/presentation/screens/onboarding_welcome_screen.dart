import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/onboarding/domain/demo_narration_factory.dart';
import 'package:context_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:context_app/features/onboarding/presentation/widgets/onboarding_page_art.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';

/// First-run welcome carousel.
///
/// Four pages introduce the product value, the last page offers a
/// "Try a sample guide" button that plays a hard-coded Fushimi Inari
/// narration so the user can experience the audio-guide flow without
/// hitting the AI backend. Finishing or skipping the carousel persists
/// the `welcomeDone` flag and returns the user to `/`.
class OnboardingWelcomeScreen extends ConsumerStatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  ConsumerState<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState
    extends ConsumerState<OnboardingWelcomeScreen> {
  static const DemoNarrationFactory _demoFactory = DemoNarrationFactory();

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).completeWelcome();
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _playSample() async {
    final language = _currentLanguage();
    final Place place = _demoFactory.buildPlace();
    final NarrationContent content;
    try {
      content = _demoFactory.buildContent(language);
    } catch (_) {
      return;
    }

    // Push the player *before* persisting `welcomeDone`. Otherwise the
    // state change would fire the router redirect away from /onboarding
    // mid-navigation and race with the push.
    await context.push<void>(
      '/player',
      extra: {'place': place, 'narrationContent': content, 'autoPlay': true},
    );
    if (!mounted) return;
    // When the player pops, flipping welcomeDone lets the router
    // redirect us to `/` on its own.
    await ref.read(onboardingControllerProvider.notifier).completeWelcome();
  }

  Language _currentLanguage() {
    final locale = EasyLocalization.of(context)?.locale;
    return locale?.languageCode == 'en'
        ? Language.english
        : Language.traditionalChinese;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    );
    final bodyStyle = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: colorScheme.onSurfaceVariant,
    );

    final pageDecoration = PageDecoration(
      titleTextStyle: titleStyle,
      bodyTextStyle: bodyStyle,
      bodyPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      imagePadding: const EdgeInsets.only(top: 48, bottom: 24),
      pageColor: colorScheme.surface,
    );

    return IntroductionScreen(
      globalBackgroundColor: colorScheme.surface,
      allowImplicitScrolling: true,
      showSkipButton: true,
      showBackButton: false,
      showNextButton: true,
      skip: Text('onboarding.skip'.tr()),
      next: const Icon(Icons.arrow_forward),
      done: Text(
        'onboarding.get_started'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onSkip: _finish,
      onDone: _finish,
      dotsDecorator: DotsDecorator(
        activeColor: AppColors.primary,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        size: const Size(8, 8),
        activeSize: const Size(22, 8),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      pages: [
        PageViewModel(
          titleWidget: Text(
            'onboarding.welcome.title'.tr(),
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          bodyWidget: Text(
            'onboarding.welcome.body'.tr(),
            style: bodyStyle,
            textAlign: TextAlign.center,
          ),
          image: const OnboardingPageArt(icon: Icons.auto_stories),
          decoration: pageDecoration,
        ),
        PageViewModel(
          titleWidget: Text(
            'onboarding.quick_guide.title'.tr(),
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          bodyWidget: Text(
            'onboarding.quick_guide.body'.tr(),
            style: bodyStyle,
            textAlign: TextAlign.center,
          ),
          image: const OnboardingPageArt(icon: Icons.camera_alt_rounded),
          decoration: pageDecoration,
        ),
        PageViewModel(
          titleWidget: Text(
            'onboarding.explore.title'.tr(),
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          bodyWidget: Text(
            'onboarding.explore.body'.tr(),
            style: bodyStyle,
            textAlign: TextAlign.center,
          ),
          image: const OnboardingPageArt(icon: Icons.explore),
          decoration: pageDecoration,
        ),
        PageViewModel(
          titleWidget: Text(
            'onboarding.journey.title'.tr(),
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'onboarding.journey.body'.tr(),
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _playSample,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('onboarding.try_sample'.tr()),
              ),
              const SizedBox(height: 8),
              Text(
                'onboarding.try_sample_hint'.tr(),
                style: bodyStyle.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          image: const OnboardingPageArt(
            icon: Icons.headphones_rounded,
            tint: AppColors.amber,
          ),
          decoration: pageDecoration,
        ),
      ],
    );
  }
}
