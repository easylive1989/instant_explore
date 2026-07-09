import { loadFont } from "@remotion/fonts";
import { continueRender, delayRender, staticFile } from "remotion";

export const serifFamily = "StorySerif";
export const sansFamily = "StorySans";

/**
 * Local subset fonts (Songti TC / Heiti TC, subset to the glyphs this story
 * uses). Loading local files keeps rendering fast and deterministic — the CJK
 * Google Font would otherwise pull hundreds of chunk files at render time.
 *
 * Each source weight is registered under the CSS weights the styles ask for,
 * so `font-weight: 500 / 900` resolve to a real file instead of faux-bolding.
 */
const serifRegular = staticFile("fonts/songti-regular.ttf");
const serifBold = staticFile("fonts/songti-bold.ttf");
const sansLight = staticFile("fonts/heiti-light.ttf");
const sansMedium = staticFile("fonts/heiti-medium.ttf");

const handle = delayRender("loading story fonts");

Promise.all([
  loadFont({ family: serifFamily, url: serifRegular, weight: "400", format: "truetype" }),
  loadFont({ family: serifFamily, url: serifRegular, weight: "500", format: "truetype" }),
  loadFont({ family: serifFamily, url: serifBold, weight: "700", format: "truetype" }),
  loadFont({ family: serifFamily, url: serifBold, weight: "900", format: "truetype" }),
  loadFont({ family: sansFamily, url: sansLight, weight: "300", format: "truetype" }),
  loadFont({ family: sansFamily, url: sansMedium, weight: "500", format: "truetype" }),
  loadFont({ family: sansFamily, url: sansMedium, weight: "700", format: "truetype" }),
])
  .then(() => continueRender(handle))
  .catch(() => continueRender(handle));
