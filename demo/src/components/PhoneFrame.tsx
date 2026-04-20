import React from "react";

type Props = {
  children: React.ReactNode;
  width?: number;
  height?: number;
};

// Lightweight iPhone mockup with a notch and rounded bezel.
// Pure CSS/SVG — no external assets.
export const PhoneFrame: React.FC<Props> = ({
  children,
  width = 430,
  height = 900,
}) => {
  const radius = 62;
  const bezel = 14;

  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius,
        padding: bezel,
        background:
          "linear-gradient(160deg, #1b2330 0%, #0c1119 55%, #1a2230 100%)",
        boxShadow:
          "0 40px 120px rgba(0,0,0,0.55), 0 0 0 1px rgba(255,255,255,0.04), inset 0 0 0 1px rgba(255,255,255,0.06)",
        position: "relative",
      }}
    >
      <div
        style={{
          width: "100%",
          height: "100%",
          borderRadius: radius - bezel,
          overflow: "hidden",
          position: "relative",
          background: "#0B111A",
        }}
      >
        {children}
        {/* Dynamic island */}
        <div
          style={{
            position: "absolute",
            top: 14,
            left: "50%",
            transform: "translateX(-50%)",
            width: 110,
            height: 30,
            borderRadius: 999,
            background: "#000",
            zIndex: 10,
          }}
        />
      </div>
    </div>
  );
};
