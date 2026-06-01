import React from "react";
import {
  AbsoluteFill,
  Audio,
  Sequence,
  getStaticFiles,
  staticFile,
} from "remotion";
import { HookScene } from "./scenes/HookScene";
import { StoryScene } from "./scenes/StoryScene";
import { AnglesScene } from "./scenes/AnglesScene";
import { ExploreScene } from "./scenes/ExploreScene";
import { JournalScene } from "./scenes/JournalScene";
import { CtaScene } from "./scenes/CtaScene";
import { colors } from "./theme";

// Scene ranges (30fps, 900 frames total):
// Hook     0–150   (5s)   manifesto opener
// Story  150–330   (6s)   feature 01 instant story
// Angles 330–510   (6s)   feature 02 many angles
// Explore510–660   (5s)   feature 03 explore nearby
// Journal660–780   (4s)   feature 04 journey journal
// CTA    780–900   (4s)
const hasFile = (name: string) => getStaticFiles().some((f) => f.name === name);

export const Main: React.FC = () => {
  const hasBgm = hasFile("bgm.mp3");

  return (
    <AbsoluteFill style={{ background: colors.paper }}>
      {hasBgm ? <Audio src={staticFile("bgm.mp3")} volume={0.8} /> : null}

      <Sequence durationInFrames={150}>
        <HookScene />
      </Sequence>
      <Sequence from={150} durationInFrames={180}>
        <StoryScene />
      </Sequence>
      <Sequence from={330} durationInFrames={180}>
        <AnglesScene />
      </Sequence>
      <Sequence from={510} durationInFrames={150}>
        <ExploreScene />
      </Sequence>
      <Sequence from={660} durationInFrames={120}>
        <JournalScene />
      </Sequence>
      <Sequence from={780} durationInFrames={120}>
        <CtaScene />
      </Sequence>
    </AbsoluteFill>
  );
};
