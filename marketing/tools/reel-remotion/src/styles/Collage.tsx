import { AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig, spring } from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import type { Beat } from "../types";
import { story, beatFrames, photoSrc } from "../data/story";
import { serifFamily, sansFamily } from "../fonts";
import { KenBurnsPhoto } from "../components/photo";
import { Reveal } from "../components/reveal";
import { HighlightedLine } from "../components/text";

const TRANSITION = 12;
const PAPER = "#e7e0d0";
const INK = "#2a251d";
const ACCENT = "#b8542f";

const Tape: React.FC<{ label: string; rotate: number }> = ({ label, rotate }) => (
  <div
    style={{
      fontFamily: sansFamily,
      fontWeight: 700,
      fontSize: 26,
      letterSpacing: "0.15em",
      color: "#4a4132",
      background: "rgba(214,196,120,0.72)",
      padding: "10px 30px",
      transform: `rotate(${rotate}deg)`,
      boxShadow: "0 6px 14px rgba(0,0,0,0.18)",
    }}
  >
    {label}
  </div>
);

const BeatScene: React.FC<{ beat: Beat; index: number }> = ({ beat, index }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const duration = beatFrames(beat);
  const dir = index % 2 === 0 ? 1 : -1;

  const drop = spring({ frame, fps, config: { damping: 14, mass: 0.9 } });
  const cardRotate = dir * (2.2 - 2.2 * drop);
  const secondary = story.beats[(index + 4) % story.beats.length].photo;
  let revealCount = 0;

  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(120% 90% at 50% 20%, #f1ebdd 0%, ${PAPER} 55%, #d8cfba 100%)`,
      }}
    >
      {/* faint secondary card peeking behind for collage density */}
      <div
        style={{
          position: "absolute",
          top: 150,
          left: dir === 1 ? 90 : undefined,
          right: dir === -1 ? 90 : undefined,
          width: 360,
          height: 460,
          background: "#fff",
          padding: 14,
          transform: `rotate(${-dir * 6}deg)`,
          boxShadow: "0 18px 34px rgba(0,0,0,0.22)",
          opacity: 0.85,
        }}
      >
        <Img
          src={staticFile(photoSrc(secondary))}
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
      </div>

      {/* main polaroid */}
      <div
        style={{
          position: "absolute",
          top: 210,
          left: 130,
          right: 130,
          height: 940,
          transform: `rotate(${cardRotate}deg) translateY(${(1 - drop) * -40}px)`,
        }}
      >
        <div
          style={{
            position: "absolute",
            top: -34,
            left: "50%",
            transform: "translateX(-50%)",
            zIndex: 2,
          }}
        >
          <Tape label={beat.kicker} rotate={dir * -2} />
        </div>
        <div
          style={{
            width: "100%",
            height: "100%",
            background: "#fdfbf6",
            padding: 26,
            paddingBottom: 96,
            boxShadow: "0 26px 50px rgba(0,0,0,0.3)",
          }}
        >
          <div style={{ position: "relative", width: "100%", height: "100%", overflow: "hidden" }}>
            <KenBurnsPhoto
              photo={beat.photo}
              focus={beat.focus}
              durationInFrames={duration}
              fromScale={1.05}
              toScale={1.15}
            />
          </div>
          {beat.title ? (
            <div
              style={{
                fontFamily: serifFamily,
                fontWeight: 700,
                fontSize: 40,
                color: INK,
                textAlign: "center",
                marginTop: 22,
              }}
            >
              {beat.title}
            </div>
          ) : null}
        </div>
      </div>

      {/* narration note */}
      <AbsoluteFill style={{ top: 1240, padding: "0 120px", justifyContent: "flex-start" }}>
        <div
          style={{
            background: "#fffdf7",
            padding: "44px 48px",
            transform: `rotate(${dir * 0.8}deg)`,
            boxShadow: "0 20px 40px rgba(0,0,0,0.2)",
          }}
        >
          {beat.lines.map((line, i) => {
            if (line === "") return <div key={i} style={{ height: 12 }} />;
            const delay = 14 + revealCount * 6;
            revealCount += 1;
            return (
              <Reveal key={i} delay={delay} fromY={14}>
                <div
                  style={{
                    fontFamily: serifFamily,
                    fontWeight: 500,
                    fontSize: 40,
                    lineHeight: 1.5,
                    color: INK,
                  }}
                >
                  <HighlightedLine
                    line={line}
                    highlights={beat.highlights}
                    highlightColor={ACCENT}
                    highlightStyle="brush"
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

export const Collage: React.FC = () => {
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
        <BeatScene beat={beat} index={i} />
      </TransitionSeries.Sequence>,
    );
  });
  return (
    <AbsoluteFill style={{ backgroundColor: PAPER }}>
      <TransitionSeries>{children}</TransitionSeries>
    </AbsoluteFill>
  );
};
