# Daily Story Share Loop — Phase 2 (Web Landing) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a web page at `lorescape.app/<locale>/story/<date>` that shows a teaser (cover, title, hook, first paragraphs) of a daily story with rich Open Graph tags and App Store / Google Play download buttons — so a shared link resolves to real content for people without the app.

**Architecture:** A Next.js 14 App Router dynamic route `src/app/[locale]/story/[date]/page.tsx`, server-rendered. It reads the story from Supabase `daily_stories` at request time using the **anon** key (server-side), so the returned HTML already contains the content (for OG scrapers + SEO). Reuses the landing's existing `[locale]` layout, `StoreButtons`, `downloadLinks`, and i18n dictionaries.

**Tech Stack:** Next.js 14.2.35 (App Router, server components), TypeScript, Tailwind, `@supabase/supabase-js` (new dep), `vitest` (new dev dep for pure-logic tests). All commands run in `landing/` with `npm`.

## Global Constraints

- Work directory for every task: `landing/` (the Next.js project). Run `npm` there.
- **No new Supabase grant/migration is required.** `daily_stories` already has `grant select ... to anon` (see `supabase/migrations/20260510000001_grant_daily_story_permissions.sql`), and RLS already limits anon to past `publish_date`s. Read ONLY the `daily_stories` table (do NOT join `daily_story_places` — it is admin-only / not granted to anon).
- Teaser reads only these `daily_stories` columns: `publish_date`, `language`, `place_name`, `place_location`, `era`, `story`, `image_url`, `card_title`, `card_title_sub`, `card_paragraphs`, `card_pull_quote`, `card_pull_quote_attrib`.
- URL shape (must match the app's share URL from Phase 1): `/<locale>/story/<date>` where `<locale>` ∈ {`zh`,`en`} and `<date>` is `yyyy-MM-dd`. Map locale→language: `zh`→`zh-TW`, `en`→`en`.
- Supabase access uses server-only env vars `SUPABASE_URL` and `SUPABASE_ANON_KEY` (the anon key is public-safe; keep it server-side, not `NEXT_PUBLIC_`). Never hardcode keys.
- Missing-story policy: an invalid `<date>` (not `yyyy-MM-dd`) → `notFound()` (404). A valid date with no story row (or a Supabase read error) → render a graceful fallback page (title/pitch + download buttons) marked `robots: noindex` — never a hard 404 or a crash.
- Reuse existing components (`StoreButtons`, `DownloadLink`, `downloadLinks.ts`) and i18n (`getDictionary`) — do not duplicate store URLs or button markup.
- Locale validation uses the existing `isLocale` from `@/i18n/config`.
- TypeScript strict: `npm run build` must type-check and build cleanly.

---

### Task 1: Test runner + Supabase dependency

**Files:**
- Modify: `landing/package.json` (add deps + `test` script)
- Create: `landing/vitest.config.ts`
- Create: `landing/src/lib/__tests__/sanity.test.ts`

**Interfaces:**
- Produces: a working `npm test` (vitest, node environment) for later tasks.

- [ ] **Step 1: Add dependencies**

Run: `cd landing && npm install @supabase/supabase-js && npm install -D vitest`
Expected: both install; `package.json` gains `@supabase/supabase-js` in `dependencies` and `vitest` in `devDependencies`.

- [ ] **Step 2: Add the test script**

In `landing/package.json` `"scripts"`, add:

```json
    "lint": "next lint",
    "test": "vitest run"
```

- [ ] **Step 3: Create `landing/vitest.config.ts`**

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
  },
  resolve: {
    alias: { "@": new URL("./src", import.meta.url).pathname },
  },
});
```

- [ ] **Step 4: Create a sanity test `landing/src/lib/__tests__/sanity.test.ts`**

```ts
import { describe, it, expect } from "vitest";

describe("vitest runner", () => {
  it("runs", () => {
    expect(1 + 1).toBe(2);
  });
});
```

- [ ] **Step 5: Run it**

Run: `cd landing && npm test`
Expected: 1 passing test; exit 0.

- [ ] **Step 6: Commit**

```bash
git add landing/package.json landing/package-lock.json landing/vitest.config.ts \
        landing/src/lib/__tests__/sanity.test.ts
git commit -m "chore(landing): add supabase-js dep and vitest test runner"
```

---

### Task 2: Daily-story data module (pure helpers + server fetch)

**Files:**
- Create: `landing/src/lib/supabase.ts`
- Create: `landing/src/lib/dailyStory.ts`
- Create: `landing/src/lib/dailyStory.test.ts`

**Interfaces:**
- Consumes: `@supabase/supabase-js`.
- Produces:
  - `type StoryTeaser = { placeName: string; placeLocation: string; era: string; title: string; hook: string; paragraphs: string[]; imageUrl: string | null; }`
  - `localeToLanguage(locale: "zh" | "en"): "zh-TW" | "en"`
  - `isValidStoryDate(date: string): boolean` (strict `yyyy-MM-dd`)
  - `firstParagraphs(row, max = 2): string[]` — first N paragraphs from `card_paragraphs` (array) or, if absent, from `story` split on blank lines
  - `rowToTeaser(row: Record<string, unknown>): StoryTeaser`
  - `getDailyStory(locale: "zh" | "en", date: string): Promise<StoryTeaser | null>` (server fetch; returns null on missing/error)

- [ ] **Step 1: Create the Supabase client `landing/src/lib/supabase.ts`**

```ts
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/// Server-side Supabase client using the public anon key.
///
/// Reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` from the environment. The anon
/// key is safe to use server-side; RLS on `daily_stories` limits reads to
/// past publish dates. Throws a clear error if the env is not configured so
/// misconfiguration fails loudly at request time rather than silently.
export function getSupabaseClient(): SupabaseClient {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_ANON_KEY;
  if (!url || !key) {
    throw new Error(
      "SUPABASE_URL and SUPABASE_ANON_KEY must be set for story pages",
    );
  }
  return createClient(url, key, { auth: { persistSession: false } });
}
```

- [ ] **Step 2: Write the failing test `landing/src/lib/dailyStory.test.ts`**

```ts
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
```

- [ ] **Step 3: Run to verify it fails**

Run: `cd landing && npm test -- dailyStory`
Expected: FAIL — module `./dailyStory` not found / exports undefined.

- [ ] **Step 4: Implement `landing/src/lib/dailyStory.ts`**

```ts
import { getSupabaseClient } from "./supabase";

export type StoryTeaser = {
  placeName: string;
  placeLocation: string;
  era: string;
  title: string;
  hook: string;
  paragraphs: string[];
  imageUrl: string | null;
};

const COLUMNS =
  "publish_date, language, place_name, place_location, era, story, " +
  "image_url, card_title, card_title_sub, card_paragraphs, " +
  "card_pull_quote, card_pull_quote_attrib";

export function localeToLanguage(locale: "zh" | "en"): "zh-TW" | "en" {
  return locale === "zh" ? "zh-TW" : "en";
}

export function isValidStoryDate(date: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return false;
  const [y, m, d] = date.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return (
    dt.getUTCFullYear() === y &&
    dt.getUTCMonth() === m - 1 &&
    dt.getUTCDate() === d
  );
}

export function firstParagraphs(
  row: Record<string, unknown>,
  max = 2,
): string[] {
  const cards = row.card_paragraphs;
  if (Array.isArray(cards) && cards.length > 0) {
    return (cards as string[]).slice(0, max);
  }
  const story = typeof row.story === "string" ? row.story : "";
  return story
    .split(/\n+/)
    .map((p) => p.trim())
    .filter((p) => p.length > 0)
    .slice(0, max);
}

export function rowToTeaser(row: Record<string, unknown>): StoryTeaser {
  const str = (v: unknown): string => (typeof v === "string" ? v : "");
  return {
    placeName: str(row.place_name),
    placeLocation: str(row.place_location),
    era: str(row.era),
    title: str(row.card_title) || str(row.place_name),
    hook: str(row.card_pull_quote) || str(row.card_title_sub),
    paragraphs: firstParagraphs(row, 2),
    imageUrl: typeof row.image_url === "string" ? row.image_url : null,
  };
}

/// Fetches one daily story teaser by locale + date. Returns null when the
/// story does not exist or the read fails — the page renders a fallback.
export async function getDailyStory(
  locale: "zh" | "en",
  date: string,
): Promise<StoryTeaser | null> {
  try {
    const client = getSupabaseClient();
    const { data, error } = await client
      .from("daily_stories")
      .select(COLUMNS)
      .eq("language", localeToLanguage(locale))
      .eq("publish_date", date)
      .limit(1)
      .maybeSingle();
    if (error || !data) return null;
    return rowToTeaser(data as Record<string, unknown>);
  } catch {
    return null;
  }
}
```

- [ ] **Step 5: Run to verify it passes**

Run: `cd landing && npm test -- dailyStory`
Expected: PASS (all describe blocks green).

- [ ] **Step 6: Commit**

```bash
git add landing/src/lib/supabase.ts landing/src/lib/dailyStory.ts \
        landing/src/lib/dailyStory.test.ts
git commit -m "feat(landing): daily story teaser data module (anon read)"
```

---

### Task 3: Story page i18n copy + download location

**Files:**
- Modify: `landing/src/lib/downloadLinks.ts` (add `"story"` to `DownloadLocation`)
- Modify: `landing/src/i18n/dictionaries.ts` (add a `story` block to `Dict`, `zh`, and `en`)

**Interfaces:**
- Produces: `d.story.{eyebrow, continueCta, notFoundTitle, notFoundBody}` copy and a `"story"` download location for GA attribution.

- [ ] **Step 1: Add the download location**

In `landing/src/lib/downloadLinks.ts`, extend the union:

```ts
export type DownloadLocation =
  | "navbar"
  | "hero"
  | "final_cta"
  | "footer"
  | "story";
```

- [ ] **Step 2: Add `story` to the `Dict` interface**

In `landing/src/i18n/dictionaries.ts`, add to the `Dict` interface (after `metadata`):

```ts
  story: {
    eyebrow: string;
    continueCta: string;
    notFoundTitle: string;
    notFoundBody: string;
  };
```

- [ ] **Step 3: Add the `zh` copy**

In the `zh` dictionary object, add:

```ts
  story: {
    eyebrow: "來自 Lorescape 的每日故事",
    continueCta: "想聽完整故事？下載 App，每天還有一則新的。",
    notFoundTitle: "這則故事還在路上",
    notFoundBody:
      "我們找不到這一則故事，但每天都有一則新的在等你。下載 Lorescape，" +
      "走到哪，就聽那裡的歷史故事。",
  },
```

- [ ] **Step 4: Add the `en` copy**

In the `en` dictionary object, add:

```ts
  story: {
    eyebrow: "A daily story from Lorescape",
    continueCta: "Want the full story? Download the app — a new one every day.",
    notFoundTitle: "This story is still on its way",
    notFoundBody:
      "We couldn't find this one, but there's a new story every day. " +
      "Download Lorescape and hear the history of any place you visit.",
  },
```

- [ ] **Step 5: Type-check**

Run: `cd landing && npx tsc --noEmit`
Expected: no errors (the `Dict` interface and both locales now match).

- [ ] **Step 6: Commit**

```bash
git add landing/src/lib/downloadLinks.ts landing/src/i18n/dictionaries.ts
git commit -m "feat(landing): story page i18n copy and download location"
```

---

### Task 4: The story page + Open Graph metadata

**Files:**
- Create: `landing/src/app/[locale]/story/[date]/page.tsx`

**Interfaces:**
- Consumes: `getDailyStory`, `isValidStoryDate` (Task 2); `getDictionary`, `isLocale` (existing); `StoreButtons` (existing); `d.story.*` (Task 3).
- Produces: the rendered route + `generateMetadata` for OG tags.

The page is a server component. `generateMetadata` fetches the story and sets OG title/description/image (falls back to a generic pitch + `noindex` when missing). The page body renders the teaser (cover, `place · location · era`, title, hook, first paragraphs, pull quote) then `StoreButtons` with `location="story"`, or the fallback block when the story is missing. Invalid date → `notFound()`.

- [ ] **Step 1: Create `landing/src/app/[locale]/story/[date]/page.tsx`**

```tsx
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getDictionary } from "@/i18n/dictionaries";
import { isLocale, type Locale } from "@/i18n/config";
import { getDailyStory, isValidStoryDate } from "@/lib/dailyStory";
import StoreButtons from "@/components/StoreButtons";

type Params = { locale: string; date: string };

export async function generateMetadata({
  params,
}: {
  params: Params;
}): Promise<Metadata> {
  if (!isLocale(params.locale) || !isValidStoryDate(params.date)) {
    return { robots: { index: false, follow: false } };
  }
  const d = getDictionary(params.locale);
  const story = await getDailyStory(params.locale, params.date);
  if (!story) {
    return {
      title: `${d.story.notFoundTitle} — Lorescape`,
      description: d.story.notFoundBody,
      robots: { index: false, follow: false },
    };
  }
  const title = `${story.title} — Lorescape`;
  const description = story.hook || story.paragraphs[0] || "";
  return {
    title,
    description,
    alternates: { canonical: `/${params.locale}/story/${params.date}` },
    openGraph: {
      title,
      description,
      type: "article",
      locale: params.locale === "zh" ? "zh_TW" : "en_US",
      siteName: "Lorescape",
      images: story.imageUrl ? [{ url: story.imageUrl }] : undefined,
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: story.imageUrl ? [story.imageUrl] : undefined,
    },
    robots: { index: true, follow: true },
  };
}

export default async function StoryPage({ params }: { params: Params }) {
  if (!isLocale(params.locale)) notFound();
  if (!isValidStoryDate(params.date)) notFound();

  const locale = params.locale as Locale;
  const d = getDictionary(locale);
  const story = await getDailyStory(locale, params.date);

  if (!story) {
    return (
      <main className="story-page story-page--empty">
        <p className="story-eyebrow">{d.story.eyebrow}</p>
        <h1 className="story-title">{d.story.notFoundTitle}</h1>
        <p className="story-body">{d.story.notFoundBody}</p>
        <div className="story-cta">
          <StoreButtons
            location="story"
            variant="light"
            labels={d.storeButtons}
          />
        </div>
      </main>
    );
  }

  return (
    <main className="story-page">
      {story.imageUrl && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          className="story-cover"
          src={story.imageUrl}
          alt={story.placeName}
        />
      )}
      <p className="story-eyebrow">{d.story.eyebrow}</p>
      <p className="story-meta">
        {story.placeName} · {story.placeLocation} · {story.era}
      </p>
      <h1 className="story-title">{story.title}</h1>
      {story.hook && <p className="story-hook">{story.hook}</p>}
      {story.paragraphs.map((p, i) => (
        <p key={i} className="story-body">
          {p}
        </p>
      ))}
      <p className="story-continue">{d.story.continueCta}</p>
      <div className="story-cta">
        <StoreButtons location="story" variant="light" labels={d.storeButtons} />
      </div>
    </main>
  );
}
```

- [ ] **Step 2: Type-check + build**

Run: `cd landing && npx tsc --noEmit && npm run build`
Expected: type-check clean; `next build` succeeds and lists the `/[locale]/story/[date]` route as dynamic (ƒ). If build complains about `next/image` usage, the `no-img-element` eslint-disable comment is already in place; `<img>` is intentional (the cover is a remote Wikipedia URL and we avoid `next/image` remote-domain config here).

- [ ] **Step 3: Commit**

```bash
git add "landing/src/app/[locale]/story/[date]/page.tsx"
git commit -m "feat(landing): daily story teaser page with OG metadata"
```

---

### Task 5: Build gate + manual verification

**Files:** none (verification only).

- [ ] **Step 1: Full checks**

Run: `cd landing && npm test && npx tsc --noEmit && npm run build`
Expected: tests pass; type-check clean; build succeeds.

- [ ] **Step 2: Manual verification (requires Supabase env)**

Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` (the project's anon key) in `landing/.env.local`, then run `npm run dev` and check:
- `http://localhost:3000/zh/story/<a real past publish_date>` renders cover, `place · location · era`, title, hook, first paragraphs, the continue CTA, and both store buttons.
- `http://localhost:3000/en/story/<same date>` renders the English story.
- View-source shows `<meta property="og:title">`, `og:description`, and `og:image` populated from the story.
- A date with no story (e.g. far future) renders the fallback block (not a crash/404) and `<meta name="robots" content="noindex...">`.
- An invalid date (`/zh/story/2026-13-01`) returns 404.

- [ ] **Step 3: No commit** (verification only). Record any follow-ups as new tasks.

---

## Deferred / follow-ups

- **Styling polish:** this plan uses semantic class names (`story-page`, `story-cover`, `story-title`, etc.) but does not add CSS. A follow-up styles them to the warm paper / serif aesthetic (or the classes map to existing tokens in `globals.css`). The page is functional and correctly structured without it.
- **ISR caching:** story pages render dynamically (SSR) per request. A later optimization can add `export const revalidate = 3600` for CDN caching.
- **RLS same-day edge:** anon RLS gates to past `publish_date`; if the RLS boundary is UTC while "today" is Asia/Taipei, today's story may be briefly unreadable to anon near midnight. Acceptable; note if it surfaces.
- **Env wiring in hosting:** `SUPABASE_URL` / `SUPABASE_ANON_KEY` must be set in the landing deploy environment (Vercel/host) for production — a USER step, not code.

## Self-review notes

- Spec coverage: Phase 2 spec bullets — dynamic `[locale]/story/[date]` route (Task 4), Supabase anon read (Task 2), teaser + first section + store CTA (Task 4 + Task 3 copy), OG tags (Task 4 `generateMetadata`), bilingual via `[locale]`/dictionaries (Task 3), graceful fallback on missing/failed read (Task 4) — each maps to a task. Grant migration intentionally omitted (verified already granted).
- Type consistency: `StoryTeaser` shape and helper signatures defined in Task 2 are consumed unchanged in Task 4; `DownloadLocation` gains `"story"` in Task 3 before Task 4 uses `location="story"`.
- No placeholders: every step has complete code and an exact command with expected result. Styling is explicitly scoped out (semantic classes only) rather than left as a vague TODO.
