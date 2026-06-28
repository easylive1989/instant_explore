# Weekly + Yearly Subscription Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the existing single-plan paywall into a multi-plan paywall (Weekly + Monthly + Yearly) with Yearly default-selected and badged "Best value", driven by RevenueCat packages.

**Architecture:** Feature-First Clean Architecture (`features/subscription/{domain,data,presentation}`). Adds `weekly` to `SubscriptionPeriod`, extends `SubscriptionPlan` with `packageIdentifier` + `isBestValue`, replaces `SubscriptionService.getCurrentPlan()` with `getAvailablePlans()`, and changes `purchase()` to take a `SubscriptionPeriod`. `SubscriptionPlanCard` becomes selection-aware; `SubscriptionScreen` renders three cards and routes purchase by period.

**Tech Stack:** Flutter, Dart 3, Riverpod, `purchases_flutter` (RevenueCat), easy_localization, flutter_test.

**Spec:** [`docs/superpowers/specs/2026-05-11-weekly-subscription-design.md`](../specs/2026-05-11-weekly-subscription-design.md)
**Backend / store setup (run in parallel with code work):** [`docs/init/subscription-setup.md`](../../init/subscription-setup.md)

**Verification command (run after each task that touches Dart):**
```bash
cd frontend && fvm flutter analyze --fatal-infos
```

**Run all subscription tests:**
```bash
cd frontend && fvm flutter test test/features/subscription/
```

---

## Task 1: Add i18n keys

**Files:**
- Modify: `frontend/assets/translations/en.json` (subscription block, around line 281–322)
- Modify: `frontend/assets/translations/zh-TW.json` (subscription block, around line 281–322)

- [ ] **Step 1: Add new English keys**

In `frontend/assets/translations/en.json`, inside the existing `"subscription": { ... }` object, add these keys (place them next to the existing `plan_label` / `plan_period` block, keep existing keys untouched):

```json
"plan_weekly": "WEEKLY PLAN",
"plan_monthly": "MONTHLY PLAN",
"plan_yearly": "YEARLY PLAN",
"period_weekly": "/ week",
"period_monthly": "/ month",
"period_yearly": "/ year",
"subscribe_weekly": "Subscribe Weekly",
"subscribe_monthly": "Subscribe Monthly",
"subscribe_yearly": "Subscribe Yearly",
"badge_best_value": "Best value",
```

Do **not** remove `plan_label`, `plan_period`, or `subscribe` yet — Task 7 removes them in lockstep with the UI migration.

- [ ] **Step 2: Add new Traditional Chinese keys**

In `frontend/assets/translations/zh-TW.json`, mirror the same keys inside `"subscription": { ... }`:

```json
"plan_weekly": "每週方案",
"plan_monthly": "每月方案",
"plan_yearly": "每年方案",
"period_weekly": "／週",
"period_monthly": "／月",
"period_yearly": "／年",
"subscribe_weekly": "訂閱每週方案",
"subscribe_monthly": "訂閱每月方案",
"subscribe_yearly": "訂閱每年方案",
"badge_best_value": "最划算",
```

- [ ] **Step 3: Sanity-check JSON validity**

```bash
cd frontend && fvm dart run --enable-asserts -e "import 'dart:convert'; import 'dart:io'; void main() { jsonDecode(File('assets/translations/en.json').readAsStringSync()); jsonDecode(File('assets/translations/zh-TW.json').readAsStringSync()); print('OK'); }"
```

Expected output: `OK`

- [ ] **Step 4: Commit**

```bash
git add frontend/assets/translations/en.json frontend/assets/translations/zh-TW.json
git commit -m "feat(subscription): add i18n keys for weekly/monthly/yearly plans"
```

---

## Task 2: Add `weekly` to `SubscriptionPeriod`

**Files:**
- Modify: `frontend/lib/features/subscription/domain/models/subscription_plan.dart`

- [ ] **Step 1: Update the enum**

Replace the enum block in `frontend/lib/features/subscription/domain/models/subscription_plan.dart` (currently at the bottom of the file) with:

```dart
/// 訂閱方案週期
enum SubscriptionPeriod { weekly, monthly, yearly }
```

- [ ] **Step 2: Run analyzer to spot non-exhaustive switches**

```bash
cd frontend && fvm flutter analyze --fatal-infos
```

Expected: warnings/errors at any `switch` over `SubscriptionPeriod` that doesn't handle `weekly`. The known site is `_mapPeriod` in `revenuecat_subscription_service.dart`; Task 5 handles it explicitly. If analyze reports other call sites we missed, add them to Task 5 before continuing.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/subscription/domain/models/subscription_plan.dart
git commit -m "feat(subscription): add weekly to SubscriptionPeriod enum"
```

---

## Task 3: Extend `SubscriptionPlan` with `packageIdentifier` and `isBestValue`

**Files:**
- Create: `frontend/test/features/subscription/domain/models/subscription_plan_test.dart`
- Modify: `frontend/lib/features/subscription/domain/models/subscription_plan.dart`

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/subscription/domain/models/subscription_plan_test.dart`:

```dart
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionPlan', () {
    test('isBestValue defaults to false', () {
      const plan = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
      );

      expect(plan.isBestValue, isFalse);
    });

    test('two plans with the same fields are equal', () {
      const a = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
      );
      const b = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('plans differing on packageIdentifier are not equal', () {
      const a = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: r'$rc_monthly',
      );
      const b = SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
        packageIdentifier: 'something_else',
      );

      expect(a, isNot(equals(b)));
    });

    test('plans differing on isBestValue are not equal', () {
      const a = SubscriptionPlan(
        priceString: 'NT\$900',
        period: SubscriptionPeriod.yearly,
        packageIdentifier: r'$rc_annual',
      );
      const b = SubscriptionPlan(
        priceString: 'NT\$900',
        period: SubscriptionPeriod.yearly,
        packageIdentifier: r'$rc_annual',
        isBestValue: true,
      );

      expect(a, isNot(equals(b)));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd frontend && fvm flutter test test/features/subscription/domain/models/subscription_plan_test.dart
```

Expected: compile error (missing `packageIdentifier` / `isBestValue` parameters).

- [ ] **Step 3: Update the model**

Replace the class body in `frontend/lib/features/subscription/domain/models/subscription_plan.dart` with:

```dart
// frontend/lib/features/subscription/domain/models/subscription_plan.dart

/// 可購買的訂閱方案資訊
///
/// [priceString] 為商店回傳的已本地化價格字串（例如 `NT$90` 或 `$2.99`），
/// 不要自己組字串或做貨幣換算。
class SubscriptionPlan {
  final String priceString;
  final SubscriptionPeriod period;
  final String packageIdentifier;
  final bool isBestValue;

  const SubscriptionPlan({
    required this.priceString,
    required this.period,
    required this.packageIdentifier,
    this.isBestValue = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          runtimeType == other.runtimeType &&
          priceString == other.priceString &&
          period == other.period &&
          packageIdentifier == other.packageIdentifier &&
          isBestValue == other.isBestValue;

  @override
  int get hashCode =>
      Object.hash(priceString, period, packageIdentifier, isBestValue);
}

/// 訂閱方案週期
enum SubscriptionPeriod { weekly, monthly, yearly }
```

- [ ] **Step 4: Run the new test**

```bash
cd frontend && fvm flutter test test/features/subscription/domain/models/subscription_plan_test.dart
```

Expected: all 4 tests PASS.

- [ ] **Step 5: Run analyzer**

```bash
cd frontend && fvm flutter analyze --fatal-infos
```

Existing test/site that uses `const SubscriptionPlan(priceString: ..., period: ...)` will now fail. Known site:
`frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart` (around lines 138–142, 156–160).
Leave those failures for Task 5 / 7 (the test rewrites them); analyzer errors there are expected for now.

If analyzer reports failures in any **production** file, stop and add a fix to this task.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/subscription/domain/models/subscription_plan.dart \
        frontend/test/features/subscription/domain/models/subscription_plan_test.dart
git commit -m "feat(subscription): add packageIdentifier and isBestValue to SubscriptionPlan"
```

---

## Task 4: Add `SubscriptionPlanNotAvailableException`

**Files:**
- Create: `frontend/lib/features/subscription/domain/errors/subscription_errors.dart`
- Create: `frontend/test/features/subscription/domain/errors/subscription_errors_test.dart`

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/subscription/domain/errors/subscription_errors_test.dart`:

```dart
import 'package:context_app/features/subscription/domain/errors/subscription_errors.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionPlanNotAvailableException', () {
    test('toString mentions the missing period', () {
      final ex = SubscriptionPlanNotAvailableException(
        SubscriptionPeriod.weekly,
      );

      expect(ex.toString(), contains('weekly'));
    });

    test('is an Exception', () {
      final ex = SubscriptionPlanNotAvailableException(
        SubscriptionPeriod.yearly,
      );

      expect(ex, isA<Exception>());
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd frontend && fvm flutter test test/features/subscription/domain/errors/subscription_errors_test.dart
```

Expected: file-not-found error on the import.

- [ ] **Step 3: Create the exception file**

Create `frontend/lib/features/subscription/domain/errors/subscription_errors.dart`:

```dart
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';

/// Thrown when the user requests a [SubscriptionPeriod] that the current
/// RevenueCat offering does not contain a package for.
class SubscriptionPlanNotAvailableException implements Exception {
  final SubscriptionPeriod period;

  SubscriptionPlanNotAvailableException(this.period);

  @override
  String toString() => 'SubscriptionPlanNotAvailableException: ${period.name}';
}
```

- [ ] **Step 4: Run the test**

```bash
cd frontend && fvm flutter test test/features/subscription/domain/errors/subscription_errors_test.dart
```

Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/subscription/domain/errors/subscription_errors.dart \
        frontend/test/features/subscription/domain/errors/subscription_errors_test.dart
git commit -m "feat(subscription): add SubscriptionPlanNotAvailableException"
```

---

## Task 5: Replace service API (`getAvailablePlans` + `purchase(period)`)

This is the breaking-change task. It updates: the abstract interface, the RC implementation (including the `_mapPeriod` bug fix), the Fake test double, and the **minimum** of `SubscriptionScreen` needed to keep the app compiling and existing tests structurally valid (we keep single-card UI for now; Task 7 swaps to multi-card UI).

**Files:**
- Modify: `frontend/lib/features/subscription/domain/services/subscription_service.dart`
- Modify: `frontend/lib/features/subscription/data/revenuecat_subscription_service.dart`
- Modify: `frontend/test/fakes/fake_subscription_service.dart`
- Modify: `frontend/lib/features/subscription/presentation/screens/subscription_screen.dart` (minimal)
- Modify: `frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart` (minimal)

- [ ] **Step 1: Update the abstract interface**

Replace `frontend/lib/features/subscription/domain/services/subscription_service.dart` with:

```dart
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';

/// 訂閱服務介面
///
/// 抽象化訂閱管理操作，方便測試時替換實作
abstract class SubscriptionService {
  /// 初始化 SDK 並設定 API key
  Future<void> initialize({required String apiKey});

  /// 綁定使用者身份（登入後呼叫）
  Future<void> logIn(String userId);

  /// 解除使用者身份（登出時呼叫）
  Future<void> logOut();

  /// 訂閱狀態變化串流
  Stream<SubscriptionStatus> get statusStream;

  /// 取得當前訂閱狀態
  Future<SubscriptionStatus> getStatus();

  /// 購買指定週期的訂閱方案。
  ///
  /// 回傳購買後的訂閱狀態。使用者取消時回傳 `null`。
  /// 若當前 offering 沒有對應 [period] 的 package，丟出
  /// [SubscriptionPlanNotAvailableException]。
  Future<SubscriptionStatus?> purchase(SubscriptionPeriod period);

  /// 恢復購買
  Future<SubscriptionStatus> restorePurchases();

  /// 取得目前可購買的方案列表，固定回傳順序：weekly → monthly → yearly。
  ///
  /// 若沒有任何可用 offerings 則回傳空 list；UI 應顯示載入錯誤。
  Future<List<SubscriptionPlan>> getAvailablePlans();
}
```

- [ ] **Step 2: Update the RevenueCat implementation**

Replace the body of `frontend/lib/features/subscription/data/revenuecat_subscription_service.dart` with:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:context_app/features/subscription/domain/errors/subscription_errors.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/domain/services/subscription_service.dart';

/// RevenueCat 實作的訂閱服務
class RevenueCatSubscriptionService implements SubscriptionService {
  static const _entitlementId = 'premium';

  /// PackageTypes we surface in the paywall, in display order.
  static const _supportedPackageTypes = <PackageType>[
    PackageType.weekly,
    PackageType.monthly,
    PackageType.annual,
  ];

  final _controller = StreamController<SubscriptionStatus>.broadcast();

  /// 全域 SDK 初始化（在 main.dart 中呼叫一次）
  static Future<void> configureSDK({required String apiKey}) async {
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  @override
  Future<void> initialize({required String apiKey}) async {
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    final info = await Purchases.getCustomerInfo();
    _controller.add(_mapToStatus(info));
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _controller.add(_mapToStatus(info));
  }

  @override
  Future<void> logIn(String userId) async {
    await Purchases.logIn(userId);
  }

  @override
  Future<void> logOut() async {
    await Purchases.logOut();
  }

  @override
  Stream<SubscriptionStatus> get statusStream => _controller.stream;

  @override
  Future<SubscriptionStatus> getStatus() async {
    final info = await Purchases.getCustomerInfo();
    return _mapToStatus(info);
  }

  @override
  Future<SubscriptionStatus?> purchase(SubscriptionPeriod period) async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        throw SubscriptionPlanNotAvailableException(period);
      }
      final targetType = _packageTypeFor(period);
      Package? package;
      for (final p in current.availablePackages) {
        if (p.packageType == targetType) {
          package = p;
          break;
        }
      }
      if (package == null) {
        throw SubscriptionPlanNotAvailableException(period);
      }
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _mapToStatus(result.customerInfo);
    } on PlatformException catch (e) {
      // 使用者取消購買
      if (e.code == '1') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<SubscriptionStatus> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    return _mapToStatus(info);
  }

  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) {
      return const [];
    }

    final byType = <PackageType, Package>{
      for (final p in current.availablePackages)
        if (_supportedPackageTypes.contains(p.packageType)) p.packageType: p,
    };

    final plans = <SubscriptionPlan>[];
    for (final type in _supportedPackageTypes) {
      final pkg = byType[type];
      if (pkg == null) continue;
      final period = mapPeriod(type);
      plans.add(SubscriptionPlan(
        priceString: pkg.storeProduct.priceString,
        period: period,
        packageIdentifier: pkg.identifier,
        isBestValue: period == SubscriptionPeriod.yearly,
      ));
    }
    return plans;
  }

  PackageType _packageTypeFor(SubscriptionPeriod period) => switch (period) {
    SubscriptionPeriod.weekly => PackageType.weekly,
    SubscriptionPeriod.monthly => PackageType.monthly,
    SubscriptionPeriod.yearly => PackageType.annual,
  };

  /// Maps a RC [PackageType] to our [SubscriptionPeriod].
  ///
  /// Only the three types in [_supportedPackageTypes] are accepted here;
  /// anything else is a programming error because [getAvailablePlans]
  /// filters by [_supportedPackageTypes] before mapping.
  @visibleForTesting
  static SubscriptionPeriod mapPeriod(PackageType type) => switch (type) {
    PackageType.weekly => SubscriptionPeriod.weekly,
    PackageType.monthly => SubscriptionPeriod.monthly,
    PackageType.annual => SubscriptionPeriod.yearly,
    _ => throw ArgumentError.value(type, 'type', 'Unsupported PackageType'),
  };

  SubscriptionStatus _mapToStatus(CustomerInfo info) {
    final entitlement = info.entitlements.active[_entitlementId];
    if (entitlement == null) {
      return SubscriptionStatus.free;
    }
    return SubscriptionStatus(
      isPremium: true,
      expirationDate: entitlement.expirationDate != null
          ? DateTime.tryParse(entitlement.expirationDate!)
          : null,
    );
  }

  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _controller.close();
  }
}
```

- [ ] **Step 3: Update the Fake service**

Replace `frontend/test/fakes/fake_subscription_service.dart` with:

```dart
import 'dart:async';

import 'package:context_app/features/subscription/domain/errors/subscription_errors.dart';
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
  List<SubscriptionPlan> _plans = const [];
  Exception? _plansError;
  final List<SubscriptionPeriod> _purchaseCalls = [];

  final StreamController<SubscriptionStatus> _controller =
      StreamController<SubscriptionStatus>.broadcast();

  FakeSubscriptionService({SubscriptionStatus initial = SubscriptionStatus.free})
    : _current = initial;

  /// Inspect the periods that [purchase] was invoked with, in order.
  List<SubscriptionPeriod> get purchaseCalls => List.unmodifiable(_purchaseCalls);

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

  /// Sets the value returned by [getAvailablePlans].
  ///
  /// When [plans] is `null`, [getAvailablePlans] returns an empty list
  /// (matching "no offerings"). When [error] is non-null, it throws.
  void stubGetAvailablePlans({
    List<SubscriptionPlan>? plans,
    Exception? error,
  }) {
    _plans = plans ?? const [];
    _plansError = error;
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
  Future<SubscriptionStatus?> purchase(SubscriptionPeriod period) async {
    _purchaseCalls.add(period);
    if (_purchaseError != null) throw _purchaseError!;
    final exists = _plans.any((p) => p.period == period);
    if (!exists && _plans.isNotEmpty) {
      throw SubscriptionPlanNotAvailableException(period);
    }
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
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    if (_plansError != null) throw _plansError!;
    return _plans;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
```

- [ ] **Step 4: Patch `SubscriptionScreen` minimally so the app compiles**

In `frontend/lib/features/subscription/presentation/screens/subscription_screen.dart`:

1. In `_loadPlan()` (around line 82), replace:
   ```dart
   final plan = await ref.read(subscriptionServiceProvider).getCurrentPlan();
   if (!mounted) return;
   setState(() {
     _plan = plan;
     _isLoadingPlan = false;
   });
   ```
   with:
   ```dart
   final plans = await ref.read(subscriptionServiceProvider).getAvailablePlans();
   if (!mounted) return;
   setState(() {
     _plan = plans.isEmpty ? null : plans.first;
     _isLoadingPlan = false;
   });
   ```
2. In `_purchase()` (around line 103), replace `final result = await service.purchase();` with:
   ```dart
   final result = _plan == null
       ? null
       : await service.purchase(_plan!.period);
   ```

These are interim shims — Task 7 rewrites this screen for multi-card UI.

- [ ] **Step 5: Patch the existing screen test to match the new API**

In `frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart`:

1. Replace every call `..stubGetCurrentPlan(plan: const SubscriptionPlan(priceString: 'NT\$90', period: SubscriptionPeriod.monthly))` with:
   ```dart
   ..stubGetAvailablePlans(
     plans: const [
       SubscriptionPlan(
         priceString: 'NT\$90',
         period: SubscriptionPeriod.monthly,
         packageIdentifier: r'$rc_monthly',
       ),
     ],
   )
   ```
2. Replace `..stubGetCurrentPlan(error: Exception('network'))` with:
   ```dart
   ..stubGetAvailablePlans(error: Exception('network'))
   ```
3. Replace `..stubGetCurrentPlan(plan: const SubscriptionPlan(priceString: 'NT\$90', period: SubscriptionPeriod.monthly))` in the retry test with the matching `stubGetAvailablePlans(plans: [...])` form.
4. Update the failing-load test message text to mention `getAvailablePlans` instead of `getCurrentPlan`.

- [ ] **Step 6: Run analyzer + all subscription tests**

```bash
cd frontend && fvm flutter analyze --fatal-infos
cd frontend && fvm flutter test test/features/subscription/
```

Expected: analyzer clean. All pre-existing tests still pass (we deliberately kept the single-card UI for now, so they verify the old text & flow against the new API).

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/subscription/domain/services/subscription_service.dart \
        frontend/lib/features/subscription/data/revenuecat_subscription_service.dart \
        frontend/lib/features/subscription/presentation/screens/subscription_screen.dart \
        frontend/test/fakes/fake_subscription_service.dart \
        frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart
git commit -m "refactor(subscription): replace getCurrentPlan with getAvailablePlans; purchase(period)"
```

---

## Task 6: Make `SubscriptionPlanCard` selection-aware

**Files:**
- Modify: `frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart`
- Modify: `frontend/test/features/subscription/presentation/widgets/subscription_plan_card_test.dart`

- [ ] **Step 1: Write the failing tests**

Append the following tests inside the existing `group('SubscriptionPlanCard', () { ... })` in `frontend/test/features/subscription/presentation/widgets/subscription_plan_card_test.dart`. Also add an import for `package:flutter/material.dart` at the top if not already there.

```dart
testWidgets(
  'given a ready state with isBestValue=true, when the card is shown, '
  'then the Best value badge text is visible',
  (tester) async {
    await _pumpCard(
      tester,
      const SubscriptionPlanCardState.ready(
        planLabel: 'YEARLY PLAN',
        priceString: 'NT\$900',
        periodLabel: '/ year',
        bullets: ['Unlimited'],
        autoRenewNotice: 'auto',
        isBestValue: true,
      ),
    );

    expect(find.text('subscription.badge_best_value'), findsOneWidget);
  },
);

testWidgets(
  'given a ready state with selected=true, when the card is shown, '
  'then the selection check icon is visible',
  (tester) async {
    await _pumpCard(
      tester,
      const SubscriptionPlanCardState.ready(
        planLabel: 'MONTHLY PLAN',
        priceString: 'NT\$90',
        periodLabel: '/ month',
        bullets: ['Unlimited'],
        autoRenewNotice: 'auto',
        selected: true,
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  },
);

testWidgets(
  'given selected=false, when the card is shown, '
  'then bullets are not rendered',
  (tester) async {
    await _pumpCard(
      tester,
      const SubscriptionPlanCardState.ready(
        planLabel: 'WEEKLY PLAN',
        priceString: 'NT\$30',
        periodLabel: '/ week',
        bullets: ['Unlimited', 'Ad-free'],
        autoRenewNotice: 'auto',
        selected: false,
      ),
    );

    expect(find.text('Unlimited'), findsNothing);
    expect(find.text('Ad-free'), findsNothing);
  },
);

testWidgets(
  'given an onTap callback, when the card is tapped, '
  'then onTap is invoked exactly once',
  (tester) async {
    var taps = 0;
    await _pumpCard(
      tester,
      SubscriptionPlanCardState.ready(
        planLabel: 'WEEKLY PLAN',
        priceString: 'NT\$30',
        periodLabel: '/ week',
        bullets: const ['Unlimited'],
        autoRenewNotice: 'auto',
        onTap: () => taps++,
      ),
    );

    await tester.tap(find.text('WEEKLY PLAN'));
    await tester.pump();

    expect(taps, 1);
  },
);
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd frontend && fvm flutter test test/features/subscription/presentation/widgets/subscription_plan_card_test.dart
```

Expected: compile errors (`selected`, `isBestValue`, `onTap` not defined on `SubscriptionPlanCardState.ready`).

- [ ] **Step 3: Extend the state and widget**

In `frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart`:

a. Update the sealed-class factory and concrete state:

```dart
sealed class SubscriptionPlanCardState {
  const SubscriptionPlanCardState();

  const factory SubscriptionPlanCardState.loading() =
      SubscriptionPlanCardStateLoading;

  const factory SubscriptionPlanCardState.error({required String message}) =
      SubscriptionPlanCardStateError;

  const factory SubscriptionPlanCardState.ready({
    required String planLabel,
    required String priceString,
    required String periodLabel,
    required List<String> bullets,
    required String autoRenewNotice,
    bool selected,
    bool isBestValue,
    VoidCallback? onTap,
  }) = SubscriptionPlanCardStateReady;
}
```

b. Update the `_Ready` concrete state class:

```dart
final class SubscriptionPlanCardStateReady extends SubscriptionPlanCardState {
  const SubscriptionPlanCardStateReady({
    required this.planLabel,
    required this.priceString,
    required this.periodLabel,
    required this.bullets,
    required this.autoRenewNotice,
    this.selected = false,
    this.isBestValue = false,
    this.onTap,
  });

  final String planLabel;
  final String priceString;
  final String periodLabel;
  final List<String> bullets;
  final String autoRenewNotice;
  final bool selected;
  final bool isBestValue;
  final VoidCallback? onTap;
}
```

c. In the top-level `build()` method of `SubscriptionPlanCard`, wire selected border colour and pass new fields to `_Ready`:

```dart
@override
Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return switch (state) {
    SubscriptionPlanCardStateLoading() => _cardShell(
      context,
      borderColor: cs.outlineVariant,
      child: const _Loading(),
    ),
    SubscriptionPlanCardStateError(:final message) => _cardShell(
      context,
      borderColor: cs.outlineVariant,
      child: _Error(message: message, onRetry: onRetry),
    ),
    SubscriptionPlanCardStateReady(
      :final planLabel,
      :final priceString,
      :final periodLabel,
      :final bullets,
      :final autoRenewNotice,
      :final selected,
      :final isBestValue,
      :final onTap,
    ) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: _cardShell(
          context,
          borderColor: selected ? cs.primary : cs.outlineVariant,
          child: _Ready(
            planLabel: planLabel,
            priceString: priceString,
            periodLabel: periodLabel,
            bullets: bullets,
            autoRenewNotice: autoRenewNotice,
            selected: selected,
            isBestValue: isBestValue,
          ),
        ),
      ),
  };
}

Widget _cardShell(
  BuildContext context, {
  required Color borderColor,
  required Widget child,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.surfaceContainerHigh,
          Theme.of(context).colorScheme.surfaceContainer,
        ],
      ),
      border: Border.all(color: borderColor, width: 2),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14137FEC),
          blurRadius: 40,
          offset: Offset(0, 12),
        ),
      ],
    ),
    padding: const EdgeInsets.all(20),
    child: child,
  );
}
```

d. Update the `_Ready` widget class to accept `selected` / `isBestValue` and conditionally render badge, check icon, bullets, and notice:

```dart
class _Ready extends StatelessWidget {
  const _Ready({
    required this.planLabel,
    required this.priceString,
    required this.periodLabel,
    required this.bullets,
    required this.autoRenewNotice,
    required this.selected,
    required this.isBestValue,
  });

  final String planLabel;
  final String priceString;
  final String periodLabel;
  final List<String> bullets;
  final String autoRenewNotice;
  final bool selected;
  final bool isBestValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (selected) ...[
              Icon(Icons.check_circle, size: 16, color: cs.primary),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                planLabel,
                style: TextStyle(
                  fontSize: SubscriptionPlanCard._planLabelFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            if (isBestValue) _BestValueBadge(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              priceString,
              style: TextStyle(
                fontSize: SubscriptionPlanCard._priceFontSize,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              periodLabel,
              style: TextStyle(
                fontSize: SubscriptionPlanCard._periodFontSize,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (selected) ...[
          const SizedBox(height: 16),
          const _Divider(),
          const SizedBox(height: 16),
          ...bullets.map((b) => _bulletRow(b, cs)),
          const SizedBox(height: 16),
          const _Divider(),
          const SizedBox(height: 12),
          Text(
            autoRenewNotice,
            style: TextStyle(
              fontSize: SubscriptionPlanCard._noticeFontSize,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _bulletRow(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✦',
            style: TextStyle(fontSize: 14, color: cs.primary, height: 1.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: SubscriptionPlanCard._bulletFontSize,
                color: cs.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BestValueBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'subscription.badge_best_value'.tr(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cs.onPrimaryContainer,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
```

Add the import `import 'package:easy_localization/easy_localization.dart';` to the top of the file.

- [ ] **Step 4: Update the existing "every provided bullet appears" test**

Because bullets now render only when `selected: true`, edit the existing test in `subscription_plan_card_test.dart` titled `'given a ready state, when the card is shown, then every provided bullet appears'` to pass `selected: true`:

```dart
const SubscriptionPlanCardState.ready(
  planLabel: 'MONTHLY PLAN',
  priceString: 'NT\$90',
  periodLabel: '/ month',
  bullets: ['Unlimited', 'Ad-free', 'Routes'],
  autoRenewNotice: 'Notice',
  selected: true, // bullets only render in the selected state
),
```

Also update the existing `'price string is the largest font on the card'` test to pass `selected: true` so `autoRenewNotice` text is still findable:

```dart
const SubscriptionPlanCardState.ready(
  planLabel: 'MONTHLY PLAN',
  priceString: 'NT\$90',
  periodLabel: '/ month',
  bullets: ['Unlimited', 'Ad-free', 'Routes'],
  autoRenewNotice: 'Auto-renews monthly. Cancel anytime.',
  selected: true,
),
```

- [ ] **Step 5: Run tests**

```bash
cd frontend && fvm flutter test test/features/subscription/presentation/widgets/subscription_plan_card_test.dart
```

Expected: all tests PASS (existing 4 + 4 new).

- [ ] **Step 6: Run analyzer**

```bash
cd frontend && fvm flutter analyze --fatal-infos
```

Expected: clean.

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart \
        frontend/test/features/subscription/presentation/widgets/subscription_plan_card_test.dart
git commit -m "feat(subscription): make plan card selection-aware with Best value badge"
```

---

## Task 7: Multi-plan paywall in `SubscriptionScreen`

**Files:**
- Modify: `frontend/lib/features/subscription/presentation/screens/subscription_screen.dart`
- Rewrite: `frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart`
- Modify: `frontend/assets/translations/en.json` (remove dead keys)
- Modify: `frontend/assets/translations/zh-TW.json` (remove dead keys)

- [ ] **Step 1: Write the failing widget tests**

Replace the contents of `frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart` with:

```dart
import 'package:context_app/app/config/legal_urls.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_subscription_service.dart';
import '../../../../helpers/pump_app.dart';

const _kWeekly = SubscriptionPlan(
  priceString: 'NT\$30',
  period: SubscriptionPeriod.weekly,
  packageIdentifier: r'$rc_weekly',
);
const _kMonthly = SubscriptionPlan(
  priceString: 'NT\$90',
  period: SubscriptionPeriod.monthly,
  packageIdentifier: r'$rc_monthly',
);
const _kYearly = SubscriptionPlan(
  priceString: 'NT\$900',
  period: SubscriptionPeriod.yearly,
  packageIdentifier: r'$rc_annual',
  isBestValue: true,
);
const _kAllPlans = [_kWeekly, _kMonthly, _kYearly];

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SubscriptionScreen', () {
    testWidgets(
      'given plans loaded, when the screen first shows, '
      'then yearly is selected and Best value badge is visible',
      (tester) async {
        await _givenScreen(tester, _serviceWith(_kAllPlans));

        expect(find.text('subscription.plan_yearly'), findsOneWidget);
        expect(find.text('subscription.badge_best_value'), findsOneWidget);
        expect(find.text('subscription.subscribe_yearly'), findsOneWidget);
      },
    );

    testWidgets(
      'given yearly selected, when the user taps the weekly card, '
      'then subscribe button label changes to Subscribe Weekly',
      (tester) async {
        await _givenScreen(tester, _serviceWith(_kAllPlans));

        await tester.tap(find.text('subscription.plan_weekly'));
        await tester.pumpAndSettle();

        expect(find.text('subscription.subscribe_weekly'), findsOneWidget);
        expect(find.text('subscription.subscribe_yearly'), findsNothing);
      },
    );

    testWidgets(
      'given the user taps subscribe, when purchase succeeds, '
      'then the service is called with the selected period and the screen pops',
      (tester) async {
        final service = _serviceWith(_kAllPlans)
          ..stubPurchase(status: const SubscriptionStatus(isPremium: true));

        await _givenScreenOnRoute(tester, service);

        await tester.tap(find.text('subscription.subscribe_yearly'));
        await tester.pumpAndSettle();

        expect(service.purchaseCalls, [SubscriptionPeriod.yearly]);
        expect(find.byType(SubscriptionScreen), findsNothing);
      },
    );

    testWidgets(
      'given the service returns only weekly + monthly, when the screen loads, '
      'then weekly is selected by default (yearly missing) and only two cards render',
      (tester) async {
        await _givenScreen(tester, _serviceWith(const [_kWeekly, _kMonthly]));

        expect(find.text('subscription.plan_weekly'), findsOneWidget);
        expect(find.text('subscription.plan_monthly'), findsOneWidget);
        expect(find.text('subscription.plan_yearly'), findsNothing);
        expect(find.text('subscription.subscribe_weekly'), findsOneWidget);
      },
    );

    testWidgets(
      'given the service throws on load, when retry is tapped, '
      'then getAvailablePlans is called again and plans render',
      (tester) async {
        final service = FakeSubscriptionService()
          ..stubGetAvailablePlans(error: Exception('network'));

        await _givenScreen(tester, service);

        expect(find.byKey(const ValueKey('planCard.retry')), findsOneWidget);

        service.stubGetAvailablePlans(plans: _kAllPlans);
        await tester.tap(find.byKey(const ValueKey('planCard.retry')));
        await tester.pumpAndSettle();

        expect(find.text('NT\$900'), findsOneWidget);
      },
    );

    testWidgets(
      'given no prior purchase, when the user taps restore, '
      'then the no-purchases snackbar is shown',
      (tester) async {
        final service = _serviceWith(_kAllPlans)
          ..stubRestore(status: SubscriptionStatus.free);

        await _givenScreen(tester, service);

        await tester.scrollUntilVisible(
          find.text('subscription.restore'),
          100,
        );
        await tester.tap(find.text('subscription.restore'));
        await tester.pumpAndSettle();

        expect(find.text('subscription.no_purchases_found'), findsOneWidget);
      },
    );

    testWidgets(
      'given the terms link is tapped, when the user interacts, '
      'then the injected launcher is called with the terms URL',
      (tester) async {
        final launched = <Uri>[];
        await _givenScreen(
          tester,
          _serviceWith(_kAllPlans),
          launcher: (uri) async {
            launched.add(uri);
            return true;
          },
        );

        await tester.scrollUntilVisible(
          find.text('subscription.terms'),
          100,
        );
        await tester.tap(find.text('subscription.terms'));
        await tester.pumpAndSettle();

        expect(launched, [Uri.parse(LegalUrls.termsOfUse)]);
      },
    );

    testWidgets(
      'given the privacy link is tapped, when the user interacts, '
      'then the injected launcher is called with the privacy URL',
      (tester) async {
        final launched = <Uri>[];
        await _givenScreen(
          tester,
          _serviceWith(_kAllPlans),
          launcher: (uri) async {
            launched.add(uri);
            return true;
          },
        );

        await tester.scrollUntilVisible(
          find.text('subscription.privacy'),
          100,
        );
        await tester.tap(find.text('subscription.privacy'));
        await tester.pumpAndSettle();

        expect(launched, [Uri.parse(LegalUrls.privacyPolicy)]);
      },
    );
  });
}

FakeSubscriptionService _serviceWith(List<SubscriptionPlan> plans) {
  return FakeSubscriptionService()..stubGetAvailablePlans(plans: plans);
}

Future<void> _givenScreen(
  WidgetTester tester,
  FakeSubscriptionService service, {
  Future<bool> Function(Uri)? launcher,
}) async {
  await pumpScreen(
    tester,
    child: SubscriptionScreen(launchUrl: launcher),
    overrides: [subscriptionServiceProvider.overrideWithValue(service)],
  );
  await tester.pumpAndSettle();
}

Future<void> _givenScreenOnRoute(
  WidgetTester tester,
  FakeSubscriptionService service,
) async {
  await pumpRouterApp(
    tester,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _Host()),
      GoRoute(
        path: '/subscription',
        builder: (_, __) => const SubscriptionScreen(),
      ),
    ],
    overrides: [subscriptionServiceProvider.overrideWithValue(service)],
  );
  final context = tester.element(find.byType(_Host));
  GoRouter.of(context).push('/subscription');
  await tester.pumpAndSettle();
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('host')));
}
```

> If `pumpRouterApp` is not present in `helpers/pump_app.dart`, check the existing test that referenced it before this change — it was used as-is in the previous version, so it already exists.

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd frontend && fvm flutter test test/features/subscription/presentation/screens/subscription_screen_test.dart
```

Expected: most fail because the screen still renders a single card with the old keys.

- [ ] **Step 3: Rewrite the screen for multi-plan UI**

Replace `frontend/lib/features/subscription/presentation/screens/subscription_screen.dart` with:

```dart
import 'package:context_app/app/config/app_colors.dart';
import 'package:context_app/app/config/legal_urls.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/presentation/widgets/subscription_plan_card.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:context_app/shared/widgets/adaptive/adaptive_widgets.dart';
import 'package:context_app/shared/widgets/midnight_kyoto_backdrop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

typedef UrlLauncher = Future<bool> Function(Uri uri);

/// Midnight Kyoto paywall screen. Multi-plan: Weekly / Monthly / Yearly.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key, UrlLauncher? launchUrl})
    : _launchUrl = launchUrl;

  final UrlLauncher? _launchUrl;

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isPurchasing = false;
  bool _isLoadingPlans = true;
  List<SubscriptionPlan> _plans = const [];
  SubscriptionPeriod? _selectedPeriod;
  String? _plansError;
  bool _showHeadline = false;
  bool _showSubheadline = false;
  bool _showPlanCards = false;

  static Future<bool> _defaultLaunchUrl(Uri uri) {
    return url_launcher.launchUrl(
      uri,
      mode: url_launcher.LaunchMode.externalApplication,
    );
  }

  UrlLauncher get _launchUrl => widget._launchUrl ?? _defaultLaunchUrl;

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _scheduleEntryAnimation();
  }

  Future<void> _scheduleEntryAnimation() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() => _showHeadline = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _showSubheadline = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _showPlanCards = true);
  }

  Widget _entry({required bool visible, required Widget child}) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.04),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });
    try {
      final plans = await ref
          .read(subscriptionServiceProvider)
          .getAvailablePlans();
      if (!mounted) return;
      if (plans.isEmpty) {
        setState(() {
          _plansError = 'subscription.plan_load_failed'.tr();
          _isLoadingPlans = false;
        });
        return;
      }
      setState(() {
        _plans = plans;
        _selectedPeriod =
            plans.any((p) => p.period == SubscriptionPeriod.yearly)
                ? SubscriptionPeriod.yearly
                : plans.first.period;
        _isLoadingPlans = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _plansError = 'subscription.plan_load_failed'.tr();
        _isLoadingPlans = false;
      });
    }
  }

  Future<void> _purchase() async {
    final period = _selectedPeriod;
    if (period == null) return;
    setState(() => _isPurchasing = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      final result = await service.purchase(period);
      if (result != null && result.isPremium && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error_prefix'.tr()}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        await _loadPlans();
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      final result = await service.restorePurchases();
      if (mounted) {
        if (result.isPremium) {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('subscription.no_purchases_found'.tr())),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error_prefix'.tr()}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _openUrl(Uri uri) async {
    final opened = await _launchUrl(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'common.error_prefix'.tr()}: $uri'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _planLabelKey(SubscriptionPeriod period) => switch (period) {
    SubscriptionPeriod.weekly => 'subscription.plan_weekly',
    SubscriptionPeriod.monthly => 'subscription.plan_monthly',
    SubscriptionPeriod.yearly => 'subscription.plan_yearly',
  };

  String _periodLabelKey(SubscriptionPeriod period) => switch (period) {
    SubscriptionPeriod.weekly => 'subscription.period_weekly',
    SubscriptionPeriod.monthly => 'subscription.period_monthly',
    SubscriptionPeriod.yearly => 'subscription.period_yearly',
  };

  String _subscribeLabel(SubscriptionPeriod? period) => switch (period) {
    SubscriptionPeriod.weekly => 'subscription.subscribe_weekly'.tr(),
    SubscriptionPeriod.monthly => 'subscription.subscribe_monthly'.tr(),
    SubscriptionPeriod.yearly => 'subscription.subscribe_yearly'.tr(),
    null => 'subscription.subscribe_yearly'.tr(),
  };

  SubscriptionPlanCardState _cardState(SubscriptionPlan plan) {
    return SubscriptionPlanCardState.ready(
      planLabel: _planLabelKey(plan.period).tr(),
      priceString: plan.priceString,
      periodLabel: _periodLabelKey(plan.period).tr(),
      bullets: [
        'subscription.benefit_unlimited'.tr(),
        'subscription.benefit_no_ads'.tr(),
        'subscription.benefit_route'.tr(),
      ],
      autoRenewNotice: 'subscription.auto_renew_notice'.tr(),
      selected: plan.period == _selectedPeriod,
      isBestValue: plan.isBestValue,
      onTap: _isPurchasing
          ? null
          : () => setState(() => _selectedPeriod = plan.period),
    );
  }

  Widget _plansSection() {
    if (_isLoadingPlans) {
      return Column(
        children: const [
          SubscriptionPlanCard(state: SubscriptionPlanCardState.loading()),
          SizedBox(height: 12),
          SubscriptionPlanCard(state: SubscriptionPlanCardState.loading()),
          SizedBox(height: 12),
          SubscriptionPlanCard(state: SubscriptionPlanCardState.loading()),
        ],
      );
    }
    final err = _plansError;
    if (err != null) {
      return SubscriptionPlanCard(
        state: SubscriptionPlanCardState.error(message: err),
        onRetry: _loadPlans,
      );
    }
    return IgnorePointer(
      ignoring: _isPurchasing,
      child: Column(
        children: [
          for (var i = 0; i < _plans.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            SubscriptionPlanCard(state: _cardState(_plans[i])),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: MidnightKyotoBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AdaptiveIconButton(
                    icon: Icon(Icons.close, color: cs.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const _PremiumIcon(),
                      const SizedBox(height: 20),
                      Text(
                        'subscription.category_label'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _entry(
                        visible: _showHeadline,
                        child: Text(
                          'subscription.headline'.tr(),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: cs.onSurface,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _entry(
                        visible: _showSubheadline,
                        child: Text(
                          'subscription.subheadline'.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.55,
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _entry(
                        visible: _showPlanCards,
                        child: _plansSection(),
                      ),
                      const SizedBox(height: 20),
                      _SubscribeButton(
                        isLoading: _isPurchasing,
                        label: _subscribeLabel(_selectedPeriod),
                        onPressed:
                            _isPurchasing || _plans.isEmpty || _selectedPeriod == null
                                ? null
                                : _purchase,
                      ),
                      const SizedBox(height: 4),
                      AdaptiveButton(
                        style: AdaptiveButtonStyle.text,
                        foregroundColor: cs.onSurfaceVariant,
                        onPressed: _isPurchasing ? null : _restore,
                        child: Text(
                          'subscription.restore'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _LegalFooter(onOpen: _openUrl),
                    ],
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

class _PremiumIcon extends StatelessWidget {
  const _PremiumIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/subscription/premium_badge.png',
      width: 120,
      height: 120,
      fit: BoxFit.contain,
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        icon: isLoading
            ? const SizedBox.shrink()
            : const Icon(Icons.lock_open_rounded),
        label: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: AdaptiveProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.onOpen});

  final Future<void> Function(Uri) onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant.withValues(alpha: 0.7);
    final linkStyle = TextStyle(
      fontSize: 12,
      color: muted,
      decoration: TextDecoration.underline,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onOpen(Uri.parse(LegalUrls.termsOfUse)),
          child: Text('subscription.terms'.tr(), style: linkStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('·', style: TextStyle(fontSize: 12, color: muted)),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onOpen(Uri.parse(LegalUrls.privacyPolicy)),
          child: Text('subscription.privacy'.tr(), style: linkStyle),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Remove the now-dead i18n keys**

In `frontend/assets/translations/en.json` (subscription block), delete these keys:
- `"plan_label": "MONTHLY PLAN",`
- `"plan_period": "/ month",`
- `"subscribe": "Subscribe Now",`

In `frontend/assets/translations/zh-TW.json` (subscription block), delete these keys:
- `"plan_label": "月訂閱",`
- `"plan_period": "／月",`
- `"subscribe": "立即訂閱",`

> If a quick `git grep '"subscription.subscribe"\|subscription.plan_label\|subscription.plan_period' frontend/lib` returns any **production** match, do not delete those keys; instead, migrate the caller in this commit before removing the key. As of the spec, the only known caller is `SubscriptionScreen`, fully replaced by this task.

- [ ] **Step 5: Run all subscription tests**

```bash
cd frontend && fvm flutter test test/features/subscription/
```

Expected: all tests PASS (Task 7 new ones + Task 3/4/6 tests).

- [ ] **Step 6: Run full analyzer**

```bash
cd frontend && fvm flutter analyze --fatal-infos
```

Expected: clean.

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/subscription/presentation/screens/subscription_screen.dart \
        frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart \
        frontend/assets/translations/en.json \
        frontend/assets/translations/zh-TW.json
git commit -m "feat(subscription): multi-plan paywall with weekly/monthly/yearly selection"
```

---

## Task 8: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Full project analyze**

```bash
cd frontend && fvm flutter analyze --fatal-infos
```

Expected: no issues.

- [ ] **Step 2: Full project test run**

```bash
cd frontend && fvm flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Manual smoke checklist (do this when the RC backend is ready)**

Track the RC / Store backend setup in [`docs/init/subscription-setup.md`](../../init/subscription-setup.md). After the backend has all three packages, run the app against Sandbox and confirm:

- Paywall shows three cards in order Weekly → Monthly → Yearly
- Yearly card is selected on entry and shows the "Best value" badge
- Tapping any card switches selection; only the selected card shows bullets + auto-renew notice
- Subscribe button text changes to match the selected period
- Purchasing each period unlocks Premium (RevenueCat Customers page shows the matching product)

- [ ] **Step 4: Push branch**

```bash
git log --oneline -10
git push origin HEAD
```

Open a PR titled `feat(subscription): add weekly/yearly plans to paywall` and link the spec + setup guide.
