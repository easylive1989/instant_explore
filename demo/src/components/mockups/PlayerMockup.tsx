import React from "react";
import { useCurrentFrame, interpolate } from "remotion";
import { Waveform } from "../Waveform";
import { easeOutExpo } from "../../utils/animations";

// Mock of the Immersive Player screen:
// ambient hero image + scrolling transcript + glass control panel.
export const PlayerMockup: React.FC = () => {
  const frame = useCurrentFrame();

  const transcriptLines = [
    "Edinburgh Castle has stood for over nine centuries…",
    "Perched on Castle Rock, an extinct volcanic plug,",
    "it guarded Scotland's crown jewels and its kings.",
    "Tonight, you stand where armies once laid siege.",
  ];

  const progress = interpolate(frame, [0, 220], [0.1, 0.72], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const micPulse = 0.9 + 0.1 * Math.sin(frame * 0.22);

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: "#0B111A",
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Ambient hero with faux castle silhouette */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background:
            "radial-gradient(ellipse at 50% 40%, #2b3d5c 0%, #162338 45%, #05080d 100%)",
        }}
      />
      <svg
        width="100%"
        height="60%"
        viewBox="0 0 430 540"
        preserveAspectRatio="xMidYMid slice"
        style={{ position: "absolute", top: 0, left: 0 }}
      >
        <defs>
          <linearGradient id="skyGlow" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#8fb3d9" stopOpacity="0.25" />
            <stop offset="100%" stopColor="#1a2a42" stopOpacity="0" />
          </linearGradient>
        </defs>
        <rect width="430" height="540" fill="url(#skyGlow)" />
        {/* Stars */}
        {Array.from({ length: 24 }).map((_, i) => (
          <circle
            key={i}
            cx={(i * 67) % 430}
            cy={((i * 43) % 240) + 20}
            r={0.8 + (i % 3) * 0.4}
            fill="#e8f0ff"
            opacity={0.5 + ((i * 13) % 40) / 100}
          />
        ))}
        {/* Castle silhouette */}
        <path
          d="M 0 540 L 0 400 L 40 400 L 45 370 L 70 370 L 75 340 L 95 340 L 100 370 L 135 370 L 140 330 L 150 330 L 160 280 L 170 330 L 180 330 L 185 370 L 230 370 L 240 330 L 250 330 L 262 300 L 274 330 L 286 330 L 296 370 L 340 370 L 345 340 L 365 340 L 370 370 L 395 370 L 400 400 L 430 400 L 430 540 Z"
          fill="#07101d"
        />
      </svg>

      {/* Top bar */}
      <div
        style={{
          position: "absolute",
          top: 58,
          left: 0,
          right: 0,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          padding: "0 22px",
          color: "#cbd5e1",
          fontSize: 13,
          zIndex: 3,
        }}
      >
        <span>✕</span>
        <span style={{ opacity: 0.8 }}>Edinburgh Castle</span>
        <span>⋯</span>
      </div>

      {/* Scrolling transcript */}
      <div
        style={{
          position: "absolute",
          left: 28,
          right: 28,
          top: 280,
          display: "flex",
          flexDirection: "column",
          gap: 14,
          zIndex: 2,
        }}
      >
        {transcriptLines.map((line, i) => {
          const lineIn = i * 45 + 30;
          const op = interpolate(frame, [lineIn, lineIn + 20], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          });
          const y = interpolate(frame, [lineIn, lineIn + 25], [14, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: easeOutExpo,
          });
          const isActive =
            frame >= lineIn && frame < lineIn + 50;
          return (
            <div
              key={i}
              style={{
                color: isActive ? "#fff" : "rgba(255,255,255,0.55)",
                fontSize: 17,
                lineHeight: 1.5,
                fontWeight: isActive ? 600 : 400,
                opacity: op,
                transform: `translateY(${y}px)`,
                letterSpacing: -0.2,
              }}
            >
              {line}
            </div>
          );
        })}
      </div>

      {/* Bottom glass control panel */}
      <div
        style={{
          position: "absolute",
          bottom: 24,
          left: 20,
          right: 20,
          borderRadius: 26,
          background: "rgba(16,25,34,0.85)",
          backdropFilter: "blur(20px)",
          border: "1px solid rgba(255,255,255,0.08)",
          padding: "20px 22px",
          zIndex: 4,
        }}
      >
        {/* Progress bar */}
        <div
          style={{
            height: 4,
            borderRadius: 4,
            background: "rgba(255,255,255,0.12)",
            position: "relative",
            marginBottom: 14,
          }}
        >
          <div
            style={{
              position: "absolute",
              left: 0,
              top: 0,
              bottom: 0,
              width: `${progress * 100}%`,
              background: "#137fec",
              borderRadius: 4,
              boxShadow: "0 0 12px rgba(19,127,236,0.6)",
            }}
          />
          <div
            style={{
              position: "absolute",
              top: -4,
              left: `${progress * 100}%`,
              width: 12,
              height: 12,
              borderRadius: 999,
              background: "#fff",
              transform: "translateX(-50%)",
              boxShadow: "0 0 10px #137fec",
            }}
          />
        </div>

        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            color: "#94a3b8",
            fontSize: 11,
            marginBottom: 14,
          }}
        >
          <span>2:14</span>
          <span>5:42</span>
        </div>

        {/* Controls */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          <Waveform width={140} height={36} barCount={18} color="#137fec" />
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div
              style={{
                width: 44,
                height: 44,
                borderRadius: 999,
                background: "rgba(255,255,255,0.08)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#fff",
                fontSize: 16,
              }}
            >
              ‖
            </div>
            {/* Mic / ask button — pulsing to suggest Q&A */}
            <div
              style={{
                width: 56,
                height: 56,
                borderRadius: 999,
                background: "#137fec",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#fff",
                fontSize: 22,
                transform: `scale(${micPulse})`,
                boxShadow: "0 8px 28px rgba(19,127,236,0.5)",
              }}
            >
              🎙
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
