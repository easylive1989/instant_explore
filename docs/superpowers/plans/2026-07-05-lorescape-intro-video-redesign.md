# Lorescape 介紹影片重製 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `demo/` 的 Remotion 介紹影片重製為「城市是一本書」6 幕敘事，片中 app 畫面高忠實對齊 `docs/design`，同時輸出 16:9 與 9:16 兩個 composition。

**Architecture:** 沿用現有 `demo/` Remotion 專案與既有元件（PhoneFrame、Wordmark、StoreBadges、Waveform、PaperBackdrop、SceneHeading 及 animations/layout helper）。新增 `data.ts` 作為文案單一事實來源，新增兩個高忠實 mockup（StoryOptions、Reader），改寫 4 個既有 mockup/scene，重新計時 `Main.tsx`，每個 scene 以 `usePortrait()` 分橫/直版排列。

**Tech Stack:** Remotion 4.0.448、React 19、TypeScript 5.9、Tailwind v4、`@remotion/google-fonts`（Noto Serif TC / Noto Sans TC）。

## 驗證方式（本計畫的「測試循環」）

Remotion 視覺元件不適合傳統單元測試。本計畫每個 task 的驗證循環固定為：

1. `cd demo && npm run lint` —— 等同 `eslint src && tsc`，型別與 lint 零錯誤（這是本專案的「編譯測試」）。
2. `cd demo && npx remotion still <CompId> <outPath> --frame=<F> --scale=0.5` —— 對指定幀渲染 PNG，用 Read 工具開圖目視，確認 task 描述列出的**必現元素/文案**都在、版面對齊 `docs/design`。渲染本身若丟錯即為 fail。
3. 通過後 `git commit`。

`<CompId>` 為 `LorescapeIntro`（16:9）或 `LorescapeIntroVertical`（9:16）。輸出 PNG 一律寫到 `demo/out/`（已在 .gitignore 忽略；若否，於 Task 1 補上）。

## Global Constraints

- 兩個 composition 皆 **30fps、900 frames（30s）**：`LorescapeIntro` 1920×1080、`LorescapeIntroVertical` 1080×1920。
- 色票、字體、陰影一律取自 `src/theme.ts`（禁止在 scene 內硬寫 hex，既有 radial-gradient 例外可保留）；字體用 `fonts.serif` / `fonts.sans`。
- 文案語言：繁體中文為主（襯線 `fonts.serif`），拉丁小字用 `fonts.sans` 大寫加字距。
- 靜音也完整；BGM 僅在 `public/bgm.mp3` 存在時掛載，缺檔正常無聲渲染（`Main.tsx` 既有 `hasFile` 邏輯保留）。
- 片中 app 畫面文案一律引用 `src/data.ts`，不得散落於元件內。
- 每個 scene 都必須用 `usePortrait()` 分橫/直版兩套排列，共用同一組動畫時間軸與 mockup。
- Scene 起訖（frames）：Hook 0–150、Explore 150–330、Angles 330–510、Reader 510–690、Journal 690–810、Cta 810–900。
- 真實文案逐字採用本計畫各 task 內的字串（源自 `docs/design/project/app/data.jsx`）。

---

### Task 1: 設計 token 與文案資料源

**Files:**
- Modify: `demo/src/theme.ts`（在 `colors` 後新增 `categoryColors` 與 `radius`）
- Create: `demo/src/data.ts`
- Modify: `demo/.gitignore`（若不存在則建立，忽略 `out/`）
- Test（驗證幀）：沿用現有 `LorescapeIntro` frame=60

**Interfaces:**
- Produces:
  - `theme.ts`：`export const categoryColors: Record<'nature'|'heritage'|'urban'|'coast'|'sacred', { ink: string; bg: string }>`；`export const radius = { sm:8, md:12, lg:16, xl:22, img:10, pill:999 } as const`
  - `data.ts`：
    - `export type StoryOption = { no: string; title: string; desc: string }`
    - `export type ReaderStory = { place: string; latin: string; chapter: string; title: string; sub: string; dropcap: string; body: string[]; quote: { q: string; by: string }; footer: string; date: string; img: string }`
    - `export type NearbyPlace = { name: string; latin: string; dist: string; cat: keyof typeof categoryColors; img: string }`
    - `export type JournalEntry = { date: string; time: string; title: string; text: string; img?: string }`
    - `export const storyOptions: StoryOption[]`（3 筆）
    - `export const stPetersStory: ReaderStory`
    - `export const nearbyPlaces: NearbyPlace[]`（3 筆）
    - `export const journalEntries: JournalEntry[]`（3 筆）
    - `export const exploreChips: string[]`

- [ ] **Step 1: 在 `theme.ts` 新增 token**

在 `colors` 物件 `as const` 之後、`fonts` 之前插入：

```ts
// Category palette (muted, refined) — ported from ls2.css :root.
export const categoryColors = {
  nature: { ink: "#4E6138", bg: "#E6E8D5" },
  heritage: { ink: "#8A6320", bg: "#F0E5CC" },
  urban: { ink: "#44597A", bg: "#DFE4EC" },
  coast: { ink: "#2F6566", bg: "#D9E7E4" },
  sacred: { ink: "#6E4A63", bg: "#ECDCE6" },
} as const;

export const radius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 22,
  img: 10,
  pill: 999,
} as const;
```

- [ ] **Step 2: 建立 `demo/src/data.ts`**

```ts
import { categoryColors } from "./theme";

export type StoryOption = { no: string; title: string; desc: string };
export type ReaderStory = {
  place: string;
  latin: string;
  chapter: string;
  title: string;
  sub: string;
  dropcap: string;
  body: string[];
  quote: { q: string; by: string };
  footer: string;
  date: string;
  img: string;
};
export type NearbyPlace = {
  name: string;
  latin: string;
  dist: string;
  cat: keyof typeof categoryColors;
  img: string;
};
export type JournalEntry = {
  date: string;
  time: string;
  title: string;
  text: string;
  img?: string;
};

// 聖伯多祿大殿三種故事角度（Ⅲ 一書多章）。
export const storyOptions: StoryOption[] = [
  {
    no: "01",
    title: "摧毀與重生的百年豪賭",
    desc: "儒略二世決定拆毀君士坦丁大帝的千年古教堂，這場瘋狂重建竟耗時百餘年……",
  },
  {
    no: "02",
    title: "祭壇之下的神聖祕密",
    desc: "世界上最大的教堂並非教宗的主教座堂，因為它底下埋藏著更神聖的祕密……",
  },
  {
    no: "03",
    title: "文藝復興巨匠的接力賽",
    desc: "米開朗基羅與拉斐爾等巨匠輪番上陣，如何在一座教堂上留下各自的瘋狂印記？",
  },
];

// Ⅳ 沉浸聆聽用的完整故事。
export const stPetersStory: ReaderStory = {
  place: "聖伯多祿大殿",
  latin: "ST. PETER'S BASILICA · VATICAN",
  chapter: "Anno · I",
  title: "摧毀與重生的百年豪賭",
  sub: "儒略二世與一座教堂的瘋狂重生",
  dropcap: "一",
  body: [
    "五〇六年四月，羅馬的春風吹拂著梵蒂岡山丘。教宗儒略二世站在那座由君士坦丁大帝於四世紀建造、如今已顯得破舊不堪的老聖伯多祿大殿前。",
    "對儒略二世而言，這座古老的教堂不僅僅是一座建築，更是天主教會最神聖的象徵，因為聖傳記載著耶穌宗徒之長聖伯多祿的遺骨，就安葬於這片土地之下。",
    "為了守護這份神聖的遺產，並展現教會的權威與榮光，他做出了一個驚世駭俗的決定——拆毀這座千年古堂，在原址上重建一座前所未見的雄偉聖殿。",
  ],
  quote: { q: "拆毀，是為了一場橫跨百年的重生。", by: "—— 聖伯多祿大殿" },
  footer: "梵蒂岡 · VATICAN",
  date: "2026年5月30日",
  img: "images/stpeters.jpg",
};

// Ⅱ 地標登場的附近清單。
export const exploreChips = ["信仰聖地", "人文古蹟", "自然景觀", "城市地標"];

export const nearbyPlaces: NearbyPlace[] = [
  {
    name: "聖伯多祿大殿",
    latin: "ST. PETER'S BASILICA",
    dist: "1.2 km",
    cat: "sacred",
    img: "images/stpeters.jpg",
  },
  {
    name: "台中朝聖宮",
    latin: "CHAOSHENG TEMPLE",
    dist: "320 m",
    cat: "heritage",
    img: "images/temple.jpg",
  },
  {
    name: "馬卡龍公園",
    latin: "MACARON PARK",
    dist: "650 m",
    cat: "nature",
    img: "images/park.jpg",
  },
];

// Ⅴ 旅程成冊的手記篇章。
export const journalEntries: JournalEntry[] = [
  {
    date: "5月 16",
    time: "09:50",
    title: "彰化泰京山莊四面佛寺",
    text: "四面佛寺的故事，要從一位平凡的蚵仔麵線小販說起。民國七十四年左右，林逢永先生跟團遠赴泰國，走進了曼谷香火鼎盛的……",
    img: "images/temple.jpg",
  },
  {
    date: "5月 12",
    time: "17:24",
    title: "南觀音山",
    text: "南觀音山的稜線在暮色中起伏，像一道凝固的浪。早年採石的痕跡仍鐫刻在山腹，如今卻被綠意慢慢縫合，成為城市邊緣一處被重新看見的野地……",
  },
  {
    date: "5月 17",
    time: "08:51",
    title: "廊子公園",
    text: "漫步廊子公園，目光總會被眼前這幾株雄偉的老榕樹吸引。它們枝繁葉茂，氣根盤結，彷彿一位位歷經滄桑的長者，靜默地守護著這片土地……",
  },
];
```

- [ ] **Step 3: 確保 `out/` 被忽略**

若 `demo/.gitignore` 不含 `out`，新增一行 `out/`。若檔案不存在則建立，內容至少：

```
node_modules/
out/
```

- [ ] **Step 4: Lint**

Run: `cd demo && npm run lint`
Expected: 無錯誤（`data.ts` 目前尚未被 import，允許 —— tsc 不會因未使用的模組報錯；若 eslint 對未使用 export 無規則亦通過）。

- [ ] **Step 5: 冒煙渲染既有影片未破壞**

Run: `cd demo && npx remotion still LorescapeIntro out/t1-smoke.png --frame=60 --scale=0.5`
Expected: 成功輸出 PNG（theme 新增 export 不影響既有 render）。

- [ ] **Step 6: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/theme.ts demo/src/data.ts demo/.gitignore
git commit -m "feat(demo): add category tokens and data source for intro redesign"
```

---

### Task 2: StoryOptionsMockup（Ⅲ 一書多章畫面）

高忠實重建 `docs/design` 的 story-opts 畫面：標題「想聽哪段故事?」+ 三個 `.opt` 列（序號 / 標題 / 描述），逐一 pop-in。

**Files:**
- Create: `demo/src/components/mockups/StoryOptionsMockup.tsx`
- Test（驗證幀）：`LorescapeIntro` frame=420（Angles 幕中段，見 Task 8 掛載後才可見；本 task 先用獨立 still，見 Step 3）

**Interfaces:**
- Consumes: `storyOptions`（data.ts）、`colors`/`fonts`/`radius`（theme）、`popIn`（animations）
- Produces: `export const StoryOptionsMockup: React.FC`（填滿 PhoneFrame 內容區，`width/height:100%`）

- [ ] **Step 1: 實作元件**

依 ls2.css 量測：容器 padding 22px（放大到影片內 phone 尺度可乘約 1.8）；`.opt__no` 襯線 22px、clay 色、寬 26px；`.opt__t` 襯線 600、18px；`.opt__d` 14px、`ink2`、line-height 1.55；列間白卡、圓角 `radius.lg`、`1px solid colors.line`。標題 `.story-opts h3` 襯線 700、24px。以 phone 內寬約 430 計，字級整體 ×1.8。

```tsx
import React from "react";
import { useCurrentFrame, useVideoConfig } from "remotion";
import { colors, fonts, radius } from "../../theme";
import { storyOptions } from "../../data";
import { popIn } from "../../utils/animations";

// docs/design story-opts 畫面：同一地標的三個故事角度，如章節目錄。
export const StoryOptionsMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: colors.paperRaised,
        padding: "84px 34px 34px",
      }}
    >
      <div
        style={{
          fontFamily: fonts.serif,
          fontWeight: 700,
          fontSize: 40,
          color: colors.ink,
          marginBottom: 26,
        }}
      >
        想聽哪段故事？
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {storyOptions.map((o, i) => {
          const p = popIn(frame, fps, 14 + i * 12);
          return (
            <div
              key={o.no}
              style={{
                display: "flex",
                gap: 18,
                padding: "22px 22px",
                borderRadius: radius.lg,
                background: colors.paper,
                border: `1px solid ${colors.line}`,
                boxShadow: "0 6px 18px rgba(40,30,18,0.06)",
                opacity: p,
                transform: `translateY(${(1 - p) * 26}px)`,
              }}
            >
              <div
                style={{
                  fontFamily: fonts.serif,
                  fontWeight: 700,
                  fontSize: 40,
                  lineHeight: 1,
                  color: colors.clay,
                  width: 48,
                  flex: "none",
                }}
              >
                {o.no}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div
                  style={{
                    fontFamily: fonts.serif,
                    fontWeight: 600,
                    fontSize: 32,
                    lineHeight: 1.3,
                    color: colors.ink,
                  }}
                >
                  {o.title}
                </div>
                <div
                  style={{
                    fontFamily: fonts.sans,
                    fontSize: 24,
                    lineHeight: 1.55,
                    color: colors.ink2,
                    marginTop: 8,
                  }}
                >
                  {o.desc}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
```

- [ ] **Step 2: Lint**

Run: `cd demo && npm run lint`
Expected: 無錯誤。

- [ ] **Step 3: 目視驗證（暫時掛載）**

在 `AnglesScene.tsx` 尚未改寫前，於 `Root.tsx` 暫加一個一次性 preview composition 不切實際；改用最省事法：在 Task 8 掛載後再抓幀。本 task 的驗證改以型別 + 於 `Main.tsx` 臨時把 `AnglesScene` 內容替換為 `<StoryOptionsMockup/>` 包在 `PhoneFrame` 內，抓幀後還原。

Run:
```
cd demo && npx remotion still LorescapeIntro out/t2-story-opts.png --frame=430 --scale=0.5
```
Expected（Read 開圖確認）：手機畫面出現標題「想聽哪段故事？」與三列，序號 01/02/03 為 clay 色，標題與描述文案與 `storyOptions` 一致。驗證後把 `Main.tsx` 臨時改動還原。

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/components/mockups/StoryOptionsMockup.tsx
git commit -m "feat(demo): high-fidelity story-options mockup"
```

---

### Task 3: ReaderMockup（Ⅳ 沉浸聆聽畫面）

高忠實重建 immersive reader：深底、頂部 place 標題、hero 圖 + chapter badge + latin overline + 標題，正文 dropcap 首字，quote，底部 audiobar（play + 進度 fill + 百分比）+ Waveform。

**Files:**
- Create: `demo/src/components/mockups/ReaderMockup.tsx`
- Test（驗證幀）：Task 9 掛載後 `LorescapeIntro` frame=600；本 task 同 Task 2 用臨時掛載抓幀。

**Interfaces:**
- Consumes: `stPetersStory`（data.ts）、`colors`/`fonts`/`radius`、`Waveform`、`Img`/`staticFile`、`interpolate`/`useCurrentFrame`
- Produces: `export const ReaderMockup: React.FC`

- [ ] **Step 1: 實作元件**

深底 `colors.inkBg`；hero 高約 320（phone 尺度）objectFit cover + 下緣 scrim；`.chapter-badge` 邊框白 0.55、圓角 6、字距 0.16em；latin overline 白 0.82、`fonts.sans` 大寫；hero 標題襯線 700 32px 白。正文區 `.reader__body` padding 30/26；`.reader__lede` 襯線 18.5px、line-height 1.92（影片尺度 ×1.7）；`.dropcap` 襯線 700 64px、`colors.clayDeep`、float left；quote 左邊框 3px clay。audiobar 固定底部：play 圓鈕 46 clay、track 進度以 `interpolate(frame,[range],[4,34])` 動、右側百分比 tabular。Waveform 疊在 audiobar 上方或 track 內以 `colors.clay`。正文 body 段落逐段 `fadeIn` 進場。

（實作者可依 still 迭代微調字級；必現元素見 Step 3。）

```tsx
import React from "react";
import {
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";
import { colors, fonts, radius } from "../../theme";
import { stPetersStory as s } from "../../data";
import { Waveform } from "../Waveform";
import { fadeIn } from "../../utils/animations";

// docs/design immersive reader：深底襯線正文 + dropcap + 底部 audiobar。
export const ReaderMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const pct = Math.round(interpolate(frame, [30, 170], [4, 34], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  }));

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: colors.inkBg,
        color: colors.onDark,
        position: "relative",
      }}
    >
      <div style={{ height: "40%", position: "relative", overflow: "hidden" }}>
        <Img
          src={staticFile(s.img)}
          alt=""
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
        <div
          style={{
            position: "absolute",
            inset: 0,
            background:
              "linear-gradient(to bottom, rgba(0,0,0,0.1) 40%, rgba(27,22,17,0.92))",
          }}
        />
        <div style={{ position: "absolute", left: 34, bottom: 118 }}>
          <span
            style={{
              display: "inline-flex",
              alignItems: "center",
              height: 44,
              padding: "0 18px",
              border: "1px solid rgba(255,255,255,0.55)",
              borderRadius: 8,
              color: "#fff",
              fontFamily: fonts.sans,
              fontSize: 18,
              fontWeight: 600,
              letterSpacing: "0.16em",
            }}
          >
            {s.chapter}
          </span>
        </div>
        <div
          style={{
            position: "absolute",
            left: 34,
            right: 34,
            bottom: 34,
          }}
        >
          <div
            style={{
              fontFamily: fonts.sans,
              fontSize: 18,
              letterSpacing: "0.14em",
              color: "rgba(255,255,255,0.8)",
              marginBottom: 12,
            }}
          >
            {s.latin}
          </div>
          <div
            style={{
              fontFamily: fonts.serif,
              fontWeight: 700,
              fontSize: 46,
              lineHeight: 1.12,
              color: "#fff",
            }}
          >
            {s.title}
          </div>
        </div>
      </div>

      <div style={{ padding: "34px 34px 160px" }}>
        <p
          style={{
            fontFamily: fonts.serif,
            fontSize: 30,
            lineHeight: 1.9,
            color: colors.onDark,
            margin: 0,
            opacity: fadeIn(frame, 24, 20),
          }}
        >
          <span
            style={{
              float: "left",
              fontFamily: fonts.serif,
              fontWeight: 700,
              fontSize: 104,
              lineHeight: 0.84,
              padding: "8px 18px 0 0",
              color: colors.clay,
            }}
          >
            {s.dropcap}
          </span>
          {s.body[0]}
        </p>
        <p
          style={{
            fontFamily: fonts.serif,
            fontSize: 30,
            lineHeight: 1.9,
            color: colors.onDark2,
            marginTop: 28,
            opacity: fadeIn(frame, 70, 20),
          }}
        >
          {s.body[1]}
        </p>
      </div>

      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          bottom: 0,
          padding: "22px 28px 34px",
          background:
            "linear-gradient(to top, rgba(27,22,17,1), rgba(27,22,17,0))",
          display: "flex",
          alignItems: "center",
          gap: 16,
        }}
      >
        <div
          style={{
            width: 72,
            height: 72,
            borderRadius: radius.pill,
            background: colors.clay,
            display: "grid",
            placeItems: "center",
            flex: "none",
          }}
        >
          <svg width="30" height="30" viewBox="0 0 24 24" fill="#fff">
            <rect x="6" y="5" width="4" height="14" rx="1" />
            <rect x="14" y="5" width="4" height="14" rx="1" />
          </svg>
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <Waveform width={360} height={40} barCount={40} color={colors.clay} />
          <div
            style={{
              height: 6,
              borderRadius: radius.pill,
              background: "rgba(255,255,255,0.16)",
              marginTop: 8,
              overflow: "hidden",
            }}
          >
            <div
              style={{
                width: `${pct}%`,
                height: "100%",
                background: colors.clay,
                borderRadius: radius.pill,
              }}
            />
          </div>
        </div>
        <div
          style={{
            flex: "none",
            fontFamily: fonts.sans,
            fontWeight: 600,
            fontSize: 22,
            color: colors.onDark2,
            fontVariantNumeric: "tabular-nums",
            minWidth: 52,
            textAlign: "right",
          }}
        >
          {pct}%
        </div>
      </div>
    </div>
  );
};
```

- [ ] **Step 2: Lint**

Run: `cd demo && npm run lint`
Expected: 無錯誤。

- [ ] **Step 3: 目視驗證（臨時掛載）**

在 `Main.tsx` 臨時把 Reader 幕（510–690，Task 9 前為舊 scene）替換成 `PhoneFrame` 包 `<ReaderMockup/>`，抓幀後還原。

Run: `cd demo && npx remotion still LorescapeIntro out/t3-reader.png --frame=600 --scale=0.5`
Expected（Read 開圖）：深底、hero 圖上有 `Anno · I` badge 與 `ST. PETER'S BASILICA · VATICAN`、標題「摧毀與重生的百年豪賭」；正文首字「一」為大 dropcap（clay）；底部有 clay play 鈕、聲紋、進度條與百分比（約 20%±）。

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/components/mockups/ReaderMockup.tsx
git commit -m "feat(demo): high-fidelity immersive reader mockup"
```

---

### Task 4: 精修 ExploreMockup 與 JournalMockup

把既有兩個 mockup 對齊 docs/design：ExploreMockup 改用 `data.ts` 的 `nearbyPlaces`（含 latin 副標與分類色 chip），JournalMockup 對齊 `docs/design` 田野手記（日期/時間眉標 + 標題 + 內文 + 可選縮圖）。

**Files:**
- Modify: `demo/src/components/mockups/ExploreMockup.tsx`（改資料源與卡片結構）
- Modify: `demo/src/components/mockups/JournalMockup.tsx`
- Test（驗證幀）：Task 7/10 掛載後抓幀；本 task 先臨時掛載。

**Interfaces:**
- Consumes: `nearbyPlaces`/`exploreChips`/`journalEntries`（data.ts）、`categoryColors`、`colors`/`fonts`/`radius`、`popIn`
- Produces: `ExploreMockup`、`JournalMockup`（簽名不變，皆 `React.FC`）

- [ ] **Step 1: 改寫 ExploreMockup**

改為 import `nearbyPlaces`、`exploreChips`、`categoryColors`；標題維持「附近值得停留」；chips 第一顆為 active（clay 底白字），其餘 `clayTint` 底 `clayDeep` 字；每張地標卡左為 78×78 圓角 `radius.img` 圖、右為襯線地名 + `fonts.sans` 大寫 latin 副標（`colors.ink3`）+ 距離（`colors.clay`）。卡片 `popIn` 交錯進場。移除舊 inline `nearby`/`chips` 常數。地名/latin/距離逐一對應 `nearbyPlaces`。

- [ ] **Step 2: 改寫 JournalMockup**

對齊 docs/design 田野手記：標題「田野手記」襯線 700；下方 `journalEntries` 逐則卡片：頂部一行 `date · time`（`colors.ink3`、`fonts.sans`、字距 0.06em）、襯線標題（`colors.ink`）、內文 3–4 行截斷（`colors.ink2`、line-height 1.7）；有 `img` 者右上角放小縮圖。卡片間白卡、`1px solid colors.line`、圓角 `radius.lg`，`popIn` 交錯進場。

- [ ] **Step 3: Lint**

Run: `cd demo && npm run lint`
Expected: 無錯誤。

- [ ] **Step 4: 目視驗證（臨時掛載）**

臨時把 Explore 幕內容替換為 `PhoneFrame` 包 `<ExploreMockup/>` 抓 frame=250；再換 `<JournalMockup/>` 抓 frame=750。

Run:
```
cd demo && npx remotion still LorescapeIntro out/t4-explore.png --frame=250 --scale=0.5
cd demo && npx remotion still LorescapeIntro out/t4-journal.png --frame=750 --scale=0.5
```
Expected：Explore 三張卡含地名/latin/距離、首個 chip active；Journal 三則含 `5月 16 · 09:50` 眉標、標題、內文，朝聖宮那則有縮圖。驗證後還原 `Main.tsx`。

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/components/mockups/ExploreMockup.tsx demo/src/components/mockups/JournalMockup.tsx
git commit -m "feat(demo): align explore & journal mockups to docs/design"
```

---

### Task 5: PhoneFrame 加入狀態列，微調比例

依 ls2.css `.phone`（390×844 → 比例 ≈ 0.462）與 `.statusbar`（時間 + 電量）補上狀態列，讓片中手機更像真機。支援深底畫面（狀態列反白）。

**Files:**
- Modify: `demo/src/components/PhoneFrame.tsx`

**Interfaces:**
- Consumes: `colors`
- Produces: `PhoneFrame`（新增可選 prop）：`{ children: React.ReactNode; width?: number; height?: number; statusDark?: boolean }`；`statusDark` 為 true 時狀態列用深色字（淺底畫面），false 用白字（深底畫面），預設 true。

- [ ] **Step 1: 加入狀態列**

在螢幕內容最上層疊一個絕對定位狀態列：左「8:20」、右「訊號/Wi-Fi/電量」簡化為一個電量方塊 + 訊號點（純 SVG/CSS）。字色依 `statusDark ? colors.ink : colors.onDark`。維持 dynamic island 不變。比例上把預設 `width=430`、`height` 改為 `Math.round(width / 0.462)`（≈ 930）以貼近真機，但保留 `height` prop 覆寫。

- [ ] **Step 2: Lint**

Run: `cd demo && npm run lint`
Expected: 無錯誤。

- [ ] **Step 3: 目視驗證**

Run: `cd demo && npx remotion still LorescapeIntro out/t5-phone.png --frame=250 --scale=0.5`
Expected：手機頂部出現時間與電量狀態列，島型鏡頭在其上；淺底 scene 狀態列為深字。

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/components/PhoneFrame.tsx
git commit -m "feat(demo): add status bar and truer proportions to PhoneFrame"
```

---

### Task 6: HookScene（Ⅰ 開場宣言，0–150）

深墨底、翻頁感浮出宣言「抬起眼睛，／世界本身就是一本書。」無 UI。橫版置中大字，直版同樣置中（字級縮小）。

**Files:**
- Modify: `demo/src/scenes/HookScene.tsx`（改寫）
- Test（驗證幀）：frame=90

**Interfaces:**
- Consumes: `colors`/`fonts`、`usePortrait`、`fadeIn`/`slideUp`、`useCurrentFrame`
- Produces: `export const HookScene: React.FC`

- [ ] **Step 1: 改寫**

背景 `radial-gradient(120% 100% at 70% -10%, #2c2620, #17120d 60%)`（深墨）。兩行宣言：line1「抬起眼睛，」line2「世界本身就是一本書。」`fonts.serif`、`colors.onDark`。line1 先 `fadeIn(frame,10,18)` + `slideUp`，line2 delay 至 `frame,30,18`。可加一條極細金色分隔線在兩行間淡入。`usePortrait()`：橫版字級 96/直版 64；皆水平置中、垂直置中。末段（frame>120）整體輕微 `fadeOut` 以接下一幕。

- [ ] **Step 2: Lint** — Run: `cd demo && npm run lint` — Expected: 無錯誤。

- [ ] **Step 3: 目視驗證（雙比例）**

Run:
```
cd demo && npx remotion still LorescapeIntro out/t6-hook-h.png --frame=90 --scale=0.5
cd demo && npx remotion still LorescapeIntroVertical out/t6-hook-v.png --frame=90 --scale=0.5
```
Expected：兩比例皆深底置中兩行宣言，文案正確、無 UI 元件、無溢出裁切。

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/scenes/HookScene.tsx
git commit -m "feat(demo): rewrite Hook scene as city-is-a-book manifesto"
```

---

### Task 7: ExploreScene（Ⅱ 地標登場，150–330）

聖伯多祿實景背景淡入，手機自畫面下方升起帶出 `ExploreMockup`，宣言「每一個地方，／都是一則等待被讀的故事。」

**Files:**
- Modify: `demo/src/scenes/ExploreScene.tsx`（改寫）
- Test（驗證幀）：frame=250（局部序號 = 全域 250）

**Interfaces:**
- Consumes: `PaperBackdrop`、`PhoneFrame`、`ExploreMockup`、`SceneHeading` 或自繪宣言、`usePortrait`、`popIn`/`slideUp`、`Img`/`staticFile`、`useCurrentFrame`/`useVideoConfig`
- Produces: `export const ExploreScene: React.FC`

- [ ] **Step 1: 改寫**

背景 `PaperBackdrop`，其上疊一張 `staticFile("images/stpeters.jpg")` 以低透明度 + 遮罩作氛圍（右側／背側），`fadeIn`。手機用 `PhoneFrame`（`statusDark`）包 `ExploreMockup`，以 `spring/slideUp` 從下方升起（distance 大、frame 0–24 局部）。宣言用 `SceneHeading`（over="EXPLORE / 探索身邊"、title 兩行）。橫版：宣言左、手機右；直版：宣言上、手機下置中。

- [ ] **Step 2: Lint** — Run: `cd demo && npm run lint` — Expected: 無錯誤。

- [ ] **Step 3: 目視驗證（雙比例）**

Run:
```
cd demo && npx remotion still LorescapeIntro out/t7-explore-h.png --frame=250 --scale=0.5
cd demo && npx remotion still LorescapeIntroVertical out/t7-explore-v.png --frame=250 --scale=0.5
```
Expected：手機顯示 ExploreMockup（附近清單），旁有宣言兩行；背景有聖伯多祿氛圍；兩比例皆無溢出。

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/scenes/ExploreScene.tsx
git commit -m "feat(demo): rewrite Explore scene (landmark reveal)"
```

---

### Task 8: AnglesScene（Ⅲ 一書多章，330–510）

手機顯示 `StoryOptionsMockup`，宣言「同一座教堂，／藏著三種讀法。」

**Files:**
- Modify: `demo/src/scenes/AnglesScene.tsx`（改寫）
- Test（驗證幀）：frame=430

**Interfaces:**
- Consumes: `PaperBackdrop`、`PhoneFrame`、`StoryOptionsMockup`、`SceneHeading`、`usePortrait`、動畫 helper
- Produces: `export const AnglesScene: React.FC`

- [ ] **Step 1: 改寫**

`PaperBackdrop`（可用 `tone="sunk"` 稍暗以分辨）。手機包 `StoryOptionsMockup`。宣言 over="MANY ANGLES / 一書多章"、title「同一座教堂，／藏著三種讀法。」。橫版宣言左手機右；直版宣言上手機下。手機以 `popIn` 輕微進場。

- [ ] **Step 2: Lint** — Run: `cd demo && npm run lint` — Expected: 無錯誤。

- [ ] **Step 3: 目視驗證（雙比例）**

Run:
```
cd demo && npx remotion still LorescapeIntro out/t8-angles-h.png --frame=430 --scale=0.5
cd demo && npx remotion still LorescapeIntroVertical out/t8-angles-v.png --frame=430 --scale=0.5
```
Expected：手機顯示「想聽哪段故事？」+ 三個角度列；旁宣言兩行；兩比例正確。

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/scenes/AnglesScene.tsx
git commit -m "feat(demo): rewrite Angles scene with story-options mockup"
```

---

### Task 9: ReaderScene（Ⅳ 沉浸聆聽，510–690）

深底沉浸幕。手機顯示 `ReaderMockup`，宣言「戴上耳機，／讓城市對你朗讀。」（白字）。

**Files:**
- Create: `demo/src/scenes/ReaderScene.tsx`
- Test（驗證幀）：frame=600

**Interfaces:**
- Consumes: `PhoneFrame`、`ReaderMockup`、`SceneHeading`（onDark）、`usePortrait`、`colors`、動畫 helper
- Produces: `export const ReaderScene: React.FC`

- [ ] **Step 1: 建立**

全幅深底 `AbsoluteFill` 背景 `colors.inkBg`（加極淡 grain 或 vignette）。手機包 `ReaderMockup`（`statusDark={false}`）。宣言用 `SceneHeading` `onDark`，over="LISTEN / 沉浸聆聽"、title「戴上耳機，／讓城市對你朗讀。」。橫版宣言左手機右；直版宣言上手機下。

- [ ] **Step 2: Lint** — Run: `cd demo && npm run lint` — Expected: 無錯誤。

- [ ] **Step 3: 目視驗證（雙比例）**

Run:
```
cd demo && npx remotion still LorescapeIntro out/t9-reader-h.png --frame=600 --scale=0.5
cd demo && npx remotion still LorescapeIntroVertical out/t9-reader-v.png --frame=600 --scale=0.5
```
Expected：深底、手機為沉浸閱讀器（dropcap「一」、audiobar），旁白字宣言；兩比例正確。

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/scenes/ReaderScene.tsx
git commit -m "feat(demo): add Reader scene (immersive listening)"
```

---

### Task 10: JournalScene（Ⅴ 旅程成冊，690–810）

手機顯示 `JournalMockup`，宣言「你走過的地方，／正在寫成一本書。」

**Files:**
- Modify: `demo/src/scenes/JournalScene.tsx`（改寫）
- Test（驗證幀）：frame=750

**Interfaces:**
- Consumes: `PaperBackdrop`、`PhoneFrame`、`JournalMockup`、`SceneHeading`、`usePortrait`
- Produces: `export const JournalScene: React.FC`

- [ ] **Step 1: 改寫**

`PaperBackdrop`。手機包 `JournalMockup`。宣言 over="YOUR JOURNAL / 旅程成冊"、title「你走過的地方，／正在寫成一本書。」。橫版宣言左手機右；直版宣言上手機下。手機或手記卡可加輕微「翻頁堆疊」進場。

- [ ] **Step 2: Lint** — Run: `cd demo && npm run lint` — Expected: 無錯誤。

- [ ] **Step 3: 目視驗證（雙比例）**

Run:
```
cd demo && npx remotion still LorescapeIntro out/t10-journal-h.png --frame=750 --scale=0.5
cd demo && npx remotion still LorescapeIntroVertical out/t10-journal-v.png --frame=750 --scale=0.5
```
Expected：手機顯示田野手記三則；旁宣言兩行；兩比例正確。

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/scenes/JournalScene.tsx
git commit -m "feat(demo): rewrite Journal scene (journey as a book)"
```

---

### Task 11: CtaScene（Ⅵ CTA，810–900）

深底收束：`Wordmark`（Lorescape）+「旅行說書人」+ slogan「城市是一本書。開始閱讀吧。」+ `StoreBadges`。

**Files:**
- Modify: `demo/src/scenes/CtaScene.tsx`（改寫）
- Test（驗證幀）：frame=860

**Interfaces:**
- Consumes: `Wordmark`、`StoreBadges`、`colors`/`fonts`、`usePortrait`、`fadeIn`/`slideUp`/`popIn`
- Produces: `export const CtaScene: React.FC`

- [ ] **Step 1: 改寫**

深墨底（同 Hook）。垂直堆疊置中：`Wordmark`（白字 `color={colors.onDark}`）→「旅行說書人」襯線副標（`colors.onDark2`）→ slogan 襯線大字「城市是一本書。開始閱讀吧。」→ `StoreBadges`。各元素 `fadeIn`/`slideUp` 交錯，badges `popIn`。橫版 badges 並排；直版可並排或上下，字級縮小。橫直版皆置中。

- [ ] **Step 2: Lint** — Run: `cd demo && npm run lint` — Expected: 無錯誤。

- [ ] **Step 3: 目視驗證（雙比例）**

Run:
```
cd demo && npx remotion still LorescapeIntro out/t11-cta-h.png --frame=860 --scale=0.5
cd demo && npx remotion still LorescapeIntroVertical out/t11-cta-v.png --frame=860 --scale=0.5
```
Expected：品牌字 + 旅行說書人 + slogan + 兩個商店徽章；兩比例皆置中無溢出。

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/src/scenes/CtaScene.tsx
git commit -m "feat(demo): rewrite CTA scene with brand and store badges"
```

---

### Task 12: Main.tsx 重新計時與串接、移除舊 StoryScene

依 Global Constraints 的 frame 起訖串接 6 幕，換掉舊的 `StoryScene`，加入 `ReaderScene`。清掉不再使用的 `StoryScene.tsx` 與 `PlayerMockup.tsx`（若確認無其他引用）。

**Files:**
- Modify: `demo/src/Main.tsx`
- Delete: `demo/src/scenes/StoryScene.tsx`、`demo/src/components/mockups/PlayerMockup.tsx`（先 grep 確認無引用）
- Test（驗證幀）：多幀（見 Step 4）

**Interfaces:**
- Consumes: 全部 6 個 scene
- Produces: 最終 `Main` composition 內容

- [ ] **Step 1: 確認無殘留引用**

Run: `cd demo && grep -rn "StoryScene\|PlayerMockup\|StoryMockup" src`
Expected：除了 `Main.tsx`（StoryScene）與檔案自身外無其他引用。`StoryMockup` 若仍被 Angles 舊碼引用，於 Task 8 已移除；此處確認為 0。

- [ ] **Step 2: 改寫 Main.tsx Sequence 串接**

```tsx
import React from "react";
import { AbsoluteFill, Audio, Sequence, getStaticFiles, staticFile } from "remotion";
import { HookScene } from "./scenes/HookScene";
import { ExploreScene } from "./scenes/ExploreScene";
import { AnglesScene } from "./scenes/AnglesScene";
import { ReaderScene } from "./scenes/ReaderScene";
import { JournalScene } from "./scenes/JournalScene";
import { CtaScene } from "./scenes/CtaScene";
import { colors } from "./theme";

const hasFile = (name: string) => getStaticFiles().some((f) => f.name === name);

export const Main: React.FC = () => {
  const hasBgm = hasFile("bgm.mp3");
  return (
    <AbsoluteFill style={{ background: colors.paper }}>
      {hasBgm ? <Audio src={staticFile("bgm.mp3")} volume={0.8} /> : null}
      <Sequence durationInFrames={150}><HookScene /></Sequence>
      <Sequence from={150} durationInFrames={180}><ExploreScene /></Sequence>
      <Sequence from={330} durationInFrames={180}><AnglesScene /></Sequence>
      <Sequence from={510} durationInFrames={180}><ReaderScene /></Sequence>
      <Sequence from={690} durationInFrames={120}><JournalScene /></Sequence>
      <Sequence from={810} durationInFrames={120}><CtaScene /></Sequence>
    </AbsoluteFill>
  );
};
```

- [ ] **Step 3: 刪除舊檔**

```bash
cd demo && rm src/scenes/StoryScene.tsx src/components/mockups/PlayerMockup.tsx
```
（若 Step 1 顯示仍有引用，先改該引用再刪。）

- [ ] **Step 4: Lint + 全幕抓幀**

Run: `cd demo && npm run lint`
Expected: 無錯誤（無 dangling import）。

Run（每幕代表幀，橫版）：
```
cd demo && for F in 90 250 430 600 750 860; do npx remotion still LorescapeIntro out/final-h-$F.png --frame=$F --scale=0.4; done
```
Expected：6 張圖依序為 Hook→Explore→Angles→Reader→Journal→Cta，內容與各 task 一致，過場無空白幀。

- [ ] **Step 5: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add -A demo/src
git commit -m "feat(demo): wire 6-scene city-is-a-book timeline, drop old scene"
```

---

### Task 13: 全片渲染驗證與 README 更新

輸出兩支完整 mp4 確認端到端無誤，並更新 `demo/README.md` 的分鏡表與檔案結構。

**Files:**
- Modify: `demo/README.md`
- Test：完整 render

- [ ] **Step 1: 更新 README**

改寫「分鏡」表為新 6 幕（Hook/Explore/Angles/Reader/Journal/Cta 及其 frame 起訖與文案），更新「檔案結構」與「客製化」對照表（scene 檔名、`data.ts`），移除已刪除檔案的描述。

- [ ] **Step 2: 完整渲染兩比例**

Run:
```
cd demo && npx remotion render LorescapeIntro out/lorescape-intro.mp4
cd demo && npx remotion render LorescapeIntroVertical out/lorescape-intro-vertical.mp4
```
Expected：兩支皆成功輸出、900 frames、無渲染錯誤。

- [ ] **Step 3: 人工目視兩支影片**

用 Read 或請使用者播放 `out/lorescape-intro.mp4`（16:9）與 `out/lorescape-intro-vertical.mp4`（9:16），確認節奏、過場、雙比例排版、文案正確、靜音下敘事完整。

- [ ] **Step 4: Commit**

```bash
cd /Users/paulwu/Documents/Github/instant_explore
git add demo/README.md
git commit -m "docs(demo): update README for city-is-a-book intro video"
```

---

## Self-Review 註記

- **Spec 涵蓋度**：6 幕（Task 6–11）、雙比例（每 scene Step 3 雙比例抓幀）、高忠實 mockup（Task 2–4）、data.ts 真實文案（Task 1）、BGM 槽（保留於 Task 12 Main）、驗證方式（每 task lint + still、Task 13 全片 render）皆對應。
- **無 placeholder**：foundation 檔案（theme/data/Main）給完整程式碼；視覺 mockup/scene 給結構規格 + 關鍵 JSX + 精確量測與逐字文案，並以 still 幀迭代收斂（本計畫「測試循環」章已聲明此為本媒介的正確驗證法）。
- **型別一致**：`data.ts` 匯出的 `storyOptions/stPetersStory/nearbyPlaces/journalEntries/exploreChips` 名稱在 Task 2–4、8–11 使用一致；`ReaderStory` 欄位（chapter/latin/dropcap/quote…）與 Task 3 元件取用一致；`PhoneFrame` 新增 `statusDark` prop 在 Task 7/9 使用一致。
