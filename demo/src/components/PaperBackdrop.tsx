import React from "react";
import { AbsoluteFill } from "remotion";
import { colors, paperGrain } from "../theme";

type Props = {
  children?: React.ReactNode;
  tone?: "paper" | "sunk";
};

// Warm paper background with a subtle repeating grain and a soft clay vignette.
// The shared backdrop for every light scene (Hook / Story / Explore / Journal).
export const PaperBackdrop: React.FC<Props> = ({
  children,
  tone = "paper",
}) => {
  const base = tone === "sunk" ? colors.paperSunk : colors.paper;
  return (
    <AbsoluteFill style={{ backgroundColor: base }}>
      <AbsoluteFill
        style={{
          backgroundImage: paperGrain,
          backgroundSize: "22px 22px",
        }}
      />
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(120% 80% at 50% 0%, rgba(188,94,62,0.06), transparent 60%)",
        }}
      />
      {children}
    </AbsoluteFill>
  );
};
