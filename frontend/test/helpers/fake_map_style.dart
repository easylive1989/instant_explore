import 'dart:typed_data';

import 'package:context_app/features/explore/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

/// 讓地圖在測試環境能真的渲染的 overrides。
///
/// 沒有這組 override，`mapStyleProvider` 會去打網路而永遠停在載入中，
/// `FlutterMap` 根本不會被建出來——於是任何「地圖上有什麼」的斷言都會失敗，
/// 而且失敗訊息看起來像是元件寫錯，其實只是樣式沒載入。
List<Override> fakeMapStyleOverrides() => [
  mapStyleProvider.overrideWith((ref) async => fakeMapStyle()),
  mapStyleVersionProvider.overrideWith((ref) async => 'test'),
];

/// 跑完 `vector_map_tiles` 掛載後排的延遲工作。
///
/// 不跑完，測試結束時會因為「widget tree 已 dispose 但 Timer 還在」而失敗，
/// 而且錯誤訊息完全看不出跟地圖有關。任何會渲染 [LorescapeMap] 的測試都要
/// 在斷言前呼叫一次。
Future<void> settleMapTimers(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 3));

/// 最小可用的 openmaptiles 樣式。
///
/// `VectorTileLayer` 會 assert theme 用到的 source 必須在 tileProviders 裡，
/// 所以 theme 至少要有一個引用 `openmaptiles` 的圖層，不能只有 background。
Style fakeMapStyle() {
  final theme = ThemeReader().read(<String, dynamic>{
    'version': 8,
    'sources': <String, dynamic>{
      'openmaptiles': <String, dynamic>{'type': 'vector'},
    },
    'layers': <dynamic>[
      <String, dynamic>{
        'id': 'background',
        'type': 'background',
        'paint': <String, dynamic>{'background-color': '#F7F1E6'},
      },
      <String, dynamic>{
        'id': 'water',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'water',
        'paint': <String, dynamic>{'fill-color': '#DFD3BD'},
      },
    ],
  });

  return Style(
    theme: theme,
    providers: TileProviders(<String, VectorTileProvider>{
      'openmaptiles': EmptyVectorTileProvider(),
    }),
  );
}

/// 永遠回空 tile 的 provider。測試不該碰網路——真的打 HTTP 會留下 retry
/// timer，讓測試在 tear-down 時因為「Timer 尚未結束」而失敗。
class EmptyVectorTileProvider extends VectorTileProvider {
  @override
  int get maximumZoom => 14;

  @override
  int get minimumZoom => 1;

  @override
  TileOffset get tileOffset => TileOffset.DEFAULT;

  @override
  Future<Uint8List> provide(TileIdentity tile) async => Uint8List(0);
}
