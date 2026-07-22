import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 管理 `vector_map_tiles` 的磁碟 tile 快取目錄。
///
/// **為什麼需要這個**：`vector_map_tiles` 的磁碟快取 key 只有
/// `{z}_{x}_{y}_{source}.pbf`，不含樣式身分，預設 TTL 30 天。2026-07-21 實測
/// 確認：改了樣式配色後，既有快取仍會餵出舊配色的畫面——把快取清掉才會套用
/// 新樣式。也就是說樣式改版後，已安裝的使用者最長會有 30 天看到舊配色。
///
/// 解法是把快取目錄依樣式版本切開：換樣式＝換目錄＝天然的 cache bust。
class MapTileCacheService {
  const MapTileCacheService();

  static const String _rootName = 'lorescape_map_tiles';

  /// 取得對應 [styleVersion] 的快取目錄，並順手刪掉其他版本的殘留，
  /// 避免每次改樣式都在使用者裝置上多留一份沒人會再讀的舊快取。
  Future<Directory> folderForStyle(String styleVersion) async {
    final base = await getTemporaryDirectory();
    final root = Directory('${base.path}/$_rootName');
    await root.create(recursive: true);

    final current = Directory('${root.path}/$styleVersion');
    await current.create(recursive: true);
    await _removeOtherVersions(root, keep: styleVersion);
    return current;
  }

  Future<void> _removeOtherVersions(
    Directory root, {
    required String keep,
  }) async {
    try {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) continue;
        if (entity.path.split('/').last == keep) continue;
        await entity.delete(recursive: true);
      }
    } on FileSystemException {
      // 清不掉舊目錄不影響功能，只是多佔一點空間；不要因此讓地圖開不起來。
    }
  }
}
