import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from "remotion";
import { PhoneFrame } from "../components/PhoneFrame";
import { HomeMockup } from "../components/mockups/HomeMockup";
import { Wordmark } from "../components/Wordmark";
import { easeOutExpo } from "../utils/animations";

export const IntroScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Phone slides in from bottom
  const phoneY = interpolate(frame, [0, 40], [200, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });
  const phoneOp = interpolate(frame, [0, 26], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Wordmark pop in
  const wordSpring = spring({
    frame: frame - 30,
    fps,
    config: { damping: 14, stiffness: 110 },
  });
  const wordOp = interpolate(frame, [30, 55], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Tagline follows
  const taglineOp = interpolate(frame, [55, 80], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const taglineY = interpolate(frame, [55, 80], [12, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

  // Subtle ambient drift
  const sceneOut = interpolate(frame, [130, 150], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ opacity: sceneOut }}>
      {/* Background */}
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(circle at 70% 30%, #15233a 0%, #0B111A 55%, #05090f 100%)",
        }}
      />
      {/* Soft blue accent */}
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(circle at 22% 70%, rgba(19,127,236,0.22) 0%, transparent 45%)",
          mixBlendMode: "screen",
        }}
      />

      {/* Layout: phone left, text right */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 120,
        }}
      >
        <div
          style={{
            transform: `translateY(${phoneY}px) scale(0.95)`,
            opacity: phoneOp,
          }}
        >
          <PhoneFrame>
            <HomeMockup />
          </PhoneFrame>
        </div>

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 22,
            maxWidth: 620,
          }}
        >
          <div
            style={{
              transform: `scale(${0.85 + 0.15 * wordSpring})`,
              opacity: wordOp,
              transformOrigin: "left center",
            }}
          >
            <Wordmark size={108} />
          </div>
          <div
            style={{
              opacity: taglineOp,
              transform: `translateY(${taglineY}px)`,
              color: "#cbd5e1",
              fontSize: 32,
              fontWeight: 300,
              letterSpacing: -0.3,
              fontFamily:
                '"Inter","Noto Sans",-apple-system,BlinkMacSystemFont,sans-serif',
            }}
          >
            Your AI pocket historian,
            <br />
            anywhere in the world.
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
