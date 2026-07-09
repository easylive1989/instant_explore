import { Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { photoSrc } from "../data/story";

export interface KenBurnsProps {
  photo: string;
  focus: string;
  durationInFrames: number;
  /** Start / end scale for the slow zoom. */
  fromScale?: number;
  toScale?: number;
  /** Extra pan in percent of frame, applied over the duration. */
  panX?: number;
  panY?: number;
  style?: React.CSSProperties;
  filter?: string;
}

/**
 * A full-bleed image with a slow, continuous Ken Burns move.
 *
 * The zoom and pan run across the whole beat so the frame never sits still —
 * this is what separates a "living" shot from a static slide.
 */
export const KenBurnsPhoto: React.FC<KenBurnsProps> = ({
  photo,
  focus,
  durationInFrames,
  fromScale = 1.08,
  toScale = 1.22,
  panX = 0,
  panY = 0,
  style,
  filter,
}) => {
  const frame = useCurrentFrame();
  const progress = interpolate(frame, [0, durationInFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const scale = fromScale + (toScale - fromScale) * progress;
  const tx = panX * progress;
  const ty = panY * progress;

  return (
    <Img
      src={staticFile(photoSrc(photo))}
      style={{
        position: "absolute",
        width: "100%",
        height: "100%",
        objectFit: "cover",
        objectPosition: focus,
        transform: `scale(${scale}) translate(${tx}%, ${ty}%)`,
        filter,
        ...style,
      }}
    />
  );
};
