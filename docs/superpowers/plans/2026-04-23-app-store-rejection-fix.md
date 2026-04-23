# App Store Rejection Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the 2026-04-21 App Store rejection (Guidelines 2.1 and 3.1.2(c)) by redesigning the paywall so subscription length, billed amount, Terms of Use link, and Privacy Policy link are present and the billed amount is the most conspicuous pricing element, while also documenting the AI disclosure reply for App Review Notes.

**Architecture:** Extract the existing Midnight Kyoto backdrop to a shared widget; introduce a `SubscriptionPlan` domain model and a `getCurrentPlan()` method on `SubscriptionService` so RevenueCat types never leak into the UI; add a `SubscriptionPlanCard` widget that renders the three screen states (loading / ready / error) with the billed amount as the dominant typographic element; refactor `SubscriptionScreen` to compose the new pieces and add Terms/Privacy links through an injectable url launcher.

**Tech Stack:** Flutter (Material 3), Riverpod, easy_localization, go_router, purchases_flutter (RevenueCat), url_launcher. Tests: `flutter_test` with the project's existing BDD-style widget-test conventions (see `flutter-widget-tests` skill) and the fake-over-mock pattern in `frontend/test/fakes/`.

**Prerequisites:**
- fvm flutter toolchain (`fvm flutter` as per CLAUDE.md)
- Run all commands from `frontend/` unless stated otherwise
- Spec reference: `docs/superpowers/specs/2026-04-23-app-store-rejection-fix-design.md`

---

## Task 1: Add legal URL constants

**Files:**
- Create: `frontend/lib/common/config/legal_urls.dart`

- [ ] **Step 1: Create the constants file**

```dart
// frontend/lib/common/config/legal_urls.dart

/// Canonical public legal document URLs referenced from anywhere in the app.
class LegalUrls {
  LegalUrls._();

  static const String termsOfUse = 'https://lorescape.app/terms';
  static const String privacyPolicy = 'https://lorescape.app/privacy';
}
```

- [ ] **Step 2: Run analyzer**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/common/config/legal_urls.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/common/config/legal_urls.dart
git commit -m "feat(config): add LegalUrls constants for terms and privacy"
```

---

## Task 2: Add SubscriptionPlan domain model

**Files:**
- Create: `frontend/lib/features/subscription/domain/models/subscription_plan.dart`

- [ ] **Step 1: Create the domain model**

```dart
// frontend/lib/features/subscription/domain/models/subscription_plan.dart

/// 可購買的訂閱方案資訊
///
/// [priceString] 為商店回傳的已本地化價格字串（例如 `NT$90` 或 `$2.99`），
/// 不要自己組字串或做貨幣換算。
class SubscriptionPlan {
  final String priceString;
  final SubscriptionPeriod period;

  const SubscriptionPlan({required this.priceString, required this.period});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          runtimeType == other.runtimeType &&
          priceString == other.priceString &&
          period == other.period;

  @override
  int get hashCode => Object.hash(priceString, period);
}

/// 訂閱方案週期
enum SubscriptionPeriod { monthly, yearly }
```

- [ ] **Step 2: Run analyzer**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/subscription/domain/models/subscription_plan.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/subscription/domain/models/subscription_plan.dart
git commit -m "feat(subscription): add SubscriptionPlan domain model"
```

---

## Task 3: Extend SubscriptionService interface with getCurrentPlan

**Files:**
- Modify: `frontend/lib/features/subscription/domain/services/subscription_service.dart`
- Modify: `frontend/test/fakes/fake_subscription_service.dart`

- [ ] **Step 1: Add `getCurrentPlan` to the interface**

Edit `frontend/lib/features/subscription/domain/services/subscription_service.dart` — add the import and a new abstract method at the bottom of the class (before the closing brace):

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

  /// 購買訂閱
  ///
  /// 回傳購買後的訂閱狀態
  /// 使用者取消時回傳 null
  Future<SubscriptionStatus?> purchase();

  /// 恢復購買
  Future<SubscriptionStatus> restorePurchases();

  /// 取得目前可購買的方案資訊（含已本地化的價格字串）
  ///
  /// 若沒有任何可用 offerings 則回傳 null。
  Future<SubscriptionPlan?> getCurrentPlan();
}
```

- [ ] **Step 2: Extend `FakeSubscriptionService` with `getCurrentPlan` + `stubGetCurrentPlan`**

Edit `frontend/test/fakes/fake_subscription_service.dart`. Add the import, a private field, a stubber, and implement the interface method. Place additions alongside the existing stubbers.

```dart
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
```

Add these fields near the other stub fields:

```dart
  SubscriptionPlan? _currentPlan;
  Exception? _currentPlanError;
```

Add this stubber alongside `stubPurchase` / `stubRestore`:

```dart
  /// Sets the value returned by [getCurrentPlan].
  ///
  /// When [plan] is `null`, [getCurrentPlan] simulates "no offerings".
  /// When [error] is non-null, [getCurrentPlan] throws it.
  void stubGetCurrentPlan({SubscriptionPlan? plan, Exception? error}) {
    _currentPlan = plan;
    _currentPlanError = error;
  }
```

Add this method inside the class alongside the other overrides:

```dart
  @override
  Future<SubscriptionPlan?> getCurrentPlan() async {
    if (_currentPlanError != null) throw _currentPlanError!;
    return _currentPlan;
  }
```

- [ ] **Step 3: Run analyzer on the touched files only**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/subscription/domain test/fakes/fake_subscription_service.dart`
Expected: `No issues found!`

(A project-wide analyze would fail here because `RevenueCatSubscriptionService` doesn't implement `getCurrentPlan` yet. That is intentional — Task 4 fixes it, and Task 12 runs the full-project analyze at the end.)

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/subscription/domain/services/subscription_service.dart frontend/test/fakes/fake_subscription_service.dart
git commit -m "feat(subscription): add getCurrentPlan to SubscriptionService and fake"
```

---

## Task 4: Implement getCurrentPlan in RevenueCatSubscriptionService

**Files:**
- Modify: `frontend/lib/features/subscription/data/revenuecat_subscription_service.dart`

- [ ] **Step 1: Implement the method**

Add the `SubscriptionPlan` import at the top of the file alongside existing imports:

```dart
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
```

Insert this method inside the class, immediately before `SubscriptionStatus _mapToStatus(CustomerInfo info) {`:

```dart
  @override
  Future<SubscriptionPlan?> getCurrentPlan() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null || current.availablePackages.isEmpty) {
      return null;
    }
    final package = current.availablePackages.first;
    return SubscriptionPlan(
      priceString: package.storeProduct.priceString,
      period: _mapPeriod(package.packageType),
    );
  }

  SubscriptionPeriod _mapPeriod(PackageType type) {
    switch (type) {
      case PackageType.annual:
        return SubscriptionPeriod.yearly;
      case PackageType.monthly:
      case PackageType.twoMonth:
      case PackageType.threeMonth:
      case PackageType.sixMonth:
      case PackageType.weekly:
      case PackageType.lifetime:
      case PackageType.custom:
      case PackageType.unknown:
        return SubscriptionPeriod.monthly;
    }
  }
```

- [ ] **Step 2: Run analyzer**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/subscription`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/subscription/data/revenuecat_subscription_service.dart
git commit -m "feat(subscription): implement getCurrentPlan in RevenueCat service"
```

---

## Task 5: Extract MidnightKyotoBackdrop to shared widget

**Files:**
- Create: `frontend/lib/shared/widgets/midnight_kyoto_backdrop.dart`
- Modify: `frontend/lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart`

- [ ] **Step 1: Create the shared widget**

```dart
// frontend/lib/shared/widgets/midnight_kyoto_backdrop.dart

import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';

/// Atmospheric backdrop layer for the Midnight Kyoto brand moments.
///
/// Draws a deep radial wash of electric blue at the top so the canvas
/// reads as "night sky over Kyoto" rather than a flat dark rectangle.
/// Used by both the onboarding welcome carousel and the subscription
/// paywall to share the same brand atmosphere.
class MidnightKyotoBackdrop extends StatelessWidget {
  const MidnightKyotoBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.85),
          radius: 1.1,
          colors: [Color(0x33137FEC), AppColors.backgroundDark],
          stops: [0.0, 0.7],
        ),
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 2: Replace the private onboarding backdrop with the shared one**

In `frontend/lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart`:

1. Add this import alongside the existing imports:

```dart
import 'package:context_app/shared/widgets/midnight_kyoto_backdrop.dart';
```

2. In `build`, replace `_MidnightKyotoBackdrop(` with `MidnightKyotoBackdrop(`.

3. Delete the private `_MidnightKyotoBackdrop` class (the one defined at the bottom of the file — lines ~213-232 including its doc comment). The shared class fully replaces it.

- [ ] **Step 3: Run the onboarding welcome screen tests**

Run: `cd frontend && fvm flutter test test/features/onboarding/presentation/screens/onboarding_welcome_screen_test.dart`
Expected: All existing tests pass.

- [ ] **Step 4: Run analyzer**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/shared lib/features/onboarding`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/shared/widgets/midnight_kyoto_backdrop.dart frontend/lib/features/onboarding/presentation/screens/onboarding_welcome_screen.dart
git commit -m "refactor(onboarding): extract MidnightKyotoBackdrop to shared widget"
```

---

## Task 6: Add i18n keys for the new paywall copy

**Files:**
- Modify: `frontend/assets/translations/en.json`
- Modify: `frontend/assets/translations/zh-TW.json`

- [ ] **Step 1: Add six new keys inside the `subscription` object of `en.json`**

Insert these entries alongside the existing `subscription.*` keys:

```json
    "category_label": "PREMIUM · MEMBERSHIP",
    "headline": "Unlock unlimited journeys",
    "subheadline": "AI guides that never stop at every corner",
    "plan_label": "MONTHLY PLAN",
    "plan_period": "/ month",
    "auto_renew_notice": "Auto-renews monthly. Cancel anytime.",
```

Placement: insert immediately after the existing `"restore": "Restore Purchases",` line, before `"terms": "Terms of Service",`.

- [ ] **Step 2: Add the same six keys inside the `subscription` object of `zh-TW.json`**

```json
    "category_label": "高級 · 會員方案",
    "headline": "解鎖無盡旅程",
    "subheadline": "每個轉角，都有一位 AI 旅伴",
    "plan_label": "月訂閱",
    "plan_period": "／月",
    "auto_renew_notice": "每月自動續訂，可隨時取消",
```

Placement: same relative location as in `en.json` (after `restore`, before `terms`).

- [ ] **Step 3: Validate JSON**

Run: `cd frontend && python3 -c "import json; json.load(open('assets/translations/en.json')); json.load(open('assets/translations/zh-TW.json')); print('ok')"`
Expected: `ok`

- [ ] **Step 4: Commit**

```bash
git add frontend/assets/translations/en.json frontend/assets/translations/zh-TW.json
git commit -m "i18n(subscription): add paywall category, headline, and plan copy"
```

---

## Task 7: Write failing tests for SubscriptionPlanCard

**Files:**
- Create: `frontend/test/features/subscription/presentation/widgets/subscription_plan_card_test.dart`

- [ ] **Step 1: Write the widget test**

```dart
// frontend/test/features/subscription/presentation/widgets/subscription_plan_card_test.dart

import 'package:context_app/features/subscription/presentation/widgets/subscription_plan_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SubscriptionPlanCard', () {
    testWidgets(
      'given the loading state, when the card is shown, '
      'then it renders a price skeleton and no subscribe-ready text',
      (tester) async {
        await _pumpCard(tester, const SubscriptionPlanCardState.loading());

        expect(
          find.byKey(const ValueKey('planCard.priceSkeleton')),
          findsOneWidget,
        );
        expect(find.text('NT\$90'), findsNothing);
      },
    );

    testWidgets(
      'given a ready state, when the card is shown, '
      'then the price string is the largest font on the card',
      (tester) async {
        await _pumpCard(
          tester,
          SubscriptionPlanCardState.ready(
            planLabel: 'MONTHLY PLAN',
            priceString: 'NT\$90',
            periodLabel: '/ month',
            bullets: const ['Unlimited', 'Ad-free', 'Routes'],
            autoRenewNotice: 'Auto-renews monthly. Cancel anytime.',
          ),
        );

        final priceSize = _fontSize(tester, 'NT\$90');
        final periodSize = _fontSize(tester, '/ month');
        final planLabelSize = _fontSize(tester, 'MONTHLY PLAN');
        final noticeSize =
            _fontSize(tester, 'Auto-renews monthly. Cancel anytime.');
        final bulletSize = _fontSize(tester, 'Unlimited');

        expect(priceSize, greaterThan(periodSize));
        expect(priceSize, greaterThan(planLabelSize));
        expect(priceSize, greaterThan(noticeSize));
        expect(priceSize, greaterThan(bulletSize));
      },
    );

    testWidgets(
      'given a ready state, when the card is shown, '
      'then every provided bullet appears',
      (tester) async {
        await _pumpCard(
          tester,
          SubscriptionPlanCardState.ready(
            planLabel: 'MONTHLY PLAN',
            priceString: 'NT\$90',
            periodLabel: '/ month',
            bullets: const ['Unlimited', 'Ad-free', 'Routes'],
            autoRenewNotice: 'Notice',
          ),
        );

        expect(find.text('Unlimited'), findsOneWidget);
        expect(find.text('Ad-free'), findsOneWidget);
        expect(find.text('Routes'), findsOneWidget);
      },
    );

    testWidgets(
      'given an error state, when the user taps retry, '
      'then onRetry is invoked exactly once',
      (tester) async {
        var retryCount = 0;
        await _pumpCard(
          tester,
          const SubscriptionPlanCardState.error(message: 'oops'),
          onRetry: () => retryCount++,
        );

        await tester.tap(find.byKey(const ValueKey('planCard.retry')));
        await tester.pump();

        expect(retryCount, 1);
        expect(find.text('oops'), findsOneWidget);
      },
    );
  });
}

double _fontSize(WidgetTester tester, String text) {
  final widget = tester.widget<Text>(find.text(text));
  final size = widget.style?.fontSize;
  expect(size, isNotNull, reason: 'Text "$text" should have explicit fontSize');
  return size!;
}

Future<void> _pumpCard(
  WidgetTester tester,
  SubscriptionPlanCardState state, {
  VoidCallback? onRetry,
}) async {
  await pumpScreen(
    tester,
    child: Scaffold(
      backgroundColor: const Color(0xFF101922),
      body: Center(
        child: SubscriptionPlanCard(state: state, onRetry: onRetry),
      ),
    ),
  );
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `cd frontend && fvm flutter test test/features/subscription/presentation/widgets/subscription_plan_card_test.dart`
Expected: compile error (`subscription_plan_card.dart` does not exist yet).

- [ ] **Step 3: Do not commit yet — Task 8 provides the implementation**

---

## Task 8: Implement SubscriptionPlanCard

**Files:**
- Create: `frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart`

- [ ] **Step 1: Create the widget file**

```dart
// frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart

import 'package:context_app/common/config/app_colors.dart';
import 'package:flutter/material.dart';

/// Paywall plan card in the Midnight Kyoto brand language.
///
/// Renders a single subscription plan inside a glass-style container.
/// The billed price is the most visually dominant element on the card
/// to satisfy App Store Guideline 3.1.2(c).
class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.state,
    this.onRetry,
  });

  final SubscriptionPlanCardState state;
  final VoidCallback? onRetry;

  static const double _priceFontSize = 40;
  static const double _periodFontSize = 14;
  static const double _planLabelFontSize = 11;
  static const double _bulletFontSize = 14;
  static const double _noticeFontSize = 11;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceDarkCard, AppColors.surfaceDark],
        ),
        border: Border.all(color: AppColors.glassBorder),
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
      child: switch (state) {
        SubscriptionPlanCardStateLoading() => const _Loading(),
        SubscriptionPlanCardStateError(:final message) => _Error(
            message: message,
            onRetry: onRetry,
          ),
        SubscriptionPlanCardStateReady(
          :final planLabel,
          :final priceString,
          :final periodLabel,
          :final bullets,
          :final autoRenewNotice,
        ) =>
          _Ready(
            planLabel: planLabel,
            priceString: priceString,
            periodLabel: periodLabel,
            bullets: bullets,
            autoRenewNotice: autoRenewNotice,
          ),
      },
    );
  }
}

/// Discriminated state for [SubscriptionPlanCard].
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
  }) = SubscriptionPlanCardStateReady;
}

final class SubscriptionPlanCardStateLoading extends SubscriptionPlanCardState {
  const SubscriptionPlanCardStateLoading();
}

final class SubscriptionPlanCardStateError extends SubscriptionPlanCardState {
  const SubscriptionPlanCardStateError({required this.message});
  final String message;
}

final class SubscriptionPlanCardStateReady extends SubscriptionPlanCardState {
  const SubscriptionPlanCardStateReady({
    required this.planLabel,
    required this.priceString,
    required this.periodLabel,
    required this.bullets,
    required this.autoRenewNotice,
  });

  final String planLabel;
  final String priceString;
  final String periodLabel;
  final List<String> bullets;
  final String autoRenewNotice;
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _SkeletonBar(
          key: ValueKey('planCard.labelSkeleton'),
          width: 120,
          height: 12,
        ),
        SizedBox(height: 16),
        _SkeletonBar(
          key: ValueKey('planCard.priceSkeleton'),
          width: 160,
          height: 36,
        ),
        SizedBox(height: 20),
        _SkeletonBar(width: double.infinity, height: 14),
        SizedBox(height: 10),
        _SkeletonBar(width: double.infinity, height: 14),
        SizedBox(height: 10),
        _SkeletonBar(width: 180, height: 14),
      ],
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white10,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('planCard.retry'),
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.planLabel,
    required this.priceString,
    required this.periodLabel,
    required this.bullets,
    required this.autoRenewNotice,
  });

  final String planLabel;
  final String priceString;
  final String periodLabel;
  final List<String> bullets;
  final String autoRenewNotice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          planLabel,
          style: const TextStyle(
            fontSize: SubscriptionPlanCard._planLabelFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textTertiaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              priceString,
              style: const TextStyle(
                fontSize: SubscriptionPlanCard._priceFontSize,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryDark,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              periodLabel,
              style: const TextStyle(
                fontSize: SubscriptionPlanCard._periodFontSize,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Divider(),
        const SizedBox(height: 16),
        ...bullets.map(_bulletRow),
        const SizedBox(height: 16),
        const _Divider(),
        const SizedBox(height: 12),
        Text(
          autoRenewNotice,
          style: const TextStyle(
            fontSize: SubscriptionPlanCard._noticeFontSize,
            color: AppColors.textTertiaryDark,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _bulletRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✦',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: SubscriptionPlanCard._bulletFontSize,
                color: AppColors.textPrimaryDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.glassBorder);
  }
}
```

- [ ] **Step 2: Run the widget tests and confirm they pass**

Run: `cd frontend && fvm flutter test test/features/subscription/presentation/widgets/subscription_plan_card_test.dart`
Expected: All 4 tests pass.

- [ ] **Step 3: Run analyzer**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/subscription/presentation/widgets test/features/subscription/presentation/widgets`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/subscription/presentation/widgets/subscription_plan_card.dart frontend/test/features/subscription/presentation/widgets/subscription_plan_card_test.dart
git commit -m "feat(subscription): add SubscriptionPlanCard widget with three states"
```

---

## Task 9: Update subscription screen tests for the new layout

**Files:**
- Modify: `frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart`

- [ ] **Step 1: Replace the test file content**

Replace the entire contents of `frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart` with:

```dart
import 'package:context_app/common/config/legal_urls.dart';
import 'package:context_app/features/subscription/domain/models/subscription_plan.dart';
import 'package:context_app/features/subscription/domain/models/subscription_status.dart';
import 'package:context_app/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:context_app/features/subscription/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_subscription_service.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SubscriptionScreen', () {
    testWidgets(
      'given a ready plan, when the screen loads, '
      'then the localized price string is rendered',
      (tester) async {
        final service = _serviceWithPlan();

        await _givenSubscriptionScreen(tester, service: service);

        expect(find.text('NT\$90'), findsOneWidget);
        expect(find.text('subscription.plan_period'), findsOneWidget);
        expect(find.text('subscription.plan_label'), findsOneWidget);
      },
    );

    testWidgets(
      'given the screen is shown, when it loads, '
      'then the benefits and primary actions are visible',
      (tester) async {
        await _givenSubscriptionScreen(tester, service: _serviceWithPlan());

        expect(find.text('subscription.benefit_no_ads'), findsOneWidget);
        expect(find.text('subscription.benefit_unlimited'), findsOneWidget);
        expect(find.text('subscription.benefit_route'), findsOneWidget);
        expect(find.text('subscription.subscribe'), findsOneWidget);
        expect(find.text('subscription.restore'), findsOneWidget);
      },
    );

    testWidgets(
      'given a successful purchase, when the user subscribes, '
      'then the screen dismisses with a positive result',
      (tester) async {
        final service = _serviceWithPlan()
          ..stubPurchase(
            status: const SubscriptionStatus(isPremium: true),
          );

        await _givenSubscriptionScreenOnRoute(tester, service);
        await _whenUserTapsSubscribe(tester);

        expect(find.byType(SubscriptionScreen), findsNothing);
      },
    );

    testWidgets(
      'given no prior purchase, when the user taps restore, '
      'then the no-purchases snackbar is shown',
      (tester) async {
        final service = _serviceWithPlan()
          ..stubRestore(status: SubscriptionStatus.free);

        await _givenSubscriptionScreen(tester, service: service);
        await _whenUserTapsRestore(tester);

        expect(find.text('subscription.no_purchases_found'), findsOneWidget);
      },
    );

    testWidgets(
      'given the terms link is tapped, when the user interacts, '
      'then the injected launcher is called with the terms URL',
      (tester) async {
        final launched = <Uri>[];
        await _givenSubscriptionScreen(
          tester,
          service: _serviceWithPlan(),
          launcher: (uri) async {
            launched.add(uri);
            return true;
          },
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
        await _givenSubscriptionScreen(
          tester,
          service: _serviceWithPlan(),
          launcher: (uri) async {
            launched.add(uri);
            return true;
          },
        );

        await tester.tap(find.text('subscription.privacy'));
        await tester.pumpAndSettle();

        expect(launched, [Uri.parse(LegalUrls.privacyPolicy)]);
      },
    );

    testWidgets(
      'given the plan fails to load, when retry is tapped, '
      'then getCurrentPlan is called again',
      (tester) async {
        final service = FakeSubscriptionService()
          ..stubGetCurrentPlan(error: Exception('network'));

        await _givenSubscriptionScreen(tester, service: service);

        expect(find.byKey(const ValueKey('planCard.retry')), findsOneWidget);

        // Seed a plan for the retry, then tap.
        service.stubGetCurrentPlan(
          plan: const SubscriptionPlan(
            priceString: 'NT\$90',
            period: SubscriptionPeriod.monthly,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('planCard.retry')));
        await tester.pumpAndSettle();

        expect(find.text('NT\$90'), findsOneWidget);
      },
    );
  });
}

FakeSubscriptionService _serviceWithPlan() {
  return FakeSubscriptionService()
    ..stubGetCurrentPlan(
      plan: const SubscriptionPlan(
        priceString: 'NT\$90',
        period: SubscriptionPeriod.monthly,
      ),
    );
}

Future<void> _givenSubscriptionScreen(
  WidgetTester tester, {
  required FakeSubscriptionService service,
  Future<bool> Function(Uri)? launcher,
}) async {
  await pumpScreen(
    tester,
    child: SubscriptionScreen(launchUrl: launcher),
    overrides: [subscriptionServiceProvider.overrideWithValue(service)],
  );
  await tester.pumpAndSettle();
}

Future<void> _givenSubscriptionScreenOnRoute(
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

Future<void> _whenUserTapsSubscribe(WidgetTester tester) async {
  await tester.tap(find.text('subscription.subscribe'));
  await tester.pumpAndSettle();
}

Future<void> _whenUserTapsRestore(WidgetTester tester) async {
  await tester.tap(find.text('subscription.restore'));
  await tester.pumpAndSettle();
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('host')));
}
```

- [ ] **Step 2: Run the test file and confirm the new expectations fail**

Run: `cd frontend && fvm flutter test test/features/subscription/presentation/screens/subscription_screen_test.dart`
Expected: Compile errors (`launchUrl` param does not exist on `SubscriptionScreen`, plus missing i18n keys). All new expectations fail.

- [ ] **Step 3: Do not commit yet — Task 10 provides the implementation**

---

## Task 10: Refactor SubscriptionScreen

**Files:**
- Modify: `frontend/lib/features/subscription/presentation/screens/subscription_screen.dart`

- [ ] **Step 1: Replace the file contents**

Replace the entire contents of `frontend/lib/features/subscription/presentation/screens/subscription_screen.dart` with:

```dart
import 'package:context_app/common/config/app_colors.dart';
import 'package:context_app/common/config/legal_urls.dart';
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

/// Midnight Kyoto paywall screen.
///
/// Displays the current subscription plan with the billed amount as the
/// dominant typographic element, a clear subscription period, and
/// functional Terms of Use and Privacy Policy links. Complies with App
/// Store Review Guidelines 3.1.2(c).
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key, UrlLauncher? launchUrl})
      : _launchUrl = launchUrl;

  final UrlLauncher? _launchUrl;

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isPurchasing = false;
  bool _isLoadingPlan = true;
  SubscriptionPlan? _plan;
  String? _planError;

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
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoadingPlan = true;
      _planError = null;
    });
    try {
      final plan =
          await ref.read(subscriptionServiceProvider).getCurrentPlan();
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _isLoadingPlan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _planError = e.toString();
        _isLoadingPlan = false;
      });
    }
  }

  Future<void> _purchase() async {
    setState(() => _isPurchasing = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      final result = await service.purchase();
      if (result != null && result.isPremium && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error_prefix'.tr()}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
            backgroundColor: AppColors.error,
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
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  SubscriptionPlanCardState _cardState() {
    if (_isLoadingPlan) return const SubscriptionPlanCardState.loading();
    if (_planError != null) {
      return SubscriptionPlanCardState.error(message: _planError!);
    }
    final plan = _plan;
    if (plan == null) {
      return SubscriptionPlanCardState.error(
        message: 'common.error_prefix'.tr(),
      );
    }
    return SubscriptionPlanCardState.ready(
      planLabel: 'subscription.plan_label'.tr(),
      priceString: plan.priceString,
      periodLabel: 'subscription.plan_period'.tr(),
      bullets: [
        'subscription.benefit_unlimited'.tr(),
        'subscription.benefit_no_ads'.tr(),
        'subscription.benefit_route'.tr(),
      ],
      autoRenewNotice: 'subscription.auto_renew_notice'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _midnightKyotoTheme(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: MidnightKyotoBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AdaptiveIconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textPrimaryDark,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.8,
                            color: AppColors.textSecondaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'subscription.headline'.tr(),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimaryDark,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'subscription.subheadline'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.55,
                            color: AppColors.textSecondaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        SubscriptionPlanCard(
                          state: _cardState(),
                          onRetry: _loadPlan,
                        ),
                        const SizedBox(height: 20),
                        _SubscribeButton(
                          isLoading: _isPurchasing,
                          onPressed:
                              _isPurchasing || _plan == null ? null : _purchase,
                        ),
                        const SizedBox(height: 4),
                        AdaptiveButton(
                          style: AdaptiveButtonStyle.text,
                          foregroundColor: AppColors.textSecondaryDark,
                          onPressed: _isPurchasing ? null : _restore,
                          child: Text(
                            'subscription.restore'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondaryDark,
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
      ),
    );
  }
}

class _PremiumIcon extends StatelessWidget {
  const _PremiumIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        icon: isLoading
            ? const SizedBox.shrink()
            : const Icon(Icons.lock_open_rounded),
        label: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: AdaptiveProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text('subscription.subscribe'.tr()),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.onOpen});

  final Future<void> Function(Uri) onOpen;

  @override
  Widget build(BuildContext context) {
    final linkStyle = const TextStyle(
      fontSize: 12,
      color: AppColors.textTertiaryDark,
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '·',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiaryDark,
            ),
          ),
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

ThemeData _midnightKyotoTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      surface: AppColors.backgroundDark,
    ),
  );
}
```

- [ ] **Step 2: Run the screen tests and confirm they pass**

Run: `cd frontend && fvm flutter test test/features/subscription/presentation/screens/subscription_screen_test.dart`
Expected: All 7 tests pass.

- [ ] **Step 3: Run analyzer**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/subscription test/features/subscription`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/subscription/presentation/screens/subscription_screen.dart frontend/test/features/subscription/presentation/screens/subscription_screen_test.dart
git commit -m "feat(subscription): redesign paywall with price, duration, and legal links

Adds localized price display via SubscriptionPlanCard, terms and
privacy footer links through an injectable url launcher, and the
Midnight Kyoto visual language to match the recent onboarding
redesign. Satisfies App Store Guideline 3.1.2(c)."
```

---

## Task 11: Write the AI disclosure reply document

**Files:**
- Create: `docs/app-review/2026-04-21-ai-disclosure-reply.md`

- [ ] **Step 1: Create the document**

```markdown
# App Store Review — AI Disclosure Reply (2026-04-21)

> Paste the body below into the App Store Connect reply for submission
> `e05d912c-09c9-445b-bb42-e57e9f1e61ef` (Guideline 2.1). Keep this file
> updated if the AI stack changes so future submissions can reuse it.

## Guideline 2.1 — AI Disclosure

**1. Does your app use any third-party AI for analysis of data?**

Yes.

**2. What is the name of the third-party AI provider?**

Google Vertex AI (Gemini 2.5 Flash), accessed through the Firebase AI
SDK (`firebase_ai` package).

**3. List the types of data being transmitted to the third-party AI.**

Per narration request, the app sends:

- Public place metadata sourced from the Google Places API: the place's
  name, formatted address, category, place types, and rating (when
  available).
- A localized prompt template (English or Traditional Chinese)
  describing the desired narration style, length, and audience.

The app does **not** transmit:

- User account identifiers
- Email addresses or names
- Device identifiers
- Photos, audio recordings, or camera input
- Location coordinates or movement data

## App Store Connect metadata checklist

Before resubmission, confirm all three:

- [ ] App Description ends with `Terms of Use (EULA): https://lorescape.app/terms`
- [ ] App Information → Privacy Policy URL is `https://lorescape.app/privacy`
- [ ] This reply is pasted into App Review Notes for the next build
```

- [ ] **Step 2: Commit**

```bash
git add docs/app-review/2026-04-21-ai-disclosure-reply.md
git commit -m "docs(app-review): AI disclosure reply for 2026-04-21 rejection"
```

---

## Task 12: Final verification

**Files:** (no code changes in this task)

- [ ] **Step 1: Run the full analyzer**

Run: `cd frontend && fvm flutter analyze --fatal-infos`
Expected: `No issues found!`

- [ ] **Step 2: Run the full test suite**

Run: `cd frontend && fvm flutter test`
Expected: All tests pass.

- [ ] **Step 3: Manually verify the paywall (optional but recommended)**

Run `cd frontend && fvm flutter run` on a simulator, navigate to
`/subscription`, and confirm:

- Midnight Kyoto backdrop is visible.
- The price string from RevenueCat is the largest text on screen.
- `MONTHLY PLAN`, `/ month`, three bullets, and the auto-renew notice
  are all present.
- Tapping "Terms of Service" opens `https://lorescape.app/terms` in the
  system browser.
- Tapping "Privacy Policy" opens `https://lorescape.app/privacy` in the
  system browser.
- Subscribe and Restore buttons behave as before.

- [ ] **Step 4: If a single verification commit is desired, amend or create an empty note commit**

Otherwise, the plan is complete — the previous per-task commits already
contain every change.
