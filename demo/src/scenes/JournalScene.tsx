import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { PhoneFrame } from "../components/PhoneFrame";
import { JournalMockup } from "../components/mockups/JournalMockup";
import { SceneHeading } from "../components/SceneHeading";
import { colors, fonts } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp, popIn } from "../utils/animations";

const stats = [
  { num: "I", cn: "自動成篇" },
  { num: "II", cn: "依旅程歸檔" },
  { num: "III", cn: "沿時間軸重溫" },
];

// Beat 5 (0–4s local): your journey is bound into a journal automatically.
export const JournalScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const portrait = usePortrait();

  const phone = (
    <div
      style={{
        opacity: fadeIn(frame, 8, 18),
        transform: `translateY(${slideUp(frame, 8, 24, 56)}px)`,
      }}
    >
      <PhoneFrame width={portrait ? 440 : 380} height={portrait ? 900 : 800}>
        <JournalMockup />
      </PhoneFrame>
    </div>
  );

  const copy = (
    <div style={{ maxWidth: 540 }}>
      <SceneHeading over="Journey Journal" title="你的旅程，自動成冊" startFrame={4} />
      <p
        style={{
          fontFamily: fonts.sans,
          fontSize: 24,
          lineHeight: 1.7,
          color: colors.ink2,
          margin: "26px 0 30px",
          opacity: fadeIn(frame, 22, 18),
        }}
      >
        每一次駐足，都被悄悄寫進一本屬於你的旅行手記。
      </p>
      <div style={{ display: "flex", gap: 14 }}>
        {stats.map((s, i) => (
          <div
            key={s.num}
            style={{
              flex: 1,
              padding: "18px 14px",
              borderRadius: 16,
              background: colors.paperRaised,
              border: `1px solid ${colors.line}`,
              textAlign: "center",
              opacity: popIn(frame, fps, 30 + i * 8),
            }}
          >
            <div style={{ fontFamily: fonts.serif, fontSize: 30, fontWeight: 700, color: colors.clay }}>
              {s.num}
            </div>
            <div style={{ fontFamily: fonts.sans, fontSize: 18, color: colors.ink2, marginTop: 6 }}>
              {s.cn}
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  return (
    <PaperBackdrop tone="sunk">
      <AbsoluteFill
        style={{
          flexDirection: portrait ? "column" : "row",
          alignItems: "center",
          justifyContent: "center",
          gap: portrait ? 44 : 100,
          padding: portrait ? "80px 60px" : "0 140px",
        }}
      >
        {copy}
        {phone}
      </AbsoluteFill>
    </PaperBackdrop>
  );
};
