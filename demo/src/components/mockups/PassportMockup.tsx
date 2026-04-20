import React from "react";
import { useCurrentFrame, interpolate } from "remotion";
import { easeOutExpo } from "../../utils/animations";

// Mock of the Knowledge Passport screen:
// header filter chips, vertical timeline with story cards on the right.
export const PassportMockup: React.FC = () => {
  const frame = useCurrentFrame();

  const entries = [
    {
      icon: "🏰",
      title: "Edinburgh Castle",
      date: "Apr 18 · Edinburgh",
      snippet: "Q: Who last held the castle during the Jacobite rising?",
    },
    {
      icon: "⛪",
      title: "St Giles' Cathedral",
      date: "Apr 18 · Edinburgh",
      snippet: "Learned about the Covenanters' revolt of 1637.",
    },
    {
      icon: "🎭",
      title: "Royal Mile",
      date: "Apr 18 · Old Town",
      snippet: "Traced 400 years of street performers & trade.",
    },
  ];

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background:
          "linear-gradient(180deg,#0B111A 0%,#111a28 100%)",
        position: "relative",
        overflow: "hidden",
        padding: "58px 20px 0",
      }}
    >
      {/* Header */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 12,
        }}
      >
        <div style={{ color: "#fff", fontSize: 26, fontWeight: 700 }}>
          Passport
        </div>
        <div
          style={{
            width: 36,
            height: 36,
            borderRadius: 999,
            background: "rgba(255,255,255,0.08)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#cbd5e1",
          }}
        >
          ✦
        </div>
      </div>

      {/* Filter chips */}
      <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
        {["Chronological", "Location", "Saved"].map((c, i) => (
          <div
            key={c}
            style={{
              padding: "6px 14px",
              borderRadius: 999,
              fontSize: 12,
              background: i === 0 ? "#137fec" : "rgba(255,255,255,0.06)",
              color: i === 0 ? "#fff" : "#cbd5e1",
              border:
                i === 0
                  ? "1px solid rgba(255,255,255,0.2)"
                  : "1px solid rgba(255,255,255,0.06)",
            }}
          >
            {c}
          </div>
        ))}
      </div>

      <div style={{ color: "#94a3b8", fontSize: 12, marginBottom: 14 }}>
        APRIL 2026
      </div>

      {/* Timeline */}
      <div style={{ position: "relative", paddingLeft: 36 }}>
        {/* Vertical line */}
        <div
          style={{
            position: "absolute",
            left: 14,
            top: 6,
            bottom: 10,
            width: 2,
            background:
              "linear-gradient(180deg,#137fec 0%,rgba(19,127,236,0.2) 100%)",
            borderRadius: 2,
          }}
        />

        {entries.map((e, i) => {
          const start = 20 + i * 30;
          const op = interpolate(frame, [start, start + 20], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          });
          const y = interpolate(frame, [start, start + 30], [24, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: easeOutExpo,
          });
          const dotScale = interpolate(
            frame,
            [start - 6, start + 12],
            [0, 1],
            {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
              easing: easeOutExpo,
            },
          );

          return (
            <div
              key={i}
              style={{
                position: "relative",
                marginBottom: 18,
                opacity: op,
                transform: `translateY(${y}px)`,
              }}
            >
              {/* Dot */}
              <div
                style={{
                  position: "absolute",
                  left: -29,
                  top: 16,
                  width: 16,
                  height: 16,
                  borderRadius: 999,
                  background: "#137fec",
                  border: "3px solid #0B111A",
                  boxShadow: "0 0 14px rgba(19,127,236,0.7)",
                  transform: `scale(${dotScale})`,
                }}
              />
              {/* Card */}
              <div
                style={{
                  background: "rgba(28,38,48,0.85)",
                  backdropFilter: "blur(16px)",
                  border: "1px solid rgba(255,255,255,0.08)",
                  borderRadius: 18,
                  padding: "14px 16px",
                  display: "flex",
                  gap: 12,
                  alignItems: "flex-start",
                }}
              >
                <div
                  style={{
                    width: 44,
                    height: 44,
                    borderRadius: 12,
                    background:
                      "linear-gradient(135deg,#2a4d7a 0%,#1e3556 100%)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontSize: 22,
                    flexShrink: 0,
                  }}
                >
                  {e.icon}
                </div>
                <div style={{ flex: 1 }}>
                  <div
                    style={{
                      color: "#fff",
                      fontSize: 15,
                      fontWeight: 600,
                      marginBottom: 3,
                    }}
                  >
                    {e.title}
                  </div>
                  <div
                    style={{
                      color: "#94a3b8",
                      fontSize: 11,
                      marginBottom: 6,
                    }}
                  >
                    {e.date}
                  </div>
                  <div
                    style={{
                      color: "#cbd5e1",
                      fontSize: 12,
                      lineHeight: 1.45,
                    }}
                  >
                    {e.snippet}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
