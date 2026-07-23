import 'package:flutter/material.dart';

/// 書架上的一本「旅程」。
@immutable
class ShelfBook {
  const ShelfBook({
    required this.title,
    required this.subtitle,
    required this.hasEntries,
    required this.onTap,
  });

  final String title;
  final String subtitle;

  /// 有沒有內容，決定書背上的小圖示（有內容＝書，空的＝無影像）。
  final bool hasEntries;
  final VoidCallback onTap;
}

/// 旅程書架，對應設計稿的 `.bookshelf`：凹槽背板 ＋ 一排立著的書 ＋ 木層板。
///
/// 書本高度刻意不齊（190 / 204 / 218 循環），跟設計稿一樣，避免看起來像
/// 一排等高的色塊。
class TripBookshelf extends StatelessWidget {
  const TripBookshelf({super.key, required this.books, required this.caption});

  final List<ShelfBook> books;

  /// 書架上方的小標，例如「旅程書架 · 3 本」。
  final String caption;

  static const List<double> _heights = [190, 204, 218];
  static const double _rowMinHeight = 214;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              caption,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.76,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Stack(
              children: [
                // 凹槽背板：比書矮一截（底部留 14），讓層板壓在前面。
                Positioned.fill(
                  bottom: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFEFE3CA), Color(0xFFE3D3B4)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                        bottom: Radius.circular(3),
                      ),
                      border: Border.all(color: const Color(0x24977850)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: _rowMinHeight,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < books.length; i++) ...[
                                if (i > 0) const SizedBox(width: 11),
                                _Book(
                                  book: books[i],
                                  height: _heights[i % _heights.length],
                                  palette: _BookPalette.values[i % 4],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const _ShelfPlank(),
                    ],
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

/// 四種書皮配色，對應設計稿的 `.book--a` ～ `.book--d`。
enum _BookPalette {
  a(Color(0xFF7A3320), Color(0xFF9C4F37)),
  c(Color(0xFF524E34), Color(0xFF706A45)),
  b(Color(0xFF332B25), Color(0xFF4F4033)),
  d(Color(0xFF654529), Color(0xFF856541));

  const _BookPalette(this.left, this.right);

  final Color left;
  final Color right;
}

class _Book extends StatelessWidget {
  const _Book({
    required this.book,
    required this.height,
    required this.palette,
  });

  final ShelfBook book;
  final double height;
  final _BookPalette palette;

  static const double _width = 60;
  static const Color _gilt = Color(0xFFF6E6C2);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${book.title}｜${book.subtitle}',
      child: GestureDetector(
        onTap: book.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: _width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [palette.left, palette.right]),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(2),
              right: Radius.circular(7),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x6B1C140A),
                offset: Offset(-5, 9),
                blurRadius: 17,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 書口：頂端一條奶油色，模擬書頁疊起來的斷面。
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 4,
                  child: ColoredBox(color: Color(0xBFF7EED6)),
                ),
              ),
              // 書脊右側的暗面，做出圓弧感。
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x4DFFFFFF),
                        Color(0x00000000),
                        Color(0x73000000),
                      ],
                      stops: [0, 0.35, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 17,
                left: 0,
                right: 0,
                child: Icon(
                  book.hasEntries
                      ? Icons.menu_book_outlined
                      : Icons.image_not_supported_outlined,
                  size: 13,
                  color: const Color(0xEBFFEECE),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 12,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x57FFE8C4)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    // 書名一律畫在框線內：實機 iOS 上曾出現字影跑到框外、
                    // 落在書脊左緣的鬼影字，這層 clip 是最後一道保險。
                    child: ClipRect(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        child: _VerticalTitle(text: book.title),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Text(
                  book.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    color: Color(0xB8FFEBC8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 直排書名。
///
/// CJK 的 `writing-mode: vertical-rl` 是「字元直立堆疊」而不是把整行轉 90°，
/// 所以這裡逐字堆疊，而不是用 `RotatedBox`——後者會讓中文躺著，完全不對。
///
/// 每個字各自是一個單行 `Text`，而不是把字用 `\n` 接成一個多行 paragraph：
/// 多行版本在實機 iOS 上會有某一行的字影被畫到框線左外側（偏移量剛好等於一個
/// 行高），變成書脊上的鬼影字。單行 paragraph 沒有跨行版面，結構上不可能發生。
class _VerticalTitle extends StatelessWidget {
  const _VerticalTitle({required this.text});

  final String text;

  /// 對應設計稿 `max-height:132px`：超出的字捨去，避免長名字把書撐爛。
  static const int _maxCharacters = 7;

  static const TextStyle _style = TextStyle(
    fontSize: 15,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: _Book._gilt,
    shadows: [
      Shadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 1),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final characters = text.characters.toList();
    final visible = characters.length > _maxCharacters
        ? [...characters.take(_maxCharacters - 1), '…']
        : characters;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final character in visible)
          Text(character, textAlign: TextAlign.center, style: _style),
      ],
    );
  }
}

/// 木層板（`.shelf__plank`）：橫向細紋＋前緣厚度。
class _ShelfPlank extends StatelessWidget {
  const _ShelfPlank();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFCFA670), Color(0xFFBB9058), Color(0xFFA2794A)],
              stops: [0, 0.55, 1],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x571C140A),
                offset: Offset(0, 16),
                blurRadius: 22,
              ),
            ],
          ),
        ),
        // 前緣：讓層板看起來有厚度而不是一條色帶。
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            height: 7,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF9A7343), Color(0xFF835F38)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }
}
