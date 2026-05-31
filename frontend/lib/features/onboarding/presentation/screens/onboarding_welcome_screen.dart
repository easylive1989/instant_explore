import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:context_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// First-run onboarding flow (Field Journal design).
///
/// Three steps in a "hybrid" tone: an immersive dark photo welcome, then two
/// warm paper screens (value pillars and category showcase). Finishing or
/// skipping plays a short closing animation, persists the `welcomeDone` flag
/// and returns the user to `/`.
///
/// All colours come from [LorescapeTokens] (or graceful fallbacks when the
/// extension is absent, e.g. widget tests), so the flow follows the active
/// brand accent.
class OnboardingWelcomeScreen extends ConsumerStatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  ConsumerState<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState
    extends ConsumerState<OnboardingWelcomeScreen> {
  static const int _stepCount = 3;
  static const Duration _finishDuration = Duration(milliseconds: 1600);

  final PageController _pageController = PageController();
  int _step = 0;
  bool _finishing = false;

  /// Hybrid flow: the welcome step is dark, the rest are paper.
  bool _isDark(int step) => step == 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_step < _stepCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await Future<void>.delayed(_finishDuration);
    if (!mounted) return;
    await ref.read(onboardingControllerProvider.notifier).completeWelcome();
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final dark = _isDark(_step);

    return Scaffold(
      backgroundColor: dark ? palette.inkBg : palette.paper,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: _finishing
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            onPageChanged: (index) => setState(() => _step = index),
            children: const [_WelcomeStep(), _ValueStep(), _CategoriesStep()],
          ),
          _ObTopBar(
            step: _step,
            stepCount: _stepCount,
            dark: dark,
            onSkip: _finish,
          ),
          _ObDock(step: _step, dark: dark, onNext: _goNext),
          if (_finishing) const _FinishOverlay(),
        ],
      ),
    );
  }
}

// ============================================================================
// Step 1 — Welcome (immersive dark hero)
// ============================================================================

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  static const String _hero = 'assets/images/onboarding/stpeters.jpg';

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_hero, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.32, 0.66, 1.0],
              colors: [
                Color(0x6B0F0B07),
                Color(0x0D0F0B07),
                Color(0x8C0F0B07),
                Color(0xF20C0906),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(color: Colors.white.withValues(alpha: 0.86)),
                const SizedBox(height: 16),
                Text(
                  'onboarding.welcome.title'.tr(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.18,
                    letterSpacing: 0.5,
                    shadows: const [
                      Shadow(color: Color(0x73000000), blurRadius: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    'onboarding.welcome.tagline'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xD1F7F1E6),
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: palette.onDark.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'onboarding.welcome.location'.tr(),
                      style: TextStyle(
                        fontSize: 12.5,
                        letterSpacing: 0.8,
                        color: palette.onDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 26, height: 1, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 9),
        Text(
          'onboarding.eyebrow'.tr(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Step 2 — Value pillars (paper)
// ============================================================================

class _ValueStep extends StatelessWidget {
  const _ValueStep();

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: palette.paper,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 74, 0, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'onboarding.value.kicker'.tr(),
                      style: textTheme.labelMedium?.copyWith(
                        color: palette.clay,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      'onboarding.value.title'.tr(),
                      style: textTheme.displaySmall?.copyWith(
                        color: palette.ink,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 9),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        'onboarding.value.subtitle'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.ink2,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    _Pillar(
                      no: 'I',
                      icon: Icons.auto_stories_outlined,
                      titleKey: 'onboarding.value.pillar1_title',
                      bodyKey: 'onboarding.value.pillar1_body',
                    ),
                    SizedBox(height: 11),
                    _Pillar(
                      no: 'II',
                      icon: Icons.explore_outlined,
                      titleKey: 'onboarding.value.pillar2_title',
                      bodyKey: 'onboarding.value.pillar2_body',
                    ),
                    SizedBox(height: 11),
                    _Pillar(
                      no: 'III',
                      icon: Icons.collections_bookmark_outlined,
                      titleKey: 'onboarding.value.pillar3_title',
                      bodyKey: 'onboarding.value.pillar3_body',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({
    required this.no,
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  final String no;
  final IconData icon;
  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: palette.paperRaised,
        borderRadius: BorderRadius.circular(palette.rLg),
        border: Border.fromBorderSide(BorderSide(color: palette.line)),
        boxShadow: palette.e1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.clayTint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: palette.clayDeep, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  no,
                  style: textTheme.labelMedium?.copyWith(
                    color: palette.clay,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  titleKey.tr(),
                  style: textTheme.titleLarge?.copyWith(
                    color: palette.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bodyKey.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.ink2,
                    fontSize: 13.5,
                    height: 1.55,
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

// ============================================================================
// Step 3 — Category showcase (paper)
// ============================================================================

class _CategoriesStep extends StatelessWidget {
  const _CategoriesStep();

  static const List<_CategoryData> _cats = [
    _CategoryData(
      nameKey: 'onboarding.categories.nature',
      latinKey: 'onboarding.categories.nature_latin',
      image: 'assets/images/onboarding/park.jpg',
      mark: Icons.terrain_outlined,
    ),
    _CategoryData(
      nameKey: 'onboarding.categories.heritage',
      latinKey: 'onboarding.categories.heritage_latin',
      image: 'assets/images/onboarding/agra.jpg',
      mark: Icons.account_balance_outlined,
    ),
    _CategoryData(
      nameKey: 'onboarding.categories.sacred',
      latinKey: 'onboarding.categories.sacred_latin',
      image: 'assets/images/onboarding/temple.jpg',
      mark: Icons.menu_book_outlined,
    ),
    _CategoryData(
      nameKey: 'onboarding.categories.urban',
      latinKey: 'onboarding.categories.urban_latin',
      image: 'assets/images/onboarding/stpeters.jpg',
      mark: Icons.apartment_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: palette.paper,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 74, 0, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'onboarding.categories.kicker'.tr(),
                      style: textTheme.labelMedium?.copyWith(
                        color: palette.clay,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'onboarding.categories.title'.tr(),
                      style: textTheme.displaySmall?.copyWith(
                        color: palette.ink,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 11),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        'onboarding.categories.subtitle'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.ink2,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 13,
                  crossAxisSpacing: 13,
                  childAspectRatio: 1 / 1.14,
                  children: [for (final cat in _cats) _CategoryTile(data: cat)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryData {
  const _CategoryData({
    required this.nameKey,
    required this.latinKey,
    required this.image,
    required this.mark,
  });

  final String nameKey;
  final String latinKey;
  final String image;
  final IconData mark;
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.data});

  final _CategoryData data;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(palette.rLg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0x24000000),
              BlendMode.darken,
            ),
            child: Image.asset(data.image, fit: BoxFit.cover),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.3, 1.0],
                colors: [Color(0x000F0B07), Color(0xB80F0B07)],
              ),
            ),
          ),
          Positioned(
            top: 11,
            left: 11,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0x57140C08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Icon(data.mark, size: 17, color: Colors.white),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 13,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.nameKey.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    shadows: const [
                      Shadow(color: Color(0x66000000), blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.latinKey.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
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

// ============================================================================
// Chrome — progress / skip / dock
// ============================================================================

class _ObTopBar extends StatelessWidget {
  const _ObTopBar({
    required this.step,
    required this.stepCount,
    required this.dark,
    required this.onSkip,
  });

  final int step;
  final int stepCount;
  final bool dark;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final muted = dark
        ? palette.onDark.withValues(alpha: 0.22)
        : palette.lineStrong.withValues(alpha: 0.5);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < stepCount; i++) ...[
                      if (i > 0) const SizedBox(width: 7),
                      Expanded(
                        flex: i == step ? 22 : 10,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 5,
                          decoration: BoxDecoration(
                            color: i <= step ? palette.clay : muted,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (step < stepCount - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSkip,
                    child: Text(
                      'onboarding.skip'.tr(),
                      style: TextStyle(
                        color: dark ? palette.onDark2 : palette.ink3,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObDock extends StatelessWidget {
  const _ObDock({required this.step, required this.dark, required this.onNext});

  final int step;
  final bool dark;
  final VoidCallback onNext;

  static const List<String> _labels = [
    'onboarding.next_welcome',
    'onboarding.next_value',
    'onboarding.next_categories',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    final isLast = step == 2;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5],
            colors: dark
                ? [const Color(0x000C0906), const Color(0xD10B0805)]
                : [palette.paper.withValues(alpha: 0), palette.paper],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onNext,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLast) ...[
                      const Icon(Icons.auto_awesome, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(_labels[step].tr()),
                    if (!isLast) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Finish overlay
// ============================================================================

class _FinishOverlay extends StatelessWidget {
  const _FinishOverlay();

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.of(context);
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.1,
            colors: [const Color(0xFF34291F), palette.inkBg],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond_outlined, size: 84, color: palette.clay),
                const SizedBox(height: 22),
                Text(
                  'onboarding.finish.title'.tr(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: palette.onDark,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    'onboarding.finish.body'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.onDark2,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(palette.clay),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'onboarding.finish.loading'.tr(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: palette.onDark2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Palette — resolves Field Journal tokens with fallbacks for plain themes
// ============================================================================

class _Palette {
  const _Palette({
    required this.paper,
    required this.paperRaised,
    required this.paperSunk,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.inkBg,
    required this.onDark,
    required this.onDark2,
    required this.clay,
    required this.clayDeep,
    required this.clayTint,
    required this.rLg,
    required this.e1,
  });

  final Color paper;
  final Color paperRaised;
  final Color paperSunk;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color inkBg;
  final Color onDark;
  final Color onDark2;
  final Color clay;
  final Color clayDeep;
  final Color clayTint;
  final double rLg;
  final List<BoxShadow> e1;

  factory _Palette.of(BuildContext context) {
    final t = Theme.of(context).extension<LorescapeTokens>();
    final cs = Theme.of(context).colorScheme;
    return _Palette(
      paper: t?.paper ?? const Color(0xFFF7F1E6),
      paperRaised: t?.paperRaised ?? const Color(0xFFFDFAF3),
      paperSunk: t?.paperSunk ?? const Color(0xFFECE3D3),
      line: t?.line ?? const Color(0xFFE4DAC8),
      lineStrong: t?.lineStrong ?? const Color(0xFFCDBFA6),
      ink: t?.ink ?? const Color(0xFF221C14),
      ink2: t?.ink2 ?? const Color(0xFF5E5341),
      ink3: t?.ink3 ?? const Color(0xFF918471),
      inkBg: t?.inkBg ?? const Color(0xFF1B1611),
      onDark: t?.onDark ?? const Color(0xFFF7F1E6),
      onDark2: t?.onDark2 ?? const Color(0xFFC3B7A4),
      clay: t?.clay ?? cs.primary,
      clayDeep: t?.clayDeep ?? const Color(0xFF97442A),
      clayTint: t?.clayTint ?? const Color(0xFFF7E8DD),
      rLg: t?.rLg ?? 16,
      e1:
          t?.e1 ??
          const [
            BoxShadow(
              color: Color(0x0F281E12),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
    );
  }
}
