import React from "react";
import { useCurrentFrame, interpolate } from "remotion";
import { easeOutExpo } from "../../utils/animations";

// Mock of the Lorescape Home screen:
// dark map background with glowing points + glassmorphism place cards.
export const HomeMockup: React.FC = () => {
  const frame = useCurrentFrame();

  const card1 = interpolate(frame, [10, 34], [40, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });
  const card2 = interpolate(frame, [22, 46], [40, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });
  const card3 = interpolate(frame, [34, 58], [40, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

  const cardOp = (from: number) =>
    interpolate(frame, [from, from + 20], [0, 1], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    });

  const pinPulse = 0.6 + 0.4 * Math.sin(frame * 0.1);

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: "#0B111A",
        position: "relative",
        overflow: "hidden",
        display: "flex",
        flexDirection: "column",
      }}
    >
      {/* Map background */}
      <svg
        width="100%"
        height="100%"
        viewBox="0 0 402 874"
        preserveAspectRatio="xMidYMid slice"
        style={{ position: "absolute", inset: 0, opacity: 0.55 }}
      >
        <defs>
          <radialGradient id="mapGlow" cx="50%" cy="40%" r="70%">
            <stop offset="0%" stopColor="#1b2a3f" />
            <stop offset="100%" stopColor="#0B111A" />
          </radialGradient>
        </defs>
        <rect width="402" height="874" fill="url(#mapGlow)" />
        {/* Street grid */}
        <g stroke="#2a3a52" strokeWidth="0.9" fill="none" opacity="0.55">
          <path d="M -20 180 L 440 120" />
          <path d="M -20 260 L 440 210" />
          <path d="M -20 360 Q 200 320 440 380" />
          <path d="M -20 480 L 440 460" />
          <path d="M -20 600 Q 200 560 440 620" />
          <path d="M 60 -10 L 120 880" />
          <path d="M 180 -10 Q 210 400 170 880" />
          <path d="M 300 -10 L 260 880" />
        </g>
        {/* Water patch */}
        <path
          d="M 280 480 Q 360 520 402 500 L 402 620 Q 360 640 280 620 Z"
          fill="#123"
          opacity="0.6"
        />
        {/* Parks */}
        <path d="M 50 120 L 160 100 L 180 200 L 60 220 Z" fill="#1b2e24" opacity="0.6" />
      </svg>

      {/* Glowing map pins */}
      <svg
        width="100%"
        height="100%"
        viewBox="0 0 402 874"
        preserveAspectRatio="xMidYMid slice"
        style={{ position: "absolute", inset: 0 }}
      >
        {[
          { x: 110, y: 260 },
          { x: 250, y: 190 },
          { x: 300, y: 360 },
          { x: 130, y: 430 },
          { x: 215, y: 500 },
        ].map((p, i) => (
          <g key={i}>
            <circle
              cx={p.x}
              cy={p.y}
              r={22 * pinPulse}
              fill="#137fec"
              opacity={0.15}
            />
            <circle cx={p.x} cy={p.y} r={5} fill="#137fec" />
            <circle cx={p.x} cy={p.y} r={2} fill="#fff" />
          </g>
        ))}
      </svg>

      {/* Top bar */}
      <div
        style={{
          padding: "58px 24px 12px",
          position: "relative",
          zIndex: 2,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <div style={{ color: "#fff", fontSize: 28, fontWeight: 700 }}>
          Explore
        </div>
        <div
          style={{
            width: 38,
            height: 38,
            borderRadius: 999,
            background: "rgba(255,255,255,0.08)",
            border: "1px solid rgba(255,255,255,0.08)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#fff",
            fontSize: 18,
          }}
        >
          ↻
        </div>
      </div>

      {/* Place cards (glassmorphism) */}
      <div
        style={{
          position: "absolute",
          bottom: 110,
          left: 0,
          right: 0,
          padding: "0 20px",
          display: "flex",
          flexDirection: "column",
          gap: 14,
          zIndex: 3,
        }}
      >
        {[
          {
            title: "Edinburgh Castle",
            distance: "320 m",
            era: "12th century · Fortress",
            y: card1,
            op: cardOp(10),
          },
          {
            title: "St Giles' Cathedral",
            distance: "550 m",
            era: "14th century · Kirk",
            y: card2,
            op: cardOp(22),
          },
          {
            title: "Royal Mile",
            distance: "780 m",
            era: "Historic street",
            y: card3,
            op: cardOp(34),
          },
        ].map((c, i) => (
          <div
            key={i}
            style={{
              transform: `translateY(${c.y}px)`,
              opacity: c.op,
              background: "rgba(255,255,255,0.08)",
              backdropFilter: "blur(16px)",
              WebkitBackdropFilter: "blur(16px)",
              borderRadius: 20,
              padding: "14px 16px",
              border: "1px solid rgba(255,255,255,0.1)",
              display: "flex",
              gap: 14,
              alignItems: "center",
            }}
          >
            <div
              style={{
                width: 54,
                height: 54,
                borderRadius: 14,
                background:
                  "linear-gradient(135deg,#2a4d7a 0%,#1e3556 100%)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 24,
              }}
            >
              🏰
            </div>
            <div style={{ flex: 1 }}>
              <div
                style={{
                  color: "#fff",
                  fontSize: 16,
                  fontWeight: 600,
                  marginBottom: 3,
                }}
              >
                {c.title}
              </div>
              <div style={{ color: "#cbd5e1", fontSize: 12 }}>
                {c.era} · {c.distance}
              </div>
            </div>
            <div
              style={{
                width: 34,
                height: 34,
                borderRadius: 999,
                background: "#137fec",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#fff",
                fontSize: 14,
              }}
            >
              ▶
            </div>
          </div>
        ))}
      </div>

      {/* Bottom tab bar */}
      <div
        style={{
          position: "absolute",
          bottom: 20,
          left: 20,
          right: 20,
          height: 66,
          borderRadius: 22,
          background: "rgba(20,28,42,0.8)",
          backdropFilter: "blur(18px)",
          border: "1px solid rgba(255,255,255,0.08)",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-around",
          zIndex: 4,
        }}
      >
        {[
          { icon: "◎", active: true, label: "Home" },
          { icon: "◈", label: "Map" },
          { icon: "✦", label: "Passport" },
          { icon: "◔", label: "Profile" },
        ].map((t, i) => (
          <div
            key={i}
            style={{
              color: t.active ? "#137fec" : "#94a3b8",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              fontSize: 11,
              gap: 3,
            }}
          >
            <div style={{ fontSize: 20 }}>{t.icon}</div>
            <div>{t.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
};
