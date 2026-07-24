import 'dart:async';

import 'package:context_app/features/explore/presentation/widgets/lorescape_map.dart';
import 'package:context_app/features/explore/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../../../helpers/fake_map_style.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUp(() async {
    await initTestEnvironment();
  });

  testWidgets(
    'given the map style is still loading, '
    'when the map is shown, '
    'then no map is rendered yet and no error is surfaced',
    (tester) async {
      await _givenLorescapeMap(tester, style: () => Completer<Style>().future);

      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('explore.map.unavailable'), findsNothing);
    },
  );

  testWidgets(
    'given the map style fails to load, '
    'when the map is shown, '
    'then the unavailable message is rendered instead of the map',
    (tester) async {
      await _givenLorescapeMap(tester, style: () => Future<Style>.error('boom'));

      expect(find.text('explore.map.unavailable'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
    },
  );

  testWidgets(
    'given the map style loaded, '
    'when the map is shown, '
    'then the map renders and overlay children are placed on top',
    (tester) async {
      await _givenLorescapeMap(
        tester,
        style: () => Future<Style>.value(fakeMapStyle()),
        children: const [SizedBox(key: Key('overlay'))],
      );

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byKey(const Key('overlay')), findsOneWidget);
      // Attribution 從地圖角標移到探索頁頂部的 ⓘ 按鈕（見 ADR 0005 與
      // explore_screen_test）；地圖本身不再直接畫出出處文字。
    },
  );
}

Future<void> _givenLorescapeMap(
  WidgetTester tester, {
  required Future<Style> Function() style,
  List<Widget> children = const [],
}) async {
  await pumpScreen(
    tester,
    child: LorescapeMap(children: children),
    // 用 factory 而非現成的 Future：先建好的 Future.error 在被 provider
    // 接手前就成了 unhandled error，測試框架會直接判定失敗。
    overrides: [
      mapStyleProvider.overrideWith((ref) => style()),
      // 版本只用來決定快取目錄名稱，測試裡給個固定值即可；不 override 的話
      // 會去讀 asset，在測試環境拿不到而讓地圖永遠停在載入中。
      mapStyleVersionProvider.overrideWith((ref) async => 'test'),
    ],
  );
  await settleMapTimers(tester);
}
