import React from "react";
import {
  AbsoluteFill,
  Audio,
  Sequence,
  getStaticFiles,
  staticFile,
} from "remotion";
import { HookScene } from "./scenes/HookScene";
import { IntroScene } from "./scenes/IntroScene";
import { NarrationScene } from "./scenes/NarrationScene";
import { PassportScene } from "./scenes/PassportScene";
import { CtaScene } from "./scenes/CtaScene";

// Scene ranges (30fps):
// Hook       0–150   (5s)
// Intro    150–300   (5s)
// Narration 300–540  (8s)
// Passport  540–750  (7s)
// CTA       750–900  (5s)

const hasFile = (name: string) =>
  getStaticFiles().some((f) => f.name === name);

export const Main: React.FC = () => {
  const hasBgm = hasFile("bgm.mp3");

  return (
    <AbsoluteFill style={{ background: "#05080d" }}>
      {hasBgm ? (
        <Audio src={staticFile("bgm.mp3")} volume={0.8} />
      ) : null}

      <Sequence durationInFrames={150}>
        <HookScene />
      </Sequence>
      <Sequence from={150} durationInFrames={150}>
        <IntroScene />
      </Sequence>
      <Sequence from={300} durationInFrames={240}>
        <NarrationScene />
      </Sequence>
      <Sequence from={540} durationInFrames={210}>
        <PassportScene />
      </Sequence>
      <Sequence from={750} durationInFrames={150}>
        <CtaScene />
      </Sequence>
    </AbsoluteFill>
  );
};
