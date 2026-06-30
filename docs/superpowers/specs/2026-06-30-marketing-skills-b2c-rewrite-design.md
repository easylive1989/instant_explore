# Lorescape 行銷 skill 套件改寫 — 設計文件

日期:2026-06-30
狀態:設計已確認,待寫實作計畫

## 背景

專案 `.claude/skills/` 下安裝了 47 個 `kai-*` 行銷 skill(來自 kai-cmo-harness),
全部已 commit 進 git。這些 skill 有三個問題:

1. **在 Mac 上是壞的** —— 每個 SKILL.md 都引用 Windows 路徑
   (`E:\Dev2\kai-cmo-harness-work\knowledge\...` 放 playbook/persona,
   `python E:\...\scripts\quality_gates\*.py` 跑品質檢查)。
2. **預設 B2B / SaaS 語境** —— ICP 是公司、談 demo / pipeline / SDR / 廣告投放,
   不符合 Lorescape 這個一人經營的 B2C 消費型 App。
3. **數量過多** —— 47 個會干擾 skill 觸發判斷,大半用不到。

本專案的真實通路:IG Reels(daily-story 自動產製)、App Store / Google Play(ASO)、
Next.js landing page(lorescape.app)、SEO/GSC、GA4。無業務團隊、不投廣告、
不走 email list、不賣 Gumroad 數位商品。

## 目標

從 49 個 kai-cmo 目錄(47 個 `kai-*` + `kai` router + `kaicalls-design`)中
**保留並改寫 15 個**、**刪除 34 個**,把保留的改寫成:
- 完全自包含(無外部 harness 路徑、無 python 腳本)
- B2C 消費型 App 語境,套用 Lorescape 真實 ICP 與品牌語氣
- 接上真實 pipeline(lorescape-metrics、daily-story、publish-reel)
- 命名前綴改為 `marketing-`

## 決策紀錄(已與使用者確認)

| 決策 | 結論 |
|---|---|
| 命名前綴 | `marketing-`(取代 `kai-`)。與產品/工程用的 `lorescape-*` 區隔,避免裸名衝突。 |
| harness 依賴 | **完全自包含改寫**。把 Four U's / 禁用字 / persona 框架直接寫進 skill 內文;品質檢查變內文 checklist。不依賴外部腳本或檔案。 |
| 待定組(11 個) | 只留 4 個:landing-page、monthly-audit、analytics、launch。其餘待定項砍掉。 |
| MARKETING.md TODO | 這次一併補。可推導的(App Store URL、價格)實作時去找;只有使用者知道的(proof points、計畫通路)提草稿給使用者確認。 |
| Git | 改動量大,開 branch 走 PR,不直接進 master。 |

## 最終保留的 15 個 skill

`kai-X` → `marketing-X`:

**核心 11:**
brand · content-calendar · seo-audit · weekly-audit · retention ·
social · repurpose · gate · competitors · cro · growth-plan

**加 4:**
landing-page · monthly-audit · analytics · launch

## 刪除的 34 個 skill

abm · ad-campaign · audit · brand-pulse · brief · budget · case-study ·
cold-outreach · daily-ad-review · data-dashboard · email-system · growth-hacker ·
html-presentation · influencer · newsletter · partnership · podcast ·
product-maker · reddit-listen · retarget · retro · sales-meeting-prep ·
sdr-operator · sdr-reply-triage · start · surround-sound · taste · topical-map ·
video · video-production · webinar · write · kai(router) · kaicalls-design

(`audit` 與 monthly-audit 重疊;`brief` 餵給已刪的 write/email-system;兩者皆刪。
`write` / `taste` 的可用精華併入 `marketing-gate`。)

## 改寫範本(套用到每個保留的 skill)

1. 目錄 `kai-X` → `marketing-X`,更新 `name:` frontmatter。
2. 移除所有 `E:\Dev2\...` 引用區塊與 `python E:\...py` 呼叫。
3. 外部 playbook / persona 引用 → 改成「從專案根目錄 `MARKETING.md` 載入產品/品牌脈絡」。
4. **B2B→B2C 重構**:SaaS/業務語言(ICP=公司、demo、pipeline)換成消費型 App 語境
   (App 使用者、App Store、RevenueCat 訂閱、IG/ASO 通路),套用 MARKETING.md 的
   Lorescape ICP 與品牌語氣(沉靜知性、第二人稱「你」、emoji ≤3 等)。
5. 品質檢查 → 引用 `marketing-gate` 內文 checklist,不再呼叫 python。
6. 資料接線(見下)。
7. description 觸發詞保留 zh-TW + en。

## 資料接線

| skill | 接到哪 |
|---|---|
| weekly-audit / monthly-audit / analytics | lorescape-metrics 的 Google Sheet(METRICS_SHEET_ID)+ GSC / GA4 / IG insights;引用 App Store / Play |
| social / content-calendar / repurpose | IG Reels + daily-story → reel → publish-reel pipeline;遵守品牌語氣 |
| seo-audit | landing page(Next.js,`landing/src/i18n/`)+ GSC |
| cro / landing-page | lorescape.app 落地頁 + App Store 轉換 |
| retention | GA4 + RevenueCat 訂閱生命週期(留存/流失) |
| gate | 共用品質基準,brand/social 等內容類 skill 都引用它 |

## marketing-gate(共用品質基準)

`kai-gate` 已近乎自包含(Four U's 表、禁用字、語氣 regex 都是內文)。改寫:
- 移除 `data/learning/gate_runs.jsonl` python log 與 `/kai-retro` 引用。
- 把外部 `algorithmic-authorship.md` 的 SEO 規則摘成內文清單(已有 5 條摘要,補足即可)。
- 語氣 regex(X-not-Y / LinkedIn slop)保留,標註主要適用英文內容(landing en、IG en caption)。
- 成為 brand / social / repurpose / content-calendar / landing-page 等內容 skill 的共用引用。

## MARKETING.md TODO 補完

現有 [TODO] 項:App Store URL、訂閱價格(weekly/monthly/yearly)、
proof points(用戶數/下載/故事生成/轉換率)、計畫通路。

- **可推導**:App Store URL、價格 → 實作時從 repo / App Store / RevenueCat 設定查。
- **僅使用者知道**:proof points 是否公開真實數字、計畫通路清單 → 提草稿給使用者確認後填。

## 執行順序(偏好小步驟)

1. 刪除 32 個 `kai-*` 目錄(一次 commit)。
2. 補完 MARKETING.md TODO(可推導項先填,使用者確認項後填)。
3. 先改寫 `marketing-gate`(共用基準,其他 skill 會引用它)。
4. 其餘 14 個逐一改名 + 改寫,分批 commit(例:audit 類一批、content 類一批、
   strategy 類一批)。每批改完掃一次有無殘留 `E:\` 路徑或 B2B 語言。
5. 最後驗證:全套 skill 內無 `kai-` 殘留、無 Windows 路徑、description 觸發詞正確。

## 非目標(YAGNI)

- 不重建 kai-cmo-harness 的 python 品質腳本(改成內文 checklist)。
- 不還原被刪的 32 個 skill 的任何功能。
- 不改動 `~/Documents/Github/marketing/kai-cmo-harness` 本機 clone(僅作參考來源)。
- 不新增廣告 / email / SDR 相關能力。
