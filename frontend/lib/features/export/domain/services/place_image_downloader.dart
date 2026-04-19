import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Result of a single image download attempt.
class DownloadedImage {
  final Uint8List bytes;
  final bool usedPlaceholder;

  const DownloadedImage({required this.bytes, required this.usedPlaceholder});
}

/// Downloads remote place images for PDF embedding, falling back to a
/// placeholder on any failure (network error, 4xx/5xx, timeout).
class PlaceImageDownloader {
  final http.Client _client;
  final Duration timeout;
  final Uint8List placeholderBytes;
  final bool _ownsClient;

  PlaceImageDownloader({
    required this.placeholderBytes,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  /// Downloads the image at [url]. A `null` or empty URL immediately resolves
  /// to the placeholder — no request is made.
  Future<DownloadedImage> download(String? url) async {
    if (url == null || url.isEmpty) {
      return DownloadedImage(bytes: placeholderBytes, usedPlaceholder: true);
    }

    try {
      final response = await _client.get(Uri.parse(url)).timeout(timeout);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.bodyBytes.isNotEmpty) {
        return DownloadedImage(
          bytes: response.bodyBytes,
          usedPlaceholder: false,
        );
      }
    } on TimeoutException {
      // Falls through to placeholder.
    } on http.ClientException {
      // Falls through to placeholder.
    } on FormatException {
      // Invalid URL — falls through to placeholder.
    }

    return DownloadedImage(bytes: placeholderBytes, usedPlaceholder: true);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
