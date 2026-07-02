import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A placeholder screen that navigates to home (`/`) once mounted.
///
/// Used for dead-end navigation states — go_router's
/// [GoRouter.errorBuilder] when a URL matches no route (e.g. a malformed
/// deep link like `/zh/storybook`), and the daily-story deep link's
/// not-found / error branches — so the user lands on home instead of an
/// error page.
///
/// Navigating during `build` is unsafe, so the redirect is scheduled as a
/// post-frame callback from [State.initState]; being a [StatefulWidget] at a
/// stable tree position, it fires exactly once rather than re-scheduling on
/// every rebuild.
class RedirectToHome extends StatefulWidget {
  const RedirectToHome({super.key});

  @override
  State<RedirectToHome> createState() => _RedirectToHomeState();
}

class _RedirectToHomeState extends State<RedirectToHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
