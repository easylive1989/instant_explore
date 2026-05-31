/// Appearance options for the Field Journal theme.
///
/// These live in `app/config` (feature-agnostic) so the theme layer can
/// depend on them without violating the app→feature dependency rule.
library;

/// Brand accent colour family (terracotta / amber / sage).
enum BrandAccent { terracotta, amber, sage }

/// Reading-surface palette for immersive reading contexts.
enum ReadingSurface { paper, sepia, night }

/// Headline typeface choice.
enum HeadlineFont { serif, sans }
