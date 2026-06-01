import React from "react";
import { Img, staticFile, useCurrentFrame } from "remotion";
import { colors, fonts } from "../../theme";
import { Waveform } from "../Waveform";

// In-app player screen for the selected angle: photo, "Anno · I" badge,
// serif title and a playing waveform.
export const PlayerMockup: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <div style={{ width: "100%", height: "100%", position: "relative" }}>
      <Img
        src={staticFile("images/stpeters.jpg")}
        alt=""
        style={{ width: "100%", height: "100%", objectFit: "cover" }}
      />
      <div
        style={{
          position: "absolute",
          inset: 0,
          background:
            "linear-gradient(to bottom, rgba(27,22,17,0.25), rgba(27,22,17,0.9))",
        }}
      />
      <div
        style={{
          position: "absolute",
          inset: 0,
          padding: "70px 38px 48px",
          display: "flex",
          flexDirection: "column",
          justifyContent: "flex-end",
          opacity: Math.min(1, frame / 16),
        }}
      >
        <span
          style={{
            alignSelf: "flex-start",
            fontFamily: fonts.sans,
            fontSize: 16,
            fontWeight: 700,
            letterSpacing: "0.16em",
            color: colors.onDark,
            padding: "8px 16px",
            borderRadius: 999,
            background: colors.clay,
          }}
        >
          Anno · I
        </span>
        <div
          style={{
            fontFamily: fonts.serif,
            fontWeight: 700,
            fontSize: 44,
            lineHeight: 1.22,
            color: colors.onDark,
            margin: "20px 0 8px",
          }}
        >
          摧毀與重生的
          <br />
          百年豪賭
        </div>
        <div
          style={{
            fontFamily: fonts.sans,
            fontSize: 20,
            color: colors.onDark2,
            marginBottom: 28,
          }}
        >
          St. Peter&apos;s Basilica
        </div>
        <Waveform width={360} height={48} barCount={40} color={colors.claySoft} />
      </div>
    </div>
  );
};
