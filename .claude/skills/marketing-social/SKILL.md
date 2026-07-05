---
name: marketing-social
description: Plan and batch-produce Lorescape Instagram content — 貼文 captions、Reels 腳本、hashtag 組、App Store 行銷文案。專注人工補充貼文與 caption / hashtag 策略，不重造每日景點故事 Reel 自動流程。Use when "social posts", "IG caption", "Instagram content", "hashtag strategy", "reels script", "social media posts", "App Store copy", "社群貼文", "Instagram 文案", "Reels 腳本", "hashtag 策略", or any request to produce or plan Instagram or App Store marketing copy for Lorescape.
---

Plan and batch-produce Instagram-first social content for Lorescape.

> **Pipeline boundary:** 每日景點故事 Reel 由 `lorescape-manual-daily-story` 自動產製、`publish-reel` 發布。本 skill 處理的是「人工補充」的社群貼文 ─ 例如品牌宣傳貼文、campaign caption、hashtag 策略、App Store 行銷文案 ─ 不重造每日 pipeline。如需操作每日故事或發布 Reel，請改用 `lorescape-manual-daily-story` / `publish-reel`。

## Phase 0: 載入產品脈絡

讀取專案根目錄的 `MARKETING.md`（與 CLAUDE.md 同層）。

- **存在：** 直接讀取 ─ 包含產品名稱、ICP、價值主張、Brand Voice、現有通路、競品分析，跳過探索問題。
- **不存在：** 探索 CLAUDE.md、README.md、landing page 等取得脈絡，再問使用者確認；本 skill 不自動建立 MARKETING.md。

重點提醒（從 MARKETING.md 取得）：
- **ICP：** 25–45 歲深度知性旅人，渴望城市靈魂與景點文化脈絡
- **Brand Voice：** 沉靜、知性、有溫度；第二人稱「你」；每篇最多 3 個 emoji；禁誇張語氣（「最強」「最好」「革命性」）
- **主力通路：** Instagram（貼文 + Reels）、App Store / Google Play

---

## Phase 1: 需求確認

從 MARKETING.md 取得後，只問 MARKETING.md 未涵蓋的項目：

1. **內容類型** ─ 一般品牌貼文？campaign 系列？App Store 更新文案？
2. **時間範圍** ─ 單篇、一週批次、或一個月？
3. **主題 / 素材** ─ 是否有現有故事、截圖、用戶回饋可用？
4. **語言** ─ 繁體中文、英文、雙語？（預設：zh-TW 主、en 次）

## Phase 2: 內容規劃

根據需求決定批次規模，規劃 Instagram 貼文行事曆草表：

| 日期 | 格式 | 主題 | 語言 | 狀態 |
|------|------|------|------|------|
| mm/dd | 貼文 caption | 品牌故事 | zh-TW | 草稿 |
| mm/dd | Reels 腳本 | 景點亮點 | zh-TW+en | 草稿 |
| mm/dd | App Store 文案 | 功能亮點 | zh-TW | 草稿 |

### 內容主軸比例（Lorescape B2C）

- **40% 旅行體驗啟發** ─ 觸發 ICP 的「我也想這樣旅行」情境
- **25% 產品功能展示** ─ 以故事帶出功能，而非功能清單
- **20% 用戶故事 / 社群互動** ─ UGC 引導、問答、景點問題
- **15% 品牌人格** ─ 每日故事系列背後的理念、設計思考

**審核關卡：** 呈現規劃表，等使用者確認後再進入 Phase 3。

## Phase 3: 批次產製

### Instagram 貼文 Caption

- 首行 hook（before "...more"）：情境起手，不用功能清單
- 內文：150–300 字；以「你」直接對話；以情境觸發情感共鳴
- 結尾 CTA：一個行動呼籲（例：「開啟 Lorescape，讓下次旅行不一樣」）
- Emoji：≤ 3 個，克制使用
- Hashtag 組：5–10 個，中英混用，分層（品牌標籤 + 旅遊類 + 景點類）

### Instagram Reels 腳本

- Hook（前 3 秒）：強視覺 / 強問題（例：「你知道眼前這棟建築藏著什麼秘密嗎？」）
- 內容弧線：15–60 秒；起 / 承 / 合；口語化節奏
- 結尾：CTA 字幕（「聽 Lorescape 說故事 ↓」）
- 搭配 caption 說明腳本對應的 B-roll 素材方向

### App Store 行銷文案

- 主標：≤ 15 字（zh-TW）/ ≤ 30 chars（en）；不堆功能
- 副標 / What's New：2–3 句，以旅行體驗開場，以功能收尾
- 禁：條目式清單、「最強 AI」等誇張語氣

### 每篇輸出格式

```markdown
# [格式] ─ [日期] ─ [主題]

**語言：** zh-TW / en
**Hook：** [首行 / 前 3 秒]

## 正文
[完整內容]

## Hashtag
[#tag1 #tag2 ...]

## 視覺方向
[簡述搭配素材或 B-roll]

## 發佈注意
- 建議時段：[時間]
- 跨貼：[是否同步 App Store / FB]
```

## Phase 4: 品質檢查

完成草稿後，發佈前執行 marketing-gate 品質檢查。

檢查重點：
- Four U's ≥ 10/16（社群貼文）
- 無禁用字、無 AI slop
- 無誇張行銷語氣（「最強」「最好」「革命性」）
- 第二人稱「你」一致
- Emoji ≤ 3

## Phase 5: 輸出

```
marketing/marketing-social/
├── _calendar.md          # 整體規劃表
├── ig-captions/
│   ├── yyyy-mm-dd.md
│   └── ...
├── reels-scripts/
│   ├── yyyy-mm-dd.md
│   └── ...
├── app-store/
│   └── what-is-new.md
└── _quality-report.md
```
