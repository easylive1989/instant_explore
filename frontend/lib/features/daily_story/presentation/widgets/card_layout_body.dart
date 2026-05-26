import 'package:cached_network_image/cached_network_image.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// IG-card-style detail body for a daily story.
///
/// Mirrors the visual structure of the Instagram card (photo plate +
/// text plate) without being a pixel-perfect clone. Decorative fields
/// (spine, Anno year, pull quote, city footer extras) gracefully omit
/// when null; the layout never collapses to a broken state.
///
/// Caller must guarantee `story.hasCardLayout == true`.
class CardLayoutBody extends StatelessWidget {
  final DailyStory story;
  const CardLayoutBody({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhotoPlate(story: story),
          _TextPlate(story: story),
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
    return AspectRatio(
      aspectRatio: 3 / 4,
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
          // Tint overlay so light photos still show white text.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0x99000000)],
              ),
            ),
          ),
          if (story.cardLocationEn != null)
            Positioned(
              left: 20,
              bottom: 160,
              child: _SpineLabel(text: story.cardLocationEn!),
            ),
          if (story.cardAnnoRoman != null)
            Positioned(
              top: 20,
              right: 20,
              child: _AnnoBadge(roman: story.cardAnnoRoman!),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.cardTitle!,
                  style: GoogleFonts.notoSerifTc(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  story.cardTitleSub!,
                  style: GoogleFonts.notoSerifTc(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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

class _SpineLabel extends StatelessWidget {
  final String text;
  const _SpineLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        letterSpacing: 3,
        fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70, width: 0.8),
      ),
      child: Text(
        'Anno · $roman',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _TextPlate extends StatelessWidget {
  final DailyStory story;
  const _TextPlate({required this.story});

  @override
  Widget build(BuildContext context) {
    final paragraphs = story.cardParagraphs!;
    return Container(
      color: const Color(0xFFFAF7F1),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            if (i == 0)
              _DropCapParagraph(text: paragraphs[i])
            else
              _BodyParagraph(text: paragraphs[i]),
          ],
          if (story.cardPullQuote != null) ...[
            const SizedBox(height: 28),
            _PullQuote(
              quote: story.cardPullQuote!,
              attrib: story.cardPullQuoteAttrib,
            ),
          ],
          const SizedBox(height: 32),
          _Footer(story: story),
        ],
      ),
    );
  }
}

class _DropCapParagraph extends StatelessWidget {
  final String text;
  const _DropCapParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return _BodyParagraph(text: text);
    final first = text.substring(0, 1);
    final rest = text.substring(1);
    return RichText(
      text: TextSpan(
        style: GoogleFonts.notoSerifTc(
          color: const Color(0xFF1B1B1B),
          fontSize: 16,
          height: 1.8,
        ),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                first,
                style: GoogleFonts.notoSerifTc(
                  color: const Color(0xFF1B1B1B),
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
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
    return Text(
      text,
      style: GoogleFonts.notoSerifTc(
        color: const Color(0xFF1B1B1B),
        fontSize: 16,
        height: 1.8,
      ),
    );
  }
}

class _PullQuote extends StatelessWidget {
  final String quote;
  final String? attrib;
  const _PullQuote({required this.quote, required this.attrib});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF8B6F3E), width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote,
              style: GoogleFonts.notoSerifTc(
                color: const Color(0xFF1B1B1B),
                fontSize: 16,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
            if (attrib != null) ...[
              const SizedBox(height: 6),
              Text(
                attrib!,
                style: GoogleFonts.notoSerifTc(
                  color: const Color(0xFF6B5C42),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
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
    return Text(
      text,
      style: GoogleFonts.notoSerifTc(
        color: const Color(0xFF6B5C42),
        fontSize: 12,
        letterSpacing: 0.6,
      ),
    );
  }
}
