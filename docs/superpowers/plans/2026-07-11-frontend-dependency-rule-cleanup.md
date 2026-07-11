# Frontend 依賴規則還債 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 消除 frontend 全部 16 筆依賴規則違規（4 筆 data 跨引、11 筆 presentation 跨引、1 筆 app/utils），並建立守門測試防止回歸。

**Architecture:** 三種手法——(1) 守門測試：architecture test 掃描 import,用「已知違規允許清單」起步,每修一筆刪一筆;(2) re-export:被跨 feature 使用的 presentation 元件由該 feature 的 `providers.dart` 明文 `export`,消費端改 import `providers.dart`(公開介面);(3) 搬家:只有單一 feature 使用的檔案搬到使用者那邊(mapper → camera、Hive repos → sync、launcher → daily_story)。

**Tech Stack:** Flutter / Dart、flutter_test（architecture test 用 `dart:io` 掃檔）、fvm。

## Global Constraints

- 一律用 `fvm` 執行 flutter / dart 指令；工作目錄 `frontend/`。
- 每個 task 完成前必過：`fvm flutter test test/architecture/dependency_rules_test.dart` 與 `fvm flutter analyze --fatal-infos`（零問題）。
- 依賴規則（CLAUDE.md）：feature 之間只能跨引他 feature 的 `domain/` 與 `providers.dart`；data / presentation 不得跨 feature 引用；`app/` 僅得以 composition root 身分（router、shell）引用 features；`core/`、`shared/` 不依賴 `features/`。
- package 名為 `context_app`（import 皆為 `package:context_app/...`）。
- commit 訊息遵循現有 conventional commits 風格（`refactor(frontend): ...`、`test(frontend): ...`）。

**Task 依賴關係：** Task 1（守門測試）建議最先做——之後每個 task 都有「從允許清單移除已修項目」步驟。Task 2–9 彼此獨立、可任意順序。Task 10 最後。若在 Task 1 之前執行其他 task，跳過允許清單步驟即可。

---

### Task 1: 依賴規則守門測試

**Files:**
- Create: `frontend/test/architecture/dependency_rules_test.dart`

**Interfaces:**
- Consumes: 無（獨立新測試）。
- Produces: `_pendingCrossFeature`（`Set<String>`，「來源檔 -> import 目標」格式的已知違規清單）與 `_pendingAppFiles`（`Set<String>`，app/ 整檔豁免清單）。Task 2–9 每修一筆違規，就從對應集合刪除該字串。

- [ ] **Step 1: 寫守門測試（含現況 16 筆違規的允許清單）**

建立 `frontend/test/architecture/dependency_rules_test.dart`：

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md「依賴規則」的守門測試。
///
/// 規則：
/// 1. feature 之間只能跨引他 feature 的 `domain/` 與 `providers.dart`
///    （providers.dart 得 re-export 精選元件作為公開介面）。
/// 2. `app/` 僅得以 composition root 身分（router、shell）引用 features。
/// 3. `core/`、`shared/` 不得引用 features。
///
/// `_pendingCrossFeature` / `_pendingAppFiles` 是已知技術債的暫時允許
/// 清單，還債任務逐條移除；新增違規會讓本測試立即失敗。

final RegExp _featureImportRe = RegExp(
  "import 'package:context_app/(features/[^']+)'",
);

/// 已知跨 feature 違規：「來源檔 -> import 目標」。修一筆刪一筆，不得新增。
const Set<String> _pendingCrossFeature = {
  // data 層跨引
  'lib/features/camera/data/image_analysis_service.dart -> features/explore/data/mappers/place_category_mapper.dart',
  'lib/features/sync/providers.dart -> features/journey/data/hive_journey_repository.dart',
  'lib/features/sync/providers.dart -> features/saved_locations/data/hive_saved_locations_repository.dart',
  'lib/features/sync/providers.dart -> features/trip/data/hive_trip_repository.dart',
  // presentation 層跨引
  'lib/features/analytics/presentation/narration_analytics_observer.dart -> features/narration/presentation/controllers/narration_state.dart',
  'lib/features/camera/presentation/widgets/analysis_result_card.dart -> features/explore/presentation/extensions/place_category_extension.dart',
  'lib/features/explore/presentation/screens/explore_screen.dart -> features/saved_locations/presentation/widgets/saved_locations_fab.dart',
  'lib/features/journey/presentation/screens/journey_screen.dart -> features/trip/presentation/widgets/trip_grid.dart',
  'lib/features/journey/presentation/widgets/timeline_entry.dart -> features/trip/presentation/widgets/move_to_trip_sheet.dart',
  'lib/features/narration/presentation/screens/select_story_hook_screen.dart -> features/explore/presentation/extensions/place_category_extension.dart',
  'lib/features/narration/presentation/widgets/editorial_hero.dart -> features/explore/presentation/extensions/place_category_extension.dart',
  'lib/features/saved_locations/presentation/widgets/saved_locations_sheet.dart -> features/explore/presentation/extensions/place_category_extension.dart',
  'lib/features/trip/presentation/screens/trip_detail_screen.dart -> features/export/presentation/default_pdf_export_pipeline.dart',
  'lib/features/trip/presentation/screens/trip_detail_screen.dart -> features/export/presentation/pdf_builder/trip_pdf_document_builder.dart',
  'lib/features/trip/presentation/screens/trip_detail_screen.dart -> features/journey/presentation/widgets/timeline_entry.dart',
};

/// app/ 中已知違規檔案（整檔豁免）。修復後清空。
const Set<String> _pendingAppFiles = {
  'lib/app/utils/daily_story_config_launcher.dart',
};

/// app/ 中允許引用 features 的 composition root（檔案或目錄前綴）。
const List<String> _appCompositionRoots = [
  'lib/app/config/router_config.dart',
  'lib/app/shell/',
];

Iterable<File> _dartFiles(String root) sync* {
  final dir = Directory(root);
  if (!dir.existsSync()) return;
  yield* dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
}

String _posix(String path) => path.replaceAll(r'\', '/');

List<String> _featureImports(File file) => _featureImportRe
    .allMatches(file.readAsStringSync())
    .map((m) => m.group(1)!)
    .toList();

void main() {
  test('feature 之間只能跨引 domain 與 providers.dart', () {
    final violations = <String>[];
    final stillPending = <String>{};
    for (final file in _dartFiles('lib/features')) {
      final path = _posix(file.path);
      final feature = path.split('/')[2];
      for (final target in _featureImports(file)) {
        final segments = target.split('/');
        final targetFeature = segments[1];
        if (targetFeature == feature) continue;
        final rest = segments.sublist(2).join('/');
        final legal = rest == 'providers.dart' || rest.startsWith('domain/');
        if (legal) continue;
        final key = '$path -> $target';
        if (_pendingCrossFeature.contains(key)) {
          stillPending.add(key);
        } else {
          violations.add(key);
        }
      }
    }
    expect(violations, isEmpty, reason: '出現允許清單外的跨 feature 引用');
    expect(
      _pendingCrossFeature.difference(stillPending),
      isEmpty,
      reason: '允許清單中有已修復項目，請自 _pendingCrossFeature 移除',
    );
  });

  test('app/ 僅 composition root 可引用 features', () {
    final violations = <String>[];
    for (final file in _dartFiles('lib/app')) {
      final path = _posix(file.path);
      if (_appCompositionRoots.any(path.startsWith)) continue;
      if (_pendingAppFiles.contains(path)) continue;
      for (final target in _featureImports(file)) {
        violations.add('$path -> $target');
      }
    }
    expect(violations, isEmpty, reason: 'app/ 非 composition root 引用 features');
  });

  test('core/ 與 shared/ 不得引用 features', () {
    final violations = <String>[];
    for (final file in [
      ..._dartFiles('lib/core'),
      ..._dartFiles('lib/shared'),
    ]) {
      final path = _posix(file.path);
      for (final target in _featureImports(file)) {
        violations.add('$path -> $target');
      }
    }
    expect(violations, isEmpty, reason: 'core/ 或 shared/ 引用 features');
  });
}
```

- [ ] **Step 2: 跑測試確認全綠（允許清單涵蓋現況）**

Run: `cd frontend && fvm flutter test test/architecture/dependency_rules_test.dart`
Expected: 3 tests PASS。若第 1 個測試因「允許清單中有已修復項目」失敗，代表清單某筆與現況 import 字串不一致——用失敗訊息比對後修正清單字串。

- [ ] **Step 3: 負向驗證（確認測試真的會抓violations）**

暫時從 `_pendingCrossFeature` 刪除第一筆（camera mapper 那行）→ 重跑同指令 → Expected: FAIL，訊息含 `lib/features/camera/data/image_analysis_service.dart -> features/explore/data/mappers/place_category_mapper.dart`。驗證後**還原該行**，重跑確認 PASS。

- [ ] **Step 4: analyze**

Run: `cd frontend && fvm flutter analyze --fatal-infos`
Expected: No issues found。

- [ ] **Step 5: Commit**

```bash
git add frontend/test/architecture/dependency_rules_test.dart
git commit -m "test(frontend): 依賴規則守門測試——16 筆已知違規入允許清單，修一筆刪一筆"
```

---

### Task 2: 刪除 camera feature（死功能；消 2 筆違規）

背景：`/camera` route 存在但**全 repo 無任何導航入口**（無 `context.go('/camera')` / `pushNamed('camera')`），無其他 feature 依賴 camera，BACKLOG 無相關項目。經使用者確認整包刪除。`image_picker` 套件與 `core/services/image_picker_service.dart` 只有 camera 使用，一併刪除；`explore/data/mappers/place_category_mapper.dart` 唯一使用者是 camera，一併刪除。

**Files:**
- Delete: `frontend/lib/features/camera/`（整個目錄，8 檔）
- Delete: `frontend/lib/core/services/image_picker_service.dart`（含 `PickedImage`，僅 camera 與其 fakes 使用）
- Delete: `frontend/lib/features/explore/data/mappers/place_category_mapper.dart`（唯一使用者是 camera）
- Delete: `frontend/test/features/camera/`（整個目錄）
- Delete: `frontend/test/fakes/fake_image_picker_service.dart`、`frontend/test/fakes/fake_image_analysis_service.dart`
- Delete: `frontend/assets/images/camera/`（`camera_icon.png`，僅 camera_screen 使用）
- Modify: `frontend/lib/app/config/router_config.dart`（import 第 11 行、`/camera` GoRoute 第 141–145 行、第 32 行註解）
- Modify: `frontend/test/app/shell/main_screen_test.dart`（camera 相關 import 與第 136 行 override）
- Modify: `frontend/test/integration/permission_denial_flow_test.dart`（刪「Camera permission denied」group 第 68 行起與 camera 相關 import）
- Modify: `frontend/pubspec.yaml`（刪 `image_picker: ^1.2.1` 第 52 行、`- assets/images/camera/` 第 140 行）
- Modify: `frontend/ios/Runner/Info.plist`（刪 `NSCameraUsageDescription` 第 56–57 行與 `NSPhotoLibraryUsageDescription` 第 62–63 行——兩者文案皆為「拍照/相片庫分析地點」，只服務 image_picker；`share_plus` 分享不需相片庫權限）
- Modify: `frontend/test/architecture/dependency_rules_test.dart`（刪允許清單 2 筆 camera 項目）

**Interfaces:**
- Consumes: 無。
- Produces: 無（純刪除）。後續 Task 3 的消費端因此少了 `analysis_result_card.dart`。

- [ ] **Step 1: 刪除檔案與目錄**

```bash
cd frontend
git rm -r lib/features/camera test/features/camera
git rm lib/core/services/image_picker_service.dart
git rm lib/features/explore/data/mappers/place_category_mapper.dart
git rm test/fakes/fake_image_picker_service.dart test/fakes/fake_image_analysis_service.dart
git rm -r assets/images/camera
```

- [ ] **Step 2: 移除 router 的 /camera route**

`lib/app/config/router_config.dart`：

1. 刪第 11 行 `import 'package:context_app/features/camera/presentation/screens/camera_screen.dart';`
2. 刪 `/camera` GoRoute（原第 141–145 行）：

```dart
        GoRoute(
          path: '/camera',
          name: 'camera',
          builder: (context, state) => const CameraScreen(),
        ),
```

3. 第 32 行註解 `// (deep links via '/player', '/camera', etc.) are left untouched` 改為 `// (deep links via '/player', etc.) are left untouched`。

- [ ] **Step 3: 修兩個測試檔**

1. `test/app/shell/main_screen_test.dart`：刪 `import 'package:context_app/features/camera/providers.dart';`（第 5 行）、fake_image_analysis / fake_image_picker 相關 import，與第 136 行 override：

```dart
    imageAnalysisServiceProvider.overrideWithValue(FakeImageAnalysisService()),
```

（若還有其他 camera 相關 override / 引用，一併刪除。）

2. `test/integration/permission_denial_flow_test.dart`：刪整個 `group('Camera permission denied', ...)`（第 68 行起）與檔頭 camera / fake_image_picker 相關 import；保留 `group('Location permission denied', ...)`。

- [ ] **Step 4: pubspec 與 iOS 權限字串**

1. `pubspec.yaml`：刪 `  image_picker: ^1.2.1`（第 52 行）與 `    - assets/images/camera/`（第 140 行）。
2. `ios/Runner/Info.plist`：刪這四行（第 56–57、62–63 行）：

```xml
	<key>NSCameraUsageDescription</key>
	<string>Lorescape 需要使用相機拍攝照片，以分析地點提供導覽。</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Lorescape 需要存取您的相片庫，以分析地點提供導覽。</string>
```

3. Run: `fvm flutter pub get`
Expected: 成功，lockfile 移除 image_picker 相關套件。

- [ ] **Step 5: 從允許清單移除 2 筆 camera 項目**

刪除 `test/architecture/dependency_rules_test.dart` 中 `_pendingCrossFeature` 的這兩行：

```dart
  'lib/features/camera/data/image_analysis_service.dart -> features/explore/data/mappers/place_category_mapper.dart',
  'lib/features/camera/presentation/widgets/analysis_result_card.dart -> features/explore/presentation/extensions/place_category_extension.dart',
```

- [ ] **Step 6: 殘留掃描**

```bash
grep -rn -i "camera\|image_picker\|ImageAnalysis\|PickedImage" lib test pubspec.yaml | grep -v -i "cached_network_image"
```

Expected: 無輸出（或僅明顯無關的字串命中；有殘留就清掉）。

- [ ] **Step 7: 驗證**

Run: `cd frontend && fvm flutter test test/architecture/dependency_rules_test.dart && fvm flutter test test/app test/integration test/features/explore && fvm flutter analyze --fatal-infos`
Expected: 全 PASS、No issues found。

- [ ] **Step 8: Commit**

```bash
git add -A frontend
git commit -m "refactor(frontend): 移除死功能 camera——無導航入口，連同 image_picker、權限字串與專屬測試"
```

---

### Task 3: place_category_extension 經 explore/providers.dart re-export（3 筆 presentation 違規）

（原本有 4 個消費端；camera 的 `analysis_result_card.dart` 已在 Task 2 隨 feature 刪除。若 Task 2 尚未執行，camera 那筆留在允許清單即可，本 task 不處理。）

**Files:**
- Modify: `frontend/lib/features/explore/providers.dart`（加 export）
- Modify: `frontend/lib/features/narration/presentation/screens/select_story_hook_screen.dart:5`
- Modify: `frontend/lib/features/narration/presentation/widgets/editorial_hero.dart:7`
- Modify: `frontend/lib/features/saved_locations/presentation/widgets/saved_locations_sheet.dart:4`
- Modify: `frontend/test/architecture/dependency_rules_test.dart`（刪允許清單 3 筆）

**Interfaces:**
- Consumes: `extension PlaceCategoryUIExtension on PlaceCategory { JournalCategory get journalCategory }`（位於 `explore/presentation/extensions/place_category_extension.dart`，檔案不搬）。
- Produces: 消費端一律改 import `package:context_app/features/explore/providers.dart` 取得該 extension。

- [ ] **Step 1: explore/providers.dart 加 export**

在 `lib/features/explore/providers.dart` 的 import 區塊之後（第 15 行空行處）加入：

```dart
// Feature 公開介面：providers.dart 得 re-export 精選元件供他 feature 使用。
export 'presentation/extensions/place_category_extension.dart';
```

- [ ] **Step 2: 換掉 3 個消費端的 import**

以下 3 檔，把

```dart
import 'package:context_app/features/explore/presentation/extensions/place_category_extension.dart';
```

改為

```dart
import 'package:context_app/features/explore/providers.dart';
```

（依字母序放進 import 區塊；3 檔目前皆未 import explore/providers.dart，不會重複）：

1. `lib/features/narration/presentation/screens/select_story_hook_screen.dart`（原第 5 行）
2. `lib/features/narration/presentation/widgets/editorial_hero.dart`（原第 7 行）
3. `lib/features/saved_locations/presentation/widgets/saved_locations_sheet.dart`（原第 4 行）

注意：`lib/features/explore/presentation/screens/explore_screen.dart:4` 也 import 此 extension，但屬同 feature 內部引用，**不改**。

- [ ] **Step 3: 從允許清單移除 3 筆**

刪除 `_pendingCrossFeature` 中含 `place_category_extension.dart` 的 3 行（narration×2、saved_locations；camera 那行由 Task 2 處理）。

- [ ] **Step 4: 驗證**

Run: `cd frontend && fvm flutter test test/architecture/dependency_rules_test.dart && fvm flutter test test/features/narration test/features/saved_locations && fvm flutter analyze --fatal-infos`
Expected: 全 PASS、No issues found。

- [ ] **Step 5: Commit**

```bash
git add frontend/lib frontend/test/architecture
git commit -m "refactor(frontend): place_category_extension 改經 explore/providers.dart 公開介面引用"
```

---

### Task 4: narration_state 經 narration/providers.dart re-export（1 筆）

**Files:**
- Modify: `frontend/lib/features/narration/providers.dart`（加 export）
- Modify: `frontend/lib/features/analytics/presentation/narration_analytics_observer.dart:9`（刪 import）
- Modify: `frontend/test/architecture/dependency_rules_test.dart`（刪允許清單 1 筆）

**Interfaces:**
- Consumes: `narration/presentation/controllers/narration_state.dart` 的 player 狀態型別（analytics observer 用來翻譯狀態轉移為事件）。
- Produces: analytics 僅透過已存在的 `import 'package:context_app/features/narration/providers.dart';`（observer 第 10 行）取得這些型別。

- [ ] **Step 1: narration/providers.dart 加 export**

在 import 區塊後加入：

```dart
// Feature 公開介面：narration player 狀態型別供 analytics observer 使用。
export 'presentation/controllers/narration_state.dart';
```

- [ ] **Step 2: 刪 analytics observer 的 presentation import**

刪除 `lib/features/analytics/presentation/narration_analytics_observer.dart` 第 9 行：

```dart
import 'package:context_app/features/narration/presentation/controllers/narration_state.dart';
```

（該檔第 10 行已有 `import 'package:context_app/features/narration/providers.dart';`，型別經 re-export 仍可解析。）

- [ ] **Step 3: 從允許清單移除 1 筆**

刪除 `_pendingCrossFeature` 中 `narration_analytics_observer.dart -> ...narration_state.dart` 那行。

- [ ] **Step 4: 驗證**

Run: `cd frontend && fvm flutter test test/architecture/dependency_rules_test.dart && fvm flutter test test/features/analytics && fvm flutter analyze --fatal-infos`
Expected: 全 PASS、No issues found。

- [ ] **Step 5: Commit**

```bash
git add frontend/lib frontend/test/architecture
git commit -m "refactor(frontend): narration_state 改經 narration/providers.dart 公開介面引用"
```

---

### Task 5: SavedLocationsFab 經 saved_locations/providers.dart re-export（1 筆）

**Files:**
- Modify: `frontend/lib/features/saved_locations/providers.dart`（加 export）
- Modify: `frontend/lib/features/explore/presentation/screens/explore_screen.dart:6`（刪 import）
- Modify: `frontend/test/architecture/dependency_rules_test.dart`（刪允許清單 1 筆）

**Interfaces:**
- Consumes: `class SavedLocationsFab extends ConsumerWidget`（explore_screen 第 80 行 `floatingActionButton: const SavedLocationsFab()`）。
- Produces: explore_screen 僅透過已存在的 `import 'package:context_app/features/saved_locations/providers.dart';`（第 7 行）取得該 widget。

- [ ] **Step 1: saved_locations/providers.dart 加 export**

在 import 區塊後加入：

```dart
// Feature 公開介面：儲存地點 FAB 供 explore 頁面掛載。
export 'presentation/widgets/saved_locations_fab.dart';
```

- [ ] **Step 2: 刪 explore_screen 的 presentation import**

刪除 `lib/features/explore/presentation/screens/explore_screen.dart` 第 6 行：

```dart
import 'package:context_app/features/saved_locations/presentation/widgets/saved_locations_fab.dart';
```

- [ ] **Step 3: 從允許清單移除 1 筆**

刪除 `_pendingCrossFeature` 中 `explore_screen.dart -> ...saved_locations_fab.dart` 那行。

- [ ] **Step 4: 驗證**

Run: `cd frontend && fvm flutter test test/architecture/dependency_rules_test.dart && fvm flutter test test/features/explore && fvm flutter analyze --fatal-infos`
Expected: 全 PASS、No issues found。

- [ ] **Step 5: Commit**

```bash
git add frontend/lib frontend/test/architecture
git commit -m "refactor(frontend): SavedLocationsFab 改經 saved_locations/providers.dart 公開介面引用"
```

---

### Task 6: PDF export pipeline 經 export/providers.dart re-export（2 筆）

**Files:**
- Modify: `frontend/lib/features/export/providers.dart`（整檔改寫）
- Modify: `frontend/lib/features/trip/presentation/screens/trip_detail_screen.dart:1,4`
- Modify: `frontend/test/architecture/dependency_rules_test.dart`（刪允許清單 2 筆）

**Interfaces:**
- Consumes: `Future<PdfExportResult> exportTripAsPdf({required WidgetRef ref, required BuildContext context, required String tripId, required TripPdfExportStrings strings})`（`export/presentation/default_pdf_export_pipeline.dart`）與 `class PdfLabels`（`export/presentation/pdf_builder/trip_pdf_document_builder.dart`，trip_detail_screen 第 411 行使用）。
- Produces: trip 僅 import `package:context_app/features/export/providers.dart`。現有 `exportFeaturePlaceholderProvider` 全 repo 無人使用，一併移除。

- [ ] **Step 1: 改寫 export/providers.dart**

整檔取代為：

```dart
/// Trip PDF export feature 的公開介面。
///
/// 依 CLAUDE.md 依賴規則，其他 feature 一律經由本檔引用 export 功能。
export 'presentation/default_pdf_export_pipeline.dart';
export 'presentation/pdf_builder/trip_pdf_document_builder.dart';
```

（原 `exportFeaturePlaceholderProvider` 為佔位符、無人引用，刪除；`flutter_riverpod` import 隨之移除。）

- [ ] **Step 2: 換 trip_detail_screen 的 import**

`lib/features/trip/presentation/screens/trip_detail_screen.dart`：

```dart
// 刪除第 1 行：
import 'package:context_app/features/export/presentation/default_pdf_export_pipeline.dart';
// 刪除第 4 行：
import 'package:context_app/features/export/presentation/pdf_builder/trip_pdf_document_builder.dart';
// 加入（依字母序）：
import 'package:context_app/features/export/providers.dart';
```

- [ ] **Step 3: 從允許清單移除 2 筆**

刪除 `_pendingCrossFeature` 中 `trip_detail_screen.dart -> features/export/...` 的 2 行。

- [ ] **Step 4: 驗證**

Run: `cd frontend && fvm flutter test test/architecture/dependency_rules_test.dart && fvm flutter test test/features/trip test/features/export && fvm flutter analyze --fatal-infos`
Expected: 全 PASS、No issues found。

- [ ] **Step 5: Commit**

```bash
git add frontend/lib frontend/test/architecture
git commit -m "refactor(frontend): PDF export pipeline 改經 export/providers.dart 公開介面引用"
```

---

### Task 7: journey ↔ trip 互用 widget 經雙方 providers.dart re-export（3 筆）

**Files:**
- Modify: `frontend/lib/features/trip/providers.dart`（加 2 個 export）
- Modify: `frontend/lib/features/journey/providers.dart`（加 1 個 export）
- Modify: `frontend/lib/features/journey/presentation/screens/journey_screen.dart:4`（刪 import）
- Modify: `frontend/lib/features/journey/presentation/widgets/timeline_entry.dart:18`（換 import）
- Modify: `frontend/lib/features/trip/presentation/screens/trip_detail_screen.dart:6`（刪 import）
- Modify: `frontend/test/architecture/dependency_rules_test.dart`（刪允許清單 3 筆）

**Interfaces:**
- Consumes: `class TripGrid`（journey_screen 第 355 行）、`Future<...> showMoveToTripSheet({required BuildContext context, String? currentTripId})`（timeline_entry 第 65 行）、`class TimelineEntry`（trip_detail_screen 第 453、504 行）。
- Produces: journey_screen 經既有 `import .../trip/providers.dart`（第 5 行）取得 `TripGrid`；timeline_entry 新增 `import .../trip/providers.dart` 取得 `showMoveToTripSheet`；trip_detail_screen 經既有 `import .../journey/providers.dart`（第 7 行）取得 `TimelineEntry`。

- [ ] **Step 1: trip/providers.dart 加 export**

在 import 區塊後加入：

```dart
// Feature 公開介面：journey 頁面重用的 trip widgets。
export 'presentation/widgets/move_to_trip_sheet.dart';
export 'presentation/widgets/trip_grid.dart';
```

- [ ] **Step 2: journey/providers.dart 加 export**

在 import 區塊後加入：

```dart
// Feature 公開介面：trip 詳情頁重用的時間軸元件。
export 'presentation/widgets/timeline_entry.dart';
```

- [ ] **Step 3: 修 3 個消費端 import**

1. `lib/features/journey/presentation/screens/journey_screen.dart`：刪第 4 行 `import 'package:context_app/features/trip/presentation/widgets/trip_grid.dart';`（第 5 行已 import trip/providers.dart）。
2. `lib/features/journey/presentation/widgets/timeline_entry.dart`：第 18 行 `import 'package:context_app/features/trip/presentation/widgets/move_to_trip_sheet.dart';` 改為 `import 'package:context_app/features/trip/providers.dart';`（依字母序擺放）。
3. `lib/features/trip/presentation/screens/trip_detail_screen.dart`：刪第 6 行 `import 'package:context_app/features/journey/presentation/widgets/timeline_entry.dart';`（第 7 行已 import journey/providers.dart）。

注意：`journey/providers.dart` export 的 `timeline_entry.dart` 自身 import `journey/providers.dart`（第 13 行）——Dart 允許 library 迴圈引用，barrel 檔常見模式，analyzer 不會報錯。`trip/providers.dart` 與 `move_to_trip_sheet.dart` 同理。

- [ ] **Step 4: 從允許清單移除 3 筆**

刪除 `_pendingCrossFeature` 中 `journey_screen.dart -> ...trip_grid.dart`、`timeline_entry.dart -> ...move_to_trip_sheet.dart`、`trip_detail_screen.dart -> ...timeline_entry.dart` 3 行。

- [ ] **Step 5: 驗證**

Run: `cd frontend && fvm flutter test test/architecture/dependency_rules_test.dart && fvm flutter test test/features/journey test/features/trip && fvm flutter analyze --fatal-infos`
Expected: 全 PASS、No issues found。

- [ ] **Step 6: Commit**

```bash
git add frontend/lib frontend/test/architecture
git commit -m "refactor(frontend): journey/trip 互用 widget 改經雙方 providers.dart 公開介面引用"
```

---

### Task 8: Hive repositories 搬到 sync/data（3 筆 data 違規）

**Files:**
- Move: `frontend/lib/features/journey/data/hive_journey_repository.dart` → `frontend/lib/features/sync/data/hive_journey_repository.dart`
- Move: `frontend/lib/features/trip/data/hive_trip_repository.dart` → `frontend/lib/features/sync/data/hive_trip_repository.dart`
- Move: `frontend/lib/features/saved_locations/data/hive_saved_locations_repository.dart` → `frontend/lib/features/sync/data/hive_saved_locations_repository.dart`
- Move: `frontend/test/features/journey/data/hive_journey_repository_test.dart` → `frontend/test/features/sync/data/hive_journey_repository_test.dart`
- Move: `frontend/test/features/trip/data/hive_trip_repository_test.dart` → `frontend/test/features/sync/data/hive_trip_repository_test.dart`
- Move: `frontend/test/features/saved_locations/data/hive_saved_locations_repository_test.dart` → `frontend/test/features/sync/data/hive_saved_locations_repository_test.dart`
- Modify: `frontend/lib/features/sync/providers.dart:2,5,19`（import 路徑）
- Modify: `frontend/test/architecture/dependency_rules_test.dart`（刪允許清單 3 筆）

**Interfaces:**
- Consumes: `HiveJourneyRepository` / `HiveTripRepository` / `HiveSavedLocationsRepository`——lib 內全 repo 只有 `sync/providers.dart` 建構它們（`local*RepositoryProvider`，介面型別 `JourneyRepository` / `TripRepository` / `SavedLocationsRepository` 不變）。
- Produces: 同名 class 搬到 `sync/data/`。各檔內部對自家 domain 介面的 import（`features/journey/domain/...` 等）不需改——搬到 sync 後成為「sync 跨引他 feature domain」，合法。

理由：local 持久化是 sync 離線架構（local + remote + syncing decorator）的一環，建構與組裝都在 sync；搬過去消除違規，也避免改成 providers 互引造成 library 迴圈。

- [ ] **Step 1: git mv 六個檔案**

```bash
cd frontend
mkdir -p test/features/sync/data
git mv lib/features/journey/data/hive_journey_repository.dart lib/features/sync/data/hive_journey_repository.dart
git mv lib/features/trip/data/hive_trip_repository.dart lib/features/sync/data/hive_trip_repository.dart
git mv lib/features/saved_locations/data/hive_saved_locations_repository.dart lib/features/sync/data/hive_saved_locations_repository.dart
git mv test/features/journey/data/hive_journey_repository_test.dart test/features/sync/data/hive_journey_repository_test.dart
git mv test/features/trip/data/hive_trip_repository_test.dart test/features/sync/data/hive_trip_repository_test.dart
git mv test/features/saved_locations/data/hive_saved_locations_repository_test.dart test/features/sync/data/hive_saved_locations_repository_test.dart
```

- [ ] **Step 2: 更新 sync/providers.dart 的 3 個 import**

```dart
// 原（第 2、5、19 行）：
import 'package:context_app/features/journey/data/hive_journey_repository.dart';
import 'package:context_app/features/saved_locations/data/hive_saved_locations_repository.dart';
import 'package:context_app/features/trip/data/hive_trip_repository.dart';
// 改為：
import 'package:context_app/features/sync/data/hive_journey_repository.dart';
import 'package:context_app/features/sync/data/hive_saved_locations_repository.dart';
import 'package:context_app/features/sync/data/hive_trip_repository.dart';
```

（依字母序調整位置。）

- [ ] **Step 3: 更新 3 個測試檔的 import**

3 個搬過去的測試檔中，把 `import 'package:context_app/features/<原feature>/data/hive_*_repository.dart';` 改為 `import 'package:context_app/features/sync/data/hive_*_repository.dart';`。用 grep 確認無漏網：

```bash
grep -rn "features/journey/data/hive\|features/trip/data/hive\|features/saved_locations/data/hive" lib test
```

Expected: 無輸出。

- [ ] **Step 4: 從允許清單移除 3 筆**

刪除 `_pendingCrossFeature` 中 `sync/providers.dart -> ...` 的 3 行（data 層跨引段落清空，連同該段註解一併刪除）。

- [ ] **Step 5: 驗證**

Run: `cd frontend && fvm flutter test test/architecture/dependency_rules_test.dart && fvm flutter test test/features/sync && fvm flutter analyze --fatal-infos`
Expected: 全 PASS、No issues found。

- [ ] **Step 6: Commit**

```bash
git add -A frontend/lib frontend/test
git commit -m "refactor(frontend): Hive repositories 搬到 sync/data——local 持久化歸 sync 架構所有"
```

---

### Task 9: daily_story_config_launcher 搬回 daily_story（app/ 違規清零）

**Files:**
- Move: `frontend/lib/app/utils/daily_story_config_launcher.dart` → `frontend/lib/features/daily_story/presentation/utils/daily_story_config_launcher.dart`
- Move: `frontend/test/app/utils/daily_story_config_launcher_test.dart` → `frontend/test/features/daily_story/presentation/utils/daily_story_config_launcher_test.dart`
- Modify: `frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart`（import 路徑）
- Modify: `frontend/test/architecture/dependency_rules_test.dart`（`_pendingAppFiles` 清空）

**Interfaces:**
- Consumes: `Place? placeFromDailyStory(DailyStory story)` 與 `void launchSamePlaceStories(BuildContext context, DailyStory story)`——全 repo 只有 `daily_story_detail_screen.dart` 使用。
- Produces: 同兩個 top-level function，搬到 daily_story feature 內。檔內 import 的 explore domain models（Place 等）從 daily_story 跨引屬合法。

- [ ] **Step 1: git mv 兩個檔案**

```bash
cd frontend
mkdir -p lib/features/daily_story/presentation/utils test/features/daily_story/presentation/utils
git mv lib/app/utils/daily_story_config_launcher.dart lib/features/daily_story/presentation/utils/daily_story_config_launcher.dart
git mv test/app/utils/daily_story_config_launcher_test.dart test/features/daily_story/presentation/utils/daily_story_config_launcher_test.dart
```

- [ ] **Step 2: 更新過時的檔內註解**

`daily_story_config_launcher.dart` doc comment 中這兩句已不符現行規則：

```dart
/// Lives in `app/` because it bridges two features (daily_story → explore);
/// features must not depend on each other directly.
```

改為：

```dart
/// Bridges daily_story → explore by building a [Place] from a [DailyStory];
/// cross-feature domain imports are allowed by the dependency rules.
```

- [ ] **Step 3: 更新兩處 import**

1. `lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart`：`import 'package:context_app/app/utils/daily_story_config_launcher.dart';` 改為 `import 'package:context_app/features/daily_story/presentation/utils/daily_story_config_launcher.dart';`。
2. 搬過去的測試檔內同樣路徑替換。

```bash
grep -rn "app/utils/daily_story_config_launcher" lib test
```

Expected: 無輸出。

- [ ] **Step 4: 清空 _pendingAppFiles**

`test/architecture/dependency_rules_test.dart`：

```dart
/// app/ 中已知違規檔案（整檔豁免）。修復後清空。
const Set<String> _pendingAppFiles = {};
```

- [ ] **Step 5: 驗證**

Run: `cd frontend && fvm flutter test test/architecture/dependency_rules_test.dart && fvm flutter test test/features/daily_story && fvm flutter analyze --fatal-infos`
Expected: 全 PASS、No issues found。

- [ ] **Step 6: Commit**

```bash
git add -A frontend/lib frontend/test
git commit -m "refactor(frontend): daily_story_config_launcher 搬回 daily_story——新依賴規則下不需 app/ 中介"
```

---

### Task 10: 收尾——全量驗證與 CLAUDE.md 慣例補充

**Files:**
- Modify: `CLAUDE.md`（依賴規則 bullet 補 re-export 慣例與守門測試位置）
- 驗證: 全 test suite

**Interfaces:**
- Consumes: Task 1–9 完成後，`_pendingCrossFeature` 與 `_pendingAppFiles` 皆為空集合。
- Produces: 文件化的 re-export 慣例。

- [ ] **Step 1: 確認允許清單歸零**

檢視 `test/architecture/dependency_rules_test.dart`：`_pendingCrossFeature` 與 `_pendingAppFiles` 都應是空集合（若尚有殘留，代表對應 task 未完成——先回去完成）。順手把兩個集合的 doc comment 更新為「已清零；不得新增」。

- [ ] **Step 2: 全量測試**

Run: `cd frontend && fvm flutter test && fvm flutter analyze --fatal-infos`
Expected: 全 PASS、No issues found。

- [ ] **Step 3: CLAUDE.md 補慣例**

`CLAUDE.md` Frontend 段的依賴規則 bullet，於「data / presentation 不得跨 feature 引用。」之後補一句：

```
  被跨 feature 重用的元件由該 feature 的 providers.dart 明文 re-export；
  守門測試在 frontend/test/architecture/dependency_rules_test.dart。
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md frontend/test/architecture
git commit -m "docs(claude): 依賴規則補 providers.dart re-export 慣例與守門測試位置"
```
