import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';
import 'package:travel_diary/features/diary/services/diary_repository_impl.dart';

// Export diary detail provider
export 'diary_detail_provider.dart';

/// Diary Repository Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();
});
