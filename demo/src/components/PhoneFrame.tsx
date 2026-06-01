import React from "react";
import { colors } from "../theme";

type Props = {
  children: React.ReactNode;
  width?: number;
  height?: number;
};

// Light-theme iPhone mockup: warm bezel, white screen, dynamic island.
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
        background: `linear-gradient(160deg, #2c241c 0%, #15110c 55%, #2c241c 100%)`,
        boxShadow:
          "0 40px 110px rgba(28,20,10,0.45), 0 0 0 1px rgba(255,255,255,0.04)",
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
          background: colors.paperRaised,
        }}
      >
        {children}
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
