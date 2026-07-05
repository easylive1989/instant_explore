import React from "react";
import { Img, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { colors, fonts, radius } from "../../theme";
import { popIn } from "../../utils/animations";
import { journalEntries } from "../../data";

// In-app journal: auto-bound entries stacking into a personal field journal.
export const JournalMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <div style={{ width: "100%", height: "100%", background: colors.paperSunk, padding: "70px 30px 30px" }}>
      <div style={{ fontFamily: fonts.serif, fontWeight: 700, fontSize: 34, color: colors.ink, marginBottom: 24 }}>
        歷程
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {journalEntries.map((e, i) => {
          const p = popIn(frame, fps, 14 + i * 14);
          return (
            <div
              key={e.title}
              style={{
                display: "flex",
                gap: 16,
                padding: 18,
                borderRadius: radius.lg,
                background: colors.paperRaised,
                border: `1px solid ${colors.line}`,
                boxShadow: "0 6px 18px rgba(40,30,18,0.09)",
                opacity: p,
                transform: `translateY(${(1 - p) * 30}px)`,
              }}
            >
              <div style={{ flex: 1, minWidth: 0 }}>
                <div
                  style={{
                    fontFamily: fonts.sans,
                    fontSize: 14,
                    fontWeight: 600,
                    letterSpacing: "0.06em",
                    color: colors.ink3,
                  }}
                >
                  {e.date} · {e.time}
                </div>
                <div
                  style={{
                    fontFamily: fonts.serif,
                    fontSize: 22,
                    color: colors.ink,
                    marginTop: 6,
                    lineHeight: 1.3,
                  }}
                >
                  {e.title}
                </div>
                <div
                  style={{
                    fontFamily: fonts.sans,
                    fontSize: 15,
                    color: colors.ink2,
                    lineHeight: 1.7,
                    marginTop: 8,
                    display: "-webkit-box",
                    WebkitLineClamp: 4,
                    WebkitBoxOrient: "vertical",
                    overflow: "hidden",
                  }}
                >
                  {e.text}
                </div>
              </div>
              {e.img && (
                <Img
                  src={staticFile(e.img)}
                  alt=""
                  style={{
                    width: 64,
                    height: 64,
                    borderRadius: radius.img,
                    objectFit: "cover",
                    flex: "none",
                  }}
                />
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};
