import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/daily_story/presentation/widgets/card_reader_theme.dart';
import 'package:context_app/features/daily_story/presentation/widgets/more_stories_cta.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Editorial reader body for a daily story.
///
/// Mirrors the design's `ReaderView` (`screens_story.jsx` + `ls2.css`): a
/// 300px dark photo hero with a chapter badge, latin overline, title and
/// italic sub, followed by a warm "paper" article body with a clay drop cap,
/// optional pull quote, a divided footer and an optional "explore more" CTA.
/// Decorative fields (latin, Anno, pull quote, city footer) omit gracefully
/// when null.
///
/// Caller must guarantee `story.hasCardLayout == true`.
class CardLayoutBody extends StatelessWidget {
  final DailyStory story;

  /// When set, a "探索更多故事" CTA is rendered at the bottom of the story.
  final VoidCallback? onExploreMore;

  const CardLayoutBody({super.key, required this.story, this.onExploreMore});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhotoPlate(story: story),
          _TextPlate(story: story, onExploreMore: onExploreMore),
        ],
      ),
    );
  }
}

class _PhotoPlate extends StatelessWidget {
  final DailyStory story;
  const _PhotoPlate({required this.story});

  @override
  Widget build(BuildContext context) {
    final imageUrl = story.imageUrl;
    final latin = story.cardLocationEn;
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.black54),
            )
          else
            Container(color: Colors.black87),
          // Editorial scrim: subtle top vignette deepening to the caption.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(15, 11, 7, 0.28),
                  Color.fromRGBO(15, 11, 7, 0.0),
                  Color.fromRGBO(15, 11, 7, 0.55),
                  Color.fromRGBO(15, 11, 7, 0.92),
                ],
                stops: [0.0, 0.28, 0.78, 1.0],
              ),
            ),
          ),
          if (story.cardAnnoRoman != null)
            Positioned(
              top: 16,
              right: 16,
              child: _AnnoBadge(roman: story.cardAnnoRoman!),
            ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (latin != null) ...[
                  Text(
                    latin.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xD1FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  story.cardTitle!,
                  style: GoogleFonts.notoSerifTc(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 2),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  story.cardTitleSub!,
                  style: GoogleFonts.notoSerifTc(
                    color: const Color(0xE6FFFFFF),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnoBadge extends StatelessWidget {
  final String roman;
  const _AnnoBadge({required this.roman});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x8CFFFFFF)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Anno · $roman',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.9,
        ),
      ),
    );
  }
}

class _TextPlate extends StatelessWidget {
  final DailyStory story;
  final VoidCallback? onExploreMore;
  const _TextPlate({required this.story, this.onExploreMore});

  @override
  Widget build(BuildContext context) {
    final paragraphs = story.cardParagraphs!;
    return Container(
      color: CardReaderTheme.readBg,
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 20),
            if (i == 0)
              _DropCapParagraph(text: paragraphs[i])
            else
              _BodyParagraph(text: paragraphs[i]),
          ],
          if (story.cardPullQuote != null) ...[
            const SizedBox(height: 30),
            _PullQuote(
              quote: story.cardPullQuote!,
              attrib: story.cardPullQuoteAttrib,
            ),
          ],
          const SizedBox(height: 34),
          _Footer(story: story),
          if (story.imageAttribution != null) ...[
            const SizedBox(height: 10),
            _PhotoCredit(text: story.imageAttribution!),
          ],
          if (onExploreMore != null) ...[
            const SizedBox(height: 28),
            MoreStoriesCta(
              onTap: onExploreMore!,
              accentColor: CardReaderTheme.clay,
              onAccentColor: const Color(0xFFFBEFE7),
              eyebrowColor: CardReaderTheme.readCap,
            ),
          ],
        ],
      ),
    );
  }
}

/// Body text style shared by the lede and following paragraphs.
TextStyle _bodyStyle() => GoogleFonts.notoSerifTc(
  color: CardReaderTheme.readInk,
  fontSize: 18.5,
  height: 1.92,
);

class _DropCapParagraph extends StatelessWidget {
  final String text;
  const _DropCapParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return _BodyParagraph(text: text);
    final first = text.characters.first;
    final rest = text.characters.skip(1).toString();
    return RichText(
      text: TextSpan(
        style: _bodyStyle(),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: Text(
                first,
                style: GoogleFonts.notoSerifTc(
                  color: CardReaderTheme.readCap,
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          TextSpan(text: rest),
        ],
      ),
    );
  }
}

class _BodyParagraph extends StatelessWidget {
  final String text;
  const _BodyParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: _bodyStyle());
  }
}

class _PullQuote extends StatelessWidget {
  final String quote;
  final String? attrib;
  const _PullQuote({required this.quote, required this.attrib});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: CardReaderTheme.clay, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 4, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote,
            style: GoogleFonts.notoSerifTc(
              color: CardReaderTheme.readInk,
              fontSize: 21,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          if (attrib != null) ...[
            const SizedBox(height: 12),
            Text(
              attrib!,
              style: GoogleFonts.notoSerifTc(
                color: CardReaderTheme.readDim,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final DailyStory story;
  const _Footer({required this.story});

  @override
  Widget build(BuildContext context) {
    final cityCh = story.cardCityCh;
    final cityEn = story.cardCityEn;
    final cityPart = [
      if (cityCh != null) cityCh,
      if (cityEn != null) cityEn,
    ].join(' ');
    final text = cityPart.isEmpty
        ? story.placeLocation
        : '${story.placeLocation} · $cityPart';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CardReaderTheme.readLine)),
      ),
      child: Text(
        text,
        style: GoogleFonts.notoSerifTc(
          color: CardReaderTheme.readDim,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Small image credit line (author / licence / source) shown under the
/// article so commercially-licensed photos are attributed.
class _PhotoCredit extends StatelessWidget {
  final String text;
  const _PhotoCredit({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      '📷 $text',
      style: GoogleFonts.notoSerifTc(
        color: CardReaderTheme.readDim,
        fontSize: 12,
        height: 1.4,
      ),
    );
  }
}
