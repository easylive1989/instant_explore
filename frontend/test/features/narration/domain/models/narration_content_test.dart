import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_content_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarrationContent', () {
    group('create', () {
      test('should split text into segments correctly', () {
        const text = '這是第一句。這是第二句。這是第三句。';
        final content = NarrationContent.create(text);

        expect(content.segments.length, 3);
        expect(content.segments[0], '這是第一句。');
        expect(content.segments[1], '這是第二句。');
        expect(content.segments[2], '這是第三句。');
      });

      test('should throw NarrationException for empty text', () {
        const text = '';

        expect(
          () => NarrationContent.create(text),
          throwsA(isA<NarrationContentException>()),
        );
      });

      test('should throw NarrationException for text too short', () {
        const text = '短文';

        expect(
          () => NarrationContent.create(text),
          throwsA(isA<NarrationContentException>()),
        );
      });

      test('should handle single segment', () {
        const text = '這是一句合格的話語。';
        final content = NarrationContent.create(text);

        expect(content.segments.length, 1);
        expect(content.segments[0], '這是一句合格的話語。');
      });

      test('should handle mixed Chinese and English punctuation', () {
        const text = '這是中文句號。This is English. 這是驚嘆號！What is this?';
        final content = NarrationContent.create(text);

        expect(content.segments.length, 4);
        expect(content.segments[0], '這是中文句號。');
        expect(content.segments[1], 'This is English.');
        expect(content.segments[2], '這是驚嘆號！');
        expect(content.segments[3], 'What is this?');
      });

      test('should estimate duration correctly', () {
        const text = '這是一段測試用的文字內容。'; // 13 characters
        final content = NarrationContent.create(
          text,
          language: 'zh-TW',
        ); // charsPerSecond = 4

        expect(content.estimatedDuration, 4); // 13/4 = 3.25 -> ceil = 4
      });
    });

    group('getSegmentIndexByCharPosition', () {
      test('should return correct segment index for normal text', () {
        const text = '這是第一句。這是第二句。這是第三句。';
        final content = NarrationContent.create(text);

        // 第一句：字符 0-5 ("這是第一句。")
        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(1), 0);
        expect(content.getSegmentIndexByCharPosition(5), 0);

        // 第二句：字符 6-11 ("這是第二句。")
        expect(content.getSegmentIndexByCharPosition(6), 1);
        expect(content.getSegmentIndexByCharPosition(7), 1);
        expect(content.getSegmentIndexByCharPosition(11), 1);

        // 第三句：字符 12-17 ("這是第三句。")
        expect(content.getSegmentIndexByCharPosition(12), 2);
        expect(content.getSegmentIndexByCharPosition(13), 2);
        expect(content.getSegmentIndexByCharPosition(17), 2);
      });

      test('should return last segment index for out of range position', () {
        const text = '這是第一句。這是第二句。這是第三句。';
        final content = NarrationContent.create(text);

        // 超出範圍的字符位置應返回最後一個段落
        expect(content.getSegmentIndexByCharPosition(1000), 2);
      });

      test('should return 0 for negative position', () {
        const text = '這是合格的第一句。這是合格的第二句。';
        final content = NarrationContent.create(text);

        // 負數位置應返回第一個段落
        expect(content.getSegmentIndexByCharPosition(-1), 0);
      });

      test('should handle single segment correctly', () {
        const text = '這是一個很長的段落測試。';
        final content = NarrationContent.create(text);

        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(3), 0);
        expect(content.getSegmentIndexByCharPosition(100), 0);
      });

      test('should handle mixed Chinese and English text', () {
        const text = 'Hello世界測試。Testing測試句。';
        final content = NarrationContent.create(text);

        // 第一句：「Hello世界測試。」
        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(9), 0);

        // 第二句：「Testing測試句。」
        expect(content.getSegmentIndexByCharPosition(10), 1);
        expect(content.getSegmentIndexByCharPosition(16), 1);
      });
    });

    group('getCurrentSegmentIndex (deprecated)', () {
      test('should still work for backward compatibility', () {
        const text = '這是第一句。這是第二句。這是第三句。';
        // 使用 language: 'zh-TW' (charsPerSecond = 4)
        // 18 個字符 / 4 字符/秒 = 4.5 秒
        // 3 個段落，每個段落約 1.5 秒
        final content = NarrationContent.create(text, language: 'zh-TW');

        // 基於時間的估算（已棄用）
        // 0 秒：第 0 個段落
        // ignore: deprecated_member_use_from_same_package
        expect(content.getCurrentSegmentIndex(0), 0);

        // 2 秒：第 1 個段落
        // ignore: deprecated_member_use_from_same_package
        expect(content.getCurrentSegmentIndex(2), 1);

        // 4 秒：第 2 個段落
        // ignore: deprecated_member_use_from_same_package
        expect(content.getCurrentSegmentIndex(4), 2);
      });
    });

    group('edge cases', () {
      test('should handle text without punctuation', () {
        const text = 'This is text without punctuation here';
        final content = NarrationContent.create(text);

        // 沒有標點符號，整個文本視為一個段落
        expect(content.segments.length, 1);
        expect(content.segments[0], 'This is text without punctuation here');
      });

      test('should handle consecutive punctuation', () {
        const text = '這是第一句話。。第二句話！！';
        final content = NarrationContent.create(text);

        // 連續標點符號會產生多個段落（部分可能為空）
        expect(content.segments.isNotEmpty, true);
      });

      test('should handle very long text', () {
        final longText = List.generate(100, (i) => '句子$i。').join();
        final content = NarrationContent.create(longText);

        expect(content.segments.length, 100);
        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(
          content.getSegmentIndexByCharPosition(content.text.length - 1),
          99,
        );
      });
    });
  });
}
