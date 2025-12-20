import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_content_exception.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarrationContent', () {
    group('create - 文本分段邏輯', () {
      test('should split text into segments by punctuation', () {
        const text = '這是第一句。這是第二句。這是第三句。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.segments.length, 3);
        expect(content.segments[0].text, '這是第一句。');
        expect(content.segments[1].text, '這是第二句。');
        expect(content.segments[2].text, '這是第三句。');
      });

      test('should handle mixed Chinese and English punctuation', () {
        const text = '這是中文句號。This is English. 這是驚嘆號！What is this?';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.segments.length, 4);
        expect(content.segments[0].text, '這是中文句號。');
        expect(content.segments[1].text, 'This is English.');
        expect(content.segments[2].text, '這是驚嘆號！');
        expect(content.segments[3].text, 'What is this?');
      });

      test('should treat text without punctuation as single segment', () {
        const text = 'This is text without punctuation here';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.segments.length, 1);
        expect(
          content.segments[0].text,
          'This is text without punctuation here',
        );
      });

      test('should calculate correct position ranges for segments', () {
        const text = '這是第一句話。這是第二句話。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.segments.length, 2);
        expect(content.segments[0].startPosition, 0);
        expect(content.segments[0].endPosition, 7);
        expect(content.segments[1].startPosition, 7);
        expect(content.segments[1].endPosition, 14);
      });
    });

    group('create - 驗證邏輯', () {
      test('should throw exception for empty text', () {
        expect(
          () => NarrationContent.create(
            '',
            language: Language.traditionalChinese,
          ),
          throwsA(isA<NarrationContentException>()),
        );
      });

      test('should throw exception for text shorter than 10 characters', () {
        expect(
          () => NarrationContent.create(
            '短文',
            language: Language.traditionalChinese,
          ),
          throwsA(isA<NarrationContentException>()),
        );
      });

      test('should accept text with exactly 10 characters', () {
        const text = '這是十個字的文本內。'; // 10 個字符
        expect(text.length, 10);

        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.segments.isNotEmpty, true);
      });
    });

    group('getSegmentIndexByCharPosition - 字符位置查找邏輯', () {
      test('should return correct segment index for positions within text', () {
        const text = '這是第一句。這是第二句。這是第三句。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        // 第一句範圍內
        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(5), 0);

        // 第二句範圍內
        expect(content.getSegmentIndexByCharPosition(6), 1);
        expect(content.getSegmentIndexByCharPosition(11), 1);

        // 第三句範圍內
        expect(content.getSegmentIndexByCharPosition(12), 2);
        expect(content.getSegmentIndexByCharPosition(17), 2);
      });

      test('should return last segment index for out of range position', () {
        const text = '這是第一句。這是第二句。這是第三句。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.getSegmentIndexByCharPosition(1000), 2);
      });

      test('should return 0 for negative position', () {
        const text = '這是合格的第一句。這是合格的第二句。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.getSegmentIndexByCharPosition(-1), 0);
      });

      test('should handle single segment correctly', () {
        const text = '這是一個很長的段落測試。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(100), 0);
      });
    });
  });
}
