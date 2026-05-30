/// User-switchable appearance options for the Field Journal theme.
///
/// These live in `app/config` (feature-agnostic) so both the theme layer
/// and the settings feature can depend on them without violating the
/// app→feature dependency rule.
library;

/// Brand accent colour family (terracotta / amber / sage).
enum BrandAccent { terracotta, amber, sage }

/// Reading-surface palette for immersive reading contexts.
enum ReadingSurface { paper, sepia, night }

/// Headline typeface choice.
enum HeadlineFont { serif, sans }

extension BrandAccentX on BrandAccent {
  String get storageKey => name;

  static BrandAccent fromStorage(String? raw) => BrandAccent.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => BrandAccent.terracotta,
  );
}

extension ReadingSurfaceX on ReadingSurface {
  String get storageKey => name;

  static ReadingSurface fromStorage(String? raw) => ReadingSurface.values
      .firstWhere((e) => e.name == raw, orElse: () => ReadingSurface.paper);
}

extension HeadlineFontX on HeadlineFont {
  String get storageKey => name;

  static HeadlineFont fromStorage(String? raw) => HeadlineFont.values
      .firstWhere((e) => e.name == raw, orElse: () => HeadlineFont.serif);
}
