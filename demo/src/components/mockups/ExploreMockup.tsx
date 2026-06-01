import React from "react";
import { Img, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { colors, fonts } from "../../theme";
import { popIn } from "../../utils/animations";

const nearby = [
  { name: "台中朝聖宮", dist: "320 m", img: "images/temple.jpg" },
  { name: "聖伯多祿大殿", dist: "1.2 km", img: "images/stpeters.jpg" },
  { name: "中央公園步道", dist: "650 m", img: "images/park.jpg" },
];

const chips = ["自然景觀", "人文古蹟", "信仰聖地", "城市地標"];

// In-app "explore nearby" list: distance-sorted place cards + category chips.
export const ExploreMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <div style={{ width: "100%", height: "100%", background: colors.paperRaised, padding: "70px 30px 30px" }}>
      <div
        style={{
          fontFamily: fonts.serif,
          fontWeight: 700,
          fontSize: 34,
          color: colors.ink,
          marginBottom: 6,
        }}
      >
        附近值得停留
      </div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, margin: "16px 0 24px" }}>
        {chips.map((c, i) => (
          <span
            key={c}
            style={{
              fontFamily: fonts.sans,
              fontSize: 17,
              fontWeight: 500,
              color: i === 0 ? colors.onDark : colors.clayDeep,
              background: i === 0 ? colors.clay : colors.clayTint,
              padding: "9px 18px",
              borderRadius: 999,
              opacity: popIn(frame, fps, 10 + i * 5),
            }}
          >
            {c}
          </span>
        ))}
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        {nearby.map((n, i) => {
          const p = popIn(frame, fps, 26 + i * 12);
          return (
            <div
              key={n.name}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 18,
                padding: 14,
                borderRadius: 18,
                background: colors.paper,
                border: `1px solid ${colors.line}`,
                opacity: p,
                transform: `translateY(${(1 - p) * 24}px)`,
              }}
            >
              <Img
                src={staticFile(n.img)}
                alt=""
                style={{ width: 78, height: 78, borderRadius: 14, objectFit: "cover" }}
              />
              <div>
                <div style={{ fontFamily: fonts.serif, fontSize: 26, color: colors.ink }}>
                  {n.name}
                </div>
                <div style={{ fontFamily: fonts.sans, fontSize: 18, color: colors.clay, marginTop: 4 }}>
                  {n.dist}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
