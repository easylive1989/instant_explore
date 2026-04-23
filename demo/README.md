# Lorescape — App Intro Video

30 秒、1920×1080、電影感的 Lorescape App 介紹影片，以 Remotion 製作。全部 UI 皆為純 code mockup (TypeScript + TailwindCSS)。

## 影片規格

- **Composition id**：`LorescapeIntro`
- **解析度**：1920 × 1080 (16:9)
- **FPS**：30
- **長度**：900 frames (30s)

### 分鏡

| Scene        | 時間     | 內容                                                             |
| ------------ | -------- | ---------------------------------------------------------------- |
| Hook         | 0–5s     | 石紋 + 裂縫金光，"Stones don't speak—until now."                  |
| Intro        | 5–10s    | iPhone + Home 畫面，Lorescape wordmark + tagline                  |
| Narration    | 10–18s   | iPhone + Immersive Player，"Real-time AI narration"               |
| Passport     | 18–25s   | iPhone + Knowledge Passport，"Every journey, remembered."         |
| CTA          | 25–30s   | Wordmark + "Read the world." + App Store / Google Play 徽章      |

## 常用指令

```bash
# 安裝依賴
npm install

# 啟動 Remotion Studio（預覽 + timeline 編輯）
npm run dev
# → http://localhost:3000

# 輸出 MP4
npx remotion render LorescapeIntro out/lorescape-intro.mp4

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
├── Root.tsx                  # Composition 註冊
├── Main.tsx                  # 組合 5 個 Sequence + Audio
├── index.ts                  # registerRoot 入口
├── index.css                 # Tailwind import
├── scenes/
│   ├── HookScene.tsx
│   ├── IntroScene.tsx
│   ├── NarrationScene.tsx
│   ├── PassportScene.tsx
│   └── CtaScene.tsx
├── components/
│   ├── PhoneFrame.tsx        # iPhone 外框
│   ├── Wordmark.tsx          # "Lorescape" 標準字
│   ├── StoneTexture.tsx      # Hook 用石紋 + 金光 SVG
│   ├── Waveform.tsx          # 聲紋動畫
│   ├── StoreBadges.tsx       # App Store / Google Play 徽章
│   └── mockups/
│       ├── HomeMockup.tsx
│       ├── PlayerMockup.tsx
│       └── PassportMockup.tsx
└── utils/
    └── animations.ts         # 共用 easing / spring helpers
```

## 客製化

| 想改的內容             | 檔案位置                                  |
| ---------------------- | ----------------------------------------- |
| Hook 文案              | `src/scenes/HookScene.tsx` (`line1`, `line2`) |
| 產品 slogan/tagline    | `src/scenes/IntroScene.tsx`, `CtaScene.tsx` |
| 品牌主色 / 背景色      | 各 scene 內的 `radial-gradient` / Tailwind 類別 |
| Store badge 連結資訊   | `src/components/StoreBadges.tsx`          |
| 影片長度 / FPS         | `src/Root.tsx` 的 `<Composition />` props |
| Scene 起訖時間         | `src/Main.tsx` 的 `<Sequence from=... durationInFrames=...>` |

## 設計參考

視覺語言對齊專案的 `docs/DESIGN_SYSTEM.md`：
- 深色背景 `#0B111A` / `#101922`
- 品牌主色 `#137fec`
- 黃金強調色 `#FFC36A` → `#FFA93D`（僅 Hook / CTA）
- 玻璃擬態：`rgba(255,255,255,0.08)` + `backdrop-filter: blur(16px)`

## 授權

本資料夾作為 Lorescape 專案的行銷素材工作區，授權隨主專案。Remotion 本身對 3 人以上團隊需要 [company license](https://www.remotion.pro/license)。
