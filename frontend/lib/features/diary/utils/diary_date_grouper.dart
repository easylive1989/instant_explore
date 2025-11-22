import 'package:intl/intl.dart';
import 'package:travel_diary/features/diary/models/diary_entry.dart';

/// 日記日期分組工具
class DiaryDateGrouper {
  /// 按日期分組日記條目
  ///
  /// 返回格式：[{date: '2025-01-22', entries: [...]}, ...]
  /// 日期從新到舊排序
  static List<Map<String, dynamic>> groupByDate(List<DiaryEntry> entries) {
    final Map<String, List<DiaryEntry>> grouped = {};

    // 按日期分組
    for (final entry in entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.visitDate);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    // 轉換為列表並排序
    final List<Map<String, dynamic>> result = [];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 降序：最新在前

    for (final key in sortedKeys) {
      // 同一天內按時間降序排序
      final entriesInDay = grouped[key]!;
      entriesInDay.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      result.add({'date': key, 'entries': entriesInDay});
    }

    return result;
  }

  /// 取得星期名稱（中文）
  static String getWeekdayName(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${weekdays[weekday - 1]}';
  }
}
