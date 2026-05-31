import 'package:context_app/app/config/appearance_options.dart';
import 'package:flutter/foundation.dart';

/// Immutable snapshot of the app's appearance configuration.
///
/// The appearance is fixed (amber accent, sepia reading surface, sans
/// headline) and is no longer user-configurable, so this is a plain value
/// object consumed by the theme layer.
@immutable
class AppearanceState {
  const AppearanceState({
    this.accent = BrandAccent.amber,
    this.reading = ReadingSurface.sepia,
    this.headlineFont = HeadlineFont.sans,
  });

  final BrandAccent accent;
  final ReadingSurface reading;
  final HeadlineFont headlineFont;
}
