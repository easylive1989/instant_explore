import type { Beat, Story } from "../types";
import storyJson from "./story.json";

export const story = storyJson as Story;

export const FPS = 30;

const nonEmptyLines = (beat: Beat): number =>
  beat.lines.filter((l) => l !== "").length;

/**
 * Per-beat on-screen duration in frames (before transitions overlap).
 *
 * Derived from the beat, not hard-coded per story, so the pipeline works for
 * any day's content. Cover and ending breathe longer; other beats scale with
 * how much text has to be read — reading time matters because narration is
 * added later, but the on-screen text must be legible on its own too.
 */
export const beatFrames = (beat: Beat): number => {
  if (beat.layout === "cover") return 140;
  if (beat.layout === "ending") return 150;
  const byText = 66 + 27 * nonEmptyLines(beat);
  return Math.max(116, Math.min(170, byText));
};

/**
 * Total composition length for a style, accounting for transitions that
 * overlap adjacent beats. `transitionFrames` is the per-cut overlap.
 */
export const totalFrames = (transitionFrames: number): number => {
  const sum = story.beats.reduce((acc, b) => acc + beatFrames(b), 0);
  const overlaps = (story.beats.length - 1) * transitionFrames;
  return sum - overlaps;
};

export const photoSrc = (photo: string): string => `photos/${photo}`;
