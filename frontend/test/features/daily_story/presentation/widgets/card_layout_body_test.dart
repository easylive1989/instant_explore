import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/widgets/card_layout_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

DailyStory _fullCardStory({
  String? cardLocationEn = 'COLOSSEUM',
  String? cardCityCh = '羅馬',
  String? cardCityEn = 'Rome',
  String? cardPullQuote = '「他們將死之人向您致敬」',
  String? cardAnnoRoman = 'LXXX',
}) {
  return DailyStory(
    publishDate: DateTime(2026, 5, 25),
    language: 'zh-TW',
    placeName: '羅馬競技場',
    placeLocation: '義大利羅馬',
    era: '公元 70-80 年',
    story: 'p1\n\np2\n\np3',
    imageUrl: null,
    wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
    cardTitle: '血腥的盛宴',
    cardTitleSub: '從石灰岩堆砌的命運舞台',
    cardParagraphs: const [
      '維斯帕先在西元七十年下令...',
      '工匠們夜以繼日地堆砌...',
      '今日的競技場斷垣殘壁...',
    ],
    cardPullQuote: cardPullQuote,
    cardPullQuoteAttrib: '── 蘇埃托尼烏斯，西元 121 年',
    cardAnnoRoman: cardAnnoRoman,
    cardLocationEn: cardLocationEn,
    cardCityCh: cardCityCh,
    cardCityEn: cardCityEn,
  );
}

Future<void> _pump(WidgetTester tester, DailyStory story) async {
  await pumpScreen(
    tester,
    child: Scaffold(body: CardLayoutBody(story: story)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('CardLayoutBody', () {
    testWidgets(
      'given full card data, '
      'when rendered, '
      'then title, subtitle, all paragraphs, pull quote, and anno roman are visible',
      (tester) async {
        await _pump(tester, _fullCardStory());

        expect(find.text('血腥的盛宴'), findsOneWidget);
        expect(find.text('從石灰岩堆砌的命運舞台'), findsOneWidget);
        // First paragraph is rendered as a RichText with a drop-cap
        // WidgetSpan ('維') and a TextSpan holding the remainder.
        // find.textContaining only walks Text widgets, so assert the
        // drop-cap and the rest via predicates against RichText.
        expect(find.text('維'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('斯帕先在西元七十年'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('工匠們夜以繼日'), findsOneWidget);
        expect(find.textContaining('今日的競技場'), findsOneWidget);
        expect(find.text('「他們將死之人向您致敬」'), findsOneWidget);
        expect(find.text('── 蘇埃托尼烏斯，西元 121 年'), findsOneWidget);
        expect(find.textContaining('LXXX'), findsOneWidget);
        expect(find.textContaining('COLOSSEUM'), findsOneWidget);
      },
    );

    testWidgets(
      'given pull quote is null, '
      'when rendered, '
      'then no quote block appears',
      (tester) async {
        await _pump(tester, _fullCardStory(cardPullQuote: null));
        expect(find.textContaining('將死之人'), findsNothing);
        expect(find.textContaining('蘇埃托尼烏斯'), findsNothing);
      },
    );

    testWidgets(
      'given cardLocationEn is null, '
      'when rendered, '
      'then the spine is omitted',
      (tester) async {
        await _pump(tester, _fullCardStory(cardLocationEn: null));
        expect(find.text('COLOSSEUM'), findsNothing);
      },
    );

    testWidgets(
      'given cardAnnoRoman is null, '
      'when rendered, '
      'then the Anno block is omitted',
      (tester) async {
        await _pump(tester, _fullCardStory(cardAnnoRoman: null));
        expect(find.textContaining('Anno'), findsNothing);
      },
    );

    testWidgets(
      'given both city fields are null, '
      'when rendered, '
      'then footer shows only the place location',
      (tester) async {
        await _pump(
          tester,
          _fullCardStory(cardCityCh: null, cardCityEn: null),
        );
        expect(find.text('義大利羅馬'), findsOneWidget);
        expect(find.textContaining('羅馬 Rome'), findsNothing);
      },
    );

    testWidgets(
      'given both city fields are present, '
      'when rendered, '
      'then footer shows place location + cardCityCh + cardCityEn',
      (tester) async {
        await _pump(tester, _fullCardStory());
        expect(find.text('義大利羅馬 · 羅馬 Rome'), findsOneWidget);
      },
    );

    testWidgets(
      'given only cardCityEn is null, '
      'when rendered, '
      'then footer shows place location + cardCityCh',
      (tester) async {
        await _pump(tester, _fullCardStory(cardCityEn: null));
        expect(find.text('義大利羅馬 · 羅馬'), findsOneWidget);
      },
    );
  });
}
