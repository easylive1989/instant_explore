---
name: marketing-content-calendar
description: Plan a Lorescape content calendar — aligns to the daily-story rhythm and weekly 景點故事 series. Covers IG 貼文/Reels、SEO 部落格、App Store 更新文案, mapped to MARKETING.md ICP and planned channels. Use when "content calendar", "monthly content plan", "editorial calendar", "content schedule", "what should we publish", "content strategy", "內容行事曆", "月份內容規劃", "發佈行程表", or any request to plan multiple Lorescape content pieces over time.
---

為 Lorescape 規劃 Instagram-first 的內容行事曆，對齊每日景點故事節奏與品牌通路。

> **Pipeline boundary:** `lorescape-manual-daily-story` 每天產製一則景點故事 Reel（每日固定節奏）。本 skill 在這個自動節奏「之上」規劃補充內容 ─ 品牌貼文、SEO 部落格、App Store 更新文案 ─ 讓每日故事與人工內容形成有機的月度內容矩陣。**不替代、不重造每日景點故事 pipeline。**

## Phase 0: 載入產品脈絡

讀取專案根目錄的 `MARKETING.md`（與 CLAUDE.md 同層）。

- **存在：** 直接讀取 ─ 包含 ICP、Brand Voice、現有通路、計畫通路，跳過探索問題。
- **不存在：** 探索 CLAUDE.md、README.md、landing page 等取得脈絡，再問使用者確認；本 skill 不自動建立 MARKETING.md。

從 MARKETING.md 提取的規劃依據：
- **ICP：** 25–45 歲深度知性旅人，以台灣用戶為核心，兼顧全球華語與英語旅人
- **現有通路：** Instagram、官網、App Store、Google Play
- **計畫通路：** SEO 部落格（lorescape.app/blog）、YouTube Shorts、TikTok
- **Brand Voice：** 沉靜知性、第二人稱「你」、emoji ≤ 3、禁誇張語氣

---

## Phase 1: 策略確認

從 MARKETING.md 取得後，只問未涵蓋的項目：

1. **時間範圍** ─ 一個月 / 一季？（預設：一個月）
2. **SEO 目標關鍵字** ─ 是否有既有關鍵字研究？
3. **App Store 節奏** ─ 本月是否有版本更新需要 What's New 文案？
4. **特殊活動 / 節日** ─ 是否有旅遊旺季、節慶、景點話題要搭配？

## Phase 2: 內容地圖

### 每日節奏基礎（自動 pipeline，本 skill 不觸碰）

| 每日 | 頻道 | 內容 | 產製方式 |
|------|------|------|----------|
| 每天 08:00 | 後端 / App | 當日景點故事（zh-TW + en） | lorescape-manual-daily-story |
| 每天 21:00 | Instagram Reels | 景點故事 Reel | publish-reel（Discord ✅ 觸發） |

### 補充內容層（本 skill 負責規劃）

在每日故事節奏「之上」，本 skill 規劃以下三類內容：

#### A. Instagram 品牌補充貼文（每週 1–2 則）

主題建議：
- **週一：景點知識系列** ─ 從本週故事提煉一個「你可能不知道的事實」
- **週四：ICP 情境啟發** ─ 觸發「我也想這樣旅行」的情境貼文
- **視需求：** 用戶故事、UGC 轉發、App 更新公告

#### B. SEO 部落格（每月 2–4 篇）

目標：lorescape.app/blog，針對「深度旅遊 + AI 導覽」關鍵字

文章類型：
- **景點深度指南：** 擴充自每日故事的某個景點，3,000+ 字
- **旅行方式：** 「如何用 Lorescape 規劃深度旅行」等操作指南
- **知識型：** 「城市歷史 / 文化脈絡」類文章，建立主題權威

#### C. App Store / Google Play 更新文案（按版本節奏）

- What's New：2–3 句，以旅行體驗開場
- 關鍵詞優化（ASO）：對齊 ICP 搜尋意圖

### 月度內容行事曆表

生成 `workspace/marketing-content-calendar/_content-map.md`：

| 週 | 日期 | 內容標題 | 格式 | 通路 | 主題 | 語言 | 優先級 |
|----|------|----------|------|------|------|------|--------|
| W1 | 週一 | 每日景點故事（自動） | Reels | IG | 景點系列 | zh-TW+en | ─ |
| W1 | 週二 | [品牌補充貼文] | 貼文 | IG | ICP 情境 | zh-TW | P1 |
| W1 | 週四 | [知識型貼文] | 貼文 | IG | 景點知識 | zh-TW | P1 |
| W2 | 週一 | [SEO 部落格草稿] | 部落格 | 官網 | 深度旅遊指南 | zh-TW | P0 |
| ... | ... | ... | ... | ... | ... | ... | ... |

### 主題叢集（SEO 用）

```
主題柱：AI 旅行說書人
├── 子主題：如何在旅行中使用 Lorescape — 目標關鍵字「旅遊 AI 導覽」
├── 子主題：台灣景點冷知識系列 — 目標關鍵字「台灣古蹟介紹」
└── 子主題：深度旅行方式指南 — 目標關鍵字「深度旅遊規劃」
```

### 候選內容評分（Kill List）

建立 `workspace/marketing-content-calendar/_idea-eval.md`：

| 構想 | 通路 | 分數 (0–25) | 決定 | 原因 |
|------|------|------------|------|------|
| ... | ... | ... | keep/hold/kill | ... |

評分維度（各 1–5 分）：
- **Business fit**：符合 MARKETING.md 目標
- **ICP pain**：對應 ICP 的旅行痛點
- **Proof available**：有故事素材 / 截圖 / 用戶回饋
- **Channel fit**：適合預計格式與通路
- **Novelty**：比競品或泛旅遊內容多出資訊增益

**20–25：收入；15–19：待補充素材後再排；0–14：移除**

**審核關卡：** 呈現內容地圖，等使用者確認主題、日期、格式後再進行 Phase 3。

## Phase 3: 內容 Brief

為行事曆中每篇 P0/P1 內容產製 Brief：

```markdown
## Brief: [標題]

- **格式：** [IG 貼文 / Reels / 部落格 / App Store]
- **通路：** [IG / 官網 / App Store]
- **語言：** zh-TW / en
- **目標關鍵字（SEO）：** [若適用]
- **ICP 痛點：** [對應 MARKETING.md ICP 的哪個痛點]
- **Hook 變體（3 個）：**
  1. [情境式 hook]
  2. [知識型 hook]
  3. [問句型 hook]
- **核心論點：** [一句話說清楚這篇要傳達什麼]
- **素材 / 來源：** [每日故事景點 / 用戶回饋 / Wikipedia 事實]
- **CTA：** [具體行動呼籲]
```

## Phase 4: 批次產製（選用）

若使用者要求直接產製內容（而非只做規劃），按以下優先序執行：

1. **IG 補充貼文 / Reels 腳本** → 交給 `marketing-social` 流程
2. **SEO 部落格** → 按 Brief 展開，遵守 SEO Lint 規則（見 marketing-gate）
3. **App Store 文案** → 短文案優先，配合版本發佈節奏

**發佈前執行 marketing-gate 品質檢查**（所有格式）。

## Phase 5: 分發備忘

生成 `workspace/marketing-content-calendar/_distribution.md`：
- 哪些 SEO 部落格可截短為 IG 貼文（交 marketing-repurpose 處理）
- App Store 更新文案與 IG 公告的對應關係
- 每月景點故事系列的 Hashtag 策略（固定標籤 + 輪換標籤）

## 輸出結構

```
workspace/marketing-content-calendar/
├── _content-map.md         # 完整月度行事曆
├── _idea-eval.md           # 候選內容評分
├── briefs/
│   ├── w1-slug.md
│   └── ...
├── drafts/                 # Phase 4 產製的草稿
│   └── ...
├── _distribution.md        # 分發備忘
└── _quality-report.md
```
