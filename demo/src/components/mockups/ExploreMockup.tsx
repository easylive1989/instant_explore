import React from "react";
import { Img, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { colors, fonts, radius, categoryColors } from "../../theme";
import { popIn } from "../../utils/animations";
import { nearbyPlaces, exploreChips } from "../../data";

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
        {exploreChips.map((c, i) => (
          <span
            key={c}
            style={{
              fontFamily: fonts.sans,
              fontSize: 17,
              fontWeight: 500,
              color: i === 0 ? colors.onDark : colors.clayDeep,
              background: i === 0 ? colors.clay : colors.clayTint,
              padding: "9px 18px",
              borderRadius: radius.pill,
              opacity: popIn(frame, fps, 10 + i * 5),
            }}
          >
            {c}
          </span>
        ))}
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        {nearbyPlaces.map((n, i) => {
          const p = popIn(frame, fps, 26 + i * 12);
          const cat = categoryColors[n.cat];
          return (
            <div
              key={n.name}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 18,
                padding: 14,
                borderRadius: radius.lg,
                background: colors.paper,
                border: `1px solid ${colors.line}`,
                opacity: p,
                transform: `translateY(${(1 - p) * 24}px)`,
              }}
            >
              <Img
                src={staticFile(n.img)}
                alt=""
                style={{ width: 78, height: 78, borderRadius: radius.img, objectFit: "cover", flex: "none" }}
              />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: fonts.serif, fontSize: 26, color: colors.ink }}>
                  {n.name}
                </div>
                <div
                  style={{
                    fontFamily: fonts.sans,
                    fontSize: 13,
                    fontWeight: 600,
                    letterSpacing: "0.05em",
                    textTransform: "uppercase",
                    color: colors.ink3,
                    marginTop: 4,
                  }}
                >
                  {n.latin}
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 6 }}>
                  <span
                    style={{
                      width: 8,
                      height: 8,
                      borderRadius: radius.pill,
                      background: cat.ink,
                      flex: "none",
                    }}
                  />
                  <span style={{ fontFamily: fonts.sans, fontSize: 18, color: colors.clay }}>
                    {n.dist}
                  </span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
