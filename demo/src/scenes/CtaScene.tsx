import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from "remotion";
import { Wordmark } from "../components/Wordmark";
import { StoreBadges } from "../components/StoreBadges";
import { easeOutExpo } from "../utils/animations";

export const CtaScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const wordSpring = spring({
    frame: frame - 4,
    fps,
    config: { damping: 16, stiffness: 110 },
  });
  const wordOp = interpolate(frame, [0, 24], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const sloganOp = interpolate(frame, [28, 58], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const sloganY = interpolate(frame, [28, 58], [20, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

  const badgesOp = interpolate(frame, [58, 88], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const badgesY = interpolate(frame, [58, 94], [40, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

  // Fade to black at end
  const sceneOut = interpolate(frame, [130, 150], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Golden halo behind wordmark
  const halo = interpolate(frame, [0, 60], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

  return (
    <AbsoluteFill style={{ opacity: sceneOut }}>
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(circle at 50% 55%, #13203a 0%, #0B111A 55%, #05090f 100%)",
        }}
      />
      {/* Golden glow halo */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(circle at 50% 42%, rgba(255,178,92,${0.3 * halo}) 0%, transparent 35%)`,
          mixBlendMode: "screen",
        }}
      />

      <AbsoluteFill
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 30,
        }}
      >
        <div
          style={{
            transform: `scale(${0.85 + 0.15 * wordSpring})`,
            opacity: wordOp,
          }}
        >
          <Wordmark size={144} />
        </div>

        <div
          style={{
            opacity: sloganOp,
            transform: `translateY(${sloganY}px)`,
            fontFamily:
              '"Inter","Noto Sans",-apple-system,BlinkMacSystemFont,sans-serif',
            fontSize: 34,
            fontWeight: 300,
            letterSpacing: -0.3,
            background:
              "linear-gradient(135deg,#FFE4AF 0%,#FFA93D 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          Read the world.
        </div>

        <div
          style={{
            opacity: badgesOp,
            transform: `translateY(${badgesY}px)`,
            marginTop: 20,
          }}
        >
          <StoreBadges />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
