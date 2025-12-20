import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/narration/domain/models/narration_content_exception.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarrationContent', () {
    group('create', () {
      test('should split text into segments correctly', () {
        const text = '這是第一句。這是第二句。這是第三句。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.segments.length, 3);
        expect(content.segments[0], '這是第一句。');
        expect(content.segments[1], '這是第二句。');
        expect(content.segments[2], '這是第三句。');
      });

      test('should throw NarrationContentException for empty text', () {
        const text = '';

        expect(
          () => NarrationContent.create(
            text,
            language: Language.traditionalChinese,
          ),
          throwsA(isA<NarrationContentException>()),
        );
      });

      test('should throw NarrationContentException for text too short', () {
        const text = '短文';

        expect(
          () => NarrationContent.create(
            text,
            language: Language.traditionalChinese,
          ),
          throwsA(isA<NarrationContentException>()),
        );
      });

      test('should handle single segment', () {
        const text = '這是一句合格的話語。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.segments.length, 1);
        expect(content.segments[0], '這是一句合格的話語。');
      });

      test('should handle mixed Chinese and English punctuation', () {
        const text = '這是中文句號。This is English. 這是驚嘆號！What is this?';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.segments.length, 4);
        expect(content.segments[0], '這是中文句號。');
        expect(content.segments[1], 'This is English.');
        expect(content.segments[2], '這是驚嘆號！');
        expect(content.segments[3], 'What is this?');
      });

      test('should set language correctly', () {
        const text = '這是一段測試用的文字內容。';
        final content = NarrationContent.create(
          text,
          language: Language.english,
        );

        expect(content.language, Language.english);
      });
    });

    group('getSegmentIndexByCharPosition', () {
      test('should return correct segment index for normal text', () {
        const text = '這是第一句。這是第二句。這是第三句。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

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
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        // 超出範圍的字符位置應返回最後一個段落
        expect(content.getSegmentIndexByCharPosition(1000), 2);
      });

      test('should return 0 for negative position', () {
        const text = '這是合格的第一句。這是合格的第二句。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        // 負數位置應返回第一個段落
        expect(content.getSegmentIndexByCharPosition(-1), 0);
      });

      test('should handle single segment correctly', () {
        const text = '這是一個很長的段落測試。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(3), 0);
        expect(content.getSegmentIndexByCharPosition(100), 0);
      });

      test('should handle mixed Chinese and English text', () {
        const text = 'Hello世界測試。Testing測試句。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        // 第一句：「Hello世界測試。」
        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(content.getSegmentIndexByCharPosition(9), 0);

        // 第二句：「Testing測試句。」
        expect(content.getSegmentIndexByCharPosition(10), 1);
        expect(content.getSegmentIndexByCharPosition(16), 1);
      });
    });

    group('edge cases', () {
      test('should handle text without punctuation', () {
        const text = 'This is text without punctuation here';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        // 沒有標點符號，整個文本視為一個段落
        expect(content.segments.length, 1);
        expect(content.segments[0], 'This is text without punctuation here');
      });

      test('should handle consecutive punctuation', () {
        const text = '這是第一句話。。第二句話！！';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        // 連續標點符號會產生多個段落（部分可能為空）
        expect(content.segments.isNotEmpty, true);
      });

      test('should handle very long text', () {
        final longText = List.generate(100, (i) => '句子$i。').join();
        final content = NarrationContent.create(
          longText,
          language: Language.traditionalChinese,
        );

        expect(content.segments.length, 100);
        expect(content.getSegmentIndexByCharPosition(0), 0);
        expect(
          content.getSegmentIndexByCharPosition(content.text.length - 1),
          99,
        );
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        const text = '這是一段測試用的文字內容。';
        final content = NarrationContent.create(
          text,
          language: Language.traditionalChinese,
        );

        final json = content.toJson();

        expect(json['text'], text);
        expect(json['segments'], ['這是一段測試用的文字內容。']);
        expect(json['language'], 'zh-TW');
        expect(json.containsKey('estimated_duration'), false);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'text': '這是一段測試用的文字內容。',
          'segments': ['這是一段測試用的文字內容。'],
          'language': 'zh-TW',
        };

        final content = NarrationContent.fromJson(json);

        expect(content.text, '這是一段測試用的文字內容。');
        expect(content.segments, ['這是一段測試用的文字內容。']);
        expect(content.language, Language.traditionalChinese);
      });
    });
  });
}
