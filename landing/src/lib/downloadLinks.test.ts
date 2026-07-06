import { describe, expect, it } from "vitest";
import {
  APP_STORE_URL,
  PLAY_STORE_URL,
  storeUrlFor,
} from "./downloadLinks";

describe("storeUrlFor", () => {
  it("returns the bare URL when no location is given", () => {
    expect(storeUrlFor("ios")).toBe(APP_STORE_URL);
    expect(storeUrlFor("android")).toBe(PLAY_STORE_URL);
  });

  it("adds an App Store campaign token scoped to the CTA location", () => {
    expect(storeUrlFor("ios", "hero")).toBe(`${APP_STORE_URL}?ct=web_hero`);
    expect(storeUrlFor("ios", "final_cta")).toBe(
      `${APP_STORE_URL}?ct=web_final_cta`,
    );
  });

  it("adds a URL-encoded Play install referrer carrying the UTM source", () => {
    const url = storeUrlFor("android", "story");
    expect(url.startsWith(`${PLAY_STORE_URL}&referrer=`)).toBe(true);

    const referrer = new URL(url).searchParams.get("referrer");
    expect(referrer).not.toBeNull();
    const utm = new URLSearchParams(referrer as string);
    expect(utm.get("utm_source")).toBe("lorescape.app");
    expect(utm.get("utm_medium")).toBe("web");
    expect(utm.get("utm_campaign")).toBe("landing");
    expect(utm.get("utm_content")).toBe("story");
  });
});
