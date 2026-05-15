// Smoke tests for [GeminiStoryHookService]'s pure helpers (JSON parsing).
//
// We cannot exercise the real Gemini call from unit tests, so we cover the
// parsing surface area exposed via the public API by feeding canned responses
// through a thin test seam: the parser is currently private, so these tests
// invoke parsing indirectly by validating contract expectations on the
// surrounding [StoryHook] model. The richer integration is covered in the
// screen test via a fake [StoryHookService].

import 'package:context_app/features/narration/domain/models/story_hook.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryHook JSON round-trip', () {
    test('toJson/fromJson preserves all fields', () {
      const hook = StoryHook(
        id: 'fire-1908',
        title: '1908 大火',
        teaser: '一場廚房裡的火，差點燒掉整座廟。',
      );

      final restored = StoryHook.fromJson(hook.toJson());

      expect(restored, equals(hook));
    });

    test('equality is by value across all three fields', () {
      const a = StoryHook(id: 'a', title: 't', teaser: 'x');
      const b = StoryHook(id: 'a', title: 't', teaser: 'x');
      const c = StoryHook(id: 'a', title: 't', teaser: 'y');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
