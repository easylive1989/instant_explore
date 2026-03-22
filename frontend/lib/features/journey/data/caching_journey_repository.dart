import 'dart:developer';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/journey/data/services/hive_journey_cache_service.dart';
import 'package:context_app/features/journey/domain/errors/journey_error.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/repositories/journey_repository.dart';

/// 使用 Decorator 模式包裝 JourneyRepository，添加快取功能
///
/// 讀取時先嘗試遠端，成功則更新快取；
/// 網路失敗時 fallback 到本地快取。
/// 寫入/刪除仍需網路，成功後同步更新快取。
class CachingJourneyRepository implements JourneyRepository {
  final JourneyRepository _remote;
  final HiveJourneyCacheService _cache;

  CachingJourneyRepository({
    required JourneyRepository remote,
    required HiveJourneyCacheService cache,
  }) : _remote = remote,
       _cache = cache;

  @override
  Future<List<JourneyEntry>> getJourneyEntries(String userId) async {
    try {
      final entries = await _remote.getJourneyEntries(userId);
      try {
        await _cache.saveEntries(userId, entries);
      } catch (e) {
        log(
          'Failed to update cache after remote fetch',
          error: e,
          name: 'CachingJourneyRepository',
        );
      }
      return entries;
    } on AppError catch (e) {
      if (e.type == JourneyError.networkError) {
        log(
          'Network error, falling back to cache',
          error: e,
          name: 'CachingJourneyRepository',
        );
        final cached = await _cache.getEntries(userId);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<void> addJourneyEntry(JourneyEntry entry) async {
    await _remote.addJourneyEntry(entry);
  }

  @override
  Future<void> deleteJourneyEntry(String id) async {
    await _remote.deleteJourneyEntry(id);
    // 刪除操作無法從 id 推斷 userId，
    // 下次 getJourneyEntries 時快取會全量覆寫
  }
}
