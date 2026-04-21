import 'package:context_app/features/onboarding/domain/demo_narration_factory.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factory = DemoNarrationFactory();

  group('DemoNarrationFactory', () {
    test(
      'given a traditional-chinese locale, when buildContent is called, '
      'then a non-empty narration is returned',
      () {
        final content = factory.buildContent(Language.traditionalChinese);

        expect(content.text.trim(), isNotEmpty);
        expect(content.segments, isNotEmpty);
        expect(content.language, Language.traditionalChinese);
      },
    );

    test(
      'given an english locale, when buildContent is called, '
      'then the english copy is used',
      () {
        final content = factory.buildContent(Language.english);

        expect(content.text, contains('Fushimi Inari'));
        expect(content.language, Language.english);
      },
    );

    test(
      'given buildPlace, then the demo place id matches the factory marker',
      () {
        final place = factory.buildPlace();

        expect(DemoNarrationFactory.isDemoPlace(place.id), isTrue);
      },
    );
  });
}
