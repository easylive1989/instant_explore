import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:context_app/features/ads/domain/services/rewarded_ad_service.dart';

/// 使用 Google Mobile Ads 的獎勵廣告服務實作
class GoogleRewardedAdService implements RewardedAdService {
  RewardedAd? _rewardedAd;

  /// Ad Unit ID（debug 用測試 ID，release 用正式 ID）
  String get _adUnitId {
    if (kReleaseMode) {
      return Platform.isIOS
          ? 'ca-app-pub-9031377620197189/2546789476'
          : 'ca-app-pub-9031377620197189/1018085386';
    }
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/1712485313'
        : 'ca-app-pub-3940256099942544/5224354917';
  }

  @override
  bool get isAdReady => _rewardedAd != null;

  @override
  Future<void> loadAd() async {
    final completer = Completer<void>();

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: ${error.message}');
          _rewardedAd = null;
          completer.complete();
        },
      ),
    );

    return completer.future;
  }

  @override
  Future<bool> showAd() async {
    if (_rewardedAd == null) {
      await loadAd();
      if (_rewardedAd == null) return false;
    }

    final completer = Completer<bool>();
    var rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        completer.complete(rewarded);
        // 預先載入下一個廣告
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        completer.complete(false);
        loadAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        rewarded = true;
      },
    );

    return completer.future;
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
