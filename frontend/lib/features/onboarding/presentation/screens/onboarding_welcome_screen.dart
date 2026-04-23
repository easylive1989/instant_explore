import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/onboarding/domain/demo_narration_factory.dart';
import 'package:context_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:context_app/features/onboarding/presentation/widgets/onboarding_page_art.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:context_app/shared/widgets/midnight_kyoto_backdrop.dart';
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
///
/// The visuals are locked to the Midnight Kyoto dark palette regardless
/// of the system theme — the brand's signature atmosphere has to land
/// the first time every user opens the app.
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
    return Theme(
      data: midnightKyotoTheme(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: MidnightKyotoBackdrop(
          child: IntroductionScreen(
            globalBackgroundColor: Colors.transparent,
            allowImplicitScrolling: true,
            showSkipButton: true,
            showBackButton: false,
            showNextButton: true,
            skip: Text(
              'onboarding.skip'.tr(),
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            next: const Icon(Icons.arrow_forward, color: AppColors.primary),
            done: Text(
              'onboarding.get_started'.tr(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            onSkip: _finish,
            onDone: _finish,
            dotsDecorator: DotsDecorator(
              activeColor: AppColors.primary,
              color: AppColors.white20,
              size: const Size(6, 6),
              activeSize: const Size(24, 6),
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            pages: [
              _page(
                serialLabel: '01',
                chipKey: 'onboarding.chip.discovery',
                titleKey: 'onboarding.welcome.title',
                bodyKey: 'onboarding.welcome.body',
                icon: Icons.auto_stories,
                accent: AppColors.primary,
              ),
              _page(
                serialLabel: '02',
                chipKey: 'onboarding.chip.ai_guide',
                titleKey: 'onboarding.quick_guide.title',
                bodyKey: 'onboarding.quick_guide.body',
                icon: Icons.camera_alt_rounded,
                accent: AppColors.primary,
              ),
              _page(
                serialLabel: '03',
                chipKey: 'onboarding.chip.explore',
                titleKey: 'onboarding.explore.title',
                bodyKey: 'onboarding.explore.body',
                icon: Icons.explore_rounded,
                accent: AppColors.primary,
              ),
              _page(
                serialLabel: '04',
                chipKey: 'onboarding.chip.passport',
                titleKey: 'onboarding.journey.title',
                bodyKey: 'onboarding.journey.body',
                icon: Icons.headphones_rounded,
                accent: AppColors.amber,
                footer: _SampleCtaFooter(onTap: _playSample),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PageViewModel _page({
    required String serialLabel,
    required String chipKey,
    required String titleKey,
    required String bodyKey,
    required IconData icon,
    required Color accent,
    Widget? footer,
  }) {
    const titleStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: AppColors.textPrimaryDark,
    );
    const bodyStyle = TextStyle(
      fontSize: 15,
      height: 1.55,
      color: AppColors.textSecondaryDark,
    );

    return PageViewModel(
      titleWidget: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
        child: Text(
          titleKey.tr(),
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
      ),
      bodyWidget: Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(bodyKey.tr(), style: bodyStyle, textAlign: TextAlign.center),
            if (footer != null) ...[const SizedBox(height: 28), footer],
          ],
        ),
      ),
      image: OnboardingPageArt(
        icon: icon,
        serialLabel: serialLabel,
        chipLabel: chipKey.tr(),
        accent: accent,
      ),
      decoration: const PageDecoration(
        pageColor: Colors.transparent,
        imagePadding: EdgeInsets.only(top: 24),
        contentMargin: EdgeInsets.zero,
        bodyPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
      ),
    );
  }
}

class _SampleCtaFooter extends StatelessWidget {
  const _SampleCtaFooter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('onboarding.try_sample'.tr()),
        ),
        const SizedBox(height: 12),
        Text(
          'onboarding.try_sample_hint'.tr(),
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.textTertiaryDark,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
