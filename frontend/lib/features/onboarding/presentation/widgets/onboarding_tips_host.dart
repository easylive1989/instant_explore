import 'dart:async';

import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/features/onboarding/domain/models/onboarding_tip.dart';
import 'package:context_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

/// Keys for the showcase targets used by [OnboardingTipsHost].
///
/// Kept on a single object so widgets spread across the bottom-nav bar can
/// share GlobalKey instances without a provider lookup.
class OnboardingShowcaseKeys {
  OnboardingShowcaseKeys._();

  static final home = GlobalKey();
  static final quickGuide = GlobalKey();
  static final journey = GlobalKey();
}

/// Wraps the app's main shell in a [ShowCaseWidget] and orchestrates
/// contextual tips.
///
/// The host reacts to bottom-nav tab changes: the first time a tab becomes
/// active, and only after a post-frame delay so the target is mounted, it
/// triggers the showcase for that tab's key and persists the "seen" flag.
/// If the target's key never attaches (e.g. the screen fails to mount),
/// the showcase silently no-ops instead of blocking the user.
class OnboardingTipsHost extends ConsumerStatefulWidget {
  const OnboardingTipsHost({
    super.key,
    required this.currentTabIndex,
    required this.child,
  });

  final int currentTabIndex;
  final Widget child;

  @override
  ConsumerState<OnboardingTipsHost> createState() => _OnboardingTipsHostState();
}

class _OnboardingTipsHostState extends ConsumerState<OnboardingTipsHost> {
  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => _TipTrigger(
        currentTabIndex: widget.currentTabIndex,
        child: widget.child,
      ),
    );
  }
}

class _TipTrigger extends ConsumerStatefulWidget {
  const _TipTrigger({required this.currentTabIndex, required this.child});

  final int currentTabIndex;
  final Widget child;

  @override
  ConsumerState<_TipTrigger> createState() => _TipTriggerState();
}

class _TipTriggerState extends ConsumerState<_TipTrigger> {
  Timer? _scheduled;

  @override
  void initState() {
    super.initState();
    _maybeTriggerForTab(widget.currentTabIndex);
  }

  @override
  void didUpdateWidget(covariant _TipTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTabIndex != widget.currentTabIndex) {
      _maybeTriggerForTab(widget.currentTabIndex);
    }
  }

  @override
  void dispose() {
    _scheduled?.cancel();
    super.dispose();
  }

  void _maybeTriggerForTab(int tabIndex) {
    final tip = _tipForTab(tabIndex);
    if (tip == null) return;

    // Wait for the target to mount and the tab transition to settle.
    _scheduled?.cancel();
    _scheduled = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final state = ref.read(onboardingControllerProvider);
      if (state.hasSeen(tip)) return;

      final key = _keyForTip(tip);
      if (key.currentContext == null) return;

      ref.read(onboardingControllerProvider.notifier).markTipSeen(tip);
      ShowCaseWidget.of(context).startShowCase([key]);
    });
  }

  OnboardingTip? _tipForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return OnboardingTip.explore;
      case 1:
        return OnboardingTip.quickGuide;
      case 2:
        return OnboardingTip.journey;
      default:
        return null;
    }
  }

  GlobalKey _keyForTip(OnboardingTip tip) {
    switch (tip) {
      case OnboardingTip.explore:
        return OnboardingShowcaseKeys.home;
      case OnboardingTip.quickGuide:
        return OnboardingShowcaseKeys.quickGuide;
      case OnboardingTip.journey:
        return OnboardingShowcaseKeys.journey;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Consistent styling for bottom-nav [Showcase] wrappers.
class OnboardingShowcase extends StatelessWidget {
  const OnboardingShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
  });

  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      descTextStyle: const TextStyle(fontSize: 13, color: Colors.white),
      tooltipBackgroundColor: AppColors.primary,
      targetShapeBorder: const CircleBorder(),
      targetPadding: const EdgeInsets.all(6),
      child: child,
    );
  }
}
