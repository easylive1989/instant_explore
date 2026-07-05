import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { Wordmark } from "../components/Wordmark";
import { StoreBadges } from "../components/StoreBadges";
import { colors, fonts } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, popIn, slideUp } from "../utils/animations";

// Beat 6 (0–4s local): dark brand outro. Bookends HookScene's dark radial
// background — the video opens and closes on the same ink gradient, with
// the wordmark, slogan, and store badges carrying the closing beat instead
// of app-feature content.
export const CtaScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const portrait = usePortrait();

  const badgeScale = (portrait ? 0.7 : 1) * popIn(frame, fps, 46);

  return (
    <AbsoluteFill
      style={{
        background:
          "radial-gradient(120% 100% at 70% -10%, #2c2620, #17120d 60%)",
      }}
    >
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          gap: portrait ? 22 : 30,
          padding: portrait ? 60 : 120,
        }}
      >
        <div
          style={{
            opacity: fadeIn(frame, 4, 16),
            transform: `translateY(${slideUp(frame, 4, 20, 30)}px)`,
          }}
        >
          <Wordmark size={portrait ? 50 : 66} color={colors.onDark} />
        </div>

        <span
          style={{
            fontFamily: fonts.serif,
            fontSize: portrait ? 19 : 24,
            fontWeight: 600,
            letterSpacing: "0.16em",
            color: colors.onDark2,
            opacity: fadeIn(frame, 16, 16),
            transform: `translateY(${slideUp(frame, 16, 16, 20)}px)`,
          }}
        >
          旅行說書人
        </span>

        <div
          style={{
            fontFamily: fonts.serif,
            fontWeight: 700,
            fontSize: portrait ? 44 : 68,
            lineHeight: 1.3,
            textAlign: "center",
            color: colors.onDark,
            opacity: fadeIn(frame, 26, 18),
            transform: `translateY(${slideUp(frame, 26, 18, 30)}px)`,
          }}
        >
          城市是一本書。
          <br />
          開始閱讀吧。
        </div>

        <div
          style={{
            marginTop: portrait ? 8 : 16,
            opacity: fadeIn(frame, 46, 16),
            transform: `scale(${badgeScale})`,
          }}
        >
          <StoreBadges />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
