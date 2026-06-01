import React from "react";
import { useCurrentFrame } from "remotion";

type Props = {
  width?: number;
  height?: number;
  barCount?: number;
  color?: string;
};

// Animated audio waveform driven by useCurrentFrame.
// No real audio analysis — purely procedural to visualize narration.
export const Waveform: React.FC<Props> = ({
  width = 320,
  height = 64,
  barCount = 48,
  color = "#bc5e3e",
}) => {
  const frame = useCurrentFrame();

  const bars = Array.from({ length: barCount }).map((_, i) => {
    const phase = i * 0.35 + frame * 0.28;
    const amp =
      0.45 + 0.55 * Math.abs(Math.sin(phase)) * (0.4 + 0.6 * Math.sin(phase * 0.6 + i * 0.1));
    const h = Math.max(3, amp * height);
    return { h };
  });

  const gap = 3;
  const barWidth = (width - gap * (barCount - 1)) / barCount;

  return (
    <svg width={width} height={height} style={{ overflow: "visible" }}>
      {bars.map((b, i) => (
        <rect
          key={i}
          x={i * (barWidth + gap)}
          y={(height - b.h) / 2}
          width={barWidth}
          height={b.h}
          rx={barWidth / 2}
          fill={color}
          opacity={0.75 + 0.25 * ((i % 7) / 6)}
        />
      ))}
    </svg>
  );
};
