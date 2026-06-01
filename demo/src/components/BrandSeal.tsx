import React from "react";
import { colors } from "../theme";

type Props = {
  size?: number;
  discColor?: string;
  markColor?: string;
};

// Circular "compass seal" brand mark inside a clay disc.
export const BrandSeal: React.FC<Props> = ({
  size = 64,
  discColor = colors.clay,
  markColor = colors.onDark,
}) => {
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        background: discColor,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        boxShadow: "0 8px 22px rgba(151,68,42,0.32)",
      }}
    >
      <svg
        width={size * 0.58}
        height={size * 0.58}
        viewBox="0 0 24 24"
        fill="none"
        stroke={markColor}
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <circle cx="12" cy="12" r="9" />
        <polygon
          points="15.5 8.5 10.5 10.5 8.5 15.5 13.5 13.5"
          fill={markColor}
          stroke="none"
        />
      </svg>
    </div>
  );
};
