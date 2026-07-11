export type Device =
  | "iphone"
  | "ipad"
  | "android"
  | "android-7"
  | "android-10"
  | "feature-graphic";

export type Orientation = "portrait" | "landscape";

export type Platform = "ios" | "android";

// Layouts the editor can render. Vary across slides for visual rhythm.
export type SlideLayout =
  | "hero"             // centered device, headline above
  | "device-bottom"    // headline top, device bottom-center
  | "device-top"       // device top, headline bottom (contrast)
  | "two-devices"      // back + front phones, headline above
  | "no-device"        // big headline + decorative blob, no device
  | "split-landscape"  // landscape tablets only: caption left + device right
  | "feature-graphic"; // 1024×500 banner with icon + name + tagline

// Per-element rect in canvas pixel space. Optional rotation in degrees and zIndex.
export type ElementTransform = {
  x: number;
  y: number;
  width: number;
  height: number;
  rotation?: number;
  zIndex?: number;
};

export type BuiltInElementId = "caption" | "device" | "deviceSecondary";
export type TextElementId = `text:${string}`;
export type ElementId = BuiltInElementId | TextElementId;

export type SelectedElement = {
  slideId: string;
  elementId: ElementId;
};

// Per-locale text keyed by locale code (e.g. "en", "de"). A locale is absent
// if the user hasn't typed anything for it; renderers fall back to en (see
// lib/locale.ts). The set of locales a project targets lives on
// ProjectState.locales.
export type LocalizedText = Partial<Record<string, string>>;

export type TextElement = {
  id: string;
  text: LocalizedText;
  transform: ElementTransform;
  fontSize?: number;
  fontWeight?: number;
  color?: string;
  align?: "left" | "center" | "right";
};

export type Slide = {
  id: string;
  layout: SlideLayout;
  label: LocalizedText;       // tiny uppercase caption above headline, per locale
  headline: LocalizedText;    // multi-line; newlines are intentional, per locale
  screenshot: string;         // path under /screenshots/ — may contain {locale}
  screenshotSecondary?: string; // for two-devices layout — may contain {locale}
  inverted?: boolean;         // dark background variant
  // Per-element overrides; when present, replaces layout default placement.
  transforms?: Partial<Record<BuiltInElementId, ElementTransform>>;
  textElements?: TextElement[];

  // ---- Hand-drawn editorial style (optional, per-slide) ----
  // When `bgColor` is set the slide renders as a flat poster block (no theme
  // gradient or blobs) with the hand-drawn treatment: corner wordmark, a
  // script accent phrase under the headline, scattered doodles, and a tilted
  // phone with a warm shadow.
  bgColor?: string;           // solid background hex; opts the slide into the style
  onDark?: boolean;           // true → light text/wordmark
  scriptPhrase?: LocalizedText; // the one brush-script accent phrase
  scriptColor?: string;       // accent color (defaults to coral)
  headlineScale?: number;     // per-slide multiplier on the headline font size (1 = default)
  featureScreenshots?: string[]; // feature-graphic only: phones shown beside the wordmark
  doodleColor?: string;       // doodle ink (defaults from onDark)
  tilt?: number;              // phone rotation in degrees (e.g. -12, 15)
  shadowRgba?: string;        // warm phone drop-shadow rgba, e.g. "8,12,30,0.5"

  // ---- Style selector + retro rubberhose extras ----
  // "retro" switches to the rubberhose mascot treatment: cream inked phone
  // bezel, Cooper-style headline, paper grain, ink doodles, and a mascot.
  style?: "hand-drawn" | "retro";
  mascot?: {
    color?: string;           // body fill (mustard / peach / pink / terracotta)
    x?: number;               // 0..1 of canvas width (mascot box left)
    y?: number;               // 0..1 of canvas height
    size?: number;            // 0..1 of canvas width (mascot box width)
    flip?: boolean;           // mirror horizontally
  };
};

export type ThemeId =
  | "clean-light"
  | "dark-bold"
  | "warm-editorial"
  | "ocean-fresh"
  | "bloom-roast";

export type Theme = {
  id: string;
  name: string;
  bg: string;          // primary background
  bgAlt: string;       // inverted background
  fg: string;          // text on bg
  fgAlt: string;       // text on bgAlt
  accent: string;
  muted: string;
};

export type ProjectState = {
  schemaVersion?: number;
  appName: string;
  themeId: string;
  // v1 projects render as isolated screens until the user opts into connected crops.
  connectedCanvas: boolean;
  // Locales this project targets. Drives the toolbar dropdown and bulk export.
  // Single-locale projects ship as ["en"] and hide the locale UI.
  locales: string[];
  locale: string;
  device: Device;
  orientation: Orientation;
  // Per-device slide decks so platform switching preserves work
  slidesByDevice: Record<Device, Slide[]>;
  appIcon?: string;    // path under /public (e.g. /app-icon.png)
};
