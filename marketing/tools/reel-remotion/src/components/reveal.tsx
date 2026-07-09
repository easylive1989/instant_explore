import { interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";

export interface RevealProps {
  /** Frame at which this element starts animating in. */
  delay: number;
  children: React.ReactNode;
  /** Slide-in distance in px. Positive = rises from below. */
  fromY?: number;
  fromX?: number;
  /** Optional fade-out near the end of the beat. */
  fadeOutAt?: number;
  style?: React.CSSProperties;
  damping?: number;
}

/**
 * Fades and slides a piece of content into place using a spring, so the
 * motion has weight instead of a mechanical linear ramp.
 */
export const Reveal: React.FC<RevealProps> = ({
  delay,
  children,
  fromY = 24,
  fromX = 0,
  fadeOutAt,
  style,
  damping = 200,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const enter = spring({
    frame: frame - delay,
    fps,
    config: { damping },
    durationInFrames: 24,
  });

  const opacityOut =
    fadeOutAt !== undefined
      ? interpolate(frame, [fadeOutAt, fadeOutAt + 12], [1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        })
      : 1;

  return (
    <div
      style={{
        opacity: enter * opacityOut,
        transform: `translate(${(1 - enter) * fromX}px, ${(1 - enter) * fromY}px)`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};
