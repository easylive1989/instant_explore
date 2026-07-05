import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { PhoneFrame } from "../components/PhoneFrame";
import { ReaderMockup } from "../components/mockups/ReaderMockup";
import { SceneHeading } from "../components/SceneHeading";
import { colors, paperGrain } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp } from "../utils/animations";

// Beat (immersive listening): the paper world falls away into a dark reading
// mode — the phone shows the full-bleed audio reader while a white manifesto
// line lands beside it. The only dark-theme scene in the deck.
export const ReaderScene: React.FC = () => {
  const frame = useCurrentFrame();
  const portrait = usePortrait();

  const phone = (
    <div
      style={{
        opacity: fadeIn(frame, 8, 18),
        transform: `translateY(${slideUp(frame, 8, 24, 56)}px)`,
      }}
    >
      <PhoneFrame
        width={portrait ? 440 : 380}
        height={portrait ? 900 : 800}
        statusDark={false}
      >
        <ReaderMockup />
      </PhoneFrame>
    </div>
  );

  const copy = (
    <div style={{ maxWidth: 640 }}>
      <SceneHeading
        onDark
        over="LISTEN · 沉浸聆聽"
        title={
          <>
            戴上耳機，
            <br />
            讓城市對你朗讀。
          </>
        }
        startFrame={4}
      />
    </div>
  );

  return (
    <AbsoluteFill style={{ backgroundColor: colors.inkBg }}>
      <AbsoluteFill
        style={{
          backgroundImage: paperGrain,
          backgroundSize: "22px 22px",
          opacity: 0.5,
        }}
      />
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(120% 80% at 50% 0%, rgba(188,94,62,0.10), transparent 60%)",
        }}
      />
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
    </AbsoluteFill>
  );
};
