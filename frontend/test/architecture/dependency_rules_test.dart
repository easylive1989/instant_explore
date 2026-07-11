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
const Set<String> _pendingCrossFeature = {};

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
