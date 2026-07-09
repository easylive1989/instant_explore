import { AbsoluteFill } from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { slide } from "@remotion/transitions/slide";
import type { Beat } from "../types";
import { story, beatFrames } from "../data/story";
import { serifFamily, sansFamily } from "../fonts";
import { KenBurnsPhoto } from "../components/photo";
import { Reveal } from "../components/reveal";
import { HighlightedLine } from "../components/text";

const TRANSITION = 14;

interface Theme {
  bg: string;
  ink: string;
  sub: string;
  accent: string;
}

const LIGHT: Theme = {
  bg: "#efe9dd",
  ink: "#1c1a17",
  sub: "#6b6155",
  accent: "#b4453b",
};
const DARK: Theme = {
  bg: "#17140f",
  ink: "#f2ece0",
  sub: "#b3a894",
  accent: "#e0a94b",
};

const BeatScene: React.FC<{ beat: Beat }> = ({ beat }) => {
  const duration = beatFrames(beat);
  const theme = beat.overlay === "darker" ? DARK : LIGHT;
  let revealCount = 0;

  return (
    <AbsoluteFill style={{ backgroundColor: theme.bg }}>
      {/* Photo panel — upper portion, with a slow push so it never sits still */}
      <div
        style={{
          position: "absolute",
          top: 96,
          left: 72,
          right: 72,
          height: 1000,
          overflow: "hidden",
          boxShadow: "0 30px 60px rgba(0,0,0,0.28)",
        }}
      >
        <KenBurnsPhoto
          photo={beat.photo}
          focus={beat.focus}
          durationInFrames={duration}
          fromScale={1.04}
          toScale={1.16}
        />
      </div>

      {/* Text block — lower portion on the matte */}
      <AbsoluteFill
        style={{
          top: 1140,
          padding: "0 78px",
          justifyContent: "flex-start",
        }}
      >
        <Reveal delay={4} fromX={-30} fromY={0}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 20,
              marginBottom: 26,
            }}
          >
            <span
              style={{
                fontFamily: sansFamily,
                fontWeight: 700,
                letterSpacing: "0.3em",
                fontSize: 24,
                color: theme.accent,
                textTransform: "uppercase",
              }}
            >
              {beat.kicker}
            </span>
            <span
              style={{ flex: 1, height: 2, background: theme.accent, opacity: 0.5 }}
            />
          </div>
        </Reveal>

        {beat.title ? (
          <Reveal delay={10} fromX={-30} fromY={0}>
            <div
              style={{
                fontFamily: serifFamily,
                fontWeight: 900,
                fontSize: 78,
                lineHeight: 1.05,
                color: theme.ink,
                marginBottom: 34,
              }}
            >
              {beat.title}
            </div>
          </Reveal>
        ) : null}

        <div>
          {beat.lines.map((line, i) => {
            if (line === "") return <div key={i} style={{ height: 16 }} />;
            const delay = 18 + revealCount * 6;
            revealCount += 1;
            return (
              <Reveal key={i} delay={delay} fromX={-26} fromY={0}>
                <div
                  style={{
                    fontFamily: sansFamily,
                    fontWeight: 300,
                    fontSize: 40,
                    lineHeight: 1.55,
                    color: theme.ink,
                  }}
                >
                  <HighlightedLine
                    line={line}
                    highlights={beat.highlights}
                    highlightColor={theme.accent}
                    highlightStyle="underline"
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

export const Editorial: React.FC = () => {
  const children: React.ReactNode[] = [];
  story.beats.forEach((beat, i) => {
    if (i > 0) {
      children.push(
        <TransitionSeries.Transition
          key={`t-${i}`}
          presentation={slide({ direction: "from-right" })}
          timing={linearTiming({ durationInFrames: TRANSITION })}
        />,
      );
    }
    children.push(
      <TransitionSeries.Sequence
        key={beat.id}
        durationInFrames={beatFrames(beat)}
      >
        <BeatScene beat={beat} />
      </TransitionSeries.Sequence>,
    );
  });
  return (
    <AbsoluteFill style={{ backgroundColor: LIGHT.bg }}>
      <TransitionSeries>{children}</TransitionSeries>
    </AbsoluteFill>
  );
};
