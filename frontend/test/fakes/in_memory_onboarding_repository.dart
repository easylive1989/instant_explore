import 'package:context_app/features/onboarding/domain/models/onboarding_state.dart';
import 'package:context_app/features/onboarding/domain/models/onboarding_tip.dart';
import 'package:context_app/features/onboarding/domain/onboarding_repository.dart';

/// Test double for [OnboardingRepository] that keeps state in memory and
/// exposes counters for assertions.
class InMemoryOnboardingRepository implements OnboardingRepository {
  InMemoryOnboardingRepository({
    bool welcomeDone = false,
    Set<OnboardingTip>? seenTips,
  })  : _welcomeDone = welcomeDone,
        _seenTips = {...?seenTips};

  bool _welcomeDone;
  final Set<OnboardingTip> _seenTips;
  int loadCalls = 0;
  int markWelcomeDoneCalls = 0;
  int resetCalls = 0;
  final List<OnboardingTip> markedTips = <OnboardingTip>[];

  @override
  Future<OnboardingState> load() async {
    loadCalls += 1;
    return OnboardingState(
      hasLoaded: true,
      welcomeDone: _welcomeDone,
      seenTips: {..._seenTips},
    );
  }

  @override
  Future<void> markTipSeen(OnboardingTip tip) async {
    markedTips.add(tip);
    _seenTips.add(tip);
  }

  @override
  Future<void> markWelcomeDone() async {
    markWelcomeDoneCalls += 1;
    _welcomeDone = true;
  }

  @override
  Future<void> reset() async {
    resetCalls += 1;
    _welcomeDone = false;
    _seenTips.clear();
  }
}
