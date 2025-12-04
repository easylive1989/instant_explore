import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary/features/images/services/image_upload_service.dart';
import 'package:travel_diary/features/images/services/image_picker_service.dart';

/// Provider for ImageUploadService
final imageUploadServiceProvider = Provider<ImageUploadService>(
  (ref) => ImageUploadService(),
);

/// Image Picker Service Provider
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});
