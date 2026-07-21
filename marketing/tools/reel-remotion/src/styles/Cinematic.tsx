import { AbsoluteFill, Img, staticFile, useCurrentFrame, interpolate } from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import type { Beat } from "../types";
import { story, beatFrames, totalFrames } from "../data/story";
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
          {isCover ? (
            <>
              {/* Zero-second hook: the first line, largest, first to appear. */}
              <Reveal delay={6} fromY={18}>
                <div
                  style={{
                    fontFamily: serifFamily,
                    fontWeight: 800,
                    fontSize: 78,
                    lineHeight: 1.35,
                    color: "#fff",
                    textShadow: "0 4px 30px rgba(0,0,0,0.65)",
                    marginBottom: 26,
                  }}
                >
                  <HighlightedLine
                    line={beat.lines[0] ?? ""}
                    highlights={beat.highlights}
                    highlightColor={HIGHLIGHT}
                    highlightStyle="color"
                  />
                </div>
              </Reveal>
              {beat.lines.slice(1).map((line, i) => {
                if (line === "") return <div key={i} style={{ height: 18 }} />;
                const delay = 18 + revealCount * 7;
                revealCount += 1;
                return (
                  <Reveal key={i} delay={delay} fromY={18}>
                    <div
                      style={{
                        fontFamily: serifFamily,
                        fontWeight: 700,
                        fontSize: 46,
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
              {/* Demoted place tag: region + place name, small, after the hook. */}
              <Reveal delay={18 + revealCount * 7 + 8} fromY={12}>
                <div style={{ marginTop: 34 }}>
                  <div
                    style={{
                      fontFamily: sansFamily,
                      fontWeight: 500,
                      letterSpacing: "0.35em",
                      fontSize: 26,
                      color: HIGHLIGHT,
                      marginBottom: 10,
                    }}
                  >
                    {beat.kicker}
                  </div>
                  <div
                    style={{
                      fontFamily: serifFamily,
                      fontWeight: 900,
                      fontSize: 46,
                      lineHeight: 1.1,
                      color: "#fff",
                      textShadow: "0 4px 30px rgba(0,0,0,0.6)",
                    }}
                  >
                    {beat.title}
                    {beat.subtitle ? (
                      <span
                        style={{
                          fontFamily: sansFamily,
                          fontWeight: 400,
                          fontSize: 26,
                          letterSpacing: "0.08em",
                          color: "rgba(245,241,233,0.7)",
                          marginLeft: 16,
                        }}
                      >
                        {beat.subtitle}
                      </span>
                    ) : null}
                  </div>
                </div>
              </Reveal>
            </>
          ) : (
            <>
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
                      fontSize: 74,
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
            </>
          )}
          {isEnding ? (
            <Reveal delay={22 + revealCount * 7 + 18} fromY={18}>
              <div style={{ marginTop: 66 }}>
                <Img
                  src={staticFile("logo-lockup-white.png")}
                  style={{
                    width: 300,
                    height: "auto",
                    marginBottom: 26,
                    filter: "drop-shadow(0 2px 12px rgba(0,0,0,0.6))",
                  }}
                />
                <div
                  style={{
                    fontFamily: serifFamily,
                    fontWeight: 700,
                    fontSize: 42,
                    lineHeight: 1.5,
                    color: "#f5f1e9",
                    textShadow: "0 2px 22px rgba(0,0,0,0.8)",
                  }}
                >
                  這裡的故事說完了。
                </div>
                <div
                  style={{
                    fontFamily: serifFamily,
                    fontWeight: 700,
                    fontSize: 42,
                    lineHeight: 1.5,
                    color: HIGHLIGHT,
                    textShadow: "0 2px 22px rgba(0,0,0,0.8)",
                    marginBottom: 16,
                  }}
                >
                  那你現在站的地方呢？
                </div>
                <div
                  style={{
                    fontFamily: sansFamily,
                    fontWeight: 500,
                    letterSpacing: "0.22em",
                    fontSize: 26,
                    color: "rgba(245,241,233,0.72)",
                  }}
                >
                  Lorescape・App Store・Google Play
                </div>
              </div>
            </Reveal>
          ) : null}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

export const Cinematic: React.FC = () => {
  const frame = useCurrentFrame();
  // The ending beat renders its own large lockup + download CTA, so fade the
  // corner watermark out as that scene arrives instead of doubling the logo.
  const endingBeat = story.beats[story.beats.length - 1];
  const endingStart = totalFrames(TRANSITION) - beatFrames(endingBeat);
  const watermarkOpacity = interpolate(
    frame,
    [endingStart - TRANSITION, endingStart],
    [0.9, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );
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
          opacity: watermarkOpacity,
          filter: "drop-shadow(0 2px 8px rgba(0,0,0,0.6))",
        }}
      />
    </AbsoluteFill>
  );
};
