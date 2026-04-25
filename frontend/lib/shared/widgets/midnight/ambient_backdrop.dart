import 'package:context_app/app/config/app_colors.dart';
import 'package:flutter/material.dart';

/// Atmospheric backdrop that runs behind the entire app.
///
/// Layers (bottom → top):
/// 1. Solid [AppColors.backgroundDark] base.
/// 2. Optional [decorationImage] (mix-blend overlay) for texture.
/// 3. Vertical gradient wash (dark → transparent → dark) to ensure
///    text legibility at the top/bottom edges.
/// 4. A slow electric-blue pulse halo near the top, hinting at the
///    "Neon Nocturne" vision.
/// 5. The provided [child] on top.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({super.key, required this.child, this.decorationImage});

  final Widget child;
  final DecorationImage? decorationImage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.backgroundDark),
        if (decorationImage != null)
          DecoratedBox(decoration: BoxDecoration(image: decorationImage)),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundDark,
                Colors.transparent,
                AppColors.backgroundDark,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        const _PulseHalo(),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _PulseHalo extends StatefulWidget {
  const _PulseHalo();

  @override
  State<_PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<_PulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.18,
      end: 0.32,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, _) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.85),
                radius: 1.1,
                colors: [
                  AppColors.primary.withValues(alpha: _opacity.value),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          );
        },
      ),
    );
  }
}
