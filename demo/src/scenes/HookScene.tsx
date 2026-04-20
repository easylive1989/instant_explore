import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
  Easing,
} from "remotion";
import { StoneTexture } from "../components/StoneTexture";
import { easeOutExpo } from "../utils/animations";

export const HookScene: React.FC = () => {
  const frame = useCurrentFrame();

  const line1 = "Stones don't speak—";
  const line2 = "until now.";

  // Line 1 letters fade in between frames 24–78
  const line1Chars = line1.split("").map((ch, i) => {
    const start = 24 + i * 2.2;
    const op = interpolate(frame, [start, start + 8], [0, 1], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: easeOutExpo,
    });
    const y = interpolate(frame, [start, start + 10], [10, 0], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: easeOutExpo,
    });
    return { ch, op, y };
  });

  // Line 2 ("until now.") fades in after ~95 frames
  const line2Op = interpolate(frame, [95, 120], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });
  const line2Y = interpolate(frame, [95, 122], [18, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

  // Final bloom + scene fade out (final 20 frames of 150)
  const bloom = interpolate(frame, [110, 150], [0, 1.1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.7, 0, 0.3, 1),
  });
  const sceneOut = interpolate(frame, [130, 150], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ opacity: sceneOut }}>
      <StoneTexture />

      {/* Bloom flash */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(circle at 50% 55%, rgba(255,200,120,${bloom * 0.6}) 0%, transparent 40%)`,
          mixBlendMode: "screen",
          pointerEvents: "none",
        }}
      />

      {/* Text */}
      <AbsoluteFill
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 14,
          fontFamily:
            '"Inter","Noto Sans",-apple-system,BlinkMacSystemFont,sans-serif',
        }}
      >
        <div
          style={{
            fontSize: 72,
            fontWeight: 300,
            letterSpacing: -1.5,
            color: "#f3e8d8",
            textShadow: "0 4px 30px rgba(0,0,0,0.6)",
          }}
        >
          {line1Chars.map((c, i) => (
            <span
              key={i}
              style={{
                display: "inline-block",
                opacity: c.op,
                transform: `translateY(${c.y}px)`,
                whiteSpace: "pre",
              }}
            >
              {c.ch}
            </span>
          ))}
        </div>
        <div
          style={{
            fontSize: 88,
            fontWeight: 700,
            letterSpacing: -2,
            background:
              "linear-gradient(135deg,#FFE4AF 0%,#FFA93D 50%,#FFE4AF 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            opacity: line2Op,
            transform: `translateY(${line2Y}px)`,
            textShadow: "0 0 40px rgba(255,180,80,0.4)",
          }}
        >
          {line2}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
