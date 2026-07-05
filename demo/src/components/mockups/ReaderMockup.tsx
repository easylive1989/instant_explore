import React from "react";
import {
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";
import { colors, fonts, radius } from "../../theme";
import { stPetersStory as s } from "../../data";
import { Waveform } from "../Waveform";
import { fadeIn } from "../../utils/animations";

// docs/design immersive reader：深底襯線正文 + dropcap + 底部 audiobar。
export const ReaderMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const pct = Math.round(interpolate(frame, [30, 170], [4, 34], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  }));

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: colors.inkBg,
        color: colors.onDark,
        position: "relative",
      }}
    >
      <div style={{ height: "40%", position: "relative", overflow: "hidden" }}>
        <Img
          src={staticFile(s.img)}
          alt=""
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
        <div
          style={{
            position: "absolute",
            inset: 0,
            background:
              "linear-gradient(to bottom, rgba(0,0,0,0.1) 40%, rgba(27,22,17,0.92))",
          }}
        />
        <div style={{ position: "absolute", left: 34, bottom: 118 }}>
          <span
            style={{
              display: "inline-flex",
              alignItems: "center",
              height: 44,
              padding: "0 18px",
              border: "1px solid rgba(255,255,255,0.55)",
              borderRadius: 8,
              color: "#fff",
              fontFamily: fonts.sans,
              fontSize: 18,
              fontWeight: 600,
              letterSpacing: "0.16em",
            }}
          >
            {s.chapter}
          </span>
        </div>
        <div
          style={{
            position: "absolute",
            left: 34,
            right: 34,
            bottom: 34,
          }}
        >
          <div
            style={{
              fontFamily: fonts.sans,
              fontSize: 18,
              letterSpacing: "0.14em",
              color: "rgba(255,255,255,0.8)",
              marginBottom: 12,
            }}
          >
            {s.latin}
          </div>
          <div
            style={{
              fontFamily: fonts.serif,
              fontWeight: 700,
              fontSize: 46,
              lineHeight: 1.12,
              color: "#fff",
            }}
          >
            {s.title}
          </div>
        </div>
      </div>

      <div style={{ padding: "34px 34px 160px" }}>
        <p
          style={{
            fontFamily: fonts.serif,
            fontSize: 30,
            lineHeight: 1.9,
            color: colors.onDark,
            margin: 0,
            opacity: fadeIn(frame, 24, 20),
          }}
        >
          <span
            style={{
              float: "left",
              fontFamily: fonts.serif,
              fontWeight: 700,
              fontSize: 104,
              lineHeight: 0.84,
              padding: "8px 18px 0 0",
              color: colors.clay,
            }}
          >
            {s.dropcap}
          </span>
          {s.body[0]}
        </p>
        <p
          style={{
            fontFamily: fonts.serif,
            fontSize: 30,
            lineHeight: 1.9,
            color: colors.onDark2,
            marginTop: 28,
            opacity: fadeIn(frame, 70, 20),
          }}
        >
          {s.body[1]}
        </p>
      </div>

      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          bottom: 0,
          padding: "22px 28px 34px",
          background:
            "linear-gradient(to top, rgba(27,22,17,1), rgba(27,22,17,0))",
          display: "flex",
          alignItems: "center",
          gap: 16,
        }}
      >
        <div
          style={{
            width: 72,
            height: 72,
            borderRadius: radius.pill,
            background: colors.clay,
            display: "grid",
            placeItems: "center",
            flex: "none",
          }}
        >
          <svg width="30" height="30" viewBox="0 0 24 24" fill="#fff">
            <rect x="6" y="5" width="4" height="14" rx="1" />
            <rect x="14" y="5" width="4" height="14" rx="1" />
          </svg>
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <Waveform width={360} height={40} barCount={40} color={colors.clay} />
          <div
            style={{
              height: 6,
              borderRadius: radius.pill,
              background: "rgba(255,255,255,0.16)",
              marginTop: 8,
              overflow: "hidden",
            }}
          >
            <div
              style={{
                width: `${pct}%`,
                height: "100%",
                background: colors.clay,
                borderRadius: radius.pill,
              }}
            />
          </div>
        </div>
        <div
          style={{
            flex: "none",
            fontFamily: fonts.sans,
            fontWeight: 600,
            fontSize: 22,
            color: colors.onDark2,
            fontVariantNumeric: "tabular-nums",
            minWidth: 52,
            textAlign: "right",
          }}
        >
          {pct}%
        </div>
      </div>
    </div>
  );
};
