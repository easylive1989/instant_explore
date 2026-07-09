import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
} from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import type { Beat } from "../types";
import { story, beatFrames } from "../data/story";
import { serifFamily, sansFamily } from "../fonts";
import { KenBurnsPhoto } from "../components/photo";
import { Reveal } from "../components/reveal";
import { HighlightedLine } from "../components/text";

const TRANSITION = 16;
const ACCENT = "#7ec8e3";

/** A vignette that starts tight on the focal point and opens as we pull back. */
const OpeningVignette: React.FC<{ duration: number; focus: string }> = ({
  duration,
  focus,
}) => {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [0, duration], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const inner = interpolate(p, [0, 1], [18, 62]);
  const outer = interpolate(p, [0, 1], [46, 105]);
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(circle at ${focus}, rgba(0,0,0,0) ${inner}%, rgba(0,0,0,0.82) ${outer}%)`,
      }}
    />
  );
};

const BeatScene: React.FC<{ beat: Beat }> = ({ beat }) => {
  const duration = beatFrames(beat);
  const isCover = beat.layout === "cover";
  let revealCount = 0;

  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      {/* Reverse Ken Burns: start deep on the detail, pull back to the whole */}
      <KenBurnsPhoto
        photo={beat.photo}
        focus={beat.focus}
        durationInFrames={duration}
        fromScale={isCover ? 1.5 : 1.75}
        toScale={1.06}
      />
      <OpeningVignette duration={duration} focus={beat.focus} />
      <AbsoluteFill
        style={{
          background:
            "linear-gradient(180deg, rgba(0,0,0,0.35) 0%, rgba(0,0,0,0) 30%, rgba(0,0,0,0) 60%, rgba(0,0,0,0.85) 100%)",
        }}
      />

      {/* top marker */}
      <AbsoluteFill style={{ padding: "110px 90px 0", justifyContent: "flex-start" }}>
        <Reveal delay={4}>
          <div
            style={{
              fontFamily: sansFamily,
              fontWeight: 700,
              letterSpacing: "0.4em",
              fontSize: 24,
              color: ACCENT,
            }}
          >
            {beat.kicker}
          </div>
        </Reveal>
      </AbsoluteFill>

      {/* narration — line-by-line reveal, centered low */}
      <AbsoluteFill
        style={{
          justifyContent: "flex-end",
          alignItems: "center",
          textAlign: "center",
          padding: "0 80px 170px",
        }}
      >
        <div>
          {beat.title ? (
            <Reveal delay={10}>
              <div
                style={{
                  fontFamily: serifFamily,
                  fontWeight: 900,
                  fontSize: isCover ? 108 : 58,
                  color: "#fff",
                  marginBottom: 28,
                  textShadow: "0 3px 26px rgba(0,0,0,0.7)",
                }}
              >
                {beat.title}
              </div>
            </Reveal>
          ) : null}
          {beat.lines.map((line, i) => {
            if (line === "") return <div key={i} style={{ height: 18 }} />;
            const delay = 20 + revealCount * 11;
            revealCount += 1;
            return (
              <Reveal key={i} delay={delay} fromY={14}>
                <div
                  style={{
                    fontFamily: serifFamily,
                    fontWeight: 500,
                    fontSize: 46,
                    lineHeight: 1.5,
                    color: "#f1efe9",
                    textShadow: "0 2px 22px rgba(0,0,0,0.85)",
                  }}
                >
                  <HighlightedLine
                    line={line}
                    highlights={beat.highlights}
                    highlightColor={ACCENT}
                    highlightStyle="color"
                  />
                </div>
              </Reveal>
            );
          })}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

export const Focus: React.FC = () => {
  const children: React.ReactNode[] = [];
  story.beats.forEach((beat, i) => {
    if (i > 0) {
      children.push(
        <TransitionSeries.Transition
          key={`t-${i}`}
          presentation={fade()}
          timing={linearTiming({ durationInFrames: TRANSITION })}
        />,
      );
    }
    children.push(
      <TransitionSeries.Sequence key={beat.id} durationInFrames={beatFrames(beat)}>
        <BeatScene beat={beat} />
      </TransitionSeries.Sequence>,
    );
  });
  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      <TransitionSeries>{children}</TransitionSeries>
    </AbsoluteFill>
  );
};
