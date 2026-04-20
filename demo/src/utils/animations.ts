import { Easing, interpolate, spring } from "remotion";

export const easeOutExpo = Easing.bezier(0.16, 1, 0.3, 1);
export const easeInOutCubic = Easing.bezier(0.65, 0, 0.35, 1);
export const easeOutQuart = Easing.bezier(0.25, 1, 0.5, 1);

export const fadeIn = (
  frame: number,
  startFrame: number,
  durationFrames: number,
) =>
  interpolate(frame, [startFrame, startFrame + durationFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOutExpo,
  });

export const fadeOut = (
  frame: number,
  startFrame: number,
  durationFrames: number,
) =>
  interpolate(frame, [startFrame, startFrame + durationFrames], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOutCubic,
  });

export const slideUp = (
  frame: number,
  startFrame: number,
  durationFrames: number,
  distance = 60,
) =>
  interpolate(
    frame,
    [startFrame, startFrame + durationFrames],
    [distance, 0],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
      easing: easeOutExpo,
    },
  );

export const popIn = (frame: number, fps: number, delayFrames = 0) =>
  spring({
    frame: frame - delayFrames,
    fps,
    config: { damping: 14, mass: 0.9, stiffness: 110 },
  });
