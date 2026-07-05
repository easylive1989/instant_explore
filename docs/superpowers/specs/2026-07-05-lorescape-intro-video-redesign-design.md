# Lorescape 介紹影片重製 —「城市是一本書」設計

日期：2026-07-05
狀態：已核可，待寫實作計畫

## 背景與目標

`demo/` 現存一支 Remotion 製作的 Lorescape App 介紹影片（30s、雙比例）。
其視覺色票已對齊 landing／`docs/design`，但分鏡與片中的手機 UI 是一套自製
mockup，與 `docs/design` 最新精緻化的 app 畫面不一致。

本次重製要做兩件事：

1. **連分鏡敘事一起重想**——改採「城市是一本書」隱喻主導的敘事骨架。
2. **高忠實重建片中 app 畫面**——探索、故事選項、沉浸閱讀器、田野手記等
   關鍵畫面，依 `docs/design/project/app/` 的排版、字體、間距、真實文案在
   Remotion 內用 code 精緻重建，讓「片中的 app＝真正的新設計」。

## 規格決策（已與使用者確認）

| 項目 | 決策 |
|------|------|
| 重設範圍 | 連分鏡敘事一起重想（等於全新影片） |
| 主要用途 | 落地頁 / YouTube Hero，電影感、步調較慢 |
| 比例 | **16:9 主力 + 9:16 直版都要** |
| 長度 | 約 30 秒、30fps、900 frames |
| 聲音 | 靜音也完整 + BGM 槽（`public/bgm.mp3` 存在才掛 `<Audio>`） |
| 文案語言 | 繁體中文為主（Noto Serif TC 襯線），拉丁小字點綴 |
| 敘事骨架 | 「城市是一本書」隱喻主導，app 畫面作為視覺插圖與節拍點綴 |
| 片中畫面忠實度 | 高忠實重建 `docs/design` 關鍵畫面 |

## 敘事分鏡（6 幕，已核可）

母題：城市＝一本書。宣言 4 句 + slogan，紙白↔深底交錯，聖伯多祿大殿貫穿。

| # | 幕 | frames | 秒 | 內容重點 | 對齊畫面 |
|---|----|--------|----|---------|---------|
| Ⅰ | 開場 | 0–150 | 0–5 | 深墨底浮出宣言「抬起眼睛，世界本身就是一本書。」不出現 UI | 純文字 + 紙紋/金光 |
| Ⅱ | 地標登場 | 150–330 | 5–11 | 聖伯多祿實景淡入，手機自下方升起帶出探索畫面。「每一個地方，都是一則等待被讀的故事。」 | `ExploreMockup`（screens_explore） |
| Ⅲ | 一書多章 | 330–510 | 11–17 | 同一地標三個故事角度卡如章節目錄依序亮起。「同一座教堂，藏著三種讀法。」 | `StoryOptionsMockup`（screens_story · STORY_OPTIONS） |
| Ⅳ | 沉浸聆聽 | 510–690 | 17–23 | 切入深底沉浸式閱讀器：襯線正文、dropcap、聲紋律動。「戴上耳機，讓城市對你朗讀。」 | `ReaderMockup`（immersive reader） |
| Ⅴ | 旅程成冊 | 690–810 | 23–27 | 田野手記／歷史畫面，讀過的故事自動歸檔成篇章。「你走過的地方，正在寫成一本書。」 | `JournalMockup`（screens_history） |
| Ⅵ | CTA | 810–900 | 27–30 | 品牌標準字 + slogan「城市是一本書。開始閱讀吧。」+ 商店徽章 | `Wordmark` / `StoreBadges` |

轉場以紙感為母題：翻頁位移、紙白↔深底交錯、手機升降用 spring；宣言文字用
`interpolate` 淡入 + 微幅上移。

## 架構

沿用現有 `demo/` Remotion 專案，保留 `package.json`、tailwind、
`@remotion/google-fonts` 設定；改寫 scenes 與 mockups。

```
demo/src/
├─ Root.tsx            # 註冊 LorescapeIntro(1920×1080) + LorescapeIntroVertical(1080×1920)
├─ Main.tsx            # <Audio>（可選）+ 6 個 <Sequence>
├─ theme.ts            # 既有 tokens + 移植 ls2.css 的分類色票與 radius
├─ data.ts            # 移植 docs/design/project/app/data.jsx 的真實文案
├─ scenes/
│  ├─ HookScene.tsx        # Ⅰ 開場宣言
│  ├─ ExploreScene.tsx     # Ⅱ 地標登場
│  ├─ AnglesScene.tsx      # Ⅲ 一書多章
│  ├─ ReaderScene.tsx      # Ⅳ 沉浸聆聽
│  ├─ JournalScene.tsx     # Ⅴ 旅程成冊
│  └─ CtaScene.tsx         # Ⅵ CTA
├─ components/
│  ├─ PhoneFrame.tsx       # 依 ls2 .phone（390×844、圓角 54、notch、status bar）忠實還原外框
│  ├─ Wordmark.tsx
│  ├─ StoreBadges.tsx
│  ├─ Waveform.tsx
│  ├─ PaperBackdrop.tsx    # 紙白/深底背景 + 紙紋
│  └─ mockups/
│     ├─ ExploreMockup.tsx       # 地標卡 + 分類 chips + 拉丁副標
│     ├─ StoryOptionsMockup.tsx  # 三張故事角度卡
│     ├─ ReaderMockup.tsx         # 深底襯線正文 + dropcap + 聲紋播放器
│     └─ JournalMockup.tsx        # 田野手記篇章列表
└─ utils/
   ├─ layout.ts           # useOrientation() 與尺規，供橫/直版共用
   └─ animations.ts       # 共用 easing / spring helper
```

### 元件職責

- **PhoneFrame**：只負責 iPhone 外框與狀態列，內容以 children 注入；不知道自己裝的是哪個 mockup。
- **各 Mockup**：純呈現，資料由 props 傳入（取自 `data.ts`）；可獨立以 still 幀檢視。
- **各 Scene**：負責該幕的版面、動畫時間軸、以及橫/直版排列；組合 PhoneFrame + mockup + 宣言文字。
- **data.ts**：單一事實來源，移植 docs/design 的 `STORY_OPTIONS`、`STORIES`、`PLACES`、分類定義。

## 雙比例處理（16:9 + 9:16）

每個 scene 透過 `useVideoConfig()` 由 `width > height` 判斷方向，經
`utils/layout.ts` 的 `useOrientation()` 取得：

- **橫版（16:9）**：宣言文字與手機左右並置，或置中大字 + 手機。
- **直版（9:16）**：垂直堆疊，手機置中、宣言在上或下。

隱喻型電影感橫版不會自動 reflow 成直版，故各 scene 需針對兩種方向各寫一套
版面，但共用同一組動畫時間軸與 mockup 元件。

## 素材與字體

- 真實地標照已在 `demo/public/images/`（stpeters、temple、agra、park）；
  缺的（如 ahwar）由 `docs/design/project/site/img/` 複製進 `public/images/`。
- 字體用 `@remotion/google-fonts` 的 NotoSerifTC / NotoSansTC（已設定）。
- BGM：`public/bgm.mp3` 存在才掛 `<Audio volume={0.8}>`，不存在照常無聲渲染。

## 驗證

Remotion 無傳統單元測試，改以：

1. `cd demo && npm run lint`（eslint + `tsc`）零錯誤。
2. `npx remotion still` 對兩個 composition 各抓每幕代表幀 PNG 目視檢查
   （建議每幕取進場、穩定、出場三幀）。
3. 可選 `npx remotion render` 輸出兩支 mp4 做完整確認。

## 非目標（YAGNI）

- 不加旁白／TTS（本輪只做靜音 + BGM 槽）。
- 不做付費牆、onboarding 幕（保持 6 幕精簡）。
- 不改動 landing 或 app 本體，只重製 `demo/` 影片。
- 不重寫 `theme.ts` 既有 tokens，只增補分類色與 radius。
