# 新增每週訂閱方案 — 設計文件

**日期**：2026-05-11
**狀態**：Spec

## 背景

目前付費牆 (`SubscriptionScreen`) 只顯示一個訂閱方案（每月）。
要在不影響既有月訂閱使用者的前提下，把付費牆改為「每週 / 每月 / 每年」三方案多選的版型，並讓「每年」標示為 Best value、預設選取。

商店與 RevenueCat 後台尚未建立每週、每年方案；後台操作獨立成
[`docs/init/subscription-setup.md`](../../init/subscription-setup.md)，本 spec 只描述程式變更。

## 目標

- 付費牆可同時顯示 weekly / monthly / yearly 三張方案卡
- 進入時預設選取 yearly，並顯示 Best value 徽章
- 點擊任一卡片切換選取；訂閱按鈕文案隨選取週期變化
- 購買流程能依使用者選取週期向 RevenueCat 傳對應 package
- 修正既有 `_mapPeriod` 將 `PackageType.weekly` 誤對應為 `monthly` 的 bug

## 非目標

- 不顯示「省 X%」、「每日均價」等比較資訊（僅顯示 RC 本地化價格與週期）
- 不引入 `SubscriptionOffering` 聚合 / 多 offering 支援（YAGNI）
- 不改變 `premium` entitlement 名稱或 `subscriptionStatusProvider` API
- 不調整付費牆視覺主視覺（headline、subheadline、背景、legal footer 沿用）

## 架構

仍維持 Feature-First + Clean Architecture：

```
features/subscription/
├── data/
│   └── revenuecat_subscription_service.dart   (改)
├── domain/
│   ├── errors/
│   │   └── subscription_errors.dart           (新)
│   ├── models/
│   │   ├── subscription_plan.dart             (改)
│   │   └── subscription_status.dart           (不變)
│   └── services/
│       └── subscription_service.dart          (改)
├── presentation/
│   ├── screens/
│   │   └── subscription_screen.dart           (改)
│   └── widgets/
│       └── subscription_plan_card.dart        (改)
└── providers.dart                              (不變)
```

## 設計

### 1. Domain Model

**`SubscriptionPeriod`** 加入 `weekly`：

```dart
enum SubscriptionPeriod { weekly, monthly, yearly }
```

**`SubscriptionPlan`** 新增兩個欄位：

```dart
class SubscriptionPlan {
  final String priceString;        // RC 本地化價格（不變）
  final SubscriptionPeriod period; // 不變
  final String packageIdentifier;  // 新增：RC Package identifier
  final bool isBestValue;          // 新增：UI badge hint

  const SubscriptionPlan({
    required this.priceString,
    required this.period,
    required this.packageIdentifier,
    this.isBestValue = false,
  });

  // operator ==, hashCode 同步擴充
}
```

理由：
- `packageIdentifier` 讓 `purchase(period)` 在 service 內可定位到正確的 `Package`，不再依賴 `availablePackages.first`。
- `isBestValue` 由 mapper 一處（`period == yearly` 時）設值；集中變更點，未來改規則容易。

### 2. Service 介面

`SubscriptionService` 抽象介面異動：

```dart
abstract class SubscriptionService {
  // ...既有方法不變

  // 移除：
  // Future<SubscriptionPlan?> getCurrentPlan();

  // 新增：
  Future<List<SubscriptionPlan>> getAvailablePlans();

  // 變更：
  Future<SubscriptionStatus?> purchase(SubscriptionPeriod period);
}
```

### 3. RevenueCat 實作

`RevenueCatSubscriptionService` 變更要點：

- **`getAvailablePlans()`**
  1. 讀 `Purchases.getOfferings()`，取 `current`。
  2. `current.availablePackages` 過濾出 `PackageType.weekly | monthly | annual`。
  3. 對應為 `SubscriptionPlan`（含 `packageIdentifier = package.identifier`、`isBestValue = period == yearly`）。
  4. 依 `weekly → monthly → yearly` 固定順序回傳。
  5. 沒有任何符合 package → 回傳空 list。

- **`purchase(SubscriptionPeriod period)`**
  1. 重新讀 `Offerings.current`（不快取，與既有風格一致）。
  2. 依 `period` 找對應 `Package`。
  3. 找不到 → 丟 `SubscriptionPlanNotAvailableException(period)`。
  4. 呼叫 `Purchases.purchase(PurchaseParams.package(package))`。
  5. 使用者取消（`PlatformException.code == '1'`）→ 回 `null`（不變）。
  6. 回傳 `_mapToStatus(result.customerInfo)`（不變）。

- **`_mapPeriod`**
  - 修正：`PackageType.weekly` → `SubscriptionPeriod.weekly`（既有 bug fix）。
  - 其餘 PackageType（`twoMonth` / `threeMonth` / `sixMonth` / `lifetime` / `custom` / `unknown`）在 `getAvailablePlans()` 階段就被過濾掉，不會走進 `_mapPeriod`。

- **Domain exception**（`domain/errors/subscription_errors.dart` 新檔）：

  ```dart
  class SubscriptionPlanNotAvailableException implements Exception {
    final SubscriptionPeriod period;
    SubscriptionPlanNotAvailableException(this.period);

    @override
    String toString() => 'Plan not available for period: $period';
  }
  ```

### 4. UI — `SubscriptionScreen`

**State 變更**：

```dart
bool _isPurchasing = false;
bool _isLoadingPlans = true;          // 改名
List<SubscriptionPlan> _plans = const [];
SubscriptionPeriod? _selectedPeriod;
String? _plansError;
bool _showHeadline = false;
bool _showSubheadline = false;
bool _showPlanCards = false;          // 改名
```

**載入流程**：

```dart
Future<void> _loadPlans() async {
  setState(() { _isLoadingPlans = true; _plansError = null; });
  try {
    final plans = await ref.read(subscriptionServiceProvider).getAvailablePlans();
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
      _selectedPeriod = plans.any((p) => p.period == SubscriptionPeriod.yearly)
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
```

**畫面結構**（保留 backdrop、headline、subheadline、legal footer、restore 連結）：

```
Plans 區塊：
  - loading → 三張 skeleton 卡（沿用既有 _SkeletonBar）
  - error   → 單一錯誤卡 + Retry（沿用既有 _Error）
  - ready   → Column of 3 × SubscriptionPlanCard，間距 12

Subscribe button：
  - 文字依 _selectedPeriod 動態：subscribe_weekly / subscribe_monthly / subscribe_yearly
  - 點擊呼叫 service.purchase(_selectedPeriod!)

購買進行中：
  - 整個 Plans 區塊用 IgnorePointer 包起來，避免切換選取
```

**Subscribe 文案**：

```dart
String _subscribeLabel(SubscriptionPeriod? period) => switch (period) {
  SubscriptionPeriod.weekly  => 'subscription.subscribe_weekly'.tr(),
  SubscriptionPeriod.monthly => 'subscription.subscribe_monthly'.tr(),
  SubscriptionPeriod.yearly  => 'subscription.subscribe_yearly'.tr(),
  null                        => 'subscription.subscribe'.tr(),
};
```

### 5. UI — `SubscriptionPlanCard`

`SubscriptionPlanCardStateReady` 新增三個欄位：

```dart
final class SubscriptionPlanCardStateReady extends SubscriptionPlanCardState {
  // 既有：
  final String planLabel;
  final String priceString;
  final String periodLabel;
  final List<String> bullets;
  final String autoRenewNotice;

  // 新增：
  final bool selected;
  final bool isBestValue;
  final VoidCallback? onTap;

  // ...
}
```

視覺規則：

- **整張卡可點**：以 `InkWell` 包 `_Ready` 內容，呼叫 `onTap`。
- **selected == true**：邊框改用 `cs.primary`；`planLabel` 前綴 `Icons.check_circle`（`cs.primary` 顏色，size 16），與文字同 baseline。
- **isBestValue == true**：卡片右上顯示「Best value」膠囊（背景 `cs.primaryContainer`、文字 `cs.onPrimaryContainer`、`subscription.badge_best_value` i18n key）。
- 兩者可同時出現且不衝突：勾勾在左上角的 planLabel 旁、badge 在右上角。
- **bullets / autoRenewNotice 只在 `selected` 的卡片展開**；未選取的卡片只顯示 `planLabel + priceString + periodLabel`，視覺降低資訊密度。

bullets / autoRenewNotice 仍由 `SubscriptionScreen` 從 i18n 拉好傳入；三張卡共用同一份內容，由 `selected` 控制是否展開。

### 6. i18n keys

新增（所有 locale 同步加）：

| Key | English | 繁中 |
|-----|---------|------|
| `subscription.plan_weekly`       | Weekly             | 每週方案 |
| `subscription.plan_monthly`      | Monthly            | 每月方案 |
| `subscription.plan_yearly`       | Yearly             | 每年方案 |
| `subscription.period_weekly`     | / week             | ／週 |
| `subscription.period_monthly`    | / month            | ／月 |
| `subscription.period_yearly`     | / year             | ／年 |
| `subscription.subscribe_weekly`  | Subscribe Weekly   | 訂閱每週方案 |
| `subscription.subscribe_monthly` | Subscribe Monthly  | 訂閱每月方案 |
| `subscription.subscribe_yearly`  | Subscribe Yearly   | 訂閱每年方案 |
| `subscription.badge_best_value`  | Best value         | 最划算 |

既有 keys 處理：

- `subscription.plan_label`、`subscription.plan_period` 改為由上述新 key 取代；舊 key 若無其他引用則移除。
- `subscription.subscribe` 保留作為 fallback（`_selectedPeriod == null` 時使用）。

### 7. 錯誤處理

| 情境 | 行為 |
|------|------|
| `Purchases.getOfferings()` 失敗 | UI 顯示 `subscription.plan_load_failed` + Retry |
| Current offering 為 null 或無符合 package | 同上 |
| 部分週期缺失（例如只有 weekly+monthly） | UI 只顯示有的方案；預設選 yearly，不存在則選列表第一個 |
| 購買時對應 package 已不存在（罕見競態） | service 丟 `SubscriptionPlanNotAvailableException`，screen 顯示 SnackBar 並重新 `_loadPlans()` |
| 使用者取消購買 | `purchase()` 回 `null`，UI 不關閉、清掉 loading（沿用） |
| 購買網路錯誤 | catch + SnackBar（沿用） |
| 載入中切換選取 | `_isPurchasing` 期間整個 Plans 區塊 `IgnorePointer` |

## 測試策略

依專案 `flutter-widget-tests` skill 與既有 `frontend/test/features/subscription/` 結構。

### 單元測試（service mapper）

抽出 pure mapper 便於單測（不需 mock RC SDK）：

- `PackageType.weekly` → `SubscriptionPeriod.weekly`（既有 bug 的迴歸測試）
- `PackageType.monthly` → `SubscriptionPeriod.monthly`
- `PackageType.annual` → `SubscriptionPeriod.yearly`
- `isBestValue` 僅在 `yearly` 時為 `true`
- `getAvailablePlans()`：三種週期都有 → 回傳順序 `weekly → monthly → yearly`
- `getAvailablePlans()`：缺少 yearly → 回傳 `weekly + monthly`
- `getAvailablePlans()`：空 offering → 回傳空 list

### Widget tests (`SubscriptionScreen`)

BDD 命名 + Fake service：

1. `given plans loaded, when screen first shows, then yearly is selected and Best value badge is visible`
2. `given yearly selected, when tap weekly card, then weekly becomes selected and subscribe button label changes to Subscribe Weekly`
3. `given user taps subscribe, then fake service.purchase is called with selected period`
4. `given service returns only weekly + monthly, then only two cards render and weekly is selected by default`
5. `given service throws on load, then error state shows; tap Retry re-invokes getAvailablePlans`
6. `given purchase in progress, then plan cards cannot be re-selected`

`FakeSubscriptionService` 擴充 `getAvailablePlans` 與帶 period 參數的 `purchase`。

## 後台 / 商店設定

詳見 [`docs/init/subscription-setup.md`](../../init/subscription-setup.md)。

驗收標準：
- Dev build 安裝後，付費牆顯示三張卡片，價格為商店本地化字串
- Sandbox 帳號可分別完成 weekly / monthly / yearly 購買流程
- 購買成功後 `subscriptionStatusProvider` 反映為 premium

## 風險與權衡

- **`SubscriptionPlan.isBestValue` 屬 UI hint 進入 domain**：可接受，集中於 mapper 控制；若未來規則複雜化（如後台動態設定），再抽 `SubscriptionOffering` 不會浪費。
- **未選取卡片不展開 bullets**：降低資訊密度但需確認設計觀感；UI 段已說明可在實作後微調。
- **取消 `getCurrentPlan()` API 屬 breaking change**：本專案只有 `SubscriptionScreen` 一處使用，影響範圍可控。

## 相關檔案

| 檔案 | 角色 |
|------|------|
| `lib/features/subscription/domain/models/subscription_plan.dart` | 加 `weekly`、`packageIdentifier`、`isBestValue` |
| `lib/features/subscription/domain/services/subscription_service.dart` | 改 `getAvailablePlans` / `purchase(period)` |
| `lib/features/subscription/domain/errors/subscription_errors.dart` | 新檔 |
| `lib/features/subscription/data/revenuecat_subscription_service.dart` | 實作新介面 + 修 `_mapPeriod` bug |
| `lib/features/subscription/presentation/screens/subscription_screen.dart` | 多卡選取、purchase 帶 period |
| `lib/features/subscription/presentation/widgets/subscription_plan_card.dart` | `selected` / `isBestValue` / `onTap` |
| `frontend/assets/translations/en.json` | 新增英文 keys |
| `frontend/assets/translations/zh-TW.json` | 新增繁中 keys |
| `docs/init/subscription-setup.md` | 後台 / 商店操作指引 |
