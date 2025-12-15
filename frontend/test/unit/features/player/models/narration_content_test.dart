import 'package:context_app/features/narration/models/narration_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarrationContent', () {
    group('fromText', () {
      test('should split text into segments correctly', () {
        const text = '第一句。第二句。第三句。';
        final content = NarrationContent.fromText(text);

        expect(content.segments.length, 3);
        expect(content.segments[0], '第一句。');
        expect(content.segments[1], '第二句。');
        expect(content.segments[2], '第三句。');
      });

      test('should handle empty text', () {
        const text = '';
        final content = NarrationContent.fromText(text);

        expect(content.segments, isEmpty);
        expect(content.text, '');
        expect(content.estimatedDuration, 0);
      });

      test('should handle single segment', () {
        const text = '這是一句話。';
        final content = NarrationContent.fromText(text);

        expect(content.segments.length, 1);
        expect(content.segments[0], '這是一句話。');
      });

      test('should handle mixed Chinese and English punctuation', () {
        const text = '中文句號。English period. 驚嘆號！Question?';
        final content = NarrationContent.fromText(text);

        expect(content.segments.length, 4);
        expect(content.segments[0], '中文句號。');
        expect(content.segments[1], 'English period.');
        expect(content.segments[2], '驚嘆號！');
        expect(content.segments[3], 'Question?');
      });

      test('should estimate duration correctly', () {
        const text = '12345'; // 5 characters
        final content = NarrationContent.fromText(text, language: 'zh-TW'); // charsPerSecond = 4

        expect(content.estimatedDuration, 2); // 5/4 = 1.25 -> ceil = 2
      });
    });

    group('getSegmentIndexByCharPosition', () {
      test('should return correct segment index for normal text', () {
        const text = '第一句。第二句。第三句。';
        final content = NarrationContent.fromText(text);

        // 第一句：字符 0-3 ("第一句。")
        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(1), 0);
        expect(content.getSegmentIndexByCharPosition(3), 0);

        // 第二句：字符 4-7 ("第二句。")
        expect(content.getSegmentIndexByCharPosition(4), 1);
        expect(content.getSegmentIndexByCharPosition(5), 1);
        expect(content.getSegmentIndexByCharPosition(7), 1);

        // 第三句：字符 8-11 ("第三句。")
        expect(content.getSegmentIndexByCharPosition(8), 2);
        expect(content.getSegmentIndexByCharPosition(9), 2);
        expect(content.getSegmentIndexByCharPosition(11), 2);
      });

      test('should return 0 for empty text', () {
        const text = '';
        final content = NarrationContent.fromText(text);

        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(100), 0);
      });

      test('should return last segment index for out of range position', () {
        const text = '第一句。第二句。第三句。';
        final content = NarrationContent.fromText(text);

        // 超出範圍的字符位置應返回最後一個段落
        expect(content.getSegmentIndexByCharPosition(1000), 2);
      });

      test('should return 0 for negative position', () {
        const text = '第一句。第二句。';
        final content = NarrationContent.fromText(text);

        // 負數位置應返回第一個段落
        expect(content.getSegmentIndexByCharPosition(-1), 0);
      });

      test('should handle single segment correctly', () {
        const text = '這是一句話。';
        final content = NarrationContent.fromText(text);

        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(3), 0);
        expect(content.getSegmentIndexByCharPosition(100), 0);
      });

      test('should handle mixed Chinese and English text', () {
        const text = 'Hello世界。Testing測試。';
        final content = NarrationContent.fromText(text);

        // 第一句："Hello世界。" (8 characters: H-e-l-l-o-世-界-。)
        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(7), 0);

        // 第二句："Testing測試。" (starts at position 8)
        expect(content.getSegmentIndexByCharPosition(8), 1);
        expect(content.getSegmentIndexByCharPosition(15), 1);
      });
    });

    group('getCurrentSegmentIndex (deprecated)', () {
      test('should still work for backward compatibility', () {
        const text = '第一句。第二句。第三句。';
        // 使用 language: 'zh-TW' (charsPerSecond = 4)
        // 12 個字符 / 4 字符/秒 = 3 秒
        // 3 個段落，每個段落 1 秒
        final content = NarrationContent.fromText(text, language: 'zh-TW');

        // 基於時間的估算（已棄用）
        // 0 秒：第 0 個段落
        // ignore: deprecated_member_use_from_same_package
        expect(content.getCurrentSegmentIndex(0), 0);

        // 1 秒：第 1 個段落
        // ignore: deprecated_member_use_from_same_package
        expect(content.getCurrentSegmentIndex(1), 1);

        // 2 秒：第 2 個段落
        // ignore: deprecated_member_use_from_same_package
        expect(content.getCurrentSegmentIndex(2), 2);
      });
    });

    group('edge cases', () {
      test('should handle text with only punctuation', () {
        const text = '。！？';
        final content = NarrationContent.fromText(text);

        // 每個標點符號應該被視為一個段落
        expect(content.segments.length, 3);
      });

      test('should handle text without punctuation', () {
        const text = 'No punctuation here';
        final content = NarrationContent.fromText(text);

        // 沒有標點符號，整個文本視為一個段落
        expect(content.segments.length, 1);
        expect(content.segments[0], 'No punctuation here');
      });

      test('should handle consecutive punctuation', () {
        const text = '第一句。。第二句！！';
        final content = NarrationContent.fromText(text);

        // 連續標點符號會產生多個段落（部分可能為空）
        expect(content.segments.isNotEmpty, true);
      });

      test('should handle very long text', () {
        final longText = List.generate(100, (i) => '句子$i。').join();
        final content = NarrationContent.fromText(longText);

        expect(content.segments.length, 100);
        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(content.text.length - 1),
            99);
      });
    });
  });
}
