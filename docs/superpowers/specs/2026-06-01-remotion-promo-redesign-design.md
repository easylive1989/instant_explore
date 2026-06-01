# Remotion 宣傳影片重做 — 對齊「地誌手記」品牌

日期：2026-06-01
範圍：`demo/`（Remotion 行銷影片工作區）

## 背景與問題

`demo/` 現有的 30 秒介紹影片建立在**舊品牌**上：深色背景 `#0B111A`、品牌藍
`#137fec`、石紋金光 hook、英文文案（"Stones don't speak—until now."、"Read the
world."），分鏡為 Hook / Intro / Narration / Passport / CTA。

但 landing（官網）已完成改版，轉向**溫暖紙感「地誌手記」**美學：紙白底、陶土主色、
襯線中文標題、中文為主的文案，並重新定義四大功能。現有影片與最新品牌、功能完全脫節，
需整支重做。

## 目標

依最新 landing 設計與功能，重做 Remotion 宣傳影片，做到：

1. 視覺與 landing 1:1 對齊（色票、字體、紙質感、陶土主色）。
2. 文案中文為主，對齊官網語氣與四大功能。
3. 同一套分鏡輸出**橫式 16:9** 與**直式 9:16** 兩個版本。
4. 真實照片 + code 畫的手機 UI mockup 混合呈現。
5. 維持 30 秒長度。

## 決策（已與使用者確認）

| 項目 | 決定 |
|---|---|
| 畫面比例 | 橫式 16:9 與直式 9:16 **兩種都要** |
| 影片長度 | 維持 30 秒 |
| 文案語言 | 中文為主，少量英文 over-line（對齊 landing） |
| 視覺素材 | 真實照片 + UI mockup 混合 |
| 分鏡結構 | A · 四功能均衡巡禮 |

## 技術架構

### 雙比例 composition

註冊兩個共用同一套 scene 元件的 composition：

| Composition id | 解析度 | 用途 |
|---|---|---|
| `LorescapeIntro` | 1920×1080 (16:9) | YouTube / 官網 / 簡報 |
| `LorescapeIntroVertical` | 1080×1920 (9:16) | Reels / App Store 預覽 |

兩者皆 30fps、900 frames、共用 `Main` 元件與全部 scene。

### 橫直自適應

新增 `src/utils/layout.ts`，提供 `usePortrait()`：以 `useVideoConfig()` 取得
`width`/`height`，回傳 `height > width`。每個 scene 依此切換版型：

- **橫式**：實景照／手機在一側，中文標題 + 說明在另一側（水平分割）。
- **直式**：照片在上、手機置中、文字堆疊在下（垂直堆疊）。

一套分鏡邏輯、兩種輸出；文案與動畫只維護一份。

## 視覺系統

把 landing `globals.css` 的 design tokens 收進 `src/theme.ts`：

```
paper        #f7f1e6   paper-raised #fdfaf3   paper-sunk #ece3d3
line         #e4dac8   line-strong  #cdbfa6
ink          #221c14   ink-2 #5e5341         ink-3 #918471
clay         #bc5e3e   clay-deep #97442a     clay-soft #f1ddce   clay-tint #f7e8dd
ink-bg       #1b1611   on-dark #f7f1e6       on-dark-2 #c3b7a4
```

- **字體**：襯線中文標題 Noto Serif TC、內文 Noto Sans TC，以
  `@remotion/google-fonts` 載入（需新增此依賴）。
- **質感**：紙張顆粒（22px radial-dot grain）、三層陰影 e1/e2/e3、英文 over-line
  全大寫 0.22em 字距陶土色。
- **棄用**：舊深藍 `#137fec`、石紋金光 hook、深色玻璃擬態。

## 分鏡（30s @ 30fps = 900 frames）

| # | 段落 | 時間 (frame) | 文案 | 畫面 / 動畫 |
|---|---|---|---|---|
| 1 | Hook 手記開場 | 0–5s (0–150) | 「別再低頭盯著螢幕。**抬起眼睛，世界本身就是展品。**」cite: Lorescape · 地誌手記 | 紙感背景 + 陶土細線描繪，襯線中文逐句上浮，「世界本身就是展品」陶土色強調 |
| 2 | 功能01 即時寫故事 | 5–11s (150–330) | over: Local Stories｜「為眼前的風景，即時寫一篇故事」 | 聖伯多祿大殿實景 → 手機滑入，故事逐行打字浮現 + 聲紋（一鍵化為語音） |
| 3 | 功能02 多種角度 | 11–17s (330–510) | over: Many Angles, One Place｜「同一座地標，不只一個故事」 | 深底區。三張故事卡（百年豪賭／神聖祕密／巨匠接力）依序翻入，選中一張 → 播放器（Anno·I 徽章 + 聲紋） |
| 4 | 功能03 探索身邊 | 17–22s (510–660) | over: Explore Nearby｜「探索身邊的風景」 | park 實景 bleed，附近地點卡 + 四個主題 chips（自然景觀／人文古蹟／信仰聖地／城市地標）依距離浮現 |
| 5 | 功能04 旅程成冊 | 22–26s (660–780) | over: Journey Journal｜「你的旅程，自動成冊」 | 手記頁／旅程卡疊合成冊，三張 stat 卡 I/II/III（自動成篇／依旅程歸檔／沿時間軸重溫）滑入 |
| 6 | CTA | 26–30s (780–900) | over: 開始你的第一段故事｜「城市是一本書。開始閱讀吧。」「加入五萬名探索者」 | 羅盤徽章描繪 → Lorescape 襯線標準字 → App Store／Google Play 徽章 |

文案來源對齊 landing 元件：Hero、Manifesto、LocalStories、ManyAngles、
ExploreNearby、JourneyJournal、FinalCTA。

## 元件架構

```
src/
├── Root.tsx                  # 註冊 2 個 composition
├── Main.tsx                  # 6 個 Sequence + Audio（橫直無關）
├── theme.ts                  # 新增：design tokens（色票、字體、陰影）
├── scenes/
│   ├── HookScene.tsx         # 重寫（manifesto 開場）
│   ├── StoryScene.tsx        # 功能01（原 NarrationScene 角色）
│   ├── AnglesScene.tsx       # 功能02
│   ├── ExploreScene.tsx      # 功能03
│   ├── JournalScene.tsx      # 功能04（原 PassportScene 角色）
│   └── CtaScene.tsx          # 重寫
├── components/
│   ├── PaperBackdrop.tsx     # 新增：紙顆粒 + 細線背景
│   ├── PhoneFrame.tsx        # 重做為淺色（白屏、陶土點綴）
│   ├── Wordmark.tsx          # 重做：襯線 + 羅盤徽章
│   ├── BrandSeal.tsx         # 新增：羅盤印記（移植 landing）
│   ├── Waveform.tsx          # 改色為陶土
│   ├── StoreBadges.tsx       # 重新配色
│   ├── SceneHeading.tsx      # 新增：over-line + 襯線大標
│   └── mockups/
│       ├── StoryMockup.tsx   # 打字故事
│       ├── PlayerMockup.tsx  # Anno 徽章播放器
│       ├── ExploreMockup.tsx # 附近地點 + chips
│       └── JournalMockup.tsx # stat 卡 / 手記頁
└── utils/
    ├── animations.ts         # 沿用並擴充
    └── layout.ts             # 新增：usePortrait()
```

**移除**：`StoneTexture`、舊 `IntroScene`、`mockups/HomeMockup`、
`mockups/PassportMockup`。

## 素材

把 landing `public/images/` 的真實照片複製進 `demo/public/images/`：
`stpeters.jpg`、`temple.jpg`、`park.jpg`、`agra.jpg`。BGM 維持現有
`public/bgm.mp3` 自動偵測機制（不存在則無聲渲染）。

## 驗證

1. `npm run lint`（eslint + tsc）全綠。
2. 兩個 composition 各抽關鍵幀 `npx remotion still <id> out/frame.png --frame=N`，
   檢查橫式與直式構圖正確。
3. `npx remotion render LorescapeIntro` 與
   `npx remotion render LorescapeIntroVertical` 各輸出一支 MP4 驗收。

## 不做（YAGNI）

- 不做配音／旁白（維持 BGM 機制）。
- 不做多語系字幕系統（中文為主，英文僅 over-line）。
- 不額外引進動畫函式庫（沿用 Remotion spring/interpolate）。
- 不做超過兩種比例（只橫 + 直）。
