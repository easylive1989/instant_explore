"use client";
// Hand-drawn editorial style primitives (Superlist-canonical look):
// flat poster background + grain, lowercase corner wordmark, scattered coral
// doodles, and a brush-script accent phrase with a wavy underline.
import * as React from "react";

export const CORAL = "#F26A50";
export const CREAM = "#F5EFDF";
export const NAVY = "#1B2336";

// Brush script: Caveat covers Latin; Ma Shan Zheng is a Chinese brush
// calligraphy face; Noto Serif TC catches any Traditional glyph Ma Shan Zheng
// lacks (so zh accents still read as an elegant emphasis rather than tofu).
export const SCRIPT_FONT = "'Caveat', 'Ma Shan Zheng', 'Noto Serif TC', cursive";
// CJK-aware sans for headlines/wordmark.
export const SANS_FONT = "'Inter', 'Noto Sans TC', system-ui, sans-serif";

// Tiled fractal-noise grain as a data-URI SVG (rasterized by the browser, so
// html-to-image captures it as a normal image).
const NOISE_SRC =
  "data:image/svg+xml;utf8," +
  encodeURIComponent(
    "<svg xmlns='http://www.w3.org/2000/svg' width='200' height='200'>" +
      "<filter id='n'><feTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2' stitchTiles='stitch'/></filter>" +
      "<rect width='100%' height='100%' filter='url(#n)'/></svg>",
  );

export function NoiseOverlay({ opacity = 0.05 }: { opacity?: number }) {
  // A CSS background data-URI (no <img> decode) keeps html-to-image from
  // hanging on the SVG-filter rasterization during export.
  return (
    <div
      aria-hidden
      style={{
        position: "absolute",
        inset: 0,
        backgroundImage: `url("${NOISE_SRC}")`,
        backgroundSize: "200px 200px",
        opacity,
        mixBlendMode: "overlay",
        pointerEvents: "none",
      }}
    />
  );
}

export function Wordmark({
  name,
  color,
  cW,
  cH,
}: {
  name: string;
  color: string;
  cW: number;
  cH: number;
}) {
  return (
    <div
      aria-hidden
      style={{
        position: "absolute",
        left: cW * 0.07,
        top: cH * 0.035,
        fontFamily: SANS_FONT,
        fontWeight: 500,
        fontSize: cW * 0.032,
        letterSpacing: "-0.01em",
        color,
        textTransform: "lowercase",
        pointerEvents: "none",
        zIndex: 6,
      }}
    >
      {name}
    </div>
  );
}

// ---------- Doodles ----------

type DoodleType = "squiggle" | "star" | "asterisk" | "arrow" | "swirl";

function DoodleSvg({ type, color, stroke }: { type: DoodleType; color: string; stroke: number }) {
  const common = {
    fill: "none",
    stroke: color,
    strokeWidth: stroke,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
  };
  switch (type) {
    case "squiggle":
      return (
        <svg viewBox="0 0 100 40" width="100%" height="100%">
          <path d="M3,22 C14,6 22,34 33,20 C44,7 52,33 64,19 C75,7 84,30 97,18" {...common} />
        </svg>
      );
    case "star":
      return (
        <svg viewBox="0 0 100 100" width="100%" height="100%">
          <path d="M50,6 L50,94 M6,50 L94,50 M20,20 L80,80 M80,20 L20,80" {...common} />
        </svg>
      );
    case "asterisk":
      return (
        <svg viewBox="0 0 100 100" width="100%" height="100%">
          <path d="M50,10 L50,90 M16,30 L84,70 M84,30 L16,70" {...common} />
        </svg>
      );
    case "arrow":
      return (
        <svg viewBox="0 0 100 100" width="100%" height="100%">
          <path d="M8,84 C30,30 64,22 88,40" {...common} />
          <path d="M88,40 L70,38 M88,40 L82,58" {...common} />
        </svg>
      );
    case "swirl":
      return (
        <svg viewBox="0 0 100 100" width="100%" height="100%">
          <path
            d="M58,52 C58,40 42,40 42,52 C42,68 66,68 66,50 C66,28 34,28 34,52 C34,80 74,80 76,46"
            {...common}
          />
        </svg>
      );
  }
}

type DoodlePlacement = { type: DoodleType; x: number; y: number; size: number; rot: number };

// Deterministic doodle set per slide index. Doodles orbit the margins.
const DOODLE_SETS: DoodlePlacement[][] = [
  [
    { type: "star", x: 0.8, y: 0.12, size: 0.07, rot: 12 },
    { type: "swirl", x: 0.05, y: 0.6, size: 0.1, rot: -8 },
    { type: "squiggle", x: 0.68, y: 0.52, size: 0.18, rot: 8 },
  ],
  [
    { type: "asterisk", x: 0.83, y: 0.1, size: 0.08, rot: 0 },
    { type: "squiggle", x: 0.07, y: 0.5, size: 0.18, rot: -10 },
    { type: "star", x: 0.16, y: 0.16, size: 0.05, rot: -14 },
  ],
  [
    { type: "arrow", x: 0.64, y: 0.4, size: 0.17, rot: 18 },
    { type: "star", x: 0.09, y: 0.5, size: 0.06, rot: 8 },
  ],
  [
    { type: "star", x: 0.79, y: 0.13, size: 0.08, rot: -10 },
    { type: "squiggle", x: 0.07, y: 0.16, size: 0.18, rot: 6 },
    { type: "asterisk", x: 0.14, y: 0.56, size: 0.06, rot: 0 },
  ],
  [
    { type: "swirl", x: 0.78, y: 0.5, size: 0.12, rot: 14 },
    { type: "squiggle", x: 0.09, y: 0.2, size: 0.17, rot: -6 },
    { type: "star", x: 0.85, y: 0.13, size: 0.06, rot: 10 },
  ],
];

export function Doodles({
  index,
  cW,
  cH,
  color,
}: {
  index: number;
  cW: number;
  cH: number;
  color: string;
}) {
  const set = DOODLE_SETS[index % DOODLE_SETS.length];
  return (
    <>
      {set.map((d, i) => (
        <div
          key={i}
          aria-hidden
          style={{
            position: "absolute",
            left: d.x * cW,
            top: d.y * cH,
            width: d.size * cW,
            height: d.size * cW,
            transform: `rotate(${d.rot}deg)`,
            pointerEvents: "none",
            zIndex: 2,
          }}
        >
          <DoodleSvg type={d.type} color={color} stroke={5} />
        </div>
      ))}
    </>
  );
}

// ---------- Script accent phrase + wavy underline ----------

export function ScriptAccent({
  text,
  color,
  fontSize,
  rotation = -2,
  fontFamily = SCRIPT_FONT,
}: {
  text: string;
  color: string;
  fontSize: number;
  rotation?: number;
  fontFamily?: string;
}) {
  if (!text) return null;
  return (
    <div
      style={{
        display: "inline-block",
        transform: rotation ? `rotate(${rotation}deg)` : undefined,
        transformOrigin: "left center",
        marginTop: fontSize * 0.1,
      }}
    >
      <div
        style={{
          fontFamily,
          fontWeight: 700,
          fontSize,
          lineHeight: 1.0,
          color,
          whiteSpace: "pre",
        }}
      >
        {text}
      </div>
      <svg
        viewBox="0 0 100 12"
        preserveAspectRatio="none"
        width="100%"
        height={fontSize * 0.26}
        style={{ display: "block", marginTop: fontSize * 0.02 }}
      >
        <path
          d="M2,7 C16,2 26,11 40,6 C54,1 64,10 78,6 C86,3.5 93,8 98,6"
          fill="none"
          stroke={color}
          strokeWidth={4}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
}
