import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/narration/domain/models/story_hook.dart';

/// 導覽 Prompt 建構器
///
/// 以「歷史故事」為單一主軸生成 narration。若提供 [hook]，會以該鉤子
/// 作為敘事起點展開完整故事；若未提供，則自動為景點挑選一條最具吸引力
/// 的歷史線索。
class NarrationPromptBuilder {
  final Place place;
  final StoryHook? hook;
  final String language;

  NarrationPromptBuilder({
    required this.place,
    required this.language,
    this.hook,
  });

  String build() {
    final languageName = language.startsWith('zh') ? '繁體中文' : 'English';
    final hookSection = hook == null
        ? '''
No specific story angle has been chosen. Pick the most evocative real-world
historical thread you can ground for this location and develop it fully.'''
        : '''
The narration MUST develop this specific story thread:
- Hook title: ${hook!.title}
- Opening teaser: ${hook!.teaser}

Treat the teaser as the cliffhanger you are now resolving. Stay on this thread;
do not bounce between unrelated topics.''';

    return '''
You are a master storyteller creating an engaging audio narration for a
location. Your sole focus is HISTORY through the lens of PEOPLE and EVENTS —
not architecture style, not geology, not generic facts.

Location:
- Name: ${place.name}
- Address: ${place.address}
- Category: ${_getCategoryDescription(place.category)}
- Tags: ${place.tags.join(', ')}

Story brief:
$hookSection

Storytelling guidelines:
- Lead with a human moment, not with dates. Dates support the story.
- Name the people involved when known. Give them motivations and feelings.
- Use sensory detail to put the listener in the scene.
- Resolve the teaser by the end — the listener should feel they got "the rest
  of the story".
- If a fact is uncertain, soften it ("legend says", "according to local
  records") rather than fabricating specifics.

Output requirements:
- Language: $languageName
- Length: 800-1200 characters, ~3-5 minutes when read aloud
- Tone: warm, vivid, conversational — like a friend who knows this place
- Do NOT include greetings, intros, or "welcome to..." phrases
- Write flowing paragraphs with clear sentence endings (。！？ or . ! ?)
- No bullet points or lists

Generate the narration now:''';
  }

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
}
