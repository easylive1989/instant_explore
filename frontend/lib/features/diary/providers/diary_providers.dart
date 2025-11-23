import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/diary/services/diary_repository.dart';
import 'package:travel_diary/features/diary/services/diary_repository_impl.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'package:travel_diary/features/images/services/image_picker_service.dart';

// Export diary detail provider
export 'diary_detail_provider.dart';

/// Diary Repository Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();
});

/// Image Upload Service Provider
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService();
});

/// Image Picker Service Provider
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});
