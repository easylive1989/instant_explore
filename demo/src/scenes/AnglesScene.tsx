import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { PhoneFrame } from "../components/PhoneFrame";
import { StoryOptionsMockup } from "../components/mockups/StoryOptionsMockup";
import { SceneHeading } from "../components/SceneHeading";
import { usePortrait } from "../utils/layout";
import { popIn } from "../utils/animations";

// Beat 3 (0–6s local): same landmark, three ways to read it — the phone pops
// in showing the story-options screen while the manifesto line lands beside it.
export const AnglesScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const portrait = usePortrait();

  const entrance = popIn(frame, fps, 6);

  const phone = (
    <div
      style={{
        opacity: entrance,
        transform: `scale(${0.94 + entrance * 0.06})`,
      }}
    >
      <PhoneFrame
        width={portrait ? 440 : 380}
        height={portrait ? 900 : 800}
        statusDark
      >
        <StoryOptionsMockup />
      </PhoneFrame>
    </div>
  );

  const copy = (
    <div style={{ maxWidth: 720 }}>
      <SceneHeading
        over="MANY ANGLES · 一書多章"
        title={
          <>
            同一座教堂，
            <br />
            藏著三種讀法。
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
