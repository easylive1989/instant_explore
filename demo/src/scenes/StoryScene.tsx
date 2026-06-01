import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { PhoneFrame } from "../components/PhoneFrame";
import { SceneHeading } from "../components/SceneHeading";
import { StoryMockup } from "../components/mockups/StoryMockup";
import { fonts, colors } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp } from "../utils/animations";

// Beat 2 (0–6s local): "write a story for the place in front of you".
export const StoryScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const portrait = usePortrait();

  const phone = (
    <div
      style={{
        opacity: fadeIn(frame, 10, 20),
        transform: `translateY(${slideUp(frame, 10, 26, 60)}px)`,
      }}
    >
      <PhoneFrame width={portrait ? 460 : 410} height={portrait ? 940 : 840}>
        <StoryMockup />
      </PhoneFrame>
    </div>
  );

  const copy = (
    <div style={{ maxWidth: 560 }}>
      <SceneHeading
        over="Local Stories"
        title={
          <>
            為眼前的風景，
            <br />
            即時寫一篇故事
          </>
        }
        startFrame={4}
      />
      <p
        style={{
          fontFamily: fonts.sans,
          fontSize: 24,
          lineHeight: 1.7,
          color: colors.ink2,
          marginTop: 28,
          opacity: fadeIn(frame, 24, 20),
        }}
      >
        不是條列式的百科資料。Lorescape 為你經過的每座地標當場編寫一篇有人物、有轉折、值得細讀的故事。
      </p>
    </div>
  );

  void fps;

  return (
    <PaperBackdrop>
      <AbsoluteFill
        style={{
          flexDirection: portrait ? "column" : "row",
          alignItems: "center",
          justifyContent: "center",
          gap: portrait ? 48 : 110,
          padding: portrait ? "90px 60px" : "0 140px",
        }}
      >
        {portrait ? (
          <>
            {copy}
            {phone}
          </>
        ) : (
          <>
            {copy}
            {phone}
          </>
        )}
      </AbsoluteFill>
    </PaperBackdrop>
  );
};
