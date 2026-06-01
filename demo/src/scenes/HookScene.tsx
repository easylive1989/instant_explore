import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { colors, fonts } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp } from "../utils/animations";

// Beat 1 (0–5s): manifesto opener on warm paper.
export const HookScene: React.FC = () => {
  const frame = useCurrentFrame();
  const portrait = usePortrait();
  const ruleWidth = fadeIn(frame, 6, 22) * (portrait ? 320 : 460);

  return (
    <PaperBackdrop>
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          padding: portrait ? 80 : 140,
        }}
      >
        <div
          style={{
            height: 2,
            width: ruleWidth,
            background: colors.clay,
            marginBottom: 44,
          }}
        />
        <div
          style={{
            fontFamily: fonts.serif,
            fontWeight: 700,
            fontSize: portrait ? 64 : 78,
            lineHeight: 1.32,
            color: colors.ink,
            textAlign: "center",
            maxWidth: portrait ? 720 : 1180,
          }}
        >
          <div
            style={{
              opacity: fadeIn(frame, 14, 18),
              transform: `translateY(${slideUp(frame, 14, 24, 36)}px)`,
            }}
          >
            別再低頭盯著螢幕。
          </div>
          <div
            style={{
              opacity: fadeIn(frame, 40, 20),
              transform: `translateY(${slideUp(frame, 40, 26, 36)}px)`,
            }}
          >
            抬起眼睛，
            <span style={{ color: colors.clay }}>世界本身就是展品。</span>
          </div>
        </div>
        <div
          style={{
            marginTop: 52,
            fontFamily: fonts.sans,
            fontSize: 22,
            letterSpacing: "0.12em",
            color: colors.ink3,
            opacity: fadeIn(frame, 78, 24),
          }}
        >
          Lorescape
        </div>
      </AbsoluteFill>
    </PaperBackdrop>
  );
};
