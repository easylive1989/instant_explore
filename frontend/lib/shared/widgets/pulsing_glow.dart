import 'package:flutter/material.dart';

/// A radial glow that slowly pulses its opacity and scale.
///
/// Used as an ambient decoration behind foreground art so the dark
/// Midnight Kyoto canvas feels alive instead of static.
class PulsingGlow extends StatefulWidget {
  const PulsingGlow({
    super.key,
    required this.color,
    this.size = 240,
    this.period = const Duration(seconds: 3),
    this.minOpacity = 0.10,
    this.maxOpacity = 0.28,
    this.child,
  });

  final Color color;
  final double size;
  final Duration period;
  final double minOpacity;
  final double maxOpacity;
  final Widget? child;

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final opacity =
            widget.minOpacity + (widget.maxOpacity - widget.minOpacity) * t;
        final scale = 0.92 + 0.08 * t;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.color.withValues(alpha: opacity),
                        widget.color.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
              if (child != null) child,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
