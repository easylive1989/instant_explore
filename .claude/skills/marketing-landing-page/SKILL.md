---
name: marketing-landing-page
description: lorescape.app 落地頁文案撰寫與審查 — 為 lorescape.app（Next.js 雙語落地頁）產生完整頁面文案，或審查現有文案，依 MARKETING.md 的 value prop 與 differentiators 對應到 dictionaries.ts 的雙語結構（zh/en）。CTA = App Store / Google Play 下載。Use when "landing page", "落地頁", "LP 文案", "hero section", "write landing page copy", "review landing page", "改落地頁", "App Store CTA", or any request to write or review lorescape.app page copy. Descriptions trigger bilingual output (English + zh-TW).
---

為 lorescape.app 撰寫或審查落地頁文案。產出可直接對應 `dictionaries.ts` 的雙語段落（zh/en）。

## Phase 0: 載入產品脈絡

讀 **`MARKETING.md`**（專案根目錄）— 取得：

- **Value Prop（主）：** 任何景點，一鍵生成有溫度的真實故事，並以純淨語音朗讀——讓你抬頭看世界，耳邊有故事。
- **Differentiators：** Wikipedia grounding、2–3 故事角度自選、逐句高亮語音、每日故事推播、文化足跡日誌。
- **ICP：** 25–45 歲深度知性旅人，自由行，台灣為核心，兼顧全球華語與英語旅人。
- **Brand Voice：** 沉靜、知性、有溫度。第二人稱「你」，情境開場，強調「史實為本」。不用誇張語氣，不堆砌功能清單。

目標 URL：**`https://lorescape.app`**
文案對應：`landing/src/i18n/dictionaries.ts`（`Dict` interface）
CTA：App Store（`https://apps.apple.com/tw/app/讀景/id6751904060`）與 Google Play（`https://play.google.com/store/apps/details?id=com.paulchwu.instantexplore`）下載按鈕。

---

## Phase 1: 任務確認

從 `MARKETING.md` 讀取。只詢問以下未涵蓋項目：

1. **任務類型** — 全頁新寫、局部改寫，或純審查？
2. **目標區塊** — 全頁 / hero / manifesto / 特定 section？
3. **流量來源** — 冷（廣告）、暖（內容/SEO）、熱（口碑/轉推）？影響 awareness level。
4. **可用社會證明** — 下載數、使用者評語、媒體報導（若有）？
5. **語言優先** — zh-TW 先寫再翻 en，或同步雙語？

## Phase 2: 頁面架構規劃

產出 wireframe（段落順序）後才開始撰寫文案：

### lorescape.app 標準頁面結構

對應 `dictionaries.ts` 的 `Dict` key：

| Section | Dict key(s) | 目的 | 感知層次 |
|---------|-------------|------|----------|
| **Hero** | `hero.*` | 情境開場 + 主承諾 + CTA | 感知 — 觸發「站在景點前」的畫面 |
| **Manifesto** | `manifesto.*` | 知性宣言，建立情感連結 | 感知 — 讓深度旅人認出自己 |
| **Local Stories** | `localStories.*` | 展示故事深度範例 | 脈絡 — 讓「即時生成」不抽象 |
| **Many Angles** | `manyAngles.*` | 2–3 視角自選，強調自由 | 脈絡 — 差異化：非單一制式內容 |
| **Features / Benefits** | （其他 Dict key）| 以結果語言說功能 | 脈絡 — Wikipedia grounding、語音高亮 |
| **Daily Story** | （推播功能區塊）| 養成每日習慣 | 許可 — 降低下載門檻 |
| **CTA** | `storeButtons.*`、`nav.downloadApp` | App Store / Google Play | 許可 — 明確行動 |

### 審核閘門

在撰寫文案前，先呈現 wireframe 請使用者確認。

### Hero 文案試驗室（新寫時執行）

產出 3 個 hero 角度，每個包含：headline、subhead、CTA 文字、適合的流量來源。
評分標準（各 1–5 分）：ICP 契合度、清晰度、可驗證性、差異化、CTA 轉換力。
僅將總分 20/25+ 的角度帶入正式文案。

## Phase 3: 文案撰寫

### 雙語格式要求

每個 `Dict` key 同時輸出 zh-TW 與 en：

```typescript
// 範例輸出格式（對應 dictionaries.ts）
hero: {
  pill: "zh: ...",          // en: "..."
  headlineTop: "zh: ...",   // en: "..."
  headlineClay: "zh: ...",  // en: "..."
  lede: "zh: ...",          // en: "..."
}
```

### Brand Voice 執行規則

- **第二人稱「你」**：中文全程使用，英文使用 "you"。
- **情境開場**：Hero/manifesto 以「當你站在…」「你曾走過…」等畫面感句型起始。
- **史實為本**：每處提及故事生成，附帶「Wikipedia 事實驗證」或「grounded in Wikipedia」。
- **句子長度**：中文 ≤ 40 字元，英文 ≤ 20 words。
- **CTA 文字**：動作動詞 + 結果（「免費下載，出發就用」非「立即下載」）。

### 禁用模式（配合 MARKETING.md Brand Voice Don'ts）

- 禁用誇張語氣詞：「最強」「最好」「革命性」
- 禁用條目式功能堆砌
- 英文禁用 AI slop 句型（"In today's rapidly evolving..."）
- 英文禁用 X-not-Y 句型（marketing-gate §3）
- 每篇最多 3 個 emoji

### CTA 規格

- 主 CTA = App Store + Google Play 雙按鈕（`storeButtons.ios` / `storeButtons.android`）
- 每個 section 一個 CTA 指向同一目標（下載），用詞各異
- 不使用 signup / checkout / demo request 等 B2B 用語

## Phase 4: 品質關卡

完稿後執行 **marketing-gate**（完整 pipeline）：

1. Four U's ≥ 12/16（落地頁全頁分數）
2. 禁用字 = 零違規
3. AI slop = 零違規
4. Voice Pattern regex（英文文案）
5. SEO Lint（若文案含搜尋目標關鍵字）
6. 每段落一個 CTA，指向同一下載目標
7. 每個功能主張有對應的 proof（Wikipedia grounding、角度自選、日誌匯出等）

## Phase 5: 輸出格式

```markdown
# lorescape.app 落地頁文案：[任務描述]

## Meta
- **目標受眾：** [ICP persona]
- **流量來源：** [cold/warm/hot]
- **任務：** [新寫/改寫/審查]
- **語言：** zh-TW + en

## Hero（dictionaries.ts: hero.*）
zh-TW:
- pill: ...
- headlineTop: ...
- headlineClay: ...
- lede: ...
en:
- pill: ...
- headlineTop: ...
- headlineClay: ...
- lede: ...

## Manifesto（dictionaries.ts: manifesto.*）
zh-TW: ...
en: ...

## [其他 Dict sections，逐一對應]

## CTA（dictionaries.ts: storeButtons.*, nav.downloadApp）
zh-TW: ...
en: ...

## Quality Gate Results
[marketing-gate 輸出]
```

若為審查任務，改以 before/after 表格輸出，每行標注 Dict key。
