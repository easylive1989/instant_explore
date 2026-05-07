import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

const _slugAlphabet =
    'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
const _slugLength = 8;
const _imagesBucket = 'shared_journey_images';

/// Payload describing the journey content to be persisted on Supabase
/// for public sharing. Used as the input to [SharedJourneyRepository].
class SharedJourneyPayload {
  final String placeId;
  final String placeName;
  final String placeAddress;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String narrationText;
  final List<String> narrationStyles;
  final String language;
  final DateTime visitedAt;

  const SharedJourneyPayload({
    required this.placeId,
    required this.placeName,
    required this.narrationText,
    required this.language,
    required this.visitedAt,
    this.placeAddress = '',
    this.imageUrl,
    this.imageBytes,
    this.narrationStyles = const [],
  });
}

/// Persists shared journey content to Supabase so the landing site
/// can render it on a public URL.
class SharedJourneyRepository {
  SharedJourneyRepository({
    required SupabaseClient client,
    required String shareBaseUrl,
    Random? random,
  }) : _client = client,
       _shareBaseUrl = shareBaseUrl,
       _random = random ?? Random.secure();

  final SupabaseClient _client;
  final String _shareBaseUrl;
  final Random _random;

  /// Inserts the payload into Supabase and returns the public share
  /// URL. If [SharedJourneyPayload.imageBytes] is provided it will be
  /// uploaded to Supabase Storage first to obtain a public URL.
  Future<String> share(SharedJourneyPayload payload) async {
    final id = _generateSlug();
    final userId = _client.auth.currentUser?.id;

    final imageUrl = payload.imageBytes != null
        ? await _uploadImage(id, payload.imageBytes!)
        : payload.imageUrl;

    await _client.from('shared_journeys').insert({
      'id': id,
      if (userId != null) 'user_id': userId,
      'place_id': payload.placeId,
      'place_name': payload.placeName,
      'place_address': payload.placeAddress,
      'place_image_url': imageUrl,
      'narration_text': payload.narrationText,
      'narration_styles': payload.narrationStyles,
      'language': payload.language,
      'visited_at': payload.visitedAt.toUtc().toIso8601String(),
    });

    return buildShareUrl(id);
  }

  String buildShareUrl(String id) {
    final base = _shareBaseUrl.endsWith('/')
        ? _shareBaseUrl.substring(0, _shareBaseUrl.length - 1)
        : _shareBaseUrl;
    return '$base/s/$id';
  }

  Future<String> _uploadImage(String id, Uint8List bytes) async {
    final path = '$id.jpg';
    await _client.storage
        .from(_imagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return _client.storage.from(_imagesBucket).getPublicUrl(path);
  }

  String _generateSlug() {
    final buffer = StringBuffer();
    for (var i = 0; i < _slugLength; i++) {
      buffer.write(_slugAlphabet[_random.nextInt(_slugAlphabet.length)]);
    }
    return buffer.toString();
  }
}
