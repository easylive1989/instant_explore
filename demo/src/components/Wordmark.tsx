import React from "react";
import { colors, fonts } from "../theme";
import { BrandSeal } from "./BrandSeal";

type Props = {
  size?: number;
  opacity?: number;
  color?: string;
  withSeal?: boolean;
};

// Serif "Lorescape" wordmark, optionally paired with the compass seal.
export const Wordmark: React.FC<Props> = ({
  size = 72,
  opacity = 1,
  color = colors.ink,
  withSeal = true,
}) => {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: size * 0.28,
        opacity,
      }}
    >
      {withSeal ? <BrandSeal size={size * 0.92} /> : null}
      <div
        style={{
          fontFamily: fonts.serif,
          fontWeight: 700,
          fontSize: size,
          letterSpacing: size * 0.01,
          color,
          lineHeight: 1,
        }}
      >
        Lorescape
      </div>
    </div>
  );
};
