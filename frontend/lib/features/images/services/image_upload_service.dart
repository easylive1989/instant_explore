import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 圖片上傳服務 (使用 Supabase Storage)
class ImageUploadService {
  final SupabaseClient _supabase;
  static const String bucketName = 'diary-images';

  ImageUploadService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// 上傳圖片到 Supabase Storage
  ///
  /// [imageFile] 要上傳的圖片檔案
  /// [diaryId] 日記 ID
  /// [index] 圖片索引 (用於檔案命名)
  ///
  /// 返回:儲存路徑 (格式: {user_id}/{diary_id}_{timestamp}_{index}.{ext})
  Future<String> uploadImage({
    required File imageFile,
    required String diaryId,
    required int index,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // 產生檔案名稱
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExt = _getFileExtension(imageFile.path);
    final fileName = '${diaryId}_${timestamp}_$index$fileExt';
    final filePath = '$userId/$fileName';

    try {
      // 上傳圖片
      await _supabase.storage
          .from(bucketName)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return filePath;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// 批次上傳多張圖片
  ///
  /// [imageFiles] 要上傳的圖片檔案列表
  /// [diaryId] 日記 ID
  ///
  /// 返回:儲存路徑列表
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String diaryId,
  }) async {
    final List<String> uploadedPaths = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final path = await uploadImage(
          imageFile: imageFiles[i],
          diaryId: diaryId,
          index: i,
        );
        uploadedPaths.add(path);
      } catch (e) {
        // 如果有任何圖片上傳失敗,刪除已上傳的圖片
        for (final path in uploadedPaths) {
          await deleteImage(path);
        }
        throw Exception('Failed to upload image ${i + 1}: $e');
      }
    }

    return uploadedPaths;
  }

  /// 取得圖片的公開 URL
  ///
  /// [storagePath] 儲存路徑
  ///
  /// 返回:圖片的公開 URL
  String getImageUrl(String storagePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(storagePath);
  }

  /// 取得圖片的臨時簽名 URL (有效期 1 小時)
  ///
  /// [storagePath] 儲存路徑
  ///
  /// 返回:圖片的臨時 URL
  Future<String> getSignedImageUrl(String storagePath) async {
    try {
      final signedUrl = await _supabase.storage
          .from(bucketName)
          .createSignedUrl(
            storagePath,
            3600, // 1 小時
          );
      return signedUrl;
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }

  /// 刪除圖片
  ///
  /// [storagePath] 儲存路徑
  Future<void> deleteImage(String storagePath) async {
    try {
      await _supabase.storage.from(bucketName).remove([storagePath]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// 批次刪除多張圖片
  ///
  /// [storagePaths] 儲存路徑列表
  Future<void> deleteMultipleImages(List<String> storagePaths) async {
    try {
      await _supabase.storage.from(bucketName).remove(storagePaths);
    } catch (e) {
      throw Exception('Failed to delete images: $e');
    }
  }

  /// 取得檔案副檔名
  String _getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1) return '.jpg'; // 預設副檔名
    return filePath.substring(lastDot);
  }

  /// 檢查 bucket 是否存在
  Future<bool> checkBucketExists() async {
    try {
      await _supabase.storage.getBucket(bucketName);
      return true;
    } catch (e) {
      return false;
    }
  }
}
