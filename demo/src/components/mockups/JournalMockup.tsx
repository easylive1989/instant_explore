import React from "react";
import { Img, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { colors, fonts } from "../../theme";
import { popIn } from "../../utils/animations";

const entries = [
  { title: "摧毀與重生的百年豪賭", place: "聖伯多祿大殿", img: "images/stpeters.jpg" },
  { title: "媽祖信仰的海上足跡", place: "台中朝聖宮", img: "images/temple.jpg" },
  { title: "蒙兀兒王朝的紅色宮牆", place: "阿格拉紅堡", img: "images/agra.jpg" },
];

// In-app journal: auto-bound entries stacking into a personal field journal.
export const JournalMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <div style={{ width: "100%", height: "100%", background: colors.paperSunk, padding: "70px 30px 30px" }}>
      <div style={{ fontFamily: fonts.sans, fontSize: 15, fontWeight: 700, letterSpacing: "0.18em", textTransform: "uppercase", color: colors.clay }}>
        My Field Journal
      </div>
      <div style={{ fontFamily: fonts.serif, fontWeight: 700, fontSize: 34, color: colors.ink, margin: "8px 0 26px" }}>
        2026 春・歐遊手記
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {entries.map((e, i) => {
          const p = popIn(frame, fps, 14 + i * 14);
          return (
            <div
              key={e.title}
              style={{
                display: "flex",
                gap: 18,
                padding: 16,
                borderRadius: 18,
                background: colors.paperRaised,
                border: `1px solid ${colors.line}`,
                boxShadow: "0 6px 18px rgba(40,30,18,0.09)",
                opacity: p,
                transform: `translateY(${(1 - p) * 30}px) rotate(${(1 - p) * -2}deg)`,
              }}
            >
              <Img
                src={staticFile(e.img)}
                alt=""
                style={{ width: 88, height: 88, borderRadius: 14, objectFit: "cover" }}
              />
              <div style={{ display: "flex", flexDirection: "column", justifyContent: "center" }}>
                <div style={{ fontFamily: fonts.serif, fontSize: 25, color: colors.ink, lineHeight: 1.3 }}>
                  {e.title}
                </div>
                <div style={{ fontFamily: fonts.sans, fontSize: 17, color: colors.ink3, marginTop: 6 }}>
                  {e.place}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
