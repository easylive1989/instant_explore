import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Result returned by [ImagePickerService.pickImage].
class PickedImage {
  /// Decoded bytes of the picked image.
  final Uint8List bytes;

  /// MIME type derived from the file extension (e.g. `image/jpeg`).
  final String mimeType;

  const PickedImage({required this.bytes, required this.mimeType});
}

/// Thin abstraction over [ImagePicker] so screens can be tested with
/// in-memory fakes instead of triggering the real picker UI.
abstract class ImagePickerService {
  /// Asks the user to pick an image from [source]. Returns `null` when
  /// the user cancels the picker.
  Future<PickedImage?> pickImage(ImageSource source);
}

class _DefaultImagePickerService implements ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<PickedImage?> pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    return PickedImage(bytes: bytes, mimeType: _mimeType(image.path));
  }

  String _mimeType(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

/// Provides the [ImagePickerService] singleton. Override in tests with
/// a fake implementation.
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return _DefaultImagePickerService();
});
