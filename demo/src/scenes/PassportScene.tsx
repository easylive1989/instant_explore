import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
} from "remotion";
import { PhoneFrame } from "../components/PhoneFrame";
import { PassportMockup } from "../components/mockups/PassportMockup";
import { easeOutExpo } from "../utils/animations";

export const PassportScene: React.FC = () => {
  const frame = useCurrentFrame();

  const phoneX = interpolate(frame, [0, 30], [-160, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });
  const phoneOp = interpolate(frame, [0, 22], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const headlineOp = interpolate(frame, [24, 54], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const headlineY = interpolate(frame, [24, 54], [18, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

  const subOp = interpolate(frame, [90, 120], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const subY = interpolate(frame, [90, 120], [18, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

  const sceneOut = interpolate(frame, [190, 210], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ opacity: sceneOut }}>
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(circle at 70% 50%, #182238 0%, #0B111A 55%, #05090f 100%)",
        }}
      />
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(circle at 25% 30%, rgba(255,195,106,0.14) 0%, transparent 45%)",
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
        }}
      >
        <div
          style={{
            transform: `translateX(${phoneX}px) scale(0.95)`,
            opacity: phoneOp,
          }}
        >
          <PhoneFrame>
            <PassportMockup />
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
          <div
            style={{
              opacity: headlineOp,
              transform: `translateY(${headlineY}px)`,
              color: "#FFC36A",
              fontSize: 16,
              letterSpacing: 4,
              fontWeight: 600,
              textTransform: "uppercase",
              fontFamily:
                '"Inter","Noto Sans",-apple-system,BlinkMacSystemFont,sans-serif',
            }}
          >
            Knowledge Passport
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
            Every journey,
            <br />
            remembered.
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
            Auto-generated cultural
            <br />
            footprints, saved forever.
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
