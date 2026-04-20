import 'dart:typed_data';

import 'package:context_app/core/services/image_picker_service.dart';
import 'package:image_picker/image_picker.dart';

/// Fake [ImagePickerService] backed by a seeded result. Records the last
/// requested [ImageSource] so tests can assert which button was tapped.
class FakeImagePickerService implements ImagePickerService {
  PickedImage? _result;
  Exception? _error;

  /// The source passed in the most recent [pickImage] call, or `null` if
  /// the picker has not been invoked yet.
  ImageSource? lastSource;

  /// Number of times [pickImage] has been called.
  int pickCount = 0;

  FakeImagePickerService({PickedImage? result, Exception? error})
    : _result = result,
      _error = error;

  /// Convenience constructor that returns a small fake JPEG.
  factory FakeImagePickerService.withImage({
    String mimeType = 'image/jpeg',
  }) {
    return FakeImagePickerService(
      result: PickedImage(
        bytes: Uint8List.fromList(const [0x89, 0x50, 0x4e, 0x47]),
        mimeType: mimeType,
      ),
    );
  }

  /// Convenience constructor that simulates the user cancelling the picker.
  factory FakeImagePickerService.cancelled() => FakeImagePickerService();

  /// Re-arms the fake to return [result] on the next call.
  void stub({PickedImage? result, Exception? error}) {
    _result = result;
    _error = error;
  }

  @override
  Future<PickedImage?> pickImage(ImageSource source) async {
    pickCount += 1;
    lastSource = source;
    if (_error != null) throw _error!;
    return _result;
  }
}
