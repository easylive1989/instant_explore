import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 自訂圖片快取管理器
///
/// 將照片快取 7 天，避免每次重開 App 都要重新下載
class PlaceImageCacheManager {
  static const key = 'placeImageCacheKey';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      // 確保使用檔案系統儲存
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
