import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('story share i18n keys', () {
    for (final locale in const ['en', 'zh-TW']) {
      test('given $locale translations, then share_card.story_share_text '
          'is a non-empty string', () {
        final json = jsonDecode(
          File('assets/translations/$locale.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final shareCard = json['share_card'] as Map<String, dynamic>;
        final value = shareCard['story_share_text'];
        expect(value, isA<String>());
        expect((value as String).trim(), isNotEmpty);
      });
    }
  });
}
