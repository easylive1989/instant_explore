import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';

/// 路線規劃 Prompt 建構器
///
/// 負責建構要求 AI 從候選景點中挑選並規劃路線的 prompt
class RoutePromptBuilder {
  final List<Place> candidatePlaces;
  final PlaceLocation userLocation;
  final String language;

  RoutePromptBuilder({
    required this.candidatePlaces,
    required this.userLocation,
    required this.language,
  });

  /// 建構完整的 prompt
  String build() {
    final languageName = language.startsWith('zh') ? '繁體中文' : 'English';
    final placesInfo = _buildPlacesInfo();

    return '''
You are a professional tour guide planning a walking route for a tourist.

User's current location:
- Latitude: ${userLocation.latitude}
- Longitude: ${userLocation.longitude}

Available nearby places:
$placesInfo

Requirements:
- Language: $languageName
- Select 2-3 of the BEST places from the list above
- Arrange them in an optimal walking order (minimize backtracking)
- Consider thematic coherence (e.g., places sharing the same historical context)
- Give the route a creative, descriptive theme title
- Write a brief overview (150-200 characters) for each selected place
- The overview should be engaging and help the tourist decide whether to visit
- Do NOT include any opening greetings or welcome phrases

IMPORTANT: You MUST respond with ONLY a valid JSON object. No markdown, no code fences, no explanation. Just the JSON.

The JSON must follow this exact schema:
{"title": "route theme title", "stops": [{"placeId": "the place id from the list", "overview": "brief engaging overview"}]}

Example:
{"title": "萬華歷史散步", "stops": [{"placeId": "ChIJabc123", "overview": "萬華最具代表性的百年古廟，融合閩南與日式建築風格..."}, {"placeId": "ChIJdef456", "overview": "清代至日治時期的老街，保留完整紅磚建築群..."}]}

Generate the route plan now:''';
  }

  /// 建構候選景點清單資訊
  String _buildPlacesInfo() {
    final buffer = StringBuffer();

    for (final place in candidatePlaces) {
      buffer.writeln('- ID: ${place.id}');
      buffer.writeln('  Name: ${place.name}');
      buffer.writeln('  Address: ${place.formattedAddress}');
      buffer.writeln('  Category: ${place.category.name}');
      buffer.writeln('  Types: ${place.types.join(', ')}');
      if (place.rating != null) {
        buffer.writeln('  Rating: ${place.rating}/5.0');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
