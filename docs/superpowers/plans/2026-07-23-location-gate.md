# Location Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 定位不可用時，在探索頁地圖中央顯示一張浮層卡（共用插圖＋i18n 說明＋依狀態的引導按鈕），取代目前半中半英、無引導的底部小字。

**Architecture:** 把 `GeolocatorService` throw 的純字串換成型別化的 `LocationError` enum，讓錯誤經既有 `AsyncValue.guard` 傳到 `filteredPlacesProvider`；`LocationService` 介面加三個引導動作方法（重新請求權限 / 開 App 設定 / 開定位設定），使 presentation 不直接依賴 geolocator；`ExploreScreen` 在 `AsyncError` 且 `error is LocationError` 時，於 Stack 疊一張置中的 `_LocationGateCard`。

**Tech Stack:** Flutter、Riverpod（AsyncNotifier）、geolocator ^14.0.2、easy_localization、flutter_test。所有 flutter/dart 指令一律 `fvm`。

## Global Constraints

- 一律用 `fvm` 執行 flutter / dart 指令。
- 每次改動後 `fvm flutter analyze --fatal-infos` 必須全綠才算完成。
- 測試 `fvm flutter test`；`test/` 鏡射 `lib/`；widget test 用 `_EmptyAssetLoader`，故斷言比對「i18n key 原文」而非翻譯結果。
- feature 分層：presentation 只能依賴同 feature 的 domain 與 providers；`LocationError`、`LocationService` 屬 domain。
- 錯誤代碼格式 `MODULE_ERROR_NAME`，實作 `AppErrorType`（見 `lib/core/errors/app_error_type.dart`）。
- 所有路徑相對於 `frontend/`；指令在 `frontend/` 下執行。

---

### Task 1: `LocationError` 型別化錯誤

**Files:**
- Create: `lib/features/explore/domain/errors/location_error.dart`
- Test: `test/features/explore/domain/errors/location_error_test.dart`

**Interfaces:**
- Consumes: `AppErrorType`（`lib/core/errors/app_error_type.dart`，`String get code`）
- Produces: `enum LocationError { serviceDisabled, permissionDenied, permissionDeniedForever }`，每個值 `code == 'LOCATION_<NAME_UPPER>'`。

- [ ] **Step 1: 寫失敗測試**

`test/features/explore/domain/errors/location_error_test.dart`：

```dart
import 'package:context_app/features/explore/domain/errors/location_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationError', () {
    test('given each value, then code follows the LOCATION_ prefix contract', () {
      expect(LocationError.serviceDisabled.code, 'LOCATION_SERVICEDISABLED');
      expect(LocationError.permissionDenied.code, 'LOCATION_PERMISSIONDENIED');
      expect(
        LocationError.permissionDeniedForever.code,
        'LOCATION_PERMISSIONDENIEDFOREVER',
      );
    });
  });
}
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `fvm flutter test test/features/explore/domain/errors/location_error_test.dart`
Expected: FAIL（`location_error.dart` 不存在，編譯錯誤）

- [ ] **Step 3: 建立 enum**

`lib/features/explore/domain/errors/location_error.dart`：

```dart
import 'package:context_app/core/errors/app_error_type.dart';

/// 定位相關錯誤，供探索頁依狀態顯示不同引導。
enum LocationError implements AppErrorType {
  /// 系統定位服務關閉（非 App 權限問題）。
  serviceDisabled,

  /// App 定位權限被拒，但仍可再次請求。
  permissionDenied,

  /// App 定位權限永久被拒，需到設定手動開啟。
  permissionDeniedForever;

  @override
  String get code => 'LOCATION_${name.toUpperCase()}';
}
```

- [ ] **Step 4: 執行測試確認通過**

Run: `fvm flutter test test/features/explore/domain/errors/location_error_test.dart`
Expected: PASS

- [ ] **Step 5: analyze**

Run: `fvm flutter analyze --fatal-infos lib/features/explore/domain/errors/location_error.dart`
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/explore/domain/errors/location_error.dart frontend/test/features/explore/domain/errors/location_error_test.dart
git commit -m "feat(explore): 新增型別化 LocationError

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: `LocationService` 加引導動作、`GeolocatorService` throw 型別化錯誤、更新 `FakeLocationService`

`GeolocatorService` 包的是 geolocator 的 static platform channel，無法在單元測試中驗證；本 task 的行為驗證留給 Task 4 的 widget 測試（透過 `FakeLocationService`）。本 task 以 `analyze` 確認編譯，並讓 fake 具備後續測試所需的注入與計數能力。

**Files:**
- Modify: `lib/features/explore/domain/services/location_service.dart`
- Modify: `lib/features/explore/data/services/geolocator_service.dart`
- Modify: `test/fakes/fake_location_service.dart`

**Interfaces:**
- Consumes: Task 1 的 `LocationError`；geolocator 的 `Geolocator.requestPermission()`、`Geolocator.openAppSettings()`、`Geolocator.openLocationSettings()`、`LocationPermission`。
- Produces:
  - `LocationService` 新增：
    - `Future<bool> requestPermission()` — 請求權限並回傳是否已授權（`whileInUse`/`always` 視為 true）。
    - `Future<void> openAppSettings()`
    - `Future<void> openLocationSettings()`
  - `FakeLocationService`：建構參數 `error` 型別由 `Exception?` 改為 `Object?`（可注入 `LocationError`）；新增 `bool grantOnRequest`（預設 true）、公開計數 `int requestPermissionCallCount`、`int openAppSettingsCallCount`、`int openLocationSettingsCallCount`。

- [ ] **Step 1: 擴充 `LocationService` 介面**

`lib/features/explore/domain/services/location_service.dart`，在既有 `getCurrentLocation()` 宣告後加入：

```dart
  /// 請求定位權限；回傳是否已取得（whileInUse / always 視為已授權）。
  Future<bool> requestPermission();

  /// 開啟系統的 App 設定頁（永久拒絕時引導使用者手動開啟）。
  Future<void> openAppSettings();

  /// 開啟系統的定位服務設定頁（定位服務關閉時引導開啟）。
  Future<void> openLocationSettings();
```

- [ ] **Step 2: `GeolocatorService` throw 型別化錯誤並實作三方法**

改寫 `lib/features/explore/data/services/geolocator_service.dart`：

```dart
import 'package:context_app/features/explore/domain/errors/location_error.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorService implements LocationService {
  @override
  Future<PlaceLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationError.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationError.permissionDenied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationError.permissionDeniedForever;
    }

    final position = await Geolocator.getCurrentPosition();
    return PlaceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
```

- [ ] **Step 3: 更新 `FakeLocationService`**

改寫 `test/fakes/fake_location_service.dart`：

```dart
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/services/location_service.dart';

/// Fake [LocationService] that returns a fixed location without touching GPS.
///
/// [error] 可注入任意物件（含 `LocationError`）讓 [getCurrentLocation] throw。
class FakeLocationService implements LocationService {
  final PlaceLocation location;
  final Object? error;

  /// [requestPermission] 的回傳值（模擬使用者是否在系統對話框授權）。
  final bool grantOnRequest;

  int requestPermissionCallCount = 0;
  int openAppSettingsCallCount = 0;
  int openLocationSettingsCallCount = 0;

  FakeLocationService({
    this.location = const PlaceLocation(latitude: 25.0, longitude: 121.0),
    this.error,
    this.grantOnRequest = true,
  });

  @override
  Future<PlaceLocation> getCurrentLocation() async {
    if (error != null) throw error!;
    return location;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCallCount += 1;
    return grantOnRequest;
  }

  @override
  Future<void> openAppSettings() async {
    openAppSettingsCallCount += 1;
  }

  @override
  Future<void> openLocationSettings() async {
    openLocationSettingsCallCount += 1;
  }
}
```

- [ ] **Step 4: analyze + 既有測試不回歸**

Run: `fvm flutter analyze --fatal-infos`
Expected: No issues found

Run: `fvm flutter test test/features/explore/presentation/screens/explore_screen_test.dart`
Expected: All tests pass（`error` 由 `Exception?` 改 `Object?` 對既有呼叫相容）

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/explore/domain/services/location_service.dart frontend/lib/features/explore/data/services/geolocator_service.dart frontend/test/fakes/fake_location_service.dart
git commit -m "feat(explore): LocationService 加引導動作、GeolocatorService throw LocationError

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: 用 agy 產出共用插圖

`agy` 是 Antigravity 的 agentic CLI（`/Users/paulwu/.local/bin/agy`）。以非互動單一 prompt 產一張插圖 PNG 存到 `frontend/assets/images/location_gate.png`。`assets/images/` 已在 `pubspec.yaml` 以目錄 glob 註冊，不需改 pubspec。

**Files:**
- Create: `frontend/assets/images/location_gate.png`（由 agy 產）

- [ ] **Step 1: 呼叫 agy 產圖**

在 repo 根目錄執行（timeout 拉長，agy 需跑 agentic loop）：

```bash
agy --dangerously-skip-permissions --prompt "請生成一張插圖並存成 PNG 檔到 frontend/assets/images/location_gate.png（覆蓋既有）。主題：地圖與定位（例如一張攤開的折疊地圖加上一個定位圖釘）。風格：暖色紙感、極簡、知性、手繪 field-journal 質感，構圖留白、置中。輸出淺色或透明底、去背，讓它能自然放在淺色與深色的卡片上都不突兀。尺寸約 800x600，不要有任何文字。"
```

- [ ] **Step 2: 驗證產出**

Run: `file frontend/assets/images/location_gate.png && ls -lh frontend/assets/images/location_gate.png`
Expected: 顯示為 PNG image data，檔案存在且大小合理（非 0 byte、非數 MB 巨檔）。

> 若 agy 未能產圖或產出不理想：停下來回報使用者，由使用者手動用 Antigravity 產一張放到同路徑後再繼續。此為 human-in-the-loop 檢核點。

- [ ] **Step 3: Commit**

```bash
git add frontend/assets/images/location_gate.png
git commit -m "assets(explore): 新增定位引導卡插圖

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: `_LocationGateCard` 浮層卡＋i18n＋接進 ExploreScreen

**Files:**
- Modify: `lib/features/explore/presentation/screens/explore_screen.dart`
- Modify: `assets/translations/zh-TW.json`
- Modify: `assets/translations/en.json`
- Modify: `test/features/explore/presentation/screens/explore_screen_test.dart`

**Interfaces:**
- Consumes: Task 1 `LocationError`；Task 2 的 `LocationService` 三方法與 `FakeLocationService` 計數；既有 `locationServiceProvider`、`placesControllerProvider`、`filteredPlacesProvider`、`LorescapeTokens`、`_kCardShadow`、`_RailNotice`。
- Produces: `_LocationGateCard`（`ConsumerWidget`，`final LocationError error`）；i18n key `explore.location_gate.<state>.{title,description,action}`，state ∈ {`service_disabled`,`permission_denied`,`permission_denied_forever`}。

- [ ] **Step 1: 加 i18n keys（zh-TW）**

`assets/translations/zh-TW.json` 的 `explore` 物件內，於 `"map"` 之後加入：

```json
    "location_gate": {
      "service_disabled": {
        "title": "定位服務已關閉",
        "description": "開啟裝置的定位服務，才能探索你身邊的故事。",
        "action": "開啟定位服務"
      },
      "permission_denied": {
        "title": "開啟定位以探索附近故事",
        "description": "Lorescape 需要你的位置，才能找出眼前值得一聽的景點。",
        "action": "允許定位"
      },
      "permission_denied_forever": {
        "title": "定位權限已關閉",
        "description": "定位權限已被永久關閉，請到系統設定手動開啟後再回來。",
        "action": "前往設定"
      }
    },
```

（注意：在 `"map": { ... }` 那個物件的右括號後補逗號，維持 JSON 合法。）

- [ ] **Step 2: 加 i18n keys（en）**

`assets/translations/en.json` 的 `explore` 物件內相同位置加入：

```json
    "location_gate": {
      "service_disabled": {
        "title": "Location services are off",
        "description": "Turn on your device's location services to explore the stories around you.",
        "action": "Open location settings"
      },
      "permission_denied": {
        "title": "Enable location to explore nearby stories",
        "description": "Lorescape needs your location to surface the places worth hearing about right in front of you.",
        "action": "Allow location"
      },
      "permission_denied_forever": {
        "title": "Location permission is off",
        "description": "Location permission is permanently denied. Open Settings to turn it back on, then return here.",
        "action": "Open settings"
      }
    },
```

- [ ] **Step 3: 驗證 JSON 合法**

Run: `cd frontend && python3 -c "import json; json.load(open('assets/translations/zh-TW.json')); json.load(open('assets/translations/en.json')); print('ok')"`
Expected: `ok`

- [ ] **Step 4: 寫失敗的 widget 測試**

在 `test/features/explore/presentation/screens/explore_screen_test.dart`：

(a) import 區加入：

```dart
import 'package:context_app/features/explore/domain/errors/location_error.dart';
```

(b) `_givenExploreScreen` 的簽章加一個可注入的 location service 參數。將

```dart
Future<void> _givenExploreScreen(
  WidgetTester tester, {
  List<Place> places = const [],
  FakePlacesRepository? repo,
  InMemorySavedLocationsRepository? savedRepo,
  double maxDistance = 10000.0,
  PlaceLocation? userLocation,
}) async {
  final fakeLocation = FakeLocationService(
    location: userLocation ?? const PlaceLocation(latitude: 25.0, longitude: 121.0),
  );
```

改為（新增 `FakeLocationService? locationService`，有傳就用它）：

```dart
Future<void> _givenExploreScreen(
  WidgetTester tester, {
  List<Place> places = const [],
  FakePlacesRepository? repo,
  InMemorySavedLocationsRepository? savedRepo,
  double maxDistance = 10000.0,
  PlaceLocation? userLocation,
  FakeLocationService? locationService,
}) async {
  final fakeLocation =
      locationService ??
      FakeLocationService(
        location:
            userLocation ?? const PlaceLocation(latitude: 25.0, longitude: 121.0),
      );
```

(c) 在 `group('ExploreScreen', ...)` 內新增一個子 group 與測試：

```dart
    group('location gate', () {
      testWidgets(
        'given permission is denied, when the screen loads, '
        'then the gate card shows the denied copy and the map cards rail is silent',
        (tester) async {
          await _givenExploreScreen(
            tester,
            locationService: FakeLocationService(
              error: LocationError.permissionDenied,
            ),
          );

          expect(
            find.text('explore.location_gate.permission_denied.title'),
            findsOneWidget,
          );
          // 底部卡片列不再吐原始錯誤字串。
          expect(find.textContaining('common.error_prefix'), findsNothing);
        },
      );

      testWidgets(
        'given permission is denied, when the action button is tapped and '
        'permission is granted, then requestPermission runs and places reload',
        (tester) async {
          final fake = FakeLocationService(
            error: LocationError.permissionDenied,
            grantOnRequest: true,
          );
          await _givenExploreScreen(tester, locationService: fake);

          await tester.tap(
            find.text('explore.location_gate.permission_denied.action'),
          );
          await tester.pump(const Duration(milliseconds: 20));
          await tester.pump(const Duration(milliseconds: 20));

          expect(fake.requestPermissionCallCount, 1);
        },
      );

      testWidgets(
        'given permission is denied forever, when the action button is tapped, '
        'then the app settings page is opened',
        (tester) async {
          final fake = FakeLocationService(
            error: LocationError.permissionDeniedForever,
          );
          await _givenExploreScreen(tester, locationService: fake);

          await tester.tap(
            find.text('explore.location_gate.permission_denied_forever.action'),
          );
          await tester.pump(const Duration(milliseconds: 20));

          expect(fake.openAppSettingsCallCount, 1);
        },
      );

      testWidgets(
        'given location services are disabled, when the action button is '
        'tapped, then the location settings page is opened',
        (tester) async {
          final fake = FakeLocationService(
            error: LocationError.serviceDisabled,
          );
          await _givenExploreScreen(tester, locationService: fake);

          await tester.tap(
            find.text('explore.location_gate.service_disabled.action'),
          );
          await tester.pump(const Duration(milliseconds: 20));

          expect(fake.openLocationSettingsCallCount, 1);
        },
      );

      testWidgets(
        'given a non-location error, when the screen loads, '
        'then no gate card is shown',
        (tester) async {
          await _givenExploreScreen(
            tester,
            locationService: FakeLocationService(error: Exception('boom')),
          );

          expect(
            find.text('explore.location_gate.permission_denied.title'),
            findsNothing,
          );
          expect(
            find.text('explore.location_gate.service_disabled.title'),
            findsNothing,
          );
        },
      );
    });
```

- [ ] **Step 5: 執行測試確認失敗**

Run: `fvm flutter test test/features/explore/presentation/screens/explore_screen_test.dart -k "location gate"`
Expected: FAIL（`_LocationGateCard` 尚未存在，gate 文案找不到）

- [ ] **Step 6: 在 ExploreScreen 疊入浮層卡**

`lib/features/explore/presentation/screens/explore_screen.dart`：

(a) 檔案頂部 import 區加入：

```dart
import 'package:context_app/features/explore/domain/errors/location_error.dart';
```

(b) 在 `build` 的 `Stack` children 內，`_MapCardsRail(...)` 之後、`Positioned(...SavedLocationsFab...)` 之前，插入置中浮層卡（僅定位錯誤時顯示）：

```dart
          // 型別化 object pattern：僅在 error 為 LocationError 時比對成功，
          // 並把 error 綁成 LocationError（`when ... is` guard 不會提升型別）。
          if (placesState case AsyncError(error: final LocationError error))
            Positioned.fill(
              child: Center(
                child: SingleChildScrollView(
                  child: _LocationGateCard(error: error),
                ),
              ),
            ),
```

(c) 修改 `_MapCardsRail` 的 error 分支：定位錯誤交給浮層卡，卡片列保持安靜。將

```dart
        error: (error, _) =>
            _RailNotice(text: '${'common.error_prefix'.tr()}: $error'),
```

改為

```dart
        error: (error, _) => error is LocationError
            ? const SizedBox.shrink()
            : _RailNotice(text: '${'common.error_prefix'.tr()}: $error'),
```

(d) 在檔案末端（例如 `_RailNotice` 類別之後）新增 `_LocationGateCard`：

```dart
/// 定位不可用時疊在地圖中央的引導卡：共用插圖＋依狀態的說明與按鈕。
class _LocationGateCard extends ConsumerWidget {
  const _LocationGateCard({required this.error});

  final LocationError error;

  /// i18n key 用的狀態名（對齊 assets/translations 的結構）。
  String get _stateKey => switch (error) {
    LocationError.serviceDisabled => 'service_disabled',
    LocationError.permissionDenied => 'permission_denied',
    LocationError.permissionDeniedForever => 'permission_denied_forever',
  };

  Future<void> _onAction(WidgetRef ref) async {
    final service = ref.read(locationServiceProvider);
    switch (error) {
      case LocationError.permissionDenied:
        final granted = await service.requestPermission();
        if (granted) {
          ref.read(placesControllerProvider.notifier).refresh();
        }
      case LocationError.permissionDeniedForever:
        await service.openAppSettings();
      case LocationError.serviceDisabled:
        await service.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final colorScheme = Theme.of(context).colorScheme;
    final base = 'explore.location_gate.$_stateKey';

    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: tokens?.paperRaised ?? colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens?.rLg ?? 16),
        border: Border.all(color: tokens?.line ?? colorScheme.outlineVariant),
        boxShadow: tokens?.e3 ?? _kCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 插圖載入失敗時退回一段留白，讓測試與缺圖情境都不會 crash。
          Image.asset(
            'assets/images/location_gate.png',
            width: 160,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(height: 120),
          ),
          const SizedBox(height: 20),
          Text(
            '$base.title'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            '$base.description'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _onAction(ref),
              child: Text('$base.action'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: 執行測試確認通過**

Run: `fvm flutter test test/features/explore/presentation/screens/explore_screen_test.dart`
Expected: 全部 PASS（含新 location gate group 與既有測試）

- [ ] **Step 8: analyze**

Run: `fvm flutter analyze --fatal-infos`
Expected: No issues found

- [ ] **Step 9: Commit**

```bash
git add frontend/lib/features/explore/presentation/screens/explore_screen.dart frontend/assets/translations/zh-TW.json frontend/assets/translations/en.json frontend/test/features/explore/presentation/screens/explore_screen_test.dart
git commit -m "feat(explore): 定位不可用時顯示浮層引導卡

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## 收尾驗證

- [ ] Run: `fvm flutter analyze --fatal-infos` → No issues found
- [ ] Run: `fvm flutter test` → 全綠
- [ ] 手動（可選）：實機／模擬器關閉定位權限，確認三種狀態各顯示正確文案與按鈕動作、插圖在淺／深色主題都自然。
