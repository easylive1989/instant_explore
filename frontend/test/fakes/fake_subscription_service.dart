import 'dart:async';

import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/domain/services/subscription_service.dart';

/// Fake [SubscriptionService] backed by an in-memory state controller.
///
/// Tests can seed the current status and drive purchase/restore outcomes
/// without touching RevenueCat.
class FakeSubscriptionService implements SubscriptionService {
  SubscriptionStatus _current;
  SubscriptionStatus? _purchaseResult;
  SubscriptionStatus? _restoreResult;
  Exception? _purchaseError;
  Exception? _restoreError;
  SubscriptionPlan? _currentPlan;
  Exception? _currentPlanError;

  final StreamController<SubscriptionStatus> _controller =
      StreamController<SubscriptionStatus>.broadcast();

  FakeSubscriptionService({SubscriptionStatus initial = SubscriptionStatus.free})
    : _current = initial;

  /// Sets the value returned by [purchase].
  ///
  /// When [status] is `null`, [purchase] simulates user cancellation.
  /// When [error] is non-null, [purchase] throws it.
  void stubPurchase({SubscriptionStatus? status, Exception? error}) {
    _purchaseResult = status;
    _purchaseError = error;
  }

  /// Sets the value returned by [restorePurchases].
  void stubRestore({SubscriptionStatus? status, Exception? error}) {
    _restoreResult = status;
    _restoreError = error;
  }

  /// Sets the value returned by [getCurrentPlan].
  ///
  /// When [plan] is `null`, [getCurrentPlan] simulates "no offerings".
  /// When [error] is non-null, [getCurrentPlan] throws it.
  void stubGetCurrentPlan({SubscriptionPlan? plan, Exception? error}) {
    _currentPlan = plan;
    _currentPlanError = error;
  }

  /// Emits [status] on [statusStream] and updates current status.
  void emit(SubscriptionStatus status) {
    _current = status;
    _controller.add(status);
  }

  @override
  Future<void> initialize({required String apiKey}) async {
    _controller.add(_current);
  }

  @override
  Future<void> logIn(String userId) async {}

  @override
  Future<void> logOut() async {}

  @override
  Stream<SubscriptionStatus> get statusStream => _controller.stream;

  @override
  Future<SubscriptionStatus> getStatus() async => _current;

  @override
  Future<SubscriptionStatus?> purchase() async {
    if (_purchaseError != null) throw _purchaseError!;
    if (_purchaseResult != null) {
      emit(_purchaseResult!);
    }
    return _purchaseResult;
  }

  @override
  Future<SubscriptionStatus> restorePurchases() async {
    if (_restoreError != null) throw _restoreError!;
    final result = _restoreResult ?? _current;
    emit(result);
    return result;
  }

  @override
  Future<SubscriptionPlan?> getCurrentPlan() async {
    if (_currentPlanError != null) throw _currentPlanError!;
    return _currentPlan;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
