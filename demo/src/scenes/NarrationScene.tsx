import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
} from "remotion";
import { PhoneFrame } from "../components/PhoneFrame";
import { PlayerMockup } from "../components/mockups/PlayerMockup";
import { easeOutExpo } from "../utils/animations";

export const NarrationScene: React.FC = () => {
  const frame = useCurrentFrame();

  // Phone slides in from right
  const phoneX = interpolate(frame, [0, 30], [160, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });
  const phoneOp = interpolate(frame, [0, 22], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Callouts
  const headlineOp = interpolate(frame, [24, 54], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const headlineY = interpolate(frame, [24, 54], [18, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

  const subOp = interpolate(frame, [130, 160], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const subY = interpolate(frame, [130, 160], [18, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

  const sceneOut = interpolate(frame, [220, 240], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ opacity: sceneOut }}>
      {/* Background */}
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(circle at 30% 50%, #152035 0%, #0B111A 55%, #05090f 100%)",
        }}
      />
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(circle at 75% 70%, rgba(19,127,236,0.2) 0%, transparent 50%)",
          mixBlendMode: "screen",
        }}
      />

      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 120,
          flexDirection: "row-reverse",
        }}
      >
        <div
          style={{
            transform: `translateX(${phoneX}px) scale(0.95)`,
            opacity: phoneOp,
          }}
        >
          <PhoneFrame>
            <PlayerMockup />
          </PhoneFrame>
        </div>

        <div
          style={{
            maxWidth: 640,
            display: "flex",
            flexDirection: "column",
            gap: 20,
          }}
        >
          {/* Eyebrow */}
          <div
            style={{
              opacity: headlineOp,
              transform: `translateY(${headlineY}px)`,
              color: "#137fec",
              fontSize: 16,
              letterSpacing: 4,
              fontWeight: 600,
              textTransform: "uppercase",
              fontFamily:
                '"Inter","Noto Sans",-apple-system,BlinkMacSystemFont,sans-serif',
            }}
          >
            AI Voice Narration
          </div>
          <div
            style={{
              opacity: headlineOp,
              transform: `translateY(${headlineY}px)`,
              color: "#fff",
              fontSize: 76,
              fontWeight: 600,
              lineHeight: 1.02,
              letterSpacing: -2,
              fontFamily:
                '"Inter","Noto Sans",-apple-system,BlinkMacSystemFont,sans-serif',
            }}
          >
            Real-time
            <br />
            AI narration.
          </div>
          <div
            style={{
              opacity: subOp,
              transform: `translateY(${subY}px)`,
              color: "#cbd5e1",
              fontSize: 28,
              fontWeight: 300,
              letterSpacing: -0.3,
              lineHeight: 1.3,
              fontFamily:
                '"Inter","Noto Sans",-apple-system,BlinkMacSystemFont,sans-serif',
            }}
          >
            Ask anything, anytime.
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
