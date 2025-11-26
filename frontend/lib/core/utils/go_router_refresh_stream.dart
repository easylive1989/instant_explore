import 'dart:async';
import 'package:flutter/foundation.dart';

/// GoRouter 的 refreshListenable 需要 ChangeNotifier
/// 此類別將 Stream 轉換為 ChangeNotifier，以便 GoRouter 監聽認證狀態變化
class GoRouterRefreshStream extends ChangeNotifier {
  /// 建立一個監聽 Stream 的 ChangeNotifier
  ///
  /// 當 Stream 發出新事件時，會通知所有監聽者（如 GoRouter）
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
