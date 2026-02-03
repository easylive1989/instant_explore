import 'dart:convert';
import 'package:http/http.dart' as http;

/// 使用 Wikimedia Commons API 取得免費圖片的服務
///
/// 這個服務完全免費，不需要 API Key
class WikimediaImageService {
  static const String _baseUrl = 'https://commons.wikimedia.org/w/api.php';

  final http.Client _client;

  WikimediaImageService({http.Client? client}) : _client = client ?? http.Client();

  /// 根據地點名稱搜尋圖片
  ///
  /// 回傳圖片 URL，如果找不到則回傳 null
  Future<String?> searchImage(String placeName) async {
    try {
      // 先搜尋相關的圖片檔案
      final searchUrl = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'action': 'query',
          'format': 'json',
          'list': 'search',
          'srsearch': '$placeName filetype:bitmap',
          'srnamespace': '6', // File namespace
          'srlimit': '5',
        },
      );

      final searchResponse = await _client.get(searchUrl);
      if (searchResponse.statusCode != 200) return null;

      final searchData = jsonDecode(searchResponse.body);
      final searchResults = searchData['query']?['search'] as List?;

      if (searchResults == null || searchResults.isEmpty) {
        return null;
      }

      // 取得第一個結果的圖片資訊
      final firstResult = searchResults.first;
      final title = firstResult['title'] as String?;

      if (title == null) return null;

      // 取得圖片的實際 URL
      final imageUrl = await _getImageUrl(title);
      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  /// 取得圖片的實際 URL
  Future<String?> _getImageUrl(String title) async {
    try {
      final infoUrl = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'action': 'query',
          'format': 'json',
          'titles': title,
          'prop': 'imageinfo',
          'iiprop': 'url',
          'iiurlwidth': '400', // 縮圖寬度
        },
      );

      final infoResponse = await _client.get(infoUrl);
      if (infoResponse.statusCode != 200) return null;

      final infoData = jsonDecode(infoResponse.body);
      final pages = infoData['query']?['pages'] as Map<String, dynamic>?;

      if (pages == null || pages.isEmpty) return null;

      // 取得第一個頁面的圖片資訊
      final firstPage = pages.values.first as Map<String, dynamic>?;
      final imageInfo = (firstPage?['imageinfo'] as List?)?.firstOrNull;

      if (imageInfo == null) return null;

      // 優先使用縮圖 URL，否則使用原始 URL
      final thumbUrl = imageInfo['thumburl'] as String?;
      final originalUrl = imageInfo['url'] as String?;

      return thumbUrl ?? originalUrl;
    } catch (e) {
      return null;
    }
  }
}
