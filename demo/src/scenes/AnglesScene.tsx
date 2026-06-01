import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { PhoneFrame } from "../components/PhoneFrame";
import { PlayerMockup } from "../components/mockups/PlayerMockup";
import { SceneHeading } from "../components/SceneHeading";
import { colors, fonts, paperGrain } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp, popIn } from "../utils/animations";
import { useVideoConfig } from "remotion";

const angles = [
  { num: "01", title: "摧毀與重生的百年豪賭" },
  { num: "02", title: "祭壇之下的神聖祕密" },
  { num: "03", title: "文藝復興巨匠的接力賽" },
];

// Beat 3 (0–6s local): dark section — same landmark, many stories.
export const AnglesScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const portrait = usePortrait();

  const cards = (
    <div style={{ display: "flex", flexDirection: "column", gap: 18, maxWidth: 540 }}>
      {angles.map((a, i) => {
        const p = popIn(frame, fps, 18 + i * 12);
        const selected = i === 0 && frame > 70;
        return (
          <div
            key={a.num}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 22,
              padding: "22px 26px",
              borderRadius: 18,
              background: selected ? colors.clay : "rgba(247,241,230,0.06)",
              border: `1px solid ${selected ? colors.clay : "rgba(247,241,230,0.14)"}`,
              opacity: p,
              transform: `translateX(${(1 - p) * 40}px)`,
            }}
          >
            <span
              style={{
                fontFamily: fonts.serif,
                fontSize: 30,
                fontWeight: 700,
                color: selected ? colors.onDark : colors.clay,
              }}
            >
              {a.num}
            </span>
            <span
              style={{
                fontFamily: fonts.serif,
                fontSize: 28,
                color: colors.onDark,
              }}
            >
              {a.title}
            </span>
          </div>
        );
      })}
    </div>
  );

  const phone = (
    <div
      style={{
        opacity: fadeIn(frame, 60, 20),
        transform: `translateY(${slideUp(frame, 60, 26, 60)}px)`,
      }}
    >
      <PhoneFrame width={portrait ? 440 : 380} height={portrait ? 900 : 800}>
        <PlayerMockup />
      </PhoneFrame>
    </div>
  );

  return (
    <AbsoluteFill style={{ backgroundColor: colors.inkBg }}>
      <AbsoluteFill
        style={{ backgroundImage: paperGrain, backgroundSize: "22px 22px", opacity: 0.4 }}
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
        <div>
          <SceneHeading
            over="Many Angles, One Place"
            title={
              <>
                同一座地標，
                <br />
                不只一個故事
              </>
            }
            startFrame={4}
            onDark
          />
          <div style={{ height: 34 }} />
          {cards}
        </div>
        {phone}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
