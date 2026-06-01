import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { Wordmark } from "../components/Wordmark";
import { StoreBadges } from "../components/StoreBadges";
import { colors, fonts } from "../theme";
import { fadeIn, slideUp } from "../utils/animations";

// Beat 6 (0–4s local): closing call-to-action on warm paper.
export const CtaScene: React.FC = () => {
  const frame = useCurrentFrame();

  return (
    <PaperBackdrop>
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          gap: 30,
          padding: 100,
        }}
      >
        <div style={{ opacity: fadeIn(frame, 4, 16), transform: `translateY(${slideUp(frame, 4, 20, 30)}px)` }}>
          <Wordmark size={66} />
        </div>
        <span
          style={{
            fontFamily: fonts.sans,
            fontSize: 18,
            fontWeight: 700,
            letterSpacing: "0.22em",
            textTransform: "uppercase",
            color: colors.clay,
            opacity: fadeIn(frame, 16, 16),
          }}
        >
          開始你的第一段故事
        </span>
        <div
          style={{
            fontFamily: fonts.serif,
            fontWeight: 700,
            fontSize: 72,
            lineHeight: 1.25,
            textAlign: "center",
            color: colors.ink,
            opacity: fadeIn(frame, 22, 18),
            transform: `translateY(${slideUp(frame, 22, 24, 34)}px)`,
          }}
        >
          城市是一本書。
          <br />
          開始閱讀吧。
        </div>
        <p
          style={{
            fontFamily: fonts.sans,
            fontSize: 24,
            color: colors.ink2,
            opacity: fadeIn(frame, 40, 18),
          }}
        >
          加入五萬名探索者，一同揭開世界各地隱藏的篇章。
        </p>
        <div style={{ marginTop: 18, opacity: fadeIn(frame, 52, 20) }}>
          <StoreBadges />
        </div>
      </AbsoluteFill>
    </PaperBackdrop>
  );
};
