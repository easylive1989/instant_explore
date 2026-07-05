import React from "react";
import { useCurrentFrame, useVideoConfig } from "remotion";
import { colors, fonts, radius } from "../../theme";
import { storyOptions } from "../../data";
import { popIn } from "../../utils/animations";

// docs/design story-opts 畫面：同一地標的三個故事角度，如章節目錄。
export const StoryOptionsMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: colors.paperRaised,
        padding: "60px 30px 28px",
      }}
    >
      <div
        style={{
          fontFamily: fonts.serif,
          fontWeight: 700,
          fontSize: 27,
          color: colors.ink,
          marginBottom: 14,
        }}
      >
        想聽哪段故事？
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {storyOptions.map((o, i) => {
          const p = popIn(frame, fps, 14 + i * 12);
          return (
            <div
              key={o.no}
              style={{
                display: "flex",
                gap: 12,
                padding: "14px 16px",
                borderRadius: radius.lg,
                background: colors.paper,
                border: `1px solid ${colors.line}`,
                boxShadow: "0 6px 18px rgba(40,30,18,0.06)",
                opacity: p,
                transform: `translateY(${(1 - p) * 26}px)`,
              }}
            >
              <div
                style={{
                  fontFamily: fonts.serif,
                  fontWeight: 700,
                  fontSize: 30,
                  lineHeight: 1,
                  color: colors.clay,
                  width: 36,
                  flex: "none",
                }}
              >
                {o.no}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div
                  style={{
                    fontFamily: fonts.serif,
                    fontWeight: 600,
                    fontSize: 22,
                    lineHeight: 1.28,
                    color: colors.ink,
                  }}
                >
                  {o.title}
                </div>
                <div
                  style={{
                    fontFamily: fonts.sans,
                    fontSize: 16,
                    lineHeight: 1.42,
                    color: colors.ink2,
                    marginTop: 5,
                  }}
                >
                  {o.desc}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
