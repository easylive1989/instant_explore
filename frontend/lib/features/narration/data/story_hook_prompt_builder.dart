import 'package:context_app/features/explore/domain/models/place.dart';

/// 建構「故事鉤子」prompt。
///
/// 要求 Gemini 以景點為主題，產生 2-3 個各自獨立的歷史故事切入點，
/// 並以嚴格 JSON 格式回傳，方便端側解析。
class StoryHookPromptBuilder {
  final Place place;
  final String language;

  StoryHookPromptBuilder({required this.place, required this.language});

  String build() {
    final languageName = language.startsWith('zh') ? '繁體中文' : 'English';
    return '''
You are a storyteller researching historical narratives for a specific location.

Location:
- Name: ${place.name}
- Address: ${place.address}
- Tags: ${place.tags.join(', ')}

Task:
Produce 2 to 3 DISTINCT story hooks rooted in this location's history. Each hook
must focus on PEOPLE, events, or moments — not on architecture style, geology,
or generic descriptions. Hooks should make the reader want to hear more.

Each hook contains:
- "id": a short slug (e.g., "great-fire-1908")
- "title": a punchy 6-14 character title in $languageName
- "teaser": a one-sentence cliffhanger (max 40 characters in $languageName)
  that opens the story but does NOT resolve it.

Constraints:
- Hooks must be different angles — do not repeat the same event with different
  wording.
- Write the title and teaser in $languageName.
- Do NOT include greetings or meta commentary.
- If you cannot ground at least 2 distinct historical angles for this place,
  return an empty array.

Output format:
Return ONLY a JSON array, no markdown fences, no prose before or after:
[
  {"id": "...", "title": "...", "teaser": "..."},
  {"id": "...", "title": "...", "teaser": "..."}
]
''';
  }
}
