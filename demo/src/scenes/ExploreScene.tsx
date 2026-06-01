import React from "react";
import { AbsoluteFill, Img, staticFile, useCurrentFrame } from "remotion";
import { PhoneFrame } from "../components/PhoneFrame";
import { ExploreMockup } from "../components/mockups/ExploreMockup";
import { SceneHeading } from "../components/SceneHeading";
import { colors, fonts } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp } from "../utils/animations";

// Beat 4 (0–5s local): full-bleed park photo + nearby exploration.
export const ExploreScene: React.FC = () => {
  const frame = useCurrentFrame();
  const portrait = usePortrait();

  const phone = (
    <div
      style={{
        opacity: fadeIn(frame, 10, 20),
        transform: `translateY(${slideUp(frame, 10, 26, 60)}px)`,
      }}
    >
      <PhoneFrame width={portrait ? 440 : 380} height={portrait ? 900 : 800}>
        <ExploreMockup />
      </PhoneFrame>
    </div>
  );

  const copy = (
    <div style={{ maxWidth: 540 }}>
      <SceneHeading over="Explore Nearby" title="探索身邊的風景" startFrame={4} onDark />
      <p
        style={{
          fontFamily: fonts.sans,
          fontSize: 24,
          lineHeight: 1.7,
          color: colors.onDark2,
          marginTop: 28,
          opacity: fadeIn(frame, 24, 20),
        }}
      >
        依距離與主題，為你列出附近值得停留的每一個角落——每一種風景，都有屬於它的故事。
      </p>
    </div>
  );

  return (
    <AbsoluteFill style={{ backgroundColor: colors.inkBg }}>
      <AbsoluteFill style={{ opacity: 0.55 }}>
        <Img
          src={staticFile("images/park.jpg")}
          alt=""
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
      </AbsoluteFill>
      <AbsoluteFill
        style={{
          background:
            "linear-gradient(120deg, rgba(27,22,17,0.92), rgba(27,22,17,0.55))",
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
