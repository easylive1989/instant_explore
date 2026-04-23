import React from "react";

type Props = {
  size?: number;
  opacity?: number;
  letterSpacing?: number;
};

export const Wordmark: React.FC<Props> = ({
  size = 72,
  opacity = 1,
  letterSpacing = -1.5,
}) => {
  return (
    <div
      style={{
        fontFamily:
          '"Inter","Noto Sans",-apple-system,BlinkMacSystemFont,sans-serif',
        fontWeight: 600,
        fontSize: size,
        letterSpacing,
        color: "#fff",
        opacity,
        lineHeight: 1,
      }}
    >
      Lorescape
    </div>
  );
};
