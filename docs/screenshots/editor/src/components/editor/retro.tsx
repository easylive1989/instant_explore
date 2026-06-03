"use client";
// Retro rubberhose mascot style primitives (1930s tin-can cartoon, Cancoco):
// warm flat backgrounds + paper grain, cream inked phone bezel, sticker doodles,
// a can-shaped white-gloved mascot, and chunky Cooper-style headlines.
import * as React from "react";
import { img } from "@/lib/image-cache";

export const INK = "#1A1A1A";
export const CREAM = "#F4E6CC";
export const BUTTER = "#FBEFD2";
export const MUSTARD = "#F2BB46";
export const CORAL = "#E45A4A";
export const BROWN = "#2A2118";
export const WORDMARK_BROWN = "#5C3A1E";

// Cooper Black-ish display (Lilita One) + chunky CJK fallback.
export const COOPER_FONT = "'Lilita One', 'Noto Sans TC', system-ui, sans-serif";
export const RETRO_BODY_FONT = "'Fredoka', 'Noto Sans TC', sans-serif";

const GRAIN_SRC =
  "data:image/svg+xml;utf8," +
  encodeURIComponent(
    "<svg xmlns='http://www.w3.org/2000/svg' width='220' height='220'>" +
      "<filter id='g'><feTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='2' stitchTiles='stitch'/></filter>" +
      "<rect width='100%' height='100%' filter='url(#g)'/></svg>",
  );

export function RetroGrain({ opacity = 0.08 }: { opacity?: number }) {
  return (
    <div
      aria-hidden
      style={{
        position: "absolute",
        inset: 0,
        backgroundImage: `url("${GRAIN_SRC}")`,
        backgroundSize: "220px 220px",
        opacity,
        mixBlendMode: "multiply",
        pointerEvents: "none",
      }}
    />
  );
}

export function RetroWordmark({ name, cW, cH }: { name: string; cW: number; cH: number }) {
  const inlay = cW * 0.0016;
  return (
    <div
      aria-hidden
      style={{
        position: "absolute",
        left: cW * 0.06,
        top: cH * 0.035,
        fontFamily: COOPER_FONT,
        fontSize: cW * 0.04,
        letterSpacing: "0.01em",
        color: WORDMARK_BROWN,
        textTransform: "lowercase",
        // cream inline highlight toward upper-left (embossed candy-bar look)
        textShadow: `-${inlay}px -${inlay}px 0 ${BUTTER}`,
        pointerEvents: "none",
        zIndex: 6,
      }}
    >
      {name}
    </div>
  );
}

// ---------- Ink doodles (stars, sparkles, plus, footprints) ----------

type DoodleType = "sparkle" | "star4" | "plus" | "swirl";

function InkDoodle({ type, stroke }: { type: DoodleType; stroke: number }) {
  const common = {
    fill: "none",
    stroke: INK,
    strokeWidth: stroke,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
  };
  switch (type) {
    case "sparkle":
      return (
        <svg viewBox="0 0 100 100" width="100%" height="100%">
          <path d="M50,8 C54,38 62,46 92,50 C62,54 54,62 50,92 C46,62 38,54 8,50 C38,46 46,38 50,8 Z" {...common} />
        </svg>
      );
    case "star4":
      return (
        <svg viewBox="0 0 100 100" width="100%" height="100%">
          <path d="M50,12 L50,88 M12,50 L88,50" {...common} />
          <path d="M26,26 L74,74 M74,26 L26,74" {...common} strokeWidth={stroke * 0.7} />
        </svg>
      );
    case "plus":
      return (
        <svg viewBox="0 0 100 100" width="100%" height="100%">
          <path d="M50,16 L50,84 M16,50 L84,50" {...common} />
        </svg>
      );
    case "swirl":
      return (
        <svg viewBox="0 0 100 100" width="100%" height="100%">
          <path d="M40,60 C40,44 60,44 60,60 C60,80 30,80 30,55 C30,28 72,28 72,60" {...common} />
        </svg>
      );
  }
}

type Placement = { type: DoodleType; x: number; y: number; size: number; rot: number };
const DOODLE_SETS: Placement[][] = [
  [
    { type: "sparkle", x: 0.8, y: 0.1, size: 0.07, rot: 0 },
    { type: "star4", x: 0.1, y: 0.46, size: 0.05, rot: 10 },
    { type: "plus", x: 0.86, y: 0.4, size: 0.04, rot: 0 },
  ],
  [
    { type: "star4", x: 0.12, y: 0.12, size: 0.06, rot: 0 },
    { type: "sparkle", x: 0.84, y: 0.46, size: 0.06, rot: 0 },
    { type: "plus", x: 0.16, y: 0.5, size: 0.035, rot: 0 },
  ],
  [
    { type: "sparkle", x: 0.82, y: 0.12, size: 0.07, rot: 0 },
    { type: "swirl", x: 0.08, y: 0.44, size: 0.08, rot: -8 },
  ],
  [
    { type: "star4", x: 0.82, y: 0.12, size: 0.06, rot: 0 },
    { type: "sparkle", x: 0.1, y: 0.16, size: 0.06, rot: 0 },
    { type: "plus", x: 0.88, y: 0.5, size: 0.035, rot: 0 },
  ],
  [
    { type: "sparkle", x: 0.12, y: 0.12, size: 0.07, rot: 0 },
    { type: "plus", x: 0.85, y: 0.18, size: 0.04, rot: 0 },
    { type: "star4", x: 0.84, y: 0.5, size: 0.05, rot: 0 },
  ],
];

export function InkDoodles({ index, cW, cH }: { index: number; cW: number; cH: number }) {
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
          <InkDoodle type={d.type} stroke={6} />
        </div>
      ))}
    </>
  );
}

// ---------- Mascot (rubberhose can) ----------

export function Mascot({
  cW,
  cH,
  x,
  y,
  size,
  color = MUSTARD,
  flip = false,
}: {
  cW: number;
  cH: number;
  x: number;
  y: number;
  size: number;
  color?: string;
  flip?: boolean;
}) {
  const w = size * cW;
  const h = w * 1.4; // viewBox 200×280
  return (
    <div
      aria-hidden
      style={{
        position: "absolute",
        left: x * cW,
        top: y * cH,
        width: w,
        height: h,
        transform: flip ? "scaleX(-1)" : undefined,
        pointerEvents: "none",
        zIndex: 4,
      }}
    >
      <svg viewBox="0 0 200 280" width="100%" height="100%">
        <defs>
          <clipPath id="mascotBody">
            <rect x="46" y="66" width="108" height="150" rx="46" />
          </clipPath>
          <pattern id="halftone" width="10" height="10" patternUnits="userSpaceOnUse">
            <circle cx="2" cy="2" r="1.7" fill={INK} />
          </pattern>
        </defs>

        {/* ground shadow */}
        <ellipse cx="100" cy="270" rx="64" ry="9" fill={INK} opacity="0.12" />

        {/* legs (sausage tubes: black underlay + color overlay) */}
        <path d="M84,206 L76,250" stroke={INK} strokeWidth="28" strokeLinecap="round" />
        <path d="M84,206 L76,250" stroke={color} strokeWidth="18" strokeLinecap="round" />
        <path d="M118,206 L128,242" stroke={INK} strokeWidth="28" strokeLinecap="round" />
        <path d="M118,206 L128,242" stroke={color} strokeWidth="18" strokeLinecap="round" />
        {/* shoes */}
        <ellipse cx="72" cy="252" rx="17" ry="10" fill={INK} transform="rotate(-12 72 252)" />
        <ellipse cx="132" cy="244" rx="17" ry="10" fill={INK} transform="rotate(14 132 244)" />

        {/* raised left arm (wave) + lowered right arm */}
        <path d="M58,116 L30,74" stroke={INK} strokeWidth="26" strokeLinecap="round" />
        <path d="M58,116 L30,74" stroke={color} strokeWidth="17" strokeLinecap="round" />
        <path d="M146,124 L176,150" stroke={INK} strokeWidth="26" strokeLinecap="round" />
        <path d="M146,124 L176,150" stroke={color} strokeWidth="17" strokeLinecap="round" />

        {/* body */}
        <rect x="46" y="66" width="108" height="150" rx="46" fill={color} stroke={INK} strokeWidth="6" />
        {/* inner shadow lower-right + halftone, clipped to body */}
        <g clipPath="url(#mascotBody)">
          <ellipse cx="150" cy="180" rx="46" ry="64" fill="#A86E1C" opacity="0.18" />
          <rect x="96" y="120" width="70" height="100" fill="url(#halftone)" opacity="0.10" />
        </g>

        {/* gloves (cream mittens) with cuff lines */}
        <circle cx="28" cy="70" r="17" fill={BUTTER} stroke={INK} strokeWidth="5" />
        <path d="M40,80 q6,4 11,2 M38,86 q6,4 11,2" stroke={INK} strokeWidth="2.6" fill="none" strokeLinecap="round" />
        <circle cx="178" cy="152" r="17" fill={BUTTER} stroke={INK} strokeWidth="5" />
        <path d="M163,160 q-5,5 -3,11 M169,162 q-5,5 -3,11" stroke={INK} strokeWidth="2.6" fill="none" strokeLinecap="round" />

        {/* eyes (pie-cut) */}
        <g>
          <ellipse cx="84" cy="120" rx="20" ry="24" fill={BUTTER} stroke={INK} strokeWidth="5" />
          <ellipse cx="120" cy="118" rx="20" ry="24" fill={BUTTER} stroke={INK} strokeWidth="5" />
          {/* pie-cut wedges in body color */}
          <path d="M84,120 L84,96 L66,108 Z" fill={color} />
          <path d="M120,118 L120,94 L138,106 Z" fill={color} />
          {/* pupils + highlight */}
          <circle cx="88" cy="124" r="11" fill={INK} />
          <circle cx="124" cy="122" r="11" fill={INK} />
          <circle cx="92" cy="120" r="3" fill={BUTTER} />
          <circle cx="128" cy="118" r="3" fill={BUTTER} />
        </g>

        {/* cheeks + smile */}
        <ellipse cx="68" cy="150" rx="9" ry="6" fill={CORAL} opacity="0.45" />
        <ellipse cx="134" cy="148" rx="9" ry="6" fill={CORAL} opacity="0.45" />
        <path d="M88,152 Q100,164 114,150" stroke={INK} strokeWidth="5" fill="none" strokeLinecap="round" />
      </svg>
    </div>
  );
}

// ---------- Cream inked phone bezel ----------

export function RetroPhone({
  src,
  alt = "",
  style,
  hideEmpty,
  aspect = 1022 / 2082,
}: {
  src: string;
  alt?: string;
  style?: React.CSSProperties;
  hideEmpty?: boolean;
  aspect?: number;
}) {
  const resolved = img(src);
  const H = 100 / aspect; // viewBox height for width 100
  // inner screen area, slightly inset so the inner ink stroke frames the shot
  const innerLeft = 8.5;
  const innerTop = 8.5;
  const innerW = 83;
  const innerH = H - 17;
  return (
    <div style={{ position: "relative", aspectRatio: `${aspect}`, ...style }}>
      <svg
        viewBox={`0 0 100 ${H}`}
        width="100%"
        height="100%"
        preserveAspectRatio="none"
        style={{ position: "absolute", inset: 0 }}
      >
        {/* cream shell + ink stroke */}
        <rect x="2" y="2" width="96" height={H - 4} rx="13" ry={13 * aspect} fill={CREAM} stroke={INK} strokeWidth="2.4" />
        {/* inner screen well */}
        <rect x="7" y="7" width="86" height={H - 14} rx="9" ry={9 * aspect} fill={BUTTER} stroke={INK} strokeWidth="1.8" />
      </svg>
      <div
        style={{
          position: "absolute",
          left: `${innerLeft}%`,
          top: `${(innerTop / H) * 100}%`,
          width: `${innerW}%`,
          height: `${(innerH / H) * 100}%`,
          borderRadius: "7% / 3.4%",
          overflow: "hidden",
          background: "#000",
        }}
      >
        {resolved ? (
          <img
            src={resolved}
            alt={alt}
            style={{ display: "block", width: "100%", height: "100%", objectFit: "cover", objectPosition: "top" }}
            draggable={false}
          />
        ) : hideEmpty ? null : (
          <div style={{ width: "100%", height: "100%", background: BUTTER }} />
        )}
      </div>
    </div>
  );
}
