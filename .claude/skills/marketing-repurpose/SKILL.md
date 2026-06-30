---
name: marketing-repurpose
description: Take one Lorescape daily-story 景點故事 and repurpose it into IG carousel、Reels 腳本、部落格段落、App Store what's-new、hashtag 組. The B2C content multiplier for Lorescape. Use when "repurpose this story", "turn this into posts", "content from daily story", "atomize story", "make carousel from story", "repurpose", "重新包裝故事", "把故事拆成貼文", "一文多用", "內容再利用", or any request to derive multiple Lorescape assets from a single daily story or other source piece.
---

將一則 Lorescape 景點故事拆解為多個通路素材。

> **預設來源：** 一則 `lorescape-manual-daily-story` 產製、已發佈至 Supabase 的每日景點故事（zh-TW + en）。使用者也可以提供其他來源（部落格段落、場景描述等），但每日故事是首選素材。

> **Pipeline boundary:** 本 skill 是「內容再利用」，不重新生成景點故事，也不執行 publish-reel 流程。如需產製新故事或發布 Reel，請用 `lorescape-manual-daily-story` / `publish-reel`。

## Phase 0: 載入產品脈絡

讀取專案根目錄的 `MARKETING.md`（與 CLAUDE.md 同層）。

- **存在：** 直接讀取 ─ 包含 ICP、Brand Voice、現有通路，跳過探索問題。
- **不存在：** 探索 CLAUDE.md、README.md、landing page 等取得脈絡，再問使用者確認；本 skill 不自動建立 MARKETING.md。

Brand Voice 寫作守則（從 MARKETING.md 強制執行）：
- 第二人稱「你」一致貫穿所有衍生素材
- emoji ≤ 3（全篇）
- 禁誇張語氣（「最強」「最好」「革命性」）
- 不堆條目式功能清單
- 沉靜知性、有溫度 ─ 像博學旅伴在耳邊輕聲說故事

---

## Phase 1: 來源輸入

從 MARKETING.md 取得品牌脈絡後，確認：

1. **來源故事** ─ 使用者貼上故事文本 / 指定景點名稱 / 指定日期（從 Supabase 或 `/tmp/lorescape_daily_story_draft.json` 讀取）
2. **目標素材** ─ 需要哪些衍生素材？（預設：全套，見 Phase 3）
3. **語言** ─ zh-TW 主、en 次，還是只需其中一種？

若使用者只說「repurpose 今天的故事」，預設讀取最新每日故事並產製全套素材。

## Phase 2: 故事解析

閱讀來源景點故事，提取：

| 提取元素 | 說明 |
|----------|------|
| **核心事實（1–3 條）** | 最令人驚嘆的史實或知識點 |
| **視覺場景** | 最具畫面感的段落（Reels / carousel 素材） |
| **情感時刻** | 觸動 ICP 旅行情感的句子 |
| **pull quote** | 原故事中可直接引用的金句（優先使用 card_pull_quote） |
| **地點脈絡** | 景點名稱、地點、時代（用於 hashtag 與 SEO） |

生成 `workspace/marketing-repurpose/_extraction-map.md`：

| 提取內容 | 類型 | 最適通路 | 格式 |
|----------|------|---------|------|
| 「[核心事實]」 | 知識點 | IG 貼文、carousel | 單張圖文 / carousel 頁 |
| 「[視覺場景]」 | 場景描述 | Reels 腳本 | 前 3 秒 hook |
| 「[pull quote]」 | 金句 | IG carousel 封面 | 引言頁 |
| ... | ... | ... | ... |

## Phase 3: 衍生素材產製

從一則景點故事，預設產製下列套件（可按需求增減）：

### 套件清單

| # | 素材 | 通路 | 規格 |
|---|------|------|------|
| 1 | **IG Carousel** ─ 景點知識卡 | Instagram | 5–8 張；首張封面 + 核心知識 + pull quote 結尾 |
| 2 | **IG Reels 腳本** | Instagram | 15–30 秒；hook（前 3 秒）+ 核心事實 + CTA 字幕 |
| 3 | **IG 貼文 Caption（zh-TW）** | Instagram | 150–300 字；情境開場 + 故事脈絡 + CTA |
| 4 | **IG 貼文 Caption（en）** | Instagram | 同上，英文版 |
| 5 | **部落格段落** | lorescape.app/blog | 300–500 字；展開一個核心知識點，SEO 友好 |
| 6 | **App Store What's New 文案** | App Store / Google Play | 2–3 句；以旅行體驗開場，以功能收尾 |
| 7 | **Hashtag 組** | Instagram | 5–10 個；品牌標籤 + 旅遊類 + 景點類；zh/en 混用 |

### 衍生製作規則

- 每則衍生素材**自給自足**（不假設讀者讀過原始故事）
- 不同格式用不同的 hook（即使出自同一個知識點）
- 每篇素材維持第二人稱「你」
- emoji ≤ 3（整份衍生套件的每一則各自計算）
- 不改寫史實；如需補充資訊，確認與原故事的 Wikipedia 來源一致

### 每則素材輸出格式

```markdown
# [素材編號] [格式] ─ [景點名稱]

**通路：** [IG 貼文 / Carousel / Reels 腳本 / 部落格 / App Store]
**語言：** zh-TW / en

## 內容
[完整文本]

## 視覺方向（若適用）
[Carousel 各張說明 / Reels B-roll 建議]

## 素材來源
[對應原故事的哪段 / card_pull_quote / 哪個知識點]
```

#### Carousel 結構範例

```
第 1 張：封面 ─ [景點名稱]＋[吸睛 hook 標題]
第 2 張：核心史實 #1（簡短，配圖描述）
第 3 張：核心史實 #2
第 4 張：視覺場景描述（文字＋建議圖片指示）
第 5 張：pull quote（「[原文金句]」─ [出處]）
第 6 張：CTA 頁（「開啟 Lorescape，現場聽故事 →」）
```

#### Reels 腳本結構範例

```
[0–3s] HOOK
你知道眼前這棟建築，曾經……

[3–20s] 核心事實（口語節奏，每句短）
字幕列 1
字幕列 2

[20–30s] CTA
「走到任何景點，讓 Lorescape 講故事給你聽。」
```

## Phase 4: 品質檢查

所有衍生素材完成後，發佈前執行 marketing-gate 品質檢查。

重點檢查項目：
- Four U's ≥ 10/16（IG 貼文 / Reels 腳本）；≥ 12/16（部落格段落）
- 無禁用字、無 AI slop
- 第二人稱「你」一致
- emoji ≤ 3（每則各自計算）
- 無誇張行銷語氣

## Phase 5: 發佈建議

建議交錯發佈（避免同一景點素材在短時間內重複曝光）：

| 時序 | 素材 | 說明 |
|------|------|------|
| Day 0 | 每日故事 Reel（自動） | publish-reel 處理 |
| Day 1 | IG Carousel 景點知識卡 | 深化同一景點的知識維度 |
| Day 3 | IG 貼文 Caption（情境款） | 情感切入，引導 ICP |
| Day 5–7 | 部落格段落（SEO） | 長效流量 |
| 按版本需求 | App Store What's New | 配合版本發佈 |

## 輸出結構

```
workspace/marketing-repurpose/
├── _extraction-map.md      # 故事解析提取圖
├── _source-story.md        # 原始故事副本（參考用）
├── carousel/
│   └── [place-name]-carousel.md
├── reels/
│   └── [place-name]-reels-script.md
├── captions/
│   ├── [place-name]-zh-tw.md
│   └── [place-name]-en.md
├── blog/
│   └── [place-name]-blog-para.md
├── app-store/
│   └── [place-name]-whats-new.md
├── hashtags/
│   └── [place-name]-hashtags.md
└── _quality-report.md
```
