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
    final aspectGuideline = _getAspectGuideline(place.category, aspect);

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
        return 'Historical & Cultural Site (人文古蹟)';
      case PlaceCategory.naturalLandscape:
        return 'Natural Landscape (自然景觀)';
      case PlaceCategory.modernUrban:
        return 'Modern Landmark & Urban (現代地標與城市)';
      case PlaceCategory.museumArt:
        return 'Museum & Art (博物館與藝術)';
      case PlaceCategory.foodMarket:
        return 'Local Food & Night Market (在地美食與夜市)';
    }
  }

  /// 取得介紹面向的描述
  String _getAspectDescription(NarrationAspect aspect) {
    switch (aspect) {
      // 人文古蹟類
      case NarrationAspect.historicalBackground:
        return 'Historical Background (歷史背景)';
      case NarrationAspect.architecture:
        return 'Architecture (建築細節)';
      case NarrationAspect.customs:
        return 'Customs (文化禁忌與習俗)';
      case NarrationAspect.relevance:
        return 'Relevance (今昔對比)';
      // 自然景觀類
      case NarrationAspect.geology:
        return 'Geology (地理成因)';
      case NarrationAspect.photoSpots:
        return 'Photo Spots (最佳拍攝點)';
      case NarrationAspect.floraFauna:
        return 'Flora & Fauna (生態觀察)';
      case NarrationAspect.myths:
        return 'Myths (傳說故事)';
      // 現代地標與城市類
      case NarrationAspect.designConcept:
        return 'Design Concept (設計理念)';
      case NarrationAspect.statistics:
        return 'Statistics (數據震撼)';
      case NarrationAspect.status:
        return 'Status (經濟與社會地位)';
      case NarrationAspect.lifestyle:
        return 'Lifestyle (周邊生活機能)';
      // 博物館與藝術展覽類
      case NarrationAspect.highlights:
        return 'Highlights (鎮館之寶)';
      case NarrationAspect.emotion:
        return 'Emotion (作品背後的情感)';
      case NarrationAspect.guidance:
        return 'Guidance (引導觀察)';
      case NarrationAspect.context:
        return 'Context (策展脈絡)';
      // 在地美食與夜市類
      case NarrationAspect.ingredients:
        return 'Ingredients (食材與產地)';
      case NarrationAspect.etiquette:
        return 'Etiquette (正確吃法)';
      case NarrationAspect.brandStory:
        return 'Brand Story (店家的故事)';
      case NarrationAspect.sensory:
        return 'Sensory (口感描述)';
    }
  }

  /// 根據景點類型和介紹面向取得具體的內容指引
  String _getAspectGuideline(PlaceCategory category, NarrationAspect aspect) {
    switch (category) {
      case PlaceCategory.historicalCultural:
        return _getHistoricalCulturalGuideline(aspect);
      case PlaceCategory.naturalLandscape:
        return _getNaturalLandscapeGuideline(aspect);
      case PlaceCategory.modernUrban:
        return _getModernUrbanGuideline(aspect);
      case PlaceCategory.museumArt:
        return _getMuseumArtGuideline(aspect);
      case PlaceCategory.foodMarket:
        return _getFoodMarketGuideline(aspect);
    }
  }

  /// 人文古蹟類的內容指引
  String _getHistoricalCulturalGuideline(NarrationAspect aspect) {
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
      case NarrationAspect.relevance:
        return '''
Focus on Relevance (今昔對比):
- Connect the past to modern life to create resonance
- Example: "This area was like today's Xinyi District - the most fashionable commercial center of its time."
- Help tourists see how historical places relate to their current experience
- Draw parallels between then and now
- Make history feel relevant to contemporary life
''';
      default:
        return _getDefaultGuideline();
    }
  }

  /// 自然景觀類的內容指引
  String _getNaturalLandscapeGuideline(NarrationAspect aspect) {
    switch (aspect) {
      case NarrationAspect.geology:
        return '''
Focus on Geology (地理成因):
- Use simple metaphors to explain geological formation
- Example: "These rock layers are like a millefeuille pastry - formed over millions of years of compression and stacking."
- Make complex geological processes accessible and fascinating
- Show your expertise through clear explanations
- Help tourists see the landscape with new understanding
''';
      case NarrationAspect.photoSpots:
        return '''
Focus on Photo Spots (最佳拍攝點):
- This is what modern tourists care about most - tell them directly where to shoot
- Example: "Stand over here on the left - from this angle you can capture both the lake's reflection and the mountain peak in one shot."
- Give specific positioning advice
- Explain why certain angles work better
- Help them create Instagram-worthy memories
''';
      case NarrationAspect.floraFauna:
        return '''
Focus on Flora & Fauna (生態觀察):
- Introduce endemic species and create a sense of treasure hunting
- Example: "If you're lucky, you might spot a Taiwan Blue Magpie in that treetop..."
- Share interesting facts about local wildlife
- Point out what to look for and when
- Make nature observation feel like an adventure
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
      default:
        return _getDefaultGuideline();
    }
  }

  /// 現代地標與城市類的內容指引
  String _getModernUrbanGuideline(NarrationAspect aspect) {
    switch (aspect) {
      case NarrationAspect.designConcept:
        return '''
Focus on Design Concept (設計理念):
- What did the architect want to express?
- Example: "This building's shape resembles bamboo, symbolizing 'rising steadily higher'..."
- Explain the philosophy and meaning behind the design
- Connect form to function and cultural significance
- Help tourists appreciate architectural intention
''';
      case NarrationAspect.statistics:
        return '''
Focus on Statistics (數據震撼):
- Use concrete numbers to create a sense of wonder (highest, fastest, most expensive)
- Example: "This elevator goes from the 1st to 89th floor in just 37 seconds - you might feel it in your ears..."
- Share impressive facts and figures
- Make statistics tangible and relatable
- Create "wow moments" through scale and achievement
''';
      case NarrationAspect.status:
        return '''
Focus on Status (經濟與社會地位):
- What does this place represent in terms of city status?
- Example: "Land here costs X per square meter. People who live here are typically..."
- Explain the social and economic significance
- Share what this location symbolizes culturally
- Give context about prestige and importance
''';
      case NarrationAspect.lifestyle:
        return '''
Focus on Lifestyle (周邊生活機能):
- Where are the good shopping spots? Where do locals go?
- Share practical insider knowledge
- Recommend authentic local experiences vs. tourist traps
- Give tips on where to eat, shop, and explore nearby
- Help tourists experience the area like a local would
''';
      default:
        return _getDefaultGuideline();
    }
  }

  /// 博物館與藝術展覽類的內容指引
  String _getMuseumArtGuideline(NarrationAspect aspect) {
    switch (aspect) {
      case NarrationAspect.highlights:
        return '''
Focus on Highlights (鎮館之寶):
- Take visitors to see the most important pieces first - ensure the visit is worthwhile
- Explain why these masterpieces matter
- Share their historical or artistic significance
- Make sure tourists know what they absolutely shouldn't miss
- Create a curated experience that maximizes their limited time
''';
      case NarrationAspect.emotion:
        return '''
Focus on Emotion (作品背後的情感):
- Share the artist's emotional state or circumstances during creation
- Example: "Van Gogh painted this while at his most mentally fragile - you can see it in these brushstrokes..."
- Connect artworks to human experiences and feelings
- Help tourists feel the emotion in the art
- Make pieces more meaningful through emotional context
''';
      case NarrationAspect.guidance:
        return '''
Focus on Guidance (引導觀察):
- Teach tourists HOW to look at art
- Example: "Step back three meters and squint your eyes - you'll see how the light and shadow change..."
- Give specific viewing techniques
- Point out details they should notice
- Transform passive looking into active seeing
''';
      case NarrationAspect.context:
        return '''
Focus on Context (策展脈絡):
- Why are these pieces displayed together?
- Explain the curatorial narrative and exhibition theme
- Help visitors understand the bigger picture
- Connect individual pieces to the overall story
- Make the exhibition more coherent and meaningful
''';
      default:
        return _getDefaultGuideline();
    }
  }

  /// 在地美食與夜市類的內容指引
  String _getFoodMarketGuideline(NarrationAspect aspect) {
    switch (aspect) {
      case NarrationAspect.ingredients:
        return '''
Focus on Ingredients (食材與產地):
- Why is the food here so delicious?
- Example: "This beef soup is so fresh and sweet because they use same-day locally slaughtered beef..."
- Explain what makes the ingredients special
- Share sourcing stories and quality details
- Make tourists appreciate what they're about to eat
''';
      case NarrationAspect.etiquette:
        return '''
Focus on Etiquette (正確吃法):
- Show the authentic local way to eat
- Example: "Locals don't drink it straight - first add a bit of vinegar, then eat with this garlic clove..."
- Share insider eating techniques
- Explain the "right" way that enhances the experience
- Help tourists eat like knowledgeable locals
''';
      case NarrationAspect.brandStory:
        return '''
Focus on Brand Story (店家的故事):
- Share the story of family businesses and their dedication
- Example: "This grandmother has been selling here for 50 years. She refuses to raise prices because she wants students to afford a full meal..."
- Tell human stories behind the food
- Create emotional connection to the vendors
- Make the food more meaningful through backstory
''';
      case NarrationAspect.sensory:
        return '''
Focus on Sensory (口感描述):
- Use vivid adjectives to preview flavors and textures
- Example: "The outer skin is so crispy it'll crunch when you bite, and the filling will burst..."
- Build anticipation through sensory language
- Describe texture, taste, aroma, and appearance
- Make mouths water with your descriptions
''';
      default:
        return _getDefaultGuideline();
    }
  }

  /// 預設的內容指引（當面向不匹配景點類型時）
  String _getDefaultGuideline() {
    return '''
Create an engaging narration about this location:
- Start with what the tourist is seeing right now
- Share the most interesting and relevant information
- Use vivid, sensory language
- Make it memorable and engaging
- Keep the tone conversational and enthusiastic
''';
  }
}
