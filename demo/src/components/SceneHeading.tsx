import React from "react";
import { useCurrentFrame } from "remotion";
import { colors, fonts } from "../theme";
import { fadeIn, slideUp } from "../utils/animations";

type Props = {
  over: string;
  title: React.ReactNode;
  startFrame?: number;
  align?: "left" | "center";
  onDark?: boolean;
};

// Over-line (uppercase clay kicker) + serif headline, with a staggered
// fade/slide-in. Shared by every feature scene.
export const SceneHeading: React.FC<Props> = ({
  over,
  title,
  startFrame = 0,
  align = "left",
  onDark = false,
}) => {
  const frame = useCurrentFrame();
  const titleColor = onDark ? colors.onDark : colors.ink;

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: align === "center" ? "center" : "flex-start",
        textAlign: align,
        gap: 16,
      }}
    >
      <span
        style={{
          fontFamily: fonts.sans,
          fontSize: 18,
          fontWeight: 700,
          letterSpacing: "0.22em",
          textTransform: "uppercase",
          color: colors.clay,
          opacity: fadeIn(frame, startFrame, 14),
          transform: `translateY(${slideUp(frame, startFrame, 18, 24)}px)`,
        }}
      >
        {over}
      </span>
      <h2
        style={{
          fontFamily: fonts.serif,
          fontWeight: 700,
          fontSize: 64,
          lineHeight: 1.18,
          color: titleColor,
          margin: 0,
          opacity: fadeIn(frame, startFrame + 6, 16),
          transform: `translateY(${slideUp(frame, startFrame + 6, 22, 40)}px)`,
        }}
      >
        {title}
      </h2>
    </div>
  );
};
