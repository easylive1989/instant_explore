import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { colors, fonts } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, fadeOut, slideUp } from "../utils/animations";

// Beat 1 (0–5s): dark, wordless-stage manifesto opener. No app UI — this is
// the "page turning open" moment before the product is shown.
export const HookScene: React.FC = () => {
  const frame = useCurrentFrame();
  const portrait = usePortrait();

  const sceneOpacity = fadeOut(frame, 120, 24);
  const dividerWidth = fadeIn(frame, 22, 20) * (portrait ? 90 : 130);

  return (
    <AbsoluteFill
      style={{
        background:
          "radial-gradient(120% 100% at 70% -10%, #2c2620, #17120d 60%)",
        opacity: sceneOpacity,
      }}
    >
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          padding: portrait ? 60 : 120,
        }}
      >
        <div
          style={{
            fontFamily: fonts.serif,
            fontWeight: 700,
            fontSize: portrait ? 64 : 96,
            lineHeight: 1.4,
            color: colors.onDark,
            textAlign: "center",
            whiteSpace: "nowrap",
          }}
        >
          <div
            style={{
              opacity: fadeIn(frame, 10, 18),
              transform: `translateY(${slideUp(frame, 10, 18, 36)}px)`,
            }}
          >
            抬起眼睛，
          </div>
          <div
            style={{
              height: 2,
              width: dividerWidth,
              margin: "18px auto",
              background: colors.clay,
            }}
          />
          <div
            style={{
              opacity: fadeIn(frame, 30, 18),
              transform: `translateY(${slideUp(frame, 30, 18, 36)}px)`,
            }}
          >
            世界本身就是一本書。
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
