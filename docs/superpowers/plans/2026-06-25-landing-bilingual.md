# Landing Page 雙語（中／英）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓 `landing/` 的首頁支援繁體中文（`/zh`）與英文（`/en`），首訪自動偵測瀏覽器語言並重導，使用者可手動切換；法律頁維持英文單一版本、網址不變。

**Architecture:** 採 Next.js App Router `[locale]` 動態區段產出 `/zh`、`/en`，root layout 改為 pass-through、由下層 layout 渲染 `<html lang>`；首頁文案抽到自製型別化字典 `src/i18n/dictionaries.ts`；根目錄 `/` 為前端 JS 偵測重導頁；法律/support/credits 放進 `(legal)` route group 保持原網址。

**Tech Stack:** Next.js 14.2 (App Router, `output: "export"`)、TypeScript、Tailwind、`next/font`、Firebase Hosting。無單元測試框架，驗證以 `npm run build` + `npm run lint` + grep `out/` 產物為主。

## Global Constraints

- 不引入任何 i18n 套件（不裝 `next-intl` 等）；字典為自製 TypeScript。
- `next.config.mjs` 維持 `output: "export"`、`images.unoptimized`，不可改。
- 法律頁網址不可變動：`/privacy`、`/terms`、`/support`、`/credits` 維持英文、內容不改。
- `defaultLocale = 'zh'`；locales 僅 `['zh','en']`。
- 中文 `lang="zh-Hant"`、英文 `lang="en"`。
- 每步驟結束前 `cd landing && npm run build` 必須成功；最終 `npm run lint` 必須通過。
- 英文為品牌創譯（transcreation），措辭以本計畫字典為準，最終交使用者審閱。
- 所有指令在 `landing/` 目錄下執行。

---

## File Structure

**新增：**
- `landing/src/i18n/config.ts` — locales / defaultLocale / Locale / isLocale。
- `landing/src/i18n/dictionaries.ts` — `Dict` 型別 + `zh`/`en` 物件 + `getDictionary`。
- `landing/src/app/fonts.ts` — `next/font` 字型宣告（自 root layout 抽出）。
- `landing/src/components/SiteHtml.tsx` — 共用 `<html lang><head><body>` 外殼。
- `landing/src/components/LocaleSwitch.tsx` — 中／EN 切換（client）。
- `landing/src/app/[locale]/layout.tsx` — locale layout（generateStaticParams / generateMetadata）。
- `landing/src/app/[locale]/page.tsx` — 雙語首頁。
- `landing/src/app/(legal)/layout.tsx` — 英文外殼 layout。

**移動（git mv）：**
- `landing/src/app/privacy/` → `landing/src/app/(legal)/privacy/`（terms / support / credits 同）。

**修改：**
- `landing/src/app/layout.tsx` — 改為 pass-through。
- `landing/src/app/page.tsx` — 改為偵測重導頁。
- `landing/src/app/sitemap.ts` — 加入 `/zh`、`/en`。
- `landing/src/components/Hero.tsx`、`Manifesto.tsx`、`LocalStories.tsx`、`ManyAngles.tsx`、`ExploreNearby.tsx`、`JourneyJournal.tsx`、`FinalCTA.tsx` — 改吃 dict prop。
- `landing/src/components/Navbar.tsx`、`Footer.tsx` — 改吃 dict prop + 加 LocaleSwitch。
- `landing/src/app/(legal)/{privacy,terms,support,credits}/page.tsx` — 傳英文 dict 給 Navbar/Footer。

---

## Task 1: i18n 字典基礎（config + dictionaries）

建立型別化字典，內含中文（自現有 component 抽出）與英文創譯。此檔先獨立存在、暫無人引用，build 仍綠。

**Files:**
- Create: `landing/src/i18n/config.ts`
- Create: `landing/src/i18n/dictionaries.ts`

**Interfaces:**
- Produces:
  - `locales = ['zh','en'] as const`、`type Locale = 'zh' | 'en'`、`defaultLocale: Locale`、`isLocale(x: string): x is Locale`
  - `type Dict`（見下方完整形狀）
  - `getDictionary(locale: Locale): Dict`
  - `dictionaries: Record<Locale, Dict>`

- [ ] **Step 1: 建立 `src/i18n/config.ts`**

```ts
export const locales = ["zh", "en"] as const;

export type Locale = (typeof locales)[number];

export const defaultLocale: Locale = "zh";

export function isLocale(value: string): value is Locale {
  return (locales as readonly string[]).includes(value);
}
```

- [ ] **Step 2: 建立 `src/i18n/dictionaries.ts`（型別 + 中英內容）**

```ts
import type { Locale } from "./config";

export interface Dict {
  nav: {
    links: { label: string; anchor: string }[];
    downloadApp: string;
    switchTo: string; // 切換鈕顯示文字（指向另一語言）
  };
  hero: {
    pill: string;
    headlineTop: string;
    headlineClay: string;
    lede: string;
    scroll: string;
    nowTouring: string;
    plateTitle: string;
    plateImageAlt: string;
    plateOrigin: string;
  };
  manifesto: { line1: string; line2Lead: string; line2Quote: string; cite: string };
  localStories: {
    no: string;
    h2Top: string;
    h2Bottom: string;
    lede: string;
    card1Title: string;
    card1Body: string;
    card2Title: string;
    card2Body: string;
    mediaCap: string;
    mediaOrigin: string;
    mediaAlt: string;
  };
  manyAngles: {
    no: string;
    over: string;
    h2Top: string;
    h2Bottom: string;
    lede: string;
    modes: { num: string; title: string; body: string }[];
    nowPlaying: string;
    phoneTitleTop: string;
    phoneTitleBottom: string;
    phoneSubtitle: string;
    phoneImageAlt: string;
  };
  exploreNearby: {
    over: string;
    h2: string;
    body: string;
    checks: string[];
    chips: string[]; // 對應 [自然,人文,信仰,城市] 四項
    imageAlt: string;
  };
  journeyJournal: {
    no: string;
    h2: string;
    lede: string;
    stats: { num: string; lab: string; caption: string; body: string }[];
  };
  finalCTA: {
    over: string;
    h2Top: string;
    h2Bottom: string;
    body: string;
    imageAlt: string;
  };
  footer: {
    tag: string;
    colProduct: string;
    colCompany: string;
    contact: string;
    colLegal: string;
    privacy: string;
    terms: string;
    credits: string;
    copyright: string;
    version: string;
  };
  metadata: {
    title: string;
    description: string;
    keywords: string[];
    ogTitle: string;
    ogDescription: string;
  };
}

const zh: Dict = {
  nav: {
    links: [
      { label: "在地故事", anchor: "#stories" },
      { label: "多種角度", anchor: "#angles" },
      { label: "探索附近", anchor: "#explore" },
      { label: "旅程手記", anchor: "#journey" },
    ],
    downloadApp: "下載 App",
    switchTo: "EN",
  },
  hero: {
    pill: "AI 隨行的旅行說書人",
    headlineTop: "體驗歷史",
    headlineClay: "而不只是風景",
    lede: "你的隨身 AI 旅行說書人。走到哪，就把那裡的來歷、傳說與歷史，說給你聽。",
    scroll: "向下捲動",
    nowTouring: "正在導覽",
    plateTitle: "摧毀與重生的百年豪賭",
    plateImageAlt: "聖伯多祿大殿",
    plateOrigin: "St. Peter's Basilica · Vatican",
  },
  manifesto: {
    line1: "別再低頭盯著螢幕。",
    line2Lead: "抬起眼睛，",
    line2Quote: "世界本身就是展品。",
    cite: "Lorescape · 地誌手記",
  },
  localStories: {
    no: "功能 01",
    h2Top: "為眼前的風景，",
    h2Bottom: "即時寫一篇故事",
    lede: "不是條列式的百科資料。Lorescape 為你經過的每座地標、古蹟與山林，當場編寫一篇有人物、有轉折、值得細讀的故事。",
    card1Title: "值得細讀的歷史長文",
    card1Body: "有起承轉合、有人物與懸念的敘事，而不是冰冷的年份與條目。",
    card2Title: "一鍵化為語音",
    card2Body: "把手機收進口袋，邊走邊聽它把這裡的來歷娓娓道來。",
    mediaCap: "台中朝聖宮",
    mediaOrigin: "Chaosheng Temple · Taichung",
    mediaAlt: "台中朝聖宮",
  },
  manyAngles: {
    no: "功能 02",
    over: "Many Angles, One Place",
    h2Top: "同一座地標，",
    h2Bottom: "不只一個故事",
    lede: "權謀、傳說、建築祕辛——AI 在每個地點為你備好幾種切入角度。挑一個最吸引你的，開始聆聽。",
    modes: [
      {
        num: "01",
        title: "摧毀與重生的百年豪賭",
        body: "儒略二世決定拆毀君士坦丁大帝的千年古教堂，這場瘋狂重建竟耗時百餘年。",
      },
      {
        num: "02",
        title: "祭壇之下的神聖祕密",
        body: "世界上最大的教堂並非教宗的主教座堂，因為它底下埋藏著更神聖的祕密。",
      },
      {
        num: "03",
        title: "文藝復興巨匠的接力賽",
        body: "米開朗基羅與拉斐爾輪番上陣，在同一座教堂留下各自的瘋狂印記。",
      },
    ],
    nowPlaying: "正在播放",
    phoneTitleTop: "摧毀與重生的",
    phoneTitleBottom: "百年豪賭",
    phoneSubtitle: "St. Peter's Basilica",
    phoneImageAlt: "聖伯多祿大殿導覽",
  },
  exploreNearby: {
    over: "功能 03 · Explore Nearby",
    h2: "探索身邊的風景",
    body: "翻開地圖之前，先看看方圓之內。Lorescape 依距離與主題，為你列出附近值得停留的每一個角落——每一種風景，都有屬於它的故事。",
    checks: [
      "依距離篩選，只看走得到的地方",
      "多種主題分類，各有專屬故事",
      "收藏想去的地點，隨時回來",
    ],
    chips: ["自然景觀", "人文古蹟", "信仰聖地", "城市地標"],
    imageAlt: "公園步道",
  },
  journeyJournal: {
    no: "功能 04",
    h2: "你的旅程，自動成冊",
    lede: "每一次駐足，都被悄悄寫進一本屬於你的旅行手記。",
    stats: [
      { num: "I", lab: "Auto Journal", caption: "自動成篇", body: "每聽完一段故事，就自動留下一篇可回味的手記。" },
      { num: "II", lab: "Trips", caption: "依旅程歸檔", body: "把沿途的記錄整理成一趟趟旅程，井然有序。" },
      { num: "III", lab: "Timeline", caption: "沿時間軸重溫", body: "順著時間軸回看，隨時重返走過的任何一個角落。" },
    ],
  },
  finalCTA: {
    over: "開始你的第一段故事",
    h2Top: "城市是一本書。",
    h2Bottom: "開始閱讀吧。",
    body: "加入五萬名探索者，一同揭開世界各地隱藏的篇章。",
    imageAlt: "阿格拉紅堡",
  },
  footer: {
    tag: "溫潤紙感 × 文學宋體 × 陶土點綴——為旅途中的每一段故事而設計。",
    colProduct: "產品",
    colCompany: "公司",
    contact: "聯絡我們",
    colLegal: "法律",
    privacy: "隱私政策",
    terms: "使用條款",
    credits: "圖片來源",
    copyright: "© 2026 Lorescape. 版權所有。",
    version: "地誌手記 · v1.0",
  },
  metadata: {
    title: "Lorescape — 讓每一處風景，開口說它的故事",
    description: "AI 隨行的旅行說書人。走到哪，就把那裡的來歷、傳說與歷史，為你即時編寫成值得細讀的故事，還能化作語音邊走邊聽。",
    keywords: ["AI 導覽", "旅行說書人", "在地故事", "語音導覽", "文化旅遊", "Lorescape", "讀景"],
    ogTitle: "Lorescape — 讓每一處風景，開口說它的故事",
    ogDescription: "AI 隨行的旅行說書人，為每一處風景備好屬於它的故事。",
  },
};

const en: Dict = {
  nav: {
    links: [
      { label: "Local Stories", anchor: "#stories" },
      { label: "Many Angles", anchor: "#angles" },
      { label: "Explore Nearby", anchor: "#explore" },
      { label: "Journey Journal", anchor: "#journey" },
    ],
    downloadApp: "Download App",
    switchTo: "中文",
  },
  hero: {
    pill: "Your AI travel storyteller",
    headlineTop: "Experience history,",
    headlineClay: "not just the view",
    lede: "Your pocket AI storyteller. Wherever you go, it tells you the origins, legends, and history of the place around you.",
    scroll: "Scroll down",
    nowTouring: "Now touring",
    plateTitle: "A century-long gamble of ruin and rebirth",
    plateImageAlt: "St. Peter's Basilica",
    plateOrigin: "St. Peter's Basilica · Vatican",
  },
  manifesto: {
    line1: "Stop staring down at your screen.",
    line2Lead: "Look up — ",
    line2Quote: "the world itself is the exhibit.",
    cite: "Lorescape · Field Notes",
  },
  localStories: {
    no: "Feature 01",
    h2Top: "A story for the view in front of you,",
    h2Bottom: "written on the spot",
    lede: "Not a bullet-point encyclopedia entry. For every landmark, monument, and mountain you pass, Lorescape composes a story with characters, twists, and depth worth reading.",
    card1Title: "Long-form history worth reading",
    card1Body: "Narrative with arc, characters, and suspense — not cold dates and entries.",
    card2Title: "Turn it into audio with one tap",
    card2Body: "Slip your phone into your pocket and listen as it recounts the story while you walk.",
    mediaCap: "Chaosheng Temple, Taichung",
    mediaOrigin: "Chaosheng Temple · Taichung",
    mediaAlt: "Chaosheng Temple",
  },
  manyAngles: {
    no: "Feature 02",
    over: "Many Angles, One Place",
    h2Top: "One landmark,",
    h2Bottom: "more than one story",
    lede: "Politics, legends, architectural secrets — AI prepares several angles for every place. Pick the one that draws you in and start listening.",
    modes: [
      {
        num: "01",
        title: "A century-long gamble of ruin and rebirth",
        body: "Pope Julius II tore down Constantine's thousand-year-old basilica — and the audacious rebuild took over a century.",
      },
      {
        num: "02",
        title: "The sacred secret beneath the altar",
        body: "The world's largest church isn't the pope's cathedral — because something far holier lies buried beneath it.",
      },
      {
        num: "03",
        title: "A relay race of Renaissance masters",
        body: "Michelangelo and Raphael took turns, each leaving their own audacious mark on the same church.",
      },
    ],
    nowPlaying: "Now playing",
    phoneTitleTop: "A century-long gamble",
    phoneTitleBottom: "of ruin and rebirth",
    phoneSubtitle: "St. Peter's Basilica",
    phoneImageAlt: "St. Peter's Basilica tour",
  },
  exploreNearby: {
    over: "Feature 03 · Explore Nearby",
    h2: "Explore what's around you",
    body: "Before you open the map, look at what's within reach. By distance and theme, Lorescape lists every nearby corner worth a stop — and every one has a story of its own.",
    checks: [
      "Filter by distance — see only places you can walk to",
      "Multiple themes, each with its own stories",
      "Save the places you want to visit and return anytime",
    ],
    chips: ["Nature", "Heritage", "Sacred Sites", "City Landmarks"],
    imageAlt: "Park trail",
  },
  journeyJournal: {
    no: "Feature 04",
    h2: "Your journey, bound into a journal automatically",
    lede: "Every stop is quietly written into a travel journal that's yours.",
    stats: [
      { num: "I", lab: "Auto Journal", caption: "Auto-written", body: "Finish a story and a memorable entry is saved for you automatically." },
      { num: "II", lab: "Trips", caption: "Filed by trip", body: "Your records along the way are organized into neat, separate trips." },
      { num: "III", lab: "Timeline", caption: "Along a timeline", body: "Look back along a timeline and revisit any corner you've walked, anytime." },
    ],
  },
  finalCTA: {
    over: "Begin your first story",
    h2Top: "The city is a book.",
    h2Bottom: "Start reading.",
    body: "Join fifty thousand explorers uncovering the hidden chapters of places around the world.",
    imageAlt: "Agra Fort",
  },
  footer: {
    tag: "Warm paper × literary serif × terracotta accents — designed for every story along the way.",
    colProduct: "Product",
    colCompany: "Company",
    contact: "Contact",
    colLegal: "Legal",
    privacy: "Privacy Policy",
    terms: "Terms of Use",
    credits: "Image Credits",
    copyright: "© 2026 Lorescape. All rights reserved.",
    version: "Field Notes · v1.0",
  },
  metadata: {
    title: "Lorescape — Let every place tell its story",
    description: "Your AI travel storyteller. Wherever you go, it writes the origins, legends, and history of the place into a story worth reading — and reads it aloud as you walk.",
    keywords: ["AI tour guide", "travel storyteller", "local stories", "audio guide", "cultural travel", "Lorescape"],
    ogTitle: "Lorescape — Let every place tell its story",
    ogDescription: "Your AI travel storyteller, with a story ready for every place you visit.",
  },
};

export const dictionaries: Record<Locale, Dict> = { zh, en };

export function getDictionary(locale: Locale): Dict {
  return dictionaries[locale];
}
```

- [ ] **Step 3: 型別檢查通過**

Run: `cd landing && npx tsc --noEmit`
Expected: 無錯誤輸出（exit 0）。

- [ ] **Step 4: build 仍綠**

Run: `cd landing && npm run build`
Expected: 成功，`out/` 仍如舊（尚未有人引用字典）。

- [ ] **Step 5: Commit**

```bash
git add landing/src/i18n/config.ts landing/src/i18n/dictionaries.ts
git commit -m "feat(landing): add typed zh/en i18n dictionary"
```

---

## Task 2: 首頁 section component 改吃字典（仍在 `/`、仍中文）

把 7 個 section component 由寫死字串改為接收 dict slice，並更新現有 `src/app/page.tsx` 以 `getDictionary('zh')` 傳入。此任務不動路由、不動 Navbar/Footer，畫面與現況一致。

**Files:**
- Modify: `landing/src/components/Hero.tsx`、`Manifesto.tsx`、`LocalStories.tsx`、`ManyAngles.tsx`、`ExploreNearby.tsx`、`JourneyJournal.tsx`、`FinalCTA.tsx`
- Modify: `landing/src/app/page.tsx`

**Interfaces:**
- Consumes: `Dict`、`getDictionary` from Task 1。
- Produces 各 component 新簽章：
  - `Hero({ d }: { d: Dict["hero"] })`
  - `Manifesto({ d }: { d: Dict["manifesto"] })`
  - `LocalStories({ d }: { d: Dict["localStories"] })`
  - `ManyAngles({ d }: { d: Dict["manyAngles"] })`
  - `ExploreNearby({ d }: { d: Dict["exploreNearby"] })`
  - `JourneyJournal({ d }: { d: Dict["journeyJournal"] })`
  - `FinalCTA({ d }: { d: Dict["finalCTA"] })`

- [ ] **Step 1: 改 `Hero.tsx`**

於檔首加 `import type { Dict } from "@/i18n/dictionaries";`，簽章改為 `export default function Hero({ d }: { d: Dict["hero"] })`，並替換字面值：

```text
"AI 隨行的旅行說書人"        → {d.pill}
"體驗歷史"                  → {d.headlineTop}
"而不只是風景"               → {d.headlineClay}
lede 整段中文                → {d.lede}
"向下捲動"                  → {d.scroll}
alt="聖伯多祿大殿"           → alt={d.plateImageAlt}
"正在導覽"                  → {d.nowTouring}
"摧毀與重生的百年豪賭"        → {d.plateTitle}
"St. Peter's Basilica · Vatican" → {d.plateOrigin}
```

- [ ] **Step 2: 改 `Manifesto.tsx`**

簽章 `Manifesto({ d }: { d: Dict["manifesto"] })`：

```text
"別再低頭盯著螢幕。"          → {d.line1}
"抬起眼睛，"                 → {d.line2Lead}
"世界本身就是展品。"          → {d.line2Quote}
"Lorescape · 地誌手記"      → {d.cite}
```

- [ ] **Step 3: 改 `LocalStories.tsx`**

簽章 `LocalStories({ d }: { d: Dict["localStories"] })`：

```text
"功能 01"                  → {d.no}
"為眼前的風景，"             → {d.h2Top}
"即時寫一篇故事"             → {d.h2Bottom}
sec-lede 整段              → {d.lede}
"值得細讀的歷史長文"          → {d.card1Title}
card1 body                → {d.card1Body}
"一鍵化為語音"               → {d.card2Title}
card2 body                → {d.card2Body}
alt="台中朝聖宮"            → alt={d.mediaAlt}
media-cap "台中朝聖宮"      → {d.mediaCap}
"Chaosheng Temple · Taichung" → {d.mediaOrigin}
```

- [ ] **Step 4: 改 `ManyAngles.tsx`**

移除檔頂的 `const modes = [...]`，改用 `d.modes`。簽章 `ManyAngles({ d }: { d: Dict["manyAngles"] })`：

```text
"功能 02"                          → {d.no}
"Many Angles, One Place"           → {d.over}
"同一座地標，"                       → {d.h2Top}
"不只一個故事"                       → {d.h2Bottom}
sec-lede 整段                       → {d.lede}
modes.map 來源 modes                → d.modes
alt="聖伯多祿大殿導覽"               → alt={d.phoneImageAlt}
"正在播放"                          → {d.nowPlaying}
ti: "摧毀與重生的" / "百年豪賭"       → {d.phoneTitleTop} / {d.phoneTitleBottom}
su: "St. Peter's Basilica"          → {d.phoneSubtitle}
```

（`badge "Anno · I"` 與三個 `circle`/SVG 等非文字不動。）

- [ ] **Step 5: 改 `ExploreNearby.tsx`**

保留檔頂 `chips` 的 `path`（SVG），但 label 改由 dict 提供：將 `chips` 陣列改為只含 `path`，並以索引對應 `d.chips[i]`。簽章 `ExploreNearby({ d }: { d: Dict["exploreNearby"] })`：

```text
const checks = [...]              → 移除，改用 d.checks
"功能 03 · Explore Nearby"        → {d.over}
"探索身邊的風景"                    → {d.h2}
p 整段                            → {d.body}
checks.map 來源                    → d.checks
alt="公園步道"                     → alt={d.imageAlt}
```

chips 區塊改為（保留各自 SVG path、label 取自 dict）：

```tsx
const chipPaths = [
  <path key="nature" d="M3 19l6-9 4 5 3-4 5 8z" />,
  <path key="heritage" d="M4 9h16M5 9v9M9 9v9M15 9v9M19 9v9M3 20h18M4 9l8-5 8 5" />,
  <g key="sacred">
    <path d="M6 4h12v16l-6-3-6 3z" />
    <path d="M12 4v6M9.5 7h5" />
  </g>,
  <g key="city">
    <rect x="5" y="3" width="14" height="18" rx="1" />
    <path d="M9 7h2M13 7h2M9 11h2M13 11h2M9 15h2M13 15h2" />
  </g>,
];
```

```tsx
<div className="cat-chips">
  {d.chips.map((label, i) => (
    <span className="cat-chip" key={label}>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
        {chipPaths[i]}
      </svg>
      {label}
    </span>
  ))}
</div>
```

- [ ] **Step 6: 改 `JourneyJournal.tsx`**

移除檔頂 `const stats = [...]`，改用 `d.stats`。簽章 `JourneyJournal({ d }: { d: Dict["journeyJournal"] })`：

```text
"功能 04"                  → {d.no}
"你的旅程，自動成冊"          → {d.h2}
sec-lede                  → {d.lede}
stats.map 來源 stats        → d.stats
stat.lab / stat.cn          → stat.lab / stat.caption
```

（`stat.cn` 在迴圈內改為 `stat.caption`。）

- [ ] **Step 7: 改 `FinalCTA.tsx`**

簽章 `FinalCTA({ d }: { d: Dict["finalCTA"] })`：

```text
"開始你的第一段故事"          → {d.over}
"城市是一本書。"             → {d.h2Top}
"開始閱讀吧。"               → {d.h2Bottom}
"加入五萬名探索者，一同揭開世界各地隱藏的篇章。" → {d.body}
alt="阿格拉紅堡"            → alt={d.imageAlt}
```

- [ ] **Step 8: 更新 `src/app/page.tsx` 傳入 zh 字典**

```tsx
import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import Manifesto from "@/components/Manifesto";
import LocalStories from "@/components/LocalStories";
import ManyAngles from "@/components/ManyAngles";
import ExploreNearby from "@/components/ExploreNearby";
import JourneyJournal from "@/components/JourneyJournal";
import FinalCTA from "@/components/FinalCTA";
import Footer from "@/components/Footer";
import { getDictionary } from "@/i18n/dictionaries";

export default function Home() {
  const d = getDictionary("zh");
  return (
    <>
      <Navbar />
      <main>
        <Hero d={d.hero} />
        <Manifesto d={d.manifesto} />
        <LocalStories d={d.localStories} />
        <ManyAngles d={d.manyAngles} />
        <ExploreNearby d={d.exploreNearby} />
        <JourneyJournal d={d.journeyJournal} />
        <FinalCTA d={d.finalCTA} />
      </main>
      <Footer />
    </>
  );
}
```

（Navbar/Footer 暫不傳 prop，仍為原本中文版，Task 3 再改。）

- [ ] **Step 9: build + 內容比對**

Run: `cd landing && npm run build`
Expected: 成功。

Run: `grep -c "體驗歷史" out/index.html`
Expected: `1`（中文首頁字面值仍出現，證明字典渲染正常）。

- [ ] **Step 10: Commit**

```bash
git add landing/src/components landing/src/app/page.tsx
git commit -m "refactor(landing): drive homepage sections from i18n dictionary"
```

---

## Task 3: 雙語路由切換（`/zh`+`/en`、偵測重導、Navbar/Footer 雙語、法律頁 route group）

這是原子性的路由翻轉：產生 `[locale]` 雙語首頁、`(legal)` 英文外殼、root pass-through + `/` 偵測頁、共用 `SiteHtml`、`LocaleSwitch`、sitemap。完成後即為可運作的雙語站。

**Files:**
- Create: `landing/src/app/fonts.ts`、`landing/src/components/SiteHtml.tsx`、`landing/src/components/LocaleSwitch.tsx`、`landing/src/app/[locale]/layout.tsx`、`landing/src/app/[locale]/page.tsx`、`landing/src/app/(legal)/layout.tsx`
- Move: `landing/src/app/{privacy,terms,support,credits}` → `landing/src/app/(legal)/{...}`
- Modify: `landing/src/app/layout.tsx`、`landing/src/app/page.tsx`、`landing/src/app/sitemap.ts`、`landing/src/components/Navbar.tsx`、`landing/src/components/Footer.tsx`、`landing/src/app/(legal)/{privacy,terms,support,credits}/page.tsx`

**Interfaces:**
- Consumes: `getDictionary`、`Dict`、`Locale`、`isLocale`、`locales`、`defaultLocale`（Task 1）；已 dict 化的 section components（Task 2）。
- Produces:
  - `SiteHtml({ lang, children }: { lang: string; children: React.ReactNode })`
  - `Navbar({ d, homeHref }: { d: Dict; homeHref: string })`
  - `Footer({ d, homeHref }: { d: Dict; homeHref: string })`
  - `LocaleSwitch({ label }: { label: string })`（client）

- [ ] **Step 1: 抽出字型 `src/app/fonts.ts`**

```ts
import { Noto_Serif_TC, Noto_Sans_TC } from "next/font/google";

export const notoSerifTc = Noto_Serif_TC({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "900"],
  variable: "--font-noto-serif-tc",
  display: "swap",
});

export const notoSansTc = Noto_Sans_TC({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-noto-sans-tc",
  display: "swap",
});
```

- [ ] **Step 2: 建立共用外殼 `src/components/SiteHtml.tsx`**

把現有 `src/app/layout.tsx` 的 `<html>`…`<body>`（含 head link、GoogleAnalytics、jsonLd）搬進來，`lang` 改為參數。

```tsx
import type React from "react";
import { GoogleAnalytics } from "@next/third-parties/google";
import { notoSerifTc, notoSansTc } from "@/app/fonts";

const gaId = process.env.NEXT_PUBLIC_GA_ID;

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "Lorescape",
  applicationCategory: "TravelApplication",
  operatingSystem: "iOS, Android",
  description:
    "AI 隨行的旅行說書人，為眼前的地標、古蹟與山林即時編寫在地故事，還能化作語音邊走邊聽。",
  offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
};

export default function SiteHtml({
  lang,
  children,
}: {
  lang: string;
  children: React.ReactNode;
}) {
  return (
    <html lang={lang} className={`${notoSerifTc.variable} ${notoSansTc.variable}`}>
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap"
          rel="stylesheet"
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body>
        {children}
        {gaId ? <GoogleAnalytics gaId={gaId} /> : null}
      </body>
    </html>
  );
}
```

（若現有 layout.tsx 的 head 還有其他 `<link>`/`<meta>`，一併搬入此處保持一致。）

- [ ] **Step 3: root layout 改 pass-through `src/app/layout.tsx`**

```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://lorescape.app"),
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return children;
}
```

- [ ] **Step 4: 建立 `LocaleSwitch.tsx`（client）**

依目前路徑切換 `/zh`↔`/en`，並記住選擇。

```tsx
"use client";

import { usePathname } from "next/navigation";

function counterpartHref(pathname: string): { href: string; target: "zh" | "en" } {
  if (pathname === "/en" || pathname.startsWith("/en/")) {
    return { href: "/zh" + pathname.slice(3), target: "zh" };
  }
  if (pathname === "/zh" || pathname.startsWith("/zh/")) {
    return { href: "/en" + pathname.slice(3), target: "en" };
  }
  // 法律頁等無語言前綴：英文內容，切換鈕導向中文首頁
  return { href: "/zh", target: "zh" };
}

export default function LocaleSwitch({ label }: { label: string }) {
  const pathname = usePathname();
  const { href, target } = counterpartHref(pathname || "/");
  return (
    <a
      className="nav__lang"
      href={href}
      onClick={() => {
        try {
          window.localStorage.setItem("lorescape_locale", target);
        } catch {
          /* ignore */
        }
      }}
    >
      {label}
    </a>
  );
}
```

- [ ] **Step 5: Navbar/Footer 改吃 dict + homeHref + 接上 LocaleSwitch**

`Navbar.tsx`：加 `import type { Dict } from "@/i18n/dictionaries";` 與 `import LocaleSwitch from "./LocaleSwitch";`，簽章 `export default function Navbar({ d, homeHref }: { d: Dict; homeHref: string })`。改動：

```text
const navLinks = [...]   → 移除，改用 d.nav.links
link.href / link.label   → `${homeHref}${link.anchor}` / link.label
"下載 App"               → {d.nav.downloadApp}
```

在 `nav__spacer` 之後、下載鈕之前插入：`<LocaleSwitch label={d.nav.switchTo} />`。

`Footer.tsx`：簽章 `export default function Footer({ d, homeHref }: { d: Dict; homeHref: string })`。改動：

```text
"溫潤紙感 …"             → {d.footer.tag}
"產品"                   → {d.footer.colProduct}
四個產品錨點 #stories…    → `${homeHref}#stories` 等，label 取 d.nav.links[i].label
"下載 App"               → {d.nav.downloadApp}
"公司"                   → {d.footer.colCompany}
"聯絡我們"                → {d.footer.contact}
"法律"                   → {d.footer.colLegal}
"隱私政策"/"使用條款"/"圖片來源" → d.footer.privacy / d.footer.terms / d.footer.credits
"© 2026 …版權所有。"      → {d.footer.copyright}
"地誌手記 · v1.0"         → {d.footer.version}
```

法律連結 `/support`、`/privacy`、`/terms`、`/credits` 維持原樣（不加語言前綴）。

- [ ] **Step 6: 建立 `[locale]/layout.tsx`**

```tsx
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import SiteHtml from "@/components/SiteHtml";
import { getDictionary } from "@/i18n/dictionaries";
import { isLocale, locales, type Locale } from "@/i18n/config";

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export function generateMetadata({
  params,
}: {
  params: { locale: string };
}): Metadata {
  if (!isLocale(params.locale)) return {};
  const d = getDictionary(params.locale);
  return {
    title: d.metadata.title,
    description: d.metadata.description,
    keywords: d.metadata.keywords,
    alternates: {
      canonical: `/${params.locale}`,
      languages: { "zh-Hant": "/zh", en: "/en", "x-default": "/" },
    },
    openGraph: {
      title: d.metadata.ogTitle,
      description: d.metadata.ogDescription,
      type: "website",
      locale: params.locale === "zh" ? "zh_TW" : "en_US",
      siteName: "Lorescape",
    },
    twitter: {
      card: "summary_large_image",
      title: d.metadata.ogTitle,
      description: d.metadata.ogDescription,
    },
    robots: { index: true, follow: true },
  };
}

export default function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { locale: string };
}) {
  if (!isLocale(params.locale)) notFound();
  const lang: string = (params.locale as Locale) === "zh" ? "zh-Hant" : "en";
  return <SiteHtml lang={lang}>{children}</SiteHtml>;
}
```

- [ ] **Step 7: 建立 `[locale]/page.tsx`（雙語首頁）**

```tsx
import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import Manifesto from "@/components/Manifesto";
import LocalStories from "@/components/LocalStories";
import ManyAngles from "@/components/ManyAngles";
import ExploreNearby from "@/components/ExploreNearby";
import JourneyJournal from "@/components/JourneyJournal";
import FinalCTA from "@/components/FinalCTA";
import Footer from "@/components/Footer";
import { getDictionary } from "@/i18n/dictionaries";
import { isLocale } from "@/i18n/config";
import { notFound } from "next/navigation";

export default function Home({ params }: { params: { locale: string } }) {
  if (!isLocale(params.locale)) notFound();
  const d = getDictionary(params.locale);
  return (
    <>
      <Navbar d={d} homeHref="" />
      <main>
        <Hero d={d.hero} />
        <Manifesto d={d.manifesto} />
        <LocalStories d={d.localStories} />
        <ManyAngles d={d.manyAngles} />
        <ExploreNearby d={d.exploreNearby} />
        <JourneyJournal d={d.journeyJournal} />
        <FinalCTA d={d.finalCTA} />
      </main>
      <Footer d={d} homeHref="" />
    </>
  );
}
```

（`homeHref=""` 因首頁本身即在 `/zh` 或 `/en`，錨點為同頁 `#stories`。）

- [ ] **Step 8: 刪除舊的 `src/app/page.tsx` 內容，改為偵測重導頁**

```tsx
const detect = `(function(){try{var s=localStorage.getItem('lorescape_locale');if(s==='zh'||s==='en'){location.replace('/'+s);return;}}catch(e){}var l=(navigator.language||'').toLowerCase();location.replace(l.indexOf('zh')===0?'/zh':'/en');})();`;

export default function RootRedirect() {
  return (
    <html lang="zh-Hant">
      <head>
        <meta httpEquiv="refresh" content="0;url=/zh" />
        <script dangerouslySetInnerHTML={{ __html: detect }} />
      </head>
      <body />
    </html>
  );
}
```

- [ ] **Step 9: 搬移法律頁到 `(legal)` route group 並建立其 layout**

```bash
cd landing/src/app
mkdir "(legal)"
git mv privacy "(legal)/privacy"
git mv terms "(legal)/terms"
git mv support "(legal)/support"
git mv credits "(legal)/credits"
```

建立 `landing/src/app/(legal)/layout.tsx`：

```tsx
import SiteHtml from "@/components/SiteHtml";

export default function LegalLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <SiteHtml lang="en">{children}</SiteHtml>;
}
```

- [ ] **Step 10: 法律頁傳英文 dict 給 Navbar/Footer**

四個檔 `(legal)/{privacy,terms,support,credits}/page.tsx` 皆於頂部加：

```tsx
import { getDictionary } from "@/i18n/dictionaries";
```

並把 `<Navbar />`、`<Footer />` 改為：

```tsx
const d = getDictionary("en");
// ...
<Navbar d={d} homeHref="/en" />
// ...
<Footer d={d} homeHref="/en" />
```

（在各 page 元件函式內取 `d`；`homeHref="/en"` 讓導覽錨點指向英文首頁。）

- [ ] **Step 11: 更新 `sitemap.ts`**

```tsx
import { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const base = "https://lorescape.app";
  return [
    { url: `${base}/zh`, changeFrequency: "monthly", priority: 1 },
    { url: `${base}/en`, changeFrequency: "monthly", priority: 1 },
    { url: `${base}/privacy`, changeFrequency: "yearly", priority: 0.5 },
    { url: `${base}/terms`, changeFrequency: "yearly", priority: 0.5 },
    { url: `${base}/support`, changeFrequency: "yearly", priority: 0.5 },
    { url: `${base}/credits`, changeFrequency: "yearly", priority: 0.3 },
  ];
}
```

- [ ] **Step 12: build + 驗證產物**

Run: `cd landing && npm run build`
Expected: 成功。若報 root layout 缺 `<html>` 而 build 失敗，採退路：在 root `layout.tsx` 改回渲染 `<html lang="zh-Hant"><body>{children}</body></html>`，並於 `[locale]/layout.tsx`、`(legal)/layout.tsx` 內以 client 片段 `document.documentElement.lang = ...` 覆寫（SiteHtml 改成不渲染 `<html>`、只渲染內容與一段設定 lang 的 inline script）。

Run: `ls out/zh/index.html out/en/index.html out/privacy.html out/terms.html out/support.html out/credits.html`
Expected: 六個檔皆存在。

Run: `grep -o 'lang="[^"]*"' out/en/index.html | head -1`
Expected: `lang="en"`。

Run: `grep -c "Experience history" out/en/index.html`
Expected: `1`。

Run: `grep -c "體驗歷史" out/zh/index.html`
Expected: `1`。

Run: `grep -o 'lang="[^"]*"' out/privacy.html | head -1`
Expected: `lang="en"`（英文法律頁，且 Navbar 已為英文）。

- [ ] **Step 13: lint**

Run: `cd landing && npm run lint`
Expected: 無錯誤（`No ESLint warnings or errors` 或 exit 0）。

- [ ] **Step 14: Commit**

```bash
git add landing/src
git commit -m "feat(landing): bilingual /zh + /en routes with auto-detect redirect"
```

---

## Task 4: 本機目視驗證（人工 checkpoint）

非程式任務，由使用者於本機確認後再合併。

- [ ] **Step 1: 啟動本機預覽**

Run: `cd landing && npx serve out`（或 `npm run dev` 後逐頁檢視）

- [ ] **Step 2: 逐項目視**

- 中文瀏覽器開 `/` → 導向 `/zh`；非中文 → `/en`（可改瀏覽器語言或清 `localStorage` 後測）。
- `/zh`、`/en` 內容、版面與品牌調性正確；切換鈕雙向可用且記住選擇。
- 英文首頁文案語意通順、無中文殘留。
- `/privacy`、`/terms`、`/support`、`/credits` 為英文、Navbar/Footer 亦為英文。

- [ ] **Step 3: 英文文案定稿**

使用者審閱 `src/i18n/dictionaries.ts` 的 `en` 區塊，回饋措辭調整；如有修改，改完重跑 Task 3 Step 12–13 後 commit。

---

## Self-Review 紀錄

- **Spec coverage：** 自動偵測（T3 S8）、`/zh`+`/en`（T3 S6–7）、自製字典（T1）、首頁雙語（T2+T3）、Navbar/Footer 雙語＋修正英文頁中文 chrome（T3 S5、S10）、法律頁維持英文且網址不變（T3 S9–10）、SEO hreflang/canonical/sitemap（T3 S6、S11）、無 firebase redirect（結構上不需，已於 spec 說明）、退路（T3 S12）。皆有對應任務。
- **Placeholder scan：** 無 TBD；字典與各步驟均含實際內容。
- **Type consistency：** `Dict` slice 命名於 T1 定義、T2/T3 一致引用；`Navbar/Footer` 簽章 `{ d: Dict; homeHref: string }` 於 T3 定義並於 T3 S7、S10 一致使用；`getDictionary`/`isLocale`/`locales` 命名一致。
