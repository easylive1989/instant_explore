#!/usr/bin/env node
// Scaffold src/data/story.json from a day's carousel + copy its photos.
//
// Usage: node scripts/prepare_story.mjs <YYYY-MM-DD>
//
// Reads marketing/outputs/daily_carousel/<date>/slides.json (the 8-beat story
// the carousel already tells) and daily_image/<date>/unsplash_results.json,
// then writes story.json with the ORIGINAL slide lines. Claude condenses the
// lines afterwards (see the lorescape-daily-reel skill) before rendering.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PROJ = path.dirname(HERE);
const REPO = path.resolve(PROJ, "../../..");

const date = process.argv[2];
if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
  console.error("Usage: node scripts/prepare_story.mjs <YYYY-MM-DD>");
  process.exit(1);
}

const carouselDir = path.join(REPO, "marketing/outputs/daily_carousel", date);
const imageDir = path.join(REPO, "marketing/outputs/daily_image", date);
const slidesPath = path.join(carouselDir, "slides.json");
if (!fs.existsSync(slidesPath)) {
  console.error(`missing ${slidesPath} — run the carousel step first`);
  process.exit(1);
}

const slides = JSON.parse(fs.readFileSync(slidesPath, "utf8")).slides;
const meta = fs.existsSync(path.join(imageDir, "unsplash_results.json"))
  ? JSON.parse(fs.readFileSync(path.join(imageDir, "unsplash_results.json"), "utf8"))
  : {};

const CN = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"];
const cover = slides.find((s) => s.layout === "cover") || slides[0];

let beatIdx = 0;
const beats = slides.map((s, i) => {
  const layout = ["cover", "beat", "bright", "ending"].includes(s.layout)
    ? s.layout
    : "beat";
  let id, kicker;
  if (layout === "cover") {
    id = "cover";
    kicker = s.tag_zh || "";
  } else if (layout === "ending") {
    id = "ending";
    kicker = "結語";
  } else {
    beatIdx += 1;
    id = `beat${beatIdx}`;
    kicker = `其之${CN[beatIdx - 1] ?? beatIdx}`;
  }
  return {
    id,
    layout,
    photo: s.photo,
    focus: "50% 40%",
    ...(s.overlay === "darker" ? { overlay: "darker" } : {}),
    kicker,
    title: s.title || "",
    ...(layout === "cover" && s.title_en ? { subtitle: s.title_en } : {}),
    lines: s.lines || [],
    highlights: s.highlights || [],
  };
});

const photographers = [];
for (const angle of Object.values(meta.angles || {})) {
  for (const p of angle.photos || []) {
    if (p.photographer && !photographers.includes(p.photographer)) {
      photographers.push(p.photographer);
    }
  }
}

const story = {
  date,
  place: meta.place || cover.title_en || "",
  placeZh: cover.title || "",
  titleZh: cover.title || "",
  titleEn: cover.title_en || "",
  region: cover.tag_zh || "",
  credits: photographers.length
    ? `Photos: ${photographers.join(", ")} / Unsplash`
    : "",
  beats,
};

fs.writeFileSync(
  path.join(PROJ, "src/data/story.json"),
  JSON.stringify(story, null, 2) + "\n",
);

// Copy the day's photos into public/photos (fresh — drop stale ones).
const dst = path.join(PROJ, "public/photos");
fs.rmSync(dst, { recursive: true, force: true });
fs.mkdirSync(dst, { recursive: true });
let copied = 0;
for (const f of fs.readdirSync(imageDir)) {
  if (/\.(jpe?g|png|webp)$/i.test(f)) {
    fs.copyFileSync(path.join(imageDir, f), path.join(dst, f));
    copied += 1;
  }
}

console.log(`story.json written: ${beats.length} beats, ${copied} photos copied`);
console.log("NEXT: condense each beat's `lines` (~half) for voiceover pace, then run scripts/build_video.sh " + date);
