import { AbsoluteFill, Img, staticFile } from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import type { Beat } from "../types";
import { story, beatFrames } from "../data/story";
import { serifFamily, sansFamily } from "../fonts";
import { KenBurnsPhoto } from "../components/photo";
import { Reveal } from "../components/reveal";
import { HighlightedLine } from "../components/text";

const TRANSITION = 18;
const HIGHLIGHT = "#f4c869";

const BeatScene: React.FC<{ beat: Beat; index: number }> = ({ beat, index }) => {
  const duration = beatFrames(beat);
  const isCover = beat.layout === "cover";
  const isEnding = beat.layout === "ending";
  const centered = isCover || isEnding;
  const panY = index % 2 === 0 ? -3 : 3;

  let revealCount = 0;

  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      <KenBurnsPhoto
        photo={beat.photo}
        focus={beat.focus}
        durationInFrames={duration}
        fromScale={1.1}
        toScale={1.24}
        panY={panY}
        filter={isEnding ? "saturate(0.9) brightness(0.85)" : undefined}
      />
      <AbsoluteFill
        style={{
          background:
            beat.overlay === "darker" || centered
              ? "linear-gradient(180deg, rgba(0,0,0,0.45) 0%, rgba(0,0,0,0.15) 40%, rgba(0,0,0,0.75) 100%)"
              : "linear-gradient(180deg, rgba(0,0,0,0) 45%, rgba(0,0,0,0.8) 100%)",
        }}
      />
      <AbsoluteFill
        style={{
          justifyContent: centered ? "center" : "flex-end",
          // Bottom-anchored narration is lifted clear of Instagram's Reels UI
          // band (username / caption / action buttons cover the bottom ~17%).
          padding: centered ? "0 90px 150px 90px" : "0 90px 330px 90px",
        }}
      >
        <div>
          <Reveal delay={6}>
            <div
              style={{
                fontFamily: sansFamily,
                fontWeight: 500,
                letterSpacing: "0.35em",
                fontSize: 29,
                color: HIGHLIGHT,
                marginBottom: 22,
              }}
            >
              {beat.kicker}
            </div>
          </Reveal>
          {beat.title ? (
            <Reveal delay={12}>
              <div
                style={{
                  fontFamily: serifFamily,
                  fontWeight: 900,
                  fontSize: isCover ? 128 : 74,
                  lineHeight: 1.1,
                  color: "#fff",
                  marginBottom: 30,
                  textShadow: "0 4px 30px rgba(0,0,0,0.6)",
                }}
              >
                {beat.title}
              </div>
            </Reveal>
          ) : null}
          {beat.lines.map((line, i) => {
            if (line === "") return <div key={i} style={{ height: 20 }} />;
            const delay = 22 + revealCount * 7;
            revealCount += 1;
            return (
              <Reveal key={i} delay={delay} fromY={18}>
                <div
                  style={{
                    fontFamily: serifFamily,
                    fontWeight: 700,
                    fontSize: 50,
                    lineHeight: 1.5,
                    color: "#f5f1e9",
                    textShadow: "0 2px 22px rgba(0,0,0,0.8)",
                  }}
                >
                  <HighlightedLine
                    line={line}
                    highlights={beat.highlights}
                    highlightColor={HIGHLIGHT}
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

export const Cinematic: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      <TransitionSeries>
        {story.beats.map((beat, index) => (
          <TransitionSeries.Sequence
            key={beat.id}
            durationInFrames={beatFrames(beat)}
          >
            <BeatScene beat={beat} index={index} />
          </TransitionSeries.Sequence>
        )).reduce<React.ReactNode[]>((acc, seq, i) => {
          if (i > 0) {
            acc.push(
              <TransitionSeries.Transition
                key={`t-${i}`}
                presentation={fade()}
                timing={linearTiming({ durationInFrames: TRANSITION })}
              />,
            );
          }
          acc.push(seq);
          return acc;
        }, [])}
      </TransitionSeries>
      <Img
        src={staticFile("logo-lockup-white.png")}
        style={{
          position: "absolute",
          right: 44,
          bottom: 120,
          width: 132,
          height: "auto",
          opacity: 0.9,
          filter: "drop-shadow(0 2px 8px rgba(0,0,0,0.6))",
        }}
      />
    </AbsoluteFill>
  );
};
