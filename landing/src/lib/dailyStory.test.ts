import { describe, it, expect } from "vitest";
import {
  localeToLanguage,
  isValidStoryDate,
  firstParagraphs,
  rowToTeaser,
} from "./dailyStory";

describe("localeToLanguage", () => {
  it("maps zh to zh-TW and en to en", () => {
    expect(localeToLanguage("zh")).toBe("zh-TW");
    expect(localeToLanguage("en")).toBe("en");
  });
});

describe("isValidStoryDate", () => {
  it("accepts a zero-padded yyyy-MM-dd", () => {
    expect(isValidStoryDate("2026-07-01")).toBe(true);
    expect(isValidStoryDate("2026-03-05")).toBe(true);
  });
  it("rejects malformed or non-calendar dates", () => {
    expect(isValidStoryDate("2026-7-1")).toBe(false);
    expect(isValidStoryDate("2026/07/01")).toBe(false);
    expect(isValidStoryDate("2026-13-01")).toBe(false);
    expect(isValidStoryDate("2026-02-30")).toBe(false);
    expect(isValidStoryDate("nope")).toBe(false);
  });
});

describe("firstParagraphs", () => {
  it("takes the first N entries from card_paragraphs", () => {
    const row = { card_paragraphs: ["a", "b", "c"] };
    expect(firstParagraphs(row, 2)).toEqual(["a", "b"]);
  });
  it("falls back to splitting story on blank lines", () => {
    const row = { card_paragraphs: null, story: "one\n\ntwo\n\nthree" };
    expect(firstParagraphs(row, 2)).toEqual(["one", "two"]);
  });
});

describe("rowToTeaser", () => {
  it("prefers card_title/card_pull_quote, falls back to place/sub", () => {
    const teaser = rowToTeaser({
      place_name: "Colosseum",
      place_location: "Rome, Italy",
      era: "70-80 CE",
      story: "body one\n\nbody two",
      image_url: "https://x/cover.jpg",
      card_title: "Ruin and rebirth",
      card_title_sub: "sub",
      card_paragraphs: ["p1", "p2", "p3"],
      card_pull_quote: "a hook",
    });
    expect(teaser.title).toBe("Ruin and rebirth");
    expect(teaser.hook).toBe("a hook");
    expect(teaser.paragraphs).toEqual(["p1", "p2"]);
    expect(teaser.imageUrl).toBe("https://x/cover.jpg");
    expect(teaser.placeName).toBe("Colosseum");
  });
  it("falls back to place_name/card_title_sub when card fields are null", () => {
    const teaser = rowToTeaser({
      place_name: "Mystery",
      place_location: "Nowhere",
      era: "2026",
      story: "only body",
      image_url: null,
      card_title: null,
      card_title_sub: "the sub hook",
      card_paragraphs: null,
      card_pull_quote: null,
    });
    expect(teaser.title).toBe("Mystery");
    expect(teaser.hook).toBe("the sub hook");
    expect(teaser.paragraphs).toEqual(["only body"]);
    expect(teaser.imageUrl).toBeNull();
  });
});
