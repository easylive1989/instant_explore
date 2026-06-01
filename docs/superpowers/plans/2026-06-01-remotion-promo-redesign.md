# Remotion 宣傳影片重做 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `demo/` 的 30 秒 Remotion 介紹影片整支重做，對齊最新「地誌手記」品牌（紙感 + 陶土色 + 中文襯線），並以同一套分鏡輸出橫式 16:9 與直式 9:16 兩個版本。

**Architecture:** 共用 design tokens (`theme.ts`) 與橫直自適應 helper (`usePortrait`)；六個 scene 元件依 `usePortrait()` 切換水平/垂直版型；`Root.tsx` 註冊兩個共用 `Main` 的 composition（橫、直）。真實照片放 `public/images/`，手機 UI 為 code mockup。

**Tech Stack:** Remotion 4.0.448、React 19、TailwindCSS v4、`@remotion/google-fonts`（Noto Serif TC / Noto Sans TC）。

**測試策略（重要）：** Remotion 影片無傳統單元測試。每個 task 的「測試關卡」是 `npm run lint`（= `eslint src && tsc`，型別 + lint 全綠），視覺 task 另以 `npx remotion still` 抽幀產生 PNG 供肉眼驗收。所有指令在 `demo/` 目錄下執行。

---

## File Structure

```
demo/
├── public/images/            # 新增：複製自 landing 的真實照片
│   ├── stpeters.jpg
│   ├── temple.jpg
│   ├── park.jpg
│   └── agra.jpg
├── src/
│   ├── Root.tsx              # 改：註冊 2 個 composition
│   ├── Main.tsx              # 改：6 個 Sequence + Audio
│   ├── theme.ts              # 新增：色票 + 字體 + 陰影 tokens
│   ├── scenes/
│   │   ├── HookScene.tsx     # 重寫
│   │   ├── StoryScene.tsx    # 新增（功能01，取代 NarrationScene）
│   │   ├── AnglesScene.tsx   # 新增（功能02）
│   │   ├── ExploreScene.tsx  # 新增（功能03）
│   │   ├── JournalScene.tsx  # 新增（功能04，取代 PassportScene）
│   │   └── CtaScene.tsx      # 重寫
│   ├── components/
│   │   ├── PaperBackdrop.tsx # 新增
│   │   ├── PhoneFrame.tsx    # 改：淺色
│   │   ├── Wordmark.tsx      # 改：襯線 + 徽章
│   │   ├── BrandSeal.tsx     # 新增
│   │   ├── SceneHeading.tsx  # 新增
│   │   ├── Waveform.tsx      # 改：陶土色預設
│   │   ├── StoreBadges.tsx   # 改：配色微調（維持深底徽章）
│   │   └── mockups/
│   │       ├── StoryMockup.tsx    # 新增
│   │       ├── PlayerMockup.tsx   # 重寫
│   │       ├── ExploreMockup.tsx  # 新增
│   │       └── JournalMockup.tsx  # 新增
│   └── utils/
│       ├── animations.ts     # 不動（沿用）
│       └── layout.ts         # 新增：usePortrait()
└── README.md                 # 改：更新分鏡表與指令
```

**移除檔案**（Task 13）：`src/scenes/IntroScene.tsx`、`src/scenes/NarrationScene.tsx`、`src/scenes/PassportScene.tsx`、`src/components/StoneTexture.tsx`、`src/components/mockups/HomeMockup.tsx`、`src/components/mockups/PassportMockup.tsx`。

---

## Task 1: 專案基礎 — 依賴、照片、theme、layout helper

**Files:**
- Modify: `demo/package.json`（新增 `@remotion/google-fonts`）
- Create: `demo/public/images/{stpeters,temple,park,agra}.jpg`
- Create: `demo/src/theme.ts`
- Create: `demo/src/utils/layout.ts`

- [ ] **Step 1: 安裝字體依賴**

Run（在 `demo/`）：
```bash
npm install @remotion/google-fonts@4.0.448
```
Expected: `package.json` 出現 `"@remotion/google-fonts": "4.0.448"`，無 peer 衝突錯誤。

- [ ] **Step 2: 複製真實照片**

Run（在 `demo/`）：
```bash
mkdir -p public/images
cp ../landing/public/images/stpeters.jpg ../landing/public/images/temple.jpg ../landing/public/images/park.jpg ../landing/public/images/agra.jpg public/images/
ls public/images
```
Expected: 列出 `agra.jpg park.jpg stpeters.jpg temple.jpg`。

- [ ] **Step 3: 建立 `src/theme.ts`**

```tsx
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
```

- [ ] **Step 4: 建立 `src/utils/layout.ts`**

```tsx
import { useVideoConfig } from "remotion";

// True when the composition is taller than it is wide (9:16 vertical export).
// Scenes branch their layout on this instead of hard-coding a single aspect.
export const usePortrait = (): boolean => {
  const { width, height } = useVideoConfig();
  return height > width;
};
```

- [ ] **Step 5: 跑 lint**

Run（在 `demo/`）：`npm run lint`
Expected: PASS，無 TypeScript error（`theme.ts` 的 google-fonts import 能解析）。

- [ ] **Step 6: Commit**

```bash
git add demo/package.json demo/package-lock.json demo/public/images demo/src/theme.ts demo/src/utils/layout.ts
git commit -m "feat(demo): add brand tokens, fonts, photos and orientation helper"
```

---

## Task 2: PaperBackdrop 元件

**Files:**
- Create: `demo/src/components/PaperBackdrop.tsx`

- [ ] **Step 1: 建立 `PaperBackdrop.tsx`**

```tsx
import React from "react";
import { AbsoluteFill } from "remotion";
import { colors, paperGrain } from "../theme";

type Props = {
  children?: React.ReactNode;
  tone?: "paper" | "sunk";
};

// Warm paper background with a subtle repeating grain and a soft clay vignette.
// The shared backdrop for every light scene (Hook / Story / Explore / Journal).
export const PaperBackdrop: React.FC<Props> = ({
  children,
  tone = "paper",
}) => {
  const base = tone === "sunk" ? colors.paperSunk : colors.paper;
  return (
    <AbsoluteFill style={{ backgroundColor: base }}>
      <AbsoluteFill
        style={{
          backgroundImage: paperGrain,
          backgroundSize: "22px 22px",
        }}
      />
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(120% 80% at 50% 0%, rgba(188,94,62,0.06), transparent 60%)",
        }}
      />
      {children}
    </AbsoluteFill>
  );
};
```

- [ ] **Step 2: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 3: Commit**

```bash
git add demo/src/components/PaperBackdrop.tsx
git commit -m "feat(demo): add PaperBackdrop warm-paper background"
```

---

## Task 3: PhoneFrame 重做為淺色

**Files:**
- Modify: `demo/src/components/PhoneFrame.tsx`（整檔替換）

- [ ] **Step 1: 整檔替換 `PhoneFrame.tsx`**

```tsx
import React from "react";
import { colors } from "../theme";

type Props = {
  children: React.ReactNode;
  width?: number;
  height?: number;
};

// Light-theme iPhone mockup: warm bezel, white screen, dynamic island.
// Pure CSS/SVG — no external assets.
export const PhoneFrame: React.FC<Props> = ({
  children,
  width = 430,
  height = 900,
}) => {
  const radius = 62;
  const bezel = 14;

  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius,
        padding: bezel,
        background: `linear-gradient(160deg, #2c241c 0%, #15110c 55%, #2c241c 100%)`,
        boxShadow:
          "0 40px 110px rgba(28,20,10,0.45), 0 0 0 1px rgba(255,255,255,0.04)",
        position: "relative",
      }}
    >
      <div
        style={{
          width: "100%",
          height: "100%",
          borderRadius: radius - bezel,
          overflow: "hidden",
          position: "relative",
          background: colors.paperRaised,
        }}
      >
        {children}
        <div
          style={{
            position: "absolute",
            top: 14,
            left: "50%",
            transform: "translateX(-50%)",
            width: 110,
            height: 30,
            borderRadius: 999,
            background: "#000",
            zIndex: 10,
          }}
        />
      </div>
    </div>
  );
};
```

- [ ] **Step 2: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 3: Commit**

```bash
git add demo/src/components/PhoneFrame.tsx
git commit -m "feat(demo): restyle PhoneFrame for light paper theme"
```

---

## Task 4: BrandSeal + Wordmark 重做

**Files:**
- Create: `demo/src/components/BrandSeal.tsx`
- Modify: `demo/src/components/Wordmark.tsx`（整檔替換）

- [ ] **Step 1: 建立 `BrandSeal.tsx`**（移植自 landing/src/components/BrandSeal.tsx，可配色）

```tsx
import React from "react";
import { colors } from "../theme";

type Props = {
  size?: number;
  discColor?: string;
  markColor?: string;
};

// Circular "compass seal" brand mark inside a clay disc.
export const BrandSeal: React.FC<Props> = ({
  size = 64,
  discColor = colors.clay,
  markColor = colors.onDark,
}) => {
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        background: discColor,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        boxShadow: "0 8px 22px rgba(151,68,42,0.32)",
      }}
    >
      <svg
        width={size * 0.58}
        height={size * 0.58}
        viewBox="0 0 24 24"
        fill="none"
        stroke={markColor}
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <circle cx="12" cy="12" r="9" />
        <polygon
          points="15.5 8.5 10.5 10.5 8.5 15.5 13.5 13.5"
          fill={markColor}
          stroke="none"
        />
      </svg>
    </div>
  );
};
```

- [ ] **Step 2: 整檔替換 `Wordmark.tsx`**

```tsx
import React from "react";
import { colors, fonts } from "../theme";
import { BrandSeal } from "./BrandSeal";

type Props = {
  size?: number;
  opacity?: number;
  color?: string;
  withSeal?: boolean;
};

// Serif "Lorescape" wordmark, optionally paired with the compass seal.
export const Wordmark: React.FC<Props> = ({
  size = 72,
  opacity = 1,
  color = colors.ink,
  withSeal = true,
}) => {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: size * 0.28,
        opacity,
      }}
    >
      {withSeal ? <BrandSeal size={size * 0.92} /> : null}
      <div
        style={{
          fontFamily: fonts.serif,
          fontWeight: 700,
          fontSize: size,
          letterSpacing: size * 0.01,
          color,
          lineHeight: 1,
        }}
      >
        Lorescape
      </div>
    </div>
  );
};
```

- [ ] **Step 3: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 4: Commit**

```bash
git add demo/src/components/BrandSeal.tsx demo/src/components/Wordmark.tsx
git commit -m "feat(demo): add BrandSeal and serif Wordmark"
```

---

## Task 5: SceneHeading 元件

**Files:**
- Create: `demo/src/components/SceneHeading.tsx`

- [ ] **Step 1: 建立 `SceneHeading.tsx`**

```tsx
import React from "react";
import { useCurrentFrame } from "remotion";
import { colors, fonts } from "../theme";
import { fadeIn, slideUp } from "../utils/animations";

type Props = {
  over: string;
  title: React.ReactNode;
  startFrame?: number;
  align?: "left" | "center";
  onDark?: boolean;
};

// Over-line (uppercase clay kicker) + serif headline, with a staggered
// fade/slide-in. Shared by every feature scene.
export const SceneHeading: React.FC<Props> = ({
  over,
  title,
  startFrame = 0,
  align = "left",
  onDark = false,
}) => {
  const frame = useCurrentFrame();
  const titleColor = onDark ? colors.onDark : colors.ink;

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: align === "center" ? "center" : "flex-start",
        textAlign: align,
        gap: 16,
      }}
    >
      <span
        style={{
          fontFamily: fonts.sans,
          fontSize: 18,
          fontWeight: 700,
          letterSpacing: "0.22em",
          textTransform: "uppercase",
          color: colors.clay,
          opacity: fadeIn(frame, startFrame, 14),
          transform: `translateY(${slideUp(frame, startFrame, 18, 24)}px)`,
        }}
      >
        {over}
      </span>
      <h2
        style={{
          fontFamily: fonts.serif,
          fontWeight: 700,
          fontSize: 64,
          lineHeight: 1.18,
          color: titleColor,
          margin: 0,
          opacity: fadeIn(frame, startFrame + 6, 16),
          transform: `translateY(${slideUp(frame, startFrame + 6, 22, 40)}px)`,
        }}
      >
        {title}
      </h2>
    </div>
  );
};
```

- [ ] **Step 2: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 3: Commit**

```bash
git add demo/src/components/SceneHeading.tsx
git commit -m "feat(demo): add SceneHeading over-line + serif title"
```

---

## Task 6: Waveform 改色 + StoreBadges 維持

**Files:**
- Modify: `demo/src/components/Waveform.tsx:14`（預設 color 改陶土）

- [ ] **Step 1: 改 `Waveform.tsx` 預設色**

把第 14 行附近的：
```tsx
  color = "#137fec",
```
改為（import 也要加 theme）：
```tsx
  color = "#bc5e3e",
```
（保持其餘程式碼不變；`#bc5e3e` 即 `colors.clay`，此處用字面值避免額外 import。）

- [ ] **Step 2: 跑 lint**

Run：`npm run lint`
Expected: PASS。

> 註：`StoreBadges.tsx` 維持現有深底徽章設計（App Store / Google Play 官方徽章本就深底），在紙感 CTA 上對比良好，本次不改。

- [ ] **Step 3: Commit**

```bash
git add demo/src/components/Waveform.tsx
git commit -m "feat(demo): recolor Waveform to clay default"
```

---

## Task 7: HookScene 重寫（手記開場）

**Files:**
- Modify: `demo/src/scenes/HookScene.tsx`（整檔替換）

- [ ] **Step 1: 整檔替換 `HookScene.tsx`**

```tsx
import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { colors, fonts } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp } from "../utils/animations";

// Beat 1 (0–5s): manifesto opener on warm paper.
export const HookScene: React.FC = () => {
  const frame = useCurrentFrame();
  const portrait = usePortrait();
  const ruleWidth = fadeIn(frame, 6, 22) * (portrait ? 320 : 460);

  return (
    <PaperBackdrop>
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          padding: portrait ? 80 : 140,
        }}
      >
        <div
          style={{
            height: 2,
            width: ruleWidth,
            background: colors.clay,
            marginBottom: 44,
          }}
        />
        <div
          style={{
            fontFamily: fonts.serif,
            fontWeight: 700,
            fontSize: portrait ? 64 : 78,
            lineHeight: 1.32,
            color: colors.ink,
            textAlign: "center",
            maxWidth: portrait ? 720 : 1180,
          }}
        >
          <div
            style={{
              opacity: fadeIn(frame, 14, 18),
              transform: `translateY(${slideUp(frame, 14, 24, 36)}px)`,
            }}
          >
            別再低頭盯著螢幕。
          </div>
          <div
            style={{
              opacity: fadeIn(frame, 40, 20),
              transform: `translateY(${slideUp(frame, 40, 26, 36)}px)`,
            }}
          >
            抬起眼睛，
            <span style={{ color: colors.clay }}>世界本身就是展品。</span>
          </div>
        </div>
        <div
          style={{
            marginTop: 52,
            fontFamily: fonts.sans,
            fontSize: 22,
            letterSpacing: "0.12em",
            color: colors.ink3,
            opacity: fadeIn(frame, 78, 24),
          }}
        >
          Lorescape · 地誌手記
        </div>
      </AbsoluteFill>
    </PaperBackdrop>
  );
};
```

- [ ] **Step 2: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 3: Commit**

```bash
git add demo/src/scenes/HookScene.tsx
git commit -m "feat(demo): rewrite HookScene as paper manifesto opener"
```

---

## Task 8: StoryMockup + StoryScene（功能01 即時寫故事）

**Files:**
- Create: `demo/src/components/mockups/StoryMockup.tsx`
- Create: `demo/src/scenes/StoryScene.tsx`

- [ ] **Step 1: 建立 `mockups/StoryMockup.tsx`**

```tsx
import React from "react";
import { staticFile, useCurrentFrame } from "remotion";
import { colors, fonts } from "../../theme";
import { Waveform } from "../Waveform";

const lines = [
  "儒略二世決定拆毀君士坦丁",
  "大帝的千年古教堂，這場瘋",
  "狂的重建，竟耗時百餘年。",
  "米開朗基羅與拉斐爾輪番上",
  "陣，在同一座教堂留下印記。",
];

// In-app screen: a place photo, a serif title, and a story that types in
// line-by-line, with a "tap to listen" waveform at the bottom.
export const StoryMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const visibleLines = Math.min(lines.length, Math.floor((frame - 20) / 16));

  return (
    <div style={{ width: "100%", height: "100%", background: colors.paperRaised }}>
      <div style={{ height: "38%", overflow: "hidden", position: "relative" }}>
        <img
          src={staticFile("images/stpeters.jpg")}
          alt=""
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
        <div
          style={{
            position: "absolute",
            inset: 0,
            background:
              "linear-gradient(to bottom, rgba(0,0,0,0) 50%, rgba(27,22,17,0.55))",
          }}
        />
      </div>
      <div style={{ padding: "30px 34px" }}>
        <span
          style={{
            fontFamily: fonts.sans,
            fontSize: 14,
            fontWeight: 700,
            letterSpacing: "0.18em",
            textTransform: "uppercase",
            color: colors.clay,
          }}
        >
          St. Peter&apos;s Basilica
        </span>
        <div
          style={{
            fontFamily: fonts.serif,
            fontWeight: 700,
            fontSize: 36,
            lineHeight: 1.25,
            color: colors.ink,
            margin: "12px 0 22px",
          }}
        >
          摧毀與重生的
          <br />
          百年豪賭
        </div>
        <div
          style={{
            fontFamily: fonts.serif,
            fontSize: 26,
            lineHeight: 1.7,
            color: colors.ink2,
          }}
        >
          {lines.map((line, i) => (
            <div
              key={line}
              style={{
                opacity: i < visibleLines ? 1 : 0,
                transition: "opacity 0.2s",
              }}
            >
              {line}
            </div>
          ))}
        </div>
        <div
          style={{
            marginTop: 30,
            display: "flex",
            alignItems: "center",
            gap: 16,
            padding: "16px 22px",
            borderRadius: 16,
            background: colors.clayTint,
          }}
        >
          <Waveform width={220} height={40} barCount={32} />
          <span
            style={{
              fontFamily: fonts.sans,
              fontSize: 18,
              fontWeight: 500,
              color: colors.clayDeep,
            }}
          >
            一鍵化為語音
          </span>
        </div>
      </div>
    </div>
  );
};
```

- [ ] **Step 2: 建立 `scenes/StoryScene.tsx`**

```tsx
import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { PhoneFrame } from "../components/PhoneFrame";
import { SceneHeading } from "../components/SceneHeading";
import { StoryMockup } from "../components/mockups/StoryMockup";
import { fonts, colors } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp } from "../utils/animations";

// Beat 2 (0–6s local): "write a story for the place in front of you".
export const StoryScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const portrait = usePortrait();

  const phone = (
    <div
      style={{
        opacity: fadeIn(frame, 10, 20),
        transform: `translateY(${slideUp(frame, 10, 26, 60)}px)`,
      }}
    >
      <PhoneFrame width={portrait ? 460 : 410} height={portrait ? 940 : 840}>
        <StoryMockup />
      </PhoneFrame>
    </div>
  );

  const copy = (
    <div style={{ maxWidth: 560 }}>
      <SceneHeading
        over="Local Stories"
        title={
          <>
            為眼前的風景，
            <br />
            即時寫一篇故事
          </>
        }
        startFrame={4}
      />
      <p
        style={{
          fontFamily: fonts.sans,
          fontSize: 24,
          lineHeight: 1.7,
          color: colors.ink2,
          marginTop: 28,
          opacity: fadeIn(frame, 24, 20),
        }}
      >
        不是條列式的百科資料。Lorescape 為你經過的每座地標當場編寫一篇有人物、有轉折、值得細讀的故事。
      </p>
    </div>
  );

  void fps;

  return (
    <PaperBackdrop>
      <AbsoluteFill
        style={{
          flexDirection: portrait ? "column" : "row",
          alignItems: "center",
          justifyContent: "center",
          gap: portrait ? 48 : 110,
          padding: portrait ? "90px 60px" : "0 140px",
        }}
      >
        {portrait ? (
          <>
            {copy}
            {phone}
          </>
        ) : (
          <>
            {copy}
            {phone}
          </>
        )}
      </AbsoluteFill>
    </PaperBackdrop>
  );
};
```

- [ ] **Step 3: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 4: Commit**

```bash
git add demo/src/components/mockups/StoryMockup.tsx demo/src/scenes/StoryScene.tsx
git commit -m "feat(demo): add StoryScene (feature 01 instant story)"
```

---

## Task 9: PlayerMockup + AnglesScene（功能02 多種角度）

**Files:**
- Modify: `demo/src/components/mockups/PlayerMockup.tsx`（整檔替換）
- Create: `demo/src/scenes/AnglesScene.tsx`

- [ ] **Step 1: 整檔替換 `mockups/PlayerMockup.tsx`**

```tsx
import React from "react";
import { staticFile, useCurrentFrame } from "remotion";
import { colors, fonts } from "../../theme";
import { Waveform } from "../Waveform";

// In-app player screen for the selected angle: photo, "Anno · I" badge,
// serif title and a playing waveform.
export const PlayerMockup: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <div style={{ width: "100%", height: "100%", position: "relative" }}>
      <img
        src={staticFile("images/stpeters.jpg")}
        alt=""
        style={{ width: "100%", height: "100%", objectFit: "cover" }}
      />
      <div
        style={{
          position: "absolute",
          inset: 0,
          background:
            "linear-gradient(to bottom, rgba(27,22,17,0.25), rgba(27,22,17,0.9))",
        }}
      />
      <div
        style={{
          position: "absolute",
          inset: 0,
          padding: "70px 38px 48px",
          display: "flex",
          flexDirection: "column",
          justifyContent: "flex-end",
          opacity: Math.min(1, frame / 16),
        }}
      >
        <span
          style={{
            alignSelf: "flex-start",
            fontFamily: fonts.sans,
            fontSize: 16,
            fontWeight: 700,
            letterSpacing: "0.16em",
            color: colors.onDark,
            padding: "8px 16px",
            borderRadius: 999,
            background: colors.clay,
          }}
        >
          Anno · I
        </span>
        <div
          style={{
            fontFamily: fonts.serif,
            fontWeight: 700,
            fontSize: 44,
            lineHeight: 1.22,
            color: colors.onDark,
            margin: "20px 0 8px",
          }}
        >
          摧毀與重生的
          <br />
          百年豪賭
        </div>
        <div
          style={{
            fontFamily: fonts.sans,
            fontSize: 20,
            color: colors.onDark2,
            marginBottom: 28,
          }}
        >
          St. Peter&apos;s Basilica
        </div>
        <Waveform width={360} height={48} barCount={40} color={colors.claySoft} />
      </div>
    </div>
  );
};
```

- [ ] **Step 2: 建立 `scenes/AnglesScene.tsx`**

```tsx
import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { PhoneFrame } from "../components/PhoneFrame";
import { PlayerMockup } from "../components/mockups/PlayerMockup";
import { SceneHeading } from "../components/SceneHeading";
import { colors, fonts, paperGrain } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp, popIn } from "../utils/animations";
import { useVideoConfig } from "remotion";

const angles = [
  { num: "01", title: "摧毀與重生的百年豪賭" },
  { num: "02", title: "祭壇之下的神聖祕密" },
  { num: "03", title: "文藝復興巨匠的接力賽" },
];

// Beat 3 (0–6s local): dark section — same landmark, many stories.
export const AnglesScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const portrait = usePortrait();

  const cards = (
    <div style={{ display: "flex", flexDirection: "column", gap: 18, maxWidth: 540 }}>
      {angles.map((a, i) => {
        const p = popIn(frame, fps, 18 + i * 12);
        const selected = i === 0 && frame > 70;
        return (
          <div
            key={a.num}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 22,
              padding: "22px 26px",
              borderRadius: 18,
              background: selected ? colors.clay : "rgba(247,241,230,0.06)",
              border: `1px solid ${selected ? colors.clay : "rgba(247,241,230,0.14)"}`,
              opacity: p,
              transform: `translateX(${(1 - p) * 40}px)`,
            }}
          >
            <span
              style={{
                fontFamily: fonts.serif,
                fontSize: 30,
                fontWeight: 700,
                color: selected ? colors.onDark : colors.clay,
              }}
            >
              {a.num}
            </span>
            <span
              style={{
                fontFamily: fonts.serif,
                fontSize: 28,
                color: colors.onDark,
              }}
            >
              {a.title}
            </span>
          </div>
        );
      })}
    </div>
  );

  const phone = (
    <div
      style={{
        opacity: fadeIn(frame, 60, 20),
        transform: `translateY(${slideUp(frame, 60, 26, 60)}px)`,
      }}
    >
      <PhoneFrame width={portrait ? 440 : 380} height={portrait ? 900 : 800}>
        <PlayerMockup />
      </PhoneFrame>
    </div>
  );

  return (
    <AbsoluteFill style={{ backgroundColor: colors.inkBg }}>
      <AbsoluteFill
        style={{ backgroundImage: paperGrain, backgroundSize: "22px 22px", opacity: 0.4 }}
      />
      <AbsoluteFill
        style={{
          flexDirection: portrait ? "column" : "row",
          alignItems: "center",
          justifyContent: "center",
          gap: portrait ? 44 : 100,
          padding: portrait ? "80px 60px" : "0 140px",
        }}
      >
        <div>
          <SceneHeading
            over="Many Angles, One Place"
            title={
              <>
                同一座地標，
                <br />
                不只一個故事
              </>
            }
            startFrame={4}
            onDark
          />
          <div style={{ height: 34 }} />
          {cards}
        </div>
        {phone}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
```

- [ ] **Step 3: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 4: Commit**

```bash
git add demo/src/components/mockups/PlayerMockup.tsx demo/src/scenes/AnglesScene.tsx
git commit -m "feat(demo): add AnglesScene (feature 02 many angles)"
```

---

## Task 10: ExploreMockup + ExploreScene（功能03 探索身邊）

**Files:**
- Create: `demo/src/components/mockups/ExploreMockup.tsx`
- Create: `demo/src/scenes/ExploreScene.tsx`

- [ ] **Step 1: 建立 `mockups/ExploreMockup.tsx`**

```tsx
import React from "react";
import { staticFile, useCurrentFrame } from "remotion";
import { colors, fonts } from "../../theme";
import { popIn } from "../../utils/animations";
import { useVideoConfig } from "remotion";

const nearby = [
  { name: "台中朝聖宮", dist: "320 m", img: "images/temple.jpg" },
  { name: "聖伯多祿大殿", dist: "1.2 km", img: "images/stpeters.jpg" },
  { name: "中央公園步道", dist: "650 m", img: "images/park.jpg" },
];

const chips = ["自然景觀", "人文古蹟", "信仰聖地", "城市地標"];

// In-app "explore nearby" list: distance-sorted place cards + category chips.
export const ExploreMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <div style={{ width: "100%", height: "100%", background: colors.paperRaised, padding: "70px 30px 30px" }}>
      <div
        style={{
          fontFamily: fonts.serif,
          fontWeight: 700,
          fontSize: 34,
          color: colors.ink,
          marginBottom: 6,
        }}
      >
        附近值得停留
      </div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, margin: "16px 0 24px" }}>
        {chips.map((c, i) => (
          <span
            key={c}
            style={{
              fontFamily: fonts.sans,
              fontSize: 17,
              fontWeight: 500,
              color: i === 0 ? colors.onDark : colors.clayDeep,
              background: i === 0 ? colors.clay : colors.clayTint,
              padding: "9px 18px",
              borderRadius: 999,
              opacity: popIn(frame, fps, 10 + i * 5),
            }}
          >
            {c}
          </span>
        ))}
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        {nearby.map((n, i) => {
          const p = popIn(frame, fps, 26 + i * 12);
          return (
            <div
              key={n.name}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 18,
                padding: 14,
                borderRadius: 18,
                background: colors.paper,
                border: `1px solid ${colors.line}`,
                opacity: p,
                transform: `translateY(${(1 - p) * 24}px)`,
              }}
            >
              <img
                src={staticFile(n.img)}
                alt=""
                style={{ width: 78, height: 78, borderRadius: 14, objectFit: "cover" }}
              />
              <div>
                <div style={{ fontFamily: fonts.serif, fontSize: 26, color: colors.ink }}>
                  {n.name}
                </div>
                <div style={{ fontFamily: fonts.sans, fontSize: 18, color: colors.clay, marginTop: 4 }}>
                  {n.dist}
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

- [ ] **Step 2: 建立 `scenes/ExploreScene.tsx`**

```tsx
import React from "react";
import { AbsoluteFill, staticFile, useCurrentFrame } from "remotion";
import { PhoneFrame } from "../components/PhoneFrame";
import { ExploreMockup } from "../components/mockups/ExploreMockup";
import { SceneHeading } from "../components/SceneHeading";
import { colors, fonts } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp } from "../utils/animations";

// Beat 4 (0–5s local): full-bleed park photo + nearby exploration.
export const ExploreScene: React.FC = () => {
  const frame = useCurrentFrame();
  const portrait = usePortrait();

  const phone = (
    <div
      style={{
        opacity: fadeIn(frame, 10, 20),
        transform: `translateY(${slideUp(frame, 10, 26, 60)}px)`,
      }}
    >
      <PhoneFrame width={portrait ? 440 : 380} height={portrait ? 900 : 800}>
        <ExploreMockup />
      </PhoneFrame>
    </div>
  );

  const copy = (
    <div style={{ maxWidth: 540 }}>
      <SceneHeading over="Explore Nearby" title="探索身邊的風景" startFrame={4} onDark />
      <p
        style={{
          fontFamily: fonts.sans,
          fontSize: 24,
          lineHeight: 1.7,
          color: colors.onDark2,
          marginTop: 28,
          opacity: fadeIn(frame, 24, 20),
        }}
      >
        依距離與主題，為你列出附近值得停留的每一個角落——每一種風景，都有屬於它的故事。
      </p>
    </div>
  );

  return (
    <AbsoluteFill style={{ backgroundColor: colors.inkBg }}>
      <AbsoluteFill style={{ opacity: 0.55 }}>
        <img
          src={staticFile("images/park.jpg")}
          alt=""
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
      </AbsoluteFill>
      <AbsoluteFill
        style={{
          background:
            "linear-gradient(120deg, rgba(27,22,17,0.92), rgba(27,22,17,0.55))",
        }}
      />
      <AbsoluteFill
        style={{
          flexDirection: portrait ? "column" : "row",
          alignItems: "center",
          justifyContent: "center",
          gap: portrait ? 44 : 100,
          padding: portrait ? "80px 60px" : "0 140px",
        }}
      >
        {copy}
        {phone}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
```

- [ ] **Step 3: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 4: Commit**

```bash
git add demo/src/components/mockups/ExploreMockup.tsx demo/src/scenes/ExploreScene.tsx
git commit -m "feat(demo): add ExploreScene (feature 03 explore nearby)"
```

---

## Task 11: JournalMockup + JournalScene（功能04 旅程成冊）

**Files:**
- Create: `demo/src/components/mockups/JournalMockup.tsx`
- Create: `demo/src/scenes/JournalScene.tsx`

- [ ] **Step 1: 建立 `mockups/JournalMockup.tsx`**

```tsx
import React from "react";
import { staticFile, useCurrentFrame } from "remotion";
import { colors, fonts } from "../../theme";
import { popIn } from "../../utils/animations";
import { useVideoConfig } from "remotion";

const entries = [
  { title: "摧毀與重生的百年豪賭", place: "聖伯多祿大殿", img: "images/stpeters.jpg" },
  { title: "媽祖信仰的海上足跡", place: "台中朝聖宮", img: "images/temple.jpg" },
  { title: "蒙兀兒王朝的紅色宮牆", place: "阿格拉紅堡", img: "images/agra.jpg" },
];

// In-app journal: auto-bound entries stacking into a personal field journal.
export const JournalMockup: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <div style={{ width: "100%", height: "100%", background: colors.paperSunk, padding: "70px 30px 30px" }}>
      <div style={{ fontFamily: fonts.sans, fontSize: 15, fontWeight: 700, letterSpacing: "0.18em", textTransform: "uppercase", color: colors.clay }}>
        My Field Journal
      </div>
      <div style={{ fontFamily: fonts.serif, fontWeight: 700, fontSize: 34, color: colors.ink, margin: "8px 0 26px" }}>
        2026 春・歐遊手記
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {entries.map((e, i) => {
          const p = popIn(frame, fps, 14 + i * 14);
          return (
            <div
              key={e.title}
              style={{
                display: "flex",
                gap: 18,
                padding: 16,
                borderRadius: 18,
                background: colors.paperRaised,
                border: `1px solid ${colors.line}`,
                boxShadow: "0 6px 18px rgba(40,30,18,0.09)",
                opacity: p,
                transform: `translateY(${(1 - p) * 30}px) rotate(${(1 - p) * -2}deg)`,
              }}
            >
              <img
                src={staticFile(e.img)}
                alt=""
                style={{ width: 88, height: 88, borderRadius: 14, objectFit: "cover" }}
              />
              <div style={{ display: "flex", flexDirection: "column", justifyContent: "center" }}>
                <div style={{ fontFamily: fonts.serif, fontSize: 25, color: colors.ink, lineHeight: 1.3 }}>
                  {e.title}
                </div>
                <div style={{ fontFamily: fonts.sans, fontSize: 17, color: colors.ink3, marginTop: 6 }}>
                  {e.place}
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

- [ ] **Step 2: 建立 `scenes/JournalScene.tsx`**

```tsx
import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { PhoneFrame } from "../components/PhoneFrame";
import { JournalMockup } from "../components/mockups/JournalMockup";
import { SceneHeading } from "../components/SceneHeading";
import { colors, fonts } from "../theme";
import { usePortrait } from "../utils/layout";
import { fadeIn, slideUp, popIn } from "../utils/animations";

const stats = [
  { num: "I", cn: "自動成篇" },
  { num: "II", cn: "依旅程歸檔" },
  { num: "III", cn: "沿時間軸重溫" },
];

// Beat 5 (0–4s local): your journey is bound into a journal automatically.
export const JournalScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const portrait = usePortrait();

  const phone = (
    <div
      style={{
        opacity: fadeIn(frame, 8, 18),
        transform: `translateY(${slideUp(frame, 8, 24, 56)}px)`,
      }}
    >
      <PhoneFrame width={portrait ? 440 : 380} height={portrait ? 900 : 800}>
        <JournalMockup />
      </PhoneFrame>
    </div>
  );

  const copy = (
    <div style={{ maxWidth: 540 }}>
      <SceneHeading over="Journey Journal" title="你的旅程，自動成冊" startFrame={4} />
      <p
        style={{
          fontFamily: fonts.sans,
          fontSize: 24,
          lineHeight: 1.7,
          color: colors.ink2,
          margin: "26px 0 30px",
          opacity: fadeIn(frame, 22, 18),
        }}
      >
        每一次駐足，都被悄悄寫進一本屬於你的旅行手記。
      </p>
      <div style={{ display: "flex", gap: 14 }}>
        {stats.map((s, i) => (
          <div
            key={s.num}
            style={{
              flex: 1,
              padding: "18px 14px",
              borderRadius: 16,
              background: colors.paperRaised,
              border: `1px solid ${colors.line}`,
              textAlign: "center",
              opacity: popIn(frame, fps, 30 + i * 8),
            }}
          >
            <div style={{ fontFamily: fonts.serif, fontSize: 30, fontWeight: 700, color: colors.clay }}>
              {s.num}
            </div>
            <div style={{ fontFamily: fonts.sans, fontSize: 18, color: colors.ink2, marginTop: 6 }}>
              {s.cn}
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  return (
    <PaperBackdrop tone="sunk">
      <AbsoluteFill
        style={{
          flexDirection: portrait ? "column" : "row",
          alignItems: "center",
          justifyContent: "center",
          gap: portrait ? 44 : 100,
          padding: portrait ? "80px 60px" : "0 140px",
        }}
      >
        {copy}
        {phone}
      </AbsoluteFill>
    </PaperBackdrop>
  );
};
```

- [ ] **Step 3: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 4: Commit**

```bash
git add demo/src/components/mockups/JournalMockup.tsx demo/src/scenes/JournalScene.tsx
git commit -m "feat(demo): add JournalScene (feature 04 journey journal)"
```

---

## Task 12: CtaScene 重寫

**Files:**
- Modify: `demo/src/scenes/CtaScene.tsx`（整檔替換）

- [ ] **Step 1: 整檔替換 `CtaScene.tsx`**

```tsx
import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { PaperBackdrop } from "../components/PaperBackdrop";
import { Wordmark } from "../components/Wordmark";
import { StoreBadges } from "../components/StoreBadges";
import { colors, fonts } from "../theme";
import { fadeIn, slideUp } from "../utils/animations";

// Beat 6 (0–4s local): closing call-to-action on warm paper.
export const CtaScene: React.FC = () => {
  const frame = useCurrentFrame();

  return (
    <PaperBackdrop>
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          gap: 30,
          padding: 100,
        }}
      >
        <div style={{ opacity: fadeIn(frame, 4, 16), transform: `translateY(${slideUp(frame, 4, 20, 30)}px)` }}>
          <Wordmark size={66} />
        </div>
        <span
          style={{
            fontFamily: fonts.sans,
            fontSize: 18,
            fontWeight: 700,
            letterSpacing: "0.22em",
            textTransform: "uppercase",
            color: colors.clay,
            opacity: fadeIn(frame, 16, 16),
          }}
        >
          開始你的第一段故事
        </span>
        <div
          style={{
            fontFamily: fonts.serif,
            fontWeight: 700,
            fontSize: 72,
            lineHeight: 1.25,
            textAlign: "center",
            color: colors.ink,
            opacity: fadeIn(frame, 22, 18),
            transform: `translateY(${slideUp(frame, 22, 24, 34)}px)`,
          }}
        >
          城市是一本書。
          <br />
          開始閱讀吧。
        </div>
        <p
          style={{
            fontFamily: fonts.sans,
            fontSize: 24,
            color: colors.ink2,
            opacity: fadeIn(frame, 40, 18),
          }}
        >
          加入五萬名探索者，一同揭開世界各地隱藏的篇章。
        </p>
        <div style={{ marginTop: 18, opacity: fadeIn(frame, 52, 20) }}>
          <StoreBadges />
        </div>
      </AbsoluteFill>
    </PaperBackdrop>
  );
};
```

- [ ] **Step 2: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 3: Commit**

```bash
git add demo/src/scenes/CtaScene.tsx
git commit -m "feat(demo): rewrite CtaScene on warm paper"
```

---

## Task 13: Main.tsx 重接 6 段 + 移除舊檔

**Files:**
- Modify: `demo/src/Main.tsx`（整檔替換）
- Delete: `IntroScene.tsx`, `NarrationScene.tsx`, `PassportScene.tsx`, `StoneTexture.tsx`, `mockups/HomeMockup.tsx`, `mockups/PassportMockup.tsx`

- [ ] **Step 1: 整檔替換 `Main.tsx`**

```tsx
import React from "react";
import {
  AbsoluteFill,
  Audio,
  Sequence,
  getStaticFiles,
  staticFile,
} from "remotion";
import { HookScene } from "./scenes/HookScene";
import { StoryScene } from "./scenes/StoryScene";
import { AnglesScene } from "./scenes/AnglesScene";
import { ExploreScene } from "./scenes/ExploreScene";
import { JournalScene } from "./scenes/JournalScene";
import { CtaScene } from "./scenes/CtaScene";
import { colors } from "./theme";

// Scene ranges (30fps, 900 frames total):
// Hook     0–150   (5s)   manifesto opener
// Story  150–330   (6s)   feature 01 instant story
// Angles 330–510   (6s)   feature 02 many angles
// Explore510–660   (5s)   feature 03 explore nearby
// Journal660–780   (4s)   feature 04 journey journal
// CTA    780–900   (4s)
const hasFile = (name: string) => getStaticFiles().some((f) => f.name === name);

export const Main: React.FC = () => {
  const hasBgm = hasFile("bgm.mp3");

  return (
    <AbsoluteFill style={{ background: colors.paper }}>
      {hasBgm ? <Audio src={staticFile("bgm.mp3")} volume={0.8} /> : null}

      <Sequence from={0} durationInFrames={150}>
        <HookScene />
      </Sequence>
      <Sequence from={150} durationInFrames={180}>
        <StoryScene />
      </Sequence>
      <Sequence from={330} durationInFrames={180}>
        <AnglesScene />
      </Sequence>
      <Sequence from={510} durationInFrames={150}>
        <ExploreScene />
      </Sequence>
      <Sequence from={660} durationInFrames={120}>
        <JournalScene />
      </Sequence>
      <Sequence from={780} durationInFrames={120}>
        <CtaScene />
      </Sequence>
    </AbsoluteFill>
  );
};
```

- [ ] **Step 2: 刪除舊檔**

Run（在 `demo/`）：
```bash
git rm src/scenes/IntroScene.tsx src/scenes/NarrationScene.tsx src/scenes/PassportScene.tsx src/components/StoneTexture.tsx src/components/mockups/HomeMockup.tsx src/components/mockups/PassportMockup.tsx
```
Expected: 六個檔案被移除。

- [ ] **Step 3: 跑 lint（確認無殘留 import）**

Run：`npm run lint`
Expected: PASS，無「找不到模組」錯誤。

- [ ] **Step 4: Commit**

```bash
git add demo/src/Main.tsx
git commit -m "feat(demo): wire 6-beat storyboard and remove old scenes"
```

---

## Task 14: Root.tsx 註冊橫直兩個 composition

**Files:**
- Modify: `demo/src/Root.tsx`（整檔替換）

- [ ] **Step 1: 整檔替換 `Root.tsx`**

```tsx
import "./index.css";
import { Composition } from "remotion";
import { Main } from "./Main";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="LorescapeIntro"
        component={Main}
        durationInFrames={900}
        fps={30}
        width={1920}
        height={1080}
      />
      <Composition
        id="LorescapeIntroVertical"
        component={Main}
        durationInFrames={900}
        fps={30}
        width={1080}
        height={1920}
      />
    </>
  );
};
```

- [ ] **Step 2: 跑 lint**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 3: 抽幀驗收（橫式）**

Run（在 `demo/`）：
```bash
npx remotion still LorescapeIntro out/h-hook.png --frame=90 --scale=0.5
npx remotion still LorescapeIntro out/h-story.png --frame=240 --scale=0.5
npx remotion still LorescapeIntro out/h-angles.png --frame=440 --scale=0.5
npx remotion still LorescapeIntro out/h-explore.png --frame=600 --scale=0.5
npx remotion still LorescapeIntro out/h-journal.png --frame=740 --scale=0.5
npx remotion still LorescapeIntro out/h-cta.png --frame=860 --scale=0.5
```
Expected: 6 個 PNG 產生。用 Read 工具開圖逐一檢查：紙感背景、中文襯線標題、陶土色 over-line、照片正確載入、手機 mockup 構圖無溢出。

- [ ] **Step 4: 抽幀驗收（直式）**

Run：
```bash
npx remotion still LorescapeIntroVertical out/v-story.png --frame=240 --scale=0.5
npx remotion still LorescapeIntroVertical out/v-angles.png --frame=440 --scale=0.5
npx remotion still LorescapeIntroVertical out/v-cta.png --frame=860 --scale=0.5
```
Expected: 3 個 PNG 產生。檢查直式為「文字在上、手機在下」垂直堆疊、無水平溢出。

- [ ] **Step 5: Commit**

```bash
git add demo/src/Root.tsx
git commit -m "feat(demo): register horizontal and vertical compositions"
```

---

## Task 15: README 更新 + 最終渲染驗收

**Files:**
- Modify: `demo/README.md`

- [ ] **Step 1: 更新 `README.md` 分鏡表與 composition 段落**

把現有「分鏡」表格替換為：

```markdown
### 分鏡

| Scene   | 時間     | 內容                                              |
| ------- | -------- | ------------------------------------------------- |
| Hook    | 0–5s     | 紙感手記開場，「抬起眼睛，世界本身就是展品。」     |
| Story   | 5–11s    | 功能01 即時寫故事，聖伯多祿實景 + 打字故事         |
| Angles  | 11–17s   | 功能02 同一地標多角度，深底播放器                 |
| Explore | 17–22s   | 功能03 探索身邊，附近地點 + 主題 chips            |
| Journal | 22–26s   | 功能04 旅程成冊，手記自動成篇                      |
| CTA     | 26–30s   | 「城市是一本書。開始閱讀吧。」+ 商店徽章           |
```

並在「影片規格」段落補上第二個 composition：

```markdown
- **Composition id**：`LorescapeIntro`（16:9, 1920×1080）、`LorescapeIntroVertical`（9:16, 1080×1920）
```

把「設計參考」段落更新為紙感品牌：

```markdown
## 設計參考

視覺語言對齊 landing（`landing/src/app/globals.css`）：
- 紙白背景 `#f7f1e6`、凸紙 `#fdfaf3`、凹紙 `#ece3d3`
- 品牌陶土色 `#bc5e3e` → 深陶 `#97442a`
- 墨色文字 `#221c14`、襯線中文標題 Noto Serif TC
- 功能02 深底區 `#1b1611`
```

- [ ] **Step 2: 最終渲染（兩支 MP4）**

Run（在 `demo/`）：
```bash
npx remotion render LorescapeIntro out/lorescape-intro.mp4
npx remotion render LorescapeIntroVertical out/lorescape-intro-vertical.mp4
```
Expected: 兩支 MP4 成功輸出，無 render error。

- [ ] **Step 3: 跑 lint 做最終確認**

Run：`npm run lint`
Expected: PASS。

- [ ] **Step 4: Commit**

```bash
git add demo/README.md
git commit -m "docs(demo): update README for redesigned promo storyboard"
```

---

## Self-Review

**Spec coverage：**
- 雙比例 composition → Task 14 ✓
- 橫直自適應 `usePortrait` → Task 1 ✓，各 scene Task 7–12 套用 ✓
- design tokens 移植 → Task 1 `theme.ts` ✓
- Noto Serif/Sans TC 載入 → Task 1 ✓
- 六段分鏡（Hook/Story/Angles/Explore/Journal/CTA）→ Task 7–12 ✓，接線 Task 13 ✓
- 元件新增（PaperBackdrop/BrandSeal/SceneHeading）→ Task 2/4/5 ✓
- 元件重做（PhoneFrame/Wordmark/Waveform/mockups）→ Task 3/4/6/8–11 ✓
- 真實照片素材 → Task 1 複製 ✓，scenes 以 `staticFile("images/...")` 引用 ✓
- 移除舊檔 → Task 13 ✓
- 驗證（lint + still + render）→ 各 task + Task 14/15 ✓

**Placeholder scan：** 無 TBD/TODO；每個程式步驟皆附完整程式碼。

**Type consistency：**
- `colors`/`fonts`/`shadows`/`paperGrain` 由 `theme.ts` 匯出，所有引用一致。
- `usePortrait()` 簽章一致（無參數、回傳 boolean）。
- `SceneHeading` props（`over`/`title`/`startFrame`/`align`/`onDark`）在 Task 5 定義，Task 8–11 使用一致。
- `Waveform` 的 `color` prop 在 Task 9/8 使用，與 Task 6 預設一致。
- `PhoneFrame` 的 `width`/`height` props 在所有 scene 一致使用。
- 圖片路徑 `images/stpeters.jpg` 等與 Task 1 複製目標一致。

無發現缺口。
