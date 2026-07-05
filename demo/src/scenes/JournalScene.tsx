import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { PhoneFrame } from "../components/PhoneFrame";
import { JournalMockup } from "../components/mockups/JournalMockup";
import { SceneHeading } from "../components/SceneHeading";
import { colors } from "../theme";
import { usePortrait } from "../utils/layout";
import { popIn } from "../utils/animations";

// Beat 5 (0–4s local): every stop is quietly bound into a personal field
// journal — the phone pops in over a light page-stack while the manifesto
// line lands beside it.
export const JournalScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const portrait = usePortrait();

  const entrance = popIn(frame, fps, 6);
  const phoneWidth = portrait ? 440 : 380;
  const phoneHeight = portrait ? 900 : 800;

  const phone = (
    <div style={{ position: "relative", width: phoneWidth, height: phoneHeight }}>
      {/* Faint pages peeking out behind the phone — a light "bound journal" feel. */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 62,
          background: colors.paperRaised,
          border: `1px solid ${colors.line}`,
          transform: `rotate(-4deg) translateY(${(1 - entrance) * 16}px)`,
          opacity: entrance * 0.55,
        }}
      />
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 62,
          background: colors.paperRaised,
          border: `1px solid ${colors.line}`,
          transform: `rotate(-2deg) translateY(${(1 - entrance) * 9}px)`,
          opacity: entrance * 0.75,
        }}
      />
      <div
        style={{
          position: "relative",
          opacity: entrance,
          transform: `scale(${0.94 + entrance * 0.06})`,
        }}
      >
        <PhoneFrame width={phoneWidth} height={phoneHeight} statusDark>
          <JournalMockup />
        </PhoneFrame>
      </div>
    </div>
  );

  const copy = (
    <div style={{ maxWidth: 640 }}>
      <SceneHeading
        over="YOUR JOURNAL · 旅程成冊"
        title={
          <>
            你走過的地方，
            <br />
            正在寫成一本書。
          </>
        }
        startFrame={4}
      />
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
