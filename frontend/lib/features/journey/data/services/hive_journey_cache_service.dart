import 'dart:convert';
import 'dart:developer';

import 'package:context_app/features/journey/data/journey_entry_mapper.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:hive/hive.dart';

/// Journey 資料的 Hive 快取服務
///
/// 負責將 JourneyEntry 列表序列化為 JSON 存入 Hive，
/// 並在需要時反序列化回 Domain Model。
/// 採用 lazy open 模式管理 Hive Box。
class HiveJourneyCacheService {
  static const String _boxName = 'journey_cache';
  static const String _entriesKeyPrefix = 'journey_entries_';

  Box? _box;

  /// 取得或開啟 Hive Box
  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  String _entriesKey(String userId) => '$_entriesKeyPrefix$userId';

  /// 取得快取的 Journey 列表
  ///
  /// 回傳 null 表示無快取資料。
  Future<List<JourneyEntry>?> getEntries(String userId) async {
    try {
      final box = await _getBox();
      final jsonStr = box.get(_entriesKey(userId)) as String?;
      if (jsonStr == null) return null;
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map(
            (json) => JourneyEntryMapper.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      log(
        'Failed to read journey cache',
        error: e,
        name: 'HiveJourneyCacheService',
      );
      return null;
    }
  }

  /// 全量覆寫快取。
  Future<void> saveEntries(String userId, List<JourneyEntry> entries) async {
    try {
      final box = await _getBox();
      final jsonList = entries.map(JourneyEntryMapper.toJson).toList();
      await box.put(_entriesKey(userId), jsonEncode(jsonList));
    } catch (e) {
      log(
        'Failed to save journey cache',
        error: e,
        name: 'HiveJourneyCacheService',
      );
    }
  }

  /// 新增一筆 entry 到快取列表頭部。
  Future<void> addEntry(String userId, JourneyEntry entry) async {
    try {
      final entries = await getEntries(userId) ?? [];
      final updated = [entry, ...entries];
      await saveEntries(userId, updated);
    } catch (e) {
      log(
        'Failed to add entry to journey cache',
        error: e,
        name: 'HiveJourneyCacheService',
      );
    }
  }

  /// 從快取中移除指定 entry。
  Future<void> removeEntry(String userId, String entryId) async {
    try {
      final entries = await getEntries(userId);
      if (entries == null) return;
      final updated = entries.where((e) => e.id != entryId).toList();
      await saveEntries(userId, updated);
    } catch (e) {
      log(
        'Failed to remove entry from journey cache',
        error: e,
        name: 'HiveJourneyCacheService',
      );
    }
  }

  /// 清除所有快取資料。
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      log(
        'Failed to clear journey cache',
        error: e,
        name: 'HiveJourneyCacheService',
      );
    }
  }
}
