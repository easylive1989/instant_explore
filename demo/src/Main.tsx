import React from "react";
import {
  AbsoluteFill,
  Audio,
  Sequence,
  getStaticFiles,
  staticFile,
} from "remotion";
import { HookScene } from "./scenes/HookScene";
import { ExploreScene } from "./scenes/ExploreScene";
import { AnglesScene } from "./scenes/AnglesScene";
import { ReaderScene } from "./scenes/ReaderScene";
import { JournalScene } from "./scenes/JournalScene";
import { CtaScene } from "./scenes/CtaScene";
import { colors } from "./theme";

// Scene ranges (30fps, 900 frames total):
// Hook     0–150   (5s)   manifesto opener
// Explore  150–330 (6s)   feature 01 explore nearby
// Angles   330–510 (6s)   feature 02 many angles
// Reader   510–690 (6s)   feature 03 immersive reader
// Journal  690–810 (4s)   feature 04 journey journal
// CTA      810–900 (3s)
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
        <ExploreScene />
      </Sequence>
      <Sequence from={330} durationInFrames={180}>
        <AnglesScene />
      </Sequence>
      <Sequence from={510} durationInFrames={180}>
        <ReaderScene />
      </Sequence>
      <Sequence from={690} durationInFrames={120}>
        <JournalScene />
      </Sequence>
      <Sequence from={810} durationInFrames={120}>
        <CtaScene />
      </Sequence>
    </AbsoluteFill>
  );
};
