import 'dart:async';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/domain/services/subscription_service.dart';

/// 測試用的假訂閱服務
class FakeSubscriptionService implements SubscriptionService {
  SubscriptionStatus _status;
  final _controller = StreamController<SubscriptionStatus>.broadcast();

  FakeSubscriptionService({SubscriptionStatus? initialStatus})
    : _status = initialStatus ?? SubscriptionStatus.free;

  /// 模擬狀態變更（測試用）
  void emitStatus(SubscriptionStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  Future<void> initialize({required String apiKey}) async {}

  @override
  Future<void> logIn(String userId) async {}

  @override
  Future<void> logOut() async {
    _status = SubscriptionStatus.free;
    _controller.add(_status);
  }

  @override
  Stream<SubscriptionStatus> get statusStream => _controller.stream;

  @override
  Future<SubscriptionStatus> getStatus() async => _status;

  @override
  Future<SubscriptionStatus?> purchase() async => _status;

  @override
  Future<SubscriptionStatus> restorePurchases() async => _status;

  void dispose() {
    _controller.close();
  }
}
