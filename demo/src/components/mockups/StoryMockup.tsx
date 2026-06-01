import React from "react";
import { Img, staticFile, useCurrentFrame } from "remotion";
import { colors, fonts } from "../../theme";
import { Waveform } from "../Waveform";

const lines = [
  "儒略二世決定拆毀君士坦丁",
  "大帝的千年古教堂，這場瘋",
  "狂的重建，竟耗時百餘年。",
  "米開朗基羅與拉斐爾輪番上",
  "陣，在同一座教堂留下印記。",
];

// In-app screen: a place photo, a serif title, and a story that types in
// line-by-line, with a "tap to listen" waveform at the bottom.
export const StoryMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const visibleLines = Math.min(lines.length, Math.floor((frame - 20) / 16));

  return (
    <div style={{ width: "100%", height: "100%", background: colors.paperRaised }}>
      <div style={{ height: "38%", overflow: "hidden", position: "relative" }}>
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
              "linear-gradient(to bottom, rgba(0,0,0,0) 50%, rgba(27,22,17,0.55))",
          }}
        />
      </div>
      <div style={{ padding: "30px 34px" }}>
        <span
          style={{
            fontFamily: fonts.sans,
            fontSize: 14,
            fontWeight: 700,
            letterSpacing: "0.18em",
            textTransform: "uppercase",
            color: colors.clay,
          }}
        >
          St. Peter&apos;s Basilica
        </span>
        <div
          style={{
            fontFamily: fonts.serif,
            fontWeight: 700,
            fontSize: 36,
            lineHeight: 1.25,
            color: colors.ink,
            margin: "12px 0 22px",
          }}
        >
          摧毀與重生的
          <br />
          百年豪賭
        </div>
        <div
          style={{
            fontFamily: fonts.serif,
            fontSize: 26,
            lineHeight: 1.7,
            color: colors.ink2,
          }}
        >
          {lines.map((line, i) => (
            <div
              key={line}
              style={{
                opacity: i < visibleLines ? 1 : 0,
              }}
            >
              {line}
            </div>
          ))}
        </div>
        <div
          style={{
            marginTop: 30,
            display: "flex",
            alignItems: "center",
            gap: 16,
            padding: "16px 22px",
            borderRadius: 16,
            background: colors.clayTint,
          }}
        >
          <Waveform width={220} height={40} barCount={32} />
          <span
            style={{
              fontFamily: fonts.sans,
              fontSize: 18,
              fontWeight: 500,
              color: colors.clayDeep,
            }}
          >
            一鍵化為語音
          </span>
        </div>
      </div>
    </div>
  );
};
