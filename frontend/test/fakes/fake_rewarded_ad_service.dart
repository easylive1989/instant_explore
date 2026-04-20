import 'package:context_app/features/ads/domain/services/rewarded_ad_service.dart';

/// Fake [RewardedAdService] that records interactions without touching ads.
class FakeRewardedAdService implements RewardedAdService {
  bool _isReady;
  bool _watchOutcome;
  int loadCount = 0;
  int showCount = 0;

  FakeRewardedAdService({bool isReady = true, bool watchOutcome = true})
    : _isReady = isReady,
      _watchOutcome = watchOutcome;

  @override
  Future<void> loadAd() async {
    loadCount += 1;
    _isReady = true;
  }

  @override
  Future<bool> showAd() async {
    showCount += 1;
    return _watchOutcome;
  }

  @override
  bool get isAdReady => _isReady;

  @override
  void dispose() {}
}
