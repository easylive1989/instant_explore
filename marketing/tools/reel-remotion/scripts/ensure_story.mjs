// Ensure src/data/story.json exists so the Remotion project can compile.
//
// story.json is the daily pipeline's working file (gitignored); a fresh
// clone only has story.sample.json. Copy the sample into place when the
// working file is missing — never overwrite an existing one.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const DATA = path.join(path.dirname(fileURLToPath(import.meta.url)), "../src/data");
const story = path.join(DATA, "story.json");
const sample = path.join(DATA, "story.sample.json");

if (!fs.existsSync(story)) {
  fs.copyFileSync(sample, story);
  console.log("story.json missing — copied from story.sample.json");
}
