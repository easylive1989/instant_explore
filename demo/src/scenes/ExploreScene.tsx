import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { PhoneFrame } from "../components/PhoneFrame";
import { ExploreMockup } from "../components/mockups/ExploreMockup";
import { SceneHeading } from "../components/SceneHeading";
import { colors, fonts } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp } from "../utils/animations";

// Beat 4 (0–5s local): a real landmark fades in as ambience, then the phone
// rises from below to show the "explore nearby" screen — the manifesto beat.
export const ExploreScene: React.FC = () => {
  const frame = useCurrentFrame();
  const portrait = usePortrait();

  // Landmark photo, kept subtle and masked toward one side so it reads as
  // ambience behind the paper backdrop rather than a full-bleed hero shot.
  const landmark = (
    <AbsoluteFill
      style={{
        opacity: 0.22 * fadeIn(frame, 0, 40),
        WebkitMaskImage:
          "radial-gradient(65% 85% at 82% 42%, black 0%, black 35%, transparent 78%)",
        maskImage:
          "radial-gradient(65% 85% at 82% 42%, black 0%, black 35%, transparent 78%)",
      }}
    >
      <Img
        src={staticFile("images/stpeters.jpg")}
        alt=""
        style={{ width: "100%", height: "100%", objectFit: "cover" }}
      />
    </AbsoluteFill>
  );

  const phone = (
    <div
      style={{
        opacity: fadeIn(frame, 0, 20),
        transform: `translateY(${slideUp(frame, 0, 24, 90)}px)`,
      }}
    >
      <PhoneFrame
        width={portrait ? 440 : 380}
        height={portrait ? 900 : 800}
        statusDark
      >
        <ExploreMockup />
      </PhoneFrame>
    </div>
  );

  const copy = (
    <div style={{ maxWidth: 820 }}>
      <SceneHeading
        over="EXPLORE · 探索身邊"
        title={
          <>
            每一個地方，
            <br />
            都是一則等待被讀的故事。
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
        依距離與主題，為你列出附近值得停留的每一個角落。
      </p>
    </div>
  );

  return (
    <PaperBackdrop>
      {landmark}
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
