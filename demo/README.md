# Lorescape — App Intro Video

30 秒、1920×1080、電影感的 Lorescape App 介紹影片，以 Remotion 製作。全部 UI 皆為純 code mockup (TypeScript + TailwindCSS)。

## 影片規格

- **Composition id**：`LorescapeIntro`（16:9, 1920×1080）、`LorescapeIntroVertical`（9:16, 1080×1920）
- **解析度**：1920 × 1080 (16:9)
- **FPS**：30
- **長度**：900 frames (30s)

### 分鏡

「城市是一本書」6 幕結構，開場與收尾都在同一片暗色 ink gradient 上呼應（頁子闔上又翻開的意象）。

| Scene   | Frame 範圍 | 時間   | 內容                                                        |
| ------- | ---------- | ------ | ------------------------------------------------------------- |
| Hook    | 0–150      | 0–5s   | 暗色開場宣言，無 App UI：「抬起眼睛，世界本身就是一本書。」   |
| Explore | 150–330    | 5–11s  | 地標登場：探索身邊清單 + 主題 chips（`ExploreMockup`）        |
| Angles  | 330–510    | 11–17s | 一書多章：同一地標的三種故事角度選單（`StoryOptionsMockup`）  |
| Reader  | 510–690    | 17–23s | 沉浸聆聽：聖伯多祿大殿故事全文閱讀器（`ReaderMockup`）        |
| Journal | 690–810    | 23–27s | 旅程成冊：手記自動彙整成篇（`JournalMockup`）                 |
| Cta     | 810–900    | 27–30s | 暗色收尾：「城市是一本書。開始閱讀吧。」+ 商店徽章             |

## 常用指令

```bash
# 安裝依賴
npm install

# 啟動 Remotion Studio（預覽 + timeline 編輯）
npm run dev
# → http://localhost:3000

# 輸出 MP4
npx remotion render LorescapeIntro out/lorescape-intro.mp4
npx remotion render LorescapeIntroVertical out/lorescape-intro-vertical.mp4

# 單幀 PNG（用來快速驗證某一幀）
npx remotion still LorescapeIntro out/frame.png --frame=90 --scale=0.5
```

## 加入 BGM

將 MP3 檔案命名為 **`bgm.mp3`** 放入 `public/` 資料夾即可，`Main.tsx` 會自動偵測並以 `<Audio>` 載入。

- 建議長度：30 秒（或更長 — 會自動被影片長度截斷）
- 建議音量：母帶到 -14 LUFS，開頭 0.3s fade-in，結尾 1s fade-out
- 預設音量：`volume={0.8}`（可在 `src/Main.tsx` 調整）

若 `public/bgm.mp3` 不存在，影片會正常渲染但無音訊。

## 檔案結構

```
src/
├── Root.tsx                  # Composition 註冊（16:9 + 9:16 兩個 Composition）
├── Main.tsx                  # 組合 6 個 Sequence（Scene 起訖 frame）+ Audio
├── theme.ts                  # 顏色 / 字型 / 陰影等 design tokens（對齊 landing）
├── data.ts                   # 全片文案與假資料（故事角度、附近地點、手記篇章…）
├── index.ts                  # registerRoot 入口
├── index.css                 # Tailwind import
├── scenes/
│   ├── HookScene.tsx         # 開場宣言
│   ├── ExploreScene.tsx      # 地標登場
│   ├── AnglesScene.tsx       # 一書多章
│   ├── ReaderScene.tsx       # 沉浸聆聽
│   ├── JournalScene.tsx      # 旅程成冊
│   └── CtaScene.tsx          # CTA 收尾
├── components/
│   ├── PhoneFrame.tsx        # iPhone 外框
│   ├── Wordmark.tsx          # "Lorescape" 標準字
│   ├── PaperBackdrop.tsx     # 紙感背景紋理
│   ├── SceneHeading.tsx      # 共用 over-line + 標題排版
│   ├── BrandSeal.tsx         # 品牌印章 / 標記
│   ├── Waveform.tsx          # 聲紋動畫
│   ├── StoreBadges.tsx       # App Store / Google Play 徽章
│   └── mockups/
│       ├── ExploreMockup.tsx      # 探索身邊列表 UI
│       ├── StoryOptionsMockup.tsx # 多角度故事選單 UI
│       ├── ReaderMockup.tsx       # 故事閱讀器 UI
│       └── JournalMockup.tsx      # 旅程手記 UI
└── utils/
    ├── animations.ts         # 共用 easing / spring helpers
    └── layout.ts             # 直向 / 橫向 (usePortrait) 版面切換
```

## 客製化

| 想改的內容                     | 檔案位置                                                      |
| ------------------------------ | -------------------------------------------------------------- |
| Hook 開場宣言文案               | `src/scenes/HookScene.tsx`（內嵌兩行文字）                     |
| CTA 收尾標語                    | `src/scenes/CtaScene.tsx`（「城市是一本書。開始閱讀吧。」）    |
| 各 Scene 的 over-line / 大標    | 各 scene 呼叫 `SceneHeading` 的 `over` / `title` props         |
| 故事角度 / 完整故事 / 附近地點 / 手記篇章等假資料 | `src/data.ts`（`storyOptions`, `stPetersStory`, `nearbyPlaces`, `journalEntries`, `exploreChips`） |
| 品牌色彩 / 字型 / 陰影 tokens   | `src/theme.ts`                                                 |
| Store badge 連結資訊            | `src/components/StoreBadges.tsx`                               |
| 影片長度 / FPS / 解析度         | `src/Root.tsx` 的 `<Composition />` props                      |
| Scene 起訖 frame                | `src/Main.tsx` 的 `<Sequence from=... durationInFrames=...>`   |

## 設計參考

視覺語言對齊 landing（`landing/src/app/globals.css`）：
- 紙白背景 `#f7f1e6`、凸紙 `#fdfaf3`、凹紙 `#ece3d3`
- 品牌陶土色 `#bc5e3e` → 深陶 `#97442a`
- 墨色文字 `#221c14`、襯線中文標題 Noto Serif TC
- 暗色收尾 / 開場漸層 `#2c2620 → #17120d`（Hook / Cta），Reader 深底 `#1b1611`

## 授權

本資料夾作為 Lorescape 專案的行銷素材工作區，授權隨主專案。Remotion 本身對 3 人以上團隊需要 [company license](https://www.remotion.pro/license)。
