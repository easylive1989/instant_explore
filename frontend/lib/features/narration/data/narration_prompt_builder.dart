import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';

/// 導覽 Prompt 建構器
///
/// 負責根據景點類型和介紹面向生成對應的 AI prompt
class NarrationPromptBuilder {
  final Place place;
  final NarrationAspect aspect;
  final String language;

  NarrationPromptBuilder({
    required this.place,
    required this.aspect,
    required this.language,
  });

  /// 建構完整的 prompt
  String build() {
    final languageName = language.startsWith('zh') ? '繁體中文' : 'English';
    final aspectGuideline = _getAspectGuideline(aspect);

    return '''
You are a professional tour guide creating an engaging audio narration for a location.

Location Information:
- Name: ${place.name}
- Address: ${place.formattedAddress}
- Category: ${_getCategoryDescription(place.category)}
- Types: ${place.types.join(', ')}
${place.rating != null ? '- Rating: ${place.rating}/5.0' : ''}

Requirements:
- Language: $languageName
- Narration Aspect: ${_getAspectDescription(aspect)}
- Target Length: approximately 800-1200 characters
- Estimated Duration: 3-5 minutes when read aloud
- Tone: Engaging, vivid, and informative - as if you're speaking to a tourist standing at the location
- Do NOT include any opening greetings, introductions, or welcome phrases (e.g., "Hello everyone", "Welcome to..."). Start directly with the content.

Content Guidelines:
$aspectGuideline

Format:
- Write in a conversational tone suitable for audio playback
- Use natural pauses (sentence breaks) for better listening experience
- Avoid bullet points or lists
- Write in flowing paragraphs with clear sentence endings (。！？or . ! ?)
- Make it engaging and memorable

Please generate the narration now:''';
  }

  /// 取得景點類型的描述
  String _getCategoryDescription(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.historicalCultural:
        return 'Historical & Cultural Site';
      case PlaceCategory.naturalLandscape:
        return 'Natural Landscape';
      case PlaceCategory.modernUrban:
        return 'Modern Landmark & Urban';
      case PlaceCategory.museumArt:
        return 'Museum & Art';
      case PlaceCategory.foodMarket:
        return 'Local Food & Night Market';
    }
  }

  /// 取得介紹面向的描述
  String _getAspectDescription(NarrationAspect aspect) {
    switch (aspect) {
      case NarrationAspect.historicalBackground:
        return 'Historical Background';
      case NarrationAspect.architecture:
        return 'Architecture';
      case NarrationAspect.customs:
        return 'Customs';
      case NarrationAspect.geology:
        return 'Geology';
      case NarrationAspect.myths:
        return 'Myths';
    }
  }

  /// 根據介紹面向取得具體的內容指引
  String _getAspectGuideline(NarrationAspect aspect) {
    switch (aspect) {
      case NarrationAspect.historicalBackground:
        return '''
Focus on Historical Background (歷史背景 - Storytelling):
- Don't just mention dates and years - tell stories about PEOPLE
- Who built this place? What love, hate, or dramatic events happened here?
- Example approach: "This wall wasn't built to defend against enemies, but to protect from pirates..."
- Make history feel alive and relatable through human stories
- Connect historical figures to their motivations and emotions
''';
      case NarrationAspect.architecture:
        return '''
Focus on Architecture (建築細節):
- Decode symbolic meanings that aren't visible to the naked eye
- Explain what architectural elements represent and why they matter
- Example: "Look up at the roof - those mythical creatures show status. The more creatures, the higher the rank. Only emperors could use this many..."
- Point out details tourists might miss and explain their significance
- Use the physical structure to tell cultural stories
''';
      case NarrationAspect.customs:
        return '''
Focus on Customs (文化禁忌與習俗):
- Tell tourists what they should do and WHY they should do it
- Explain the reasoning behind cultural practices
- Example: "Enter through this side of the temple gate - it's called 'entering the dragon's throat' and brings good fortune..."
- Share do's and don'ts in an engaging, non-preachy way
- Make cultural practices feel meaningful rather than arbitrary
''';
      case NarrationAspect.geology:
        return '''
Focus on Geology (地理成因):
- Use simple metaphors to explain geological formation
- Example: "These rock layers are like a millefeuille pastry - formed over millions of years of compression and stacking."
- Make complex geological processes accessible and fascinating
- Show your expertise through clear explanations
- Help tourists see the landscape with new understanding
''';
      case NarrationAspect.myths:
        return '''
Focus on Myths (傳說故事):
- Give the landscape spiritual meaning through local legends
- Example: "Local indigenous people believe this mountain is the embodiment of a guardian deity..."
- Share stories that add mystique to the natural beauty
- Connect landscape features to mythological narratives
- Make nature feel more enchanting through storytelling
''';
    }
  }
}
