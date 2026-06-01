import { useVideoConfig } from "remotion";

// True when the composition is taller than it is wide (9:16 vertical export).
// Scenes branch their layout on this instead of hard-coding a single aspect.
export const usePortrait = (): boolean => {
  const { width, height } = useVideoConfig();
  return height > width;
};
