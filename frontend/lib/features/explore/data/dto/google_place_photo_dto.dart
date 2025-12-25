/// Google Places API Photo DTO
///
/// 用於解析 Google Places API 回傳的照片資料
class GooglePlacePhotoDto {
  final String name;
  final int widthPx;
  final int heightPx;
  final List<String> authorAttributions;

  GooglePlacePhotoDto({
    required this.name,
    required this.widthPx,
    required this.heightPx,
    required this.authorAttributions,
  });

  factory GooglePlacePhotoDto.fromJson(Map<String, dynamic> json) {
    return GooglePlacePhotoDto(
      name: json['name'] ?? '',
      widthPx: json['widthPx'] ?? 0,
      heightPx: json['heightPx'] ?? 0,
      authorAttributions: _extractAuthorAttributions(
        json['authorAttributions'],
      ),
    );
  }

  static List<String> _extractAuthorAttributions(dynamic authorAttributions) {
    if (authorAttributions == null) return [];

    if (authorAttributions is List) {
      return authorAttributions.map((attribution) {
        if (attribution is String) {
          return attribution;
        } else if (attribution is Map<String, dynamic>) {
          return attribution['displayName']?.toString() ??
              attribution['uri']?.toString() ??
              attribution.toString();
        }
        return attribution.toString();
      }).toList();
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'widthPx': widthPx,
      'heightPx': heightPx,
      'authorAttributions': authorAttributions,
    };
  }

  /// 產生照片 URL
  String toPhotoUrl({int? maxWidth, int? maxHeight, required String apiKey}) {
    final baseUrl = 'https://places.googleapis.com/v1/$name/media';
    final params = <String>[];

    if (maxWidth != null) {
      params.add('maxWidthPx=$maxWidth');
    }
    if (maxHeight != null) {
      params.add('maxHeightPx=$maxHeight');
    }
    params.add('key=$apiKey');

    return '$baseUrl?${params.join('&')}';
  }
}
