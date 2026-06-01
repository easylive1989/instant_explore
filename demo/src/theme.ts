import { loadFont as loadSerif } from "@remotion/google-fonts/NotoSerifTC";
import { loadFont as loadSans } from "@remotion/google-fonts/NotoSansTC";

const { fontFamily: serifLoaded } = loadSerif("normal", {
  weights: ["400", "600", "700"],
});
const { fontFamily: sansLoaded } = loadSans("normal", {
  weights: ["400", "500", "700"],
});

// Design tokens ported 1:1 from landing/src/app/globals.css :root.
export const colors = {
  paper: "#f7f1e6",
  paperRaised: "#fdfaf3",
  paperSunk: "#ece3d3",
  line: "#e4dac8",
  lineStrong: "#cdbfa6",
  ink: "#221c14",
  ink2: "#5e5341",
  ink3: "#918471",
  clay: "#bc5e3e",
  clayDeep: "#97442a",
  claySoft: "#f1ddce",
  clayTint: "#f7e8dd",
  inkBg: "#1b1611",
  inkBg2: "#251e17",
  onDark: "#f7f1e6",
  onDark2: "#c3b7a4",
} as const;

export const fonts = {
  serif: `${serifLoaded}, "Songti TC", serif`,
  sans: `${sansLoaded}, -apple-system, sans-serif`,
} as const;

export const shadows = {
  e1: "0 1px 2px rgba(40,30,18,0.06)",
  e2: "0 6px 18px rgba(40,30,18,0.09)",
  e3: "0 18px 44px rgba(28,20,10,0.2)",
} as const;

// Repeating paper-grain dot pattern (matches landing body background).
export const paperGrain =
  "radial-gradient(circle at 1px 1px, rgba(120,100,70,0.05) 1px, transparent 0)";
