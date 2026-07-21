import 'package:context_app/app/config/lorescape_tokens.dart';
import 'package:flutter/material.dart';

/// 頁面主標，對應設計稿的 `.masthead`：一段短橫線＋全大寫眼眉字，
/// 底下壓襯線大標，最後一條細分隔線（左端有一小段 clay 色）。
class Masthead extends StatelessWidget {
  const Masthead({
    super.key,
    required this.eyebrow,
    required this.title,
    this.actions,
  });

  final String eyebrow;
  final String title;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<LorescapeTokens>();
    final colorScheme = Theme.of(context).colorScheme;
    final clay = tokens?.clay ?? colorScheme.primary;
    final line = tokens?.line ?? colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 1.5,
                          decoration: BoxDecoration(
                            color: clay,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            eyebrow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.3,
                              color: clay,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 37,
                        height: 0.98,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: actions,
                ),
            ],
          ),
          const SizedBox(height: 16),
          // 細分隔線，左端 46px 換成 clay 色（設計稿的 `.masthead__rule::before`）。
          SizedBox(
            height: 1,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: line)),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 46,
                  child: ColoredBox(color: clay),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
