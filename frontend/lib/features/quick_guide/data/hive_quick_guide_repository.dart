import 'dart:convert';

import 'package:context_app/features/quick_guide/domain/models/quick_guide_entry.dart';
import 'package:context_app/features/quick_guide/domain/repositories/quick_guide_repository.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

/// Hive-based local implementation of [QuickGuideRepository].
///
/// Each [QuickGuideEntry] is stored as a JSON string keyed by its id.
class HiveQuickGuideRepository implements QuickGuideRepository {
  static const String _boxName = 'quick_guide_entries';
  static final _log = Logger('HiveQuickGuideRepository');

  Future<Box<dynamic>> _getBox() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<List<QuickGuideEntry>> getAll() async {
    try {
      final box = await _getBox();
      return box.values
          .map(
            (v) => QuickGuideEntry.fromJson(
              jsonDecode(v as String) as Map<String, dynamic>,
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, stack) {
      _log.warning('Failed to load quick guide entries', e, stack);
      return [];
    }
  }

  @override
  Future<void> save(QuickGuideEntry entry) async {
    final box = await _getBox();
    await box.put(entry.id, jsonEncode(entry.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
