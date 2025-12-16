/// Google Places API 照片資料模型
///
/// 用於儲存地點照片相關資訊
class PlacePhoto {
  final String name;
  final int widthPx;
  final int heightPx;
  final List<String> authorAttributions;

  PlacePhoto({
    required this.name,
    required this.widthPx,
    required this.heightPx,
    required this.authorAttributions,
  });

  factory PlacePhoto.fromJson(Map<String, dynamic> json) {
    return PlacePhoto(
      name: json['name'] ?? '',
      widthPx: json['widthPx'] ?? 0,
      heightPx: json['heightPx'] ?? 0,
      authorAttributions: _extractAuthorAttributions(
        json['authorAttributions'],
      ),
    );
  }

  /// 提取作者歸屬資訊
  static List<String> _extractAuthorAttributions(dynamic authorAttributions) {
    if (authorAttributions == null) return [];

    if (authorAttributions is List) {
      return authorAttributions.map((attribution) {
        if (attribution is String) {
          return attribution;
        } else if (attribution is Map<String, dynamic>) {
          // 從物件中提取 displayName 或其他識別資訊
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
  /// [maxWidth] 照片最大寬度
  /// [maxHeight] 照片最大高度
  /// [apiKey] Google Places API 金鑰
  String getPhotoUrl({int? maxWidth, int? maxHeight, required String apiKey}) {
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

  @override
  String toString() {
    return 'PlacePhoto(name: $name, widthPx: $widthPx, heightPx: $heightPx)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlacePhoto && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
