---
name: marketing-seo-audit
description: lorescape.app 技術 SEO 審計 — 對 lorescape.app（Next.js 雙語落地頁）執行完整技術 SEO 稽核，含可抓取性、索引、Core Web Vitals、結構化標記、內部連結、行動裝置 UX、雙語內容品質。產出優先修復清單。Use when "SEO audit", "technical SEO", "site audit", "crawl issues", "indexation problems", "why aren't we ranking", "SEO health check", "SEO 稽核", "排名問題", "搜尋流量", or any request to diagnose SEO issues on lorescape.app. Descriptions trigger bilingual output (English + zh-TW).
---

對 lorescape.app 執行技術 SEO 稽核。產出優先修復清單。

## Phase 0: 載入產品脈絡

讀 **`MARKETING.md`**（專案根目錄）— 包含產品名稱、ICP、品牌語氣、目標頻道與競爭定位。略過已涵蓋的發現問題。

目標站台固定為 **`https://lorescape.app`**，Next.js 雙語落地頁（zh/en）。
文案來源：`landing/src/i18n/dictionaries.ts`。

---

## Phase 1: 稽核範圍確認

從 `MARKETING.md` 讀取。只詢問以下未涵蓋項目：

1. **範圍** — 全站或特定頁面（landing、/blog 等）？
2. **已知問題** — 使用者已發現或懷疑的問題？
3. **重點** — 排名、流量、索引、速度？
4. **Search Console 存取** — 是否已透過 `lorescape-metrics` 取得 GSC 資料？

## Phase 2: 資料取得

### Search Console 資料（GSC）

執行 **`lorescape-metrics`** skill 抓取 GSC 資料（`gsc` 分頁）：
- 每日 clicks / impressions / CTR / position
- 找出點擊率低但曝光高的頁面 → 優化機會
- 找出 position 介於 8–20 的關鍵字 → 衝進前五

若 GSC 資料尚未同步，先呼叫 lorescape-metrics 補抓缺口，再繼續稽核。

### 公開觀察資料

可用工具（PageSpeed Insights、Chrome DevTools、Lighthouse）觀察並記錄：
- Core Web Vitals（LCP、INP、CLS）
- HTTPS 狀態、robots.txt、sitemap.xml
- 結構化資料（JSON-LD）

每筆資料附來源後設資料：

```yaml
source_tier: connected | public_observed | user_provided | missing_data
source_name: ""
retrieved_at: ""
confidence: high | medium | low
```

缺少的私有資料標記為 `missing_data`，不得估算。

## Phase 3: 稽核執行

### Layer 1: 可抓取性與索引

- robots.txt — 是否封鎖重要頁面？
- XML sitemap — 是否存在、已提交、是否最新？
- Canonical tags — 是否正確且一致（zh vs en 雙語版本）？
- Noindex/nofollow — 是否有非預期封鎖？
- HTTP 狀態碼 — 404、redirect chains、5xx？
- hreflang — 雙語頁面（zh/en）的語言標記是否正確？

### Layer 2: 技術效能

- Core Web Vitals（LCP、INP、CLS）
- 行動裝置友善性（關鍵：ICP 以行動裝置為主）
- 頁面速度（伺服器回應時間、render-blocking 資源）
- HTTPS — 混合內容、憑證問題？
- 結構化資料 / schema markup — 存在且有效？

### Layer 3: 頁面 SEO

- Title tags — 唯一、含關鍵字、< 60 字元？（zh/en 各語言版本）
- Meta descriptions — 唯一、吸引人、< 155 字元？
- H1 tags — 每頁一個、與關鍵字相關？
- Image alt text — 描述性、含關鍵字？
- 內部連結 — 孤兒頁面、淺層連結深度？
- URL 結構 — 乾淨、描述性、扁平層級？

### Layer 4: 內容品質（雙語）

lorescape.app 為雙語站（zh/en），文案在 `landing/src/i18n/dictionaries.ts`，
對照 `Dict` 結構的各 key 審查：

- `hero`：headlineTop / headlineClay / lede — 是否有 zh/en 對應？是否符合 MARKETING.md 的主 value prop（「任何景點，一鍵生成有溫度的真實故事」）？
- `manifesto`：語氣是否符合 MARKETING.md Brand Voice（沉靜、知性、有溫度）？
- `localStories`、`manyAngles` 等區塊：是否清楚傳達 differentiators？
- 薄內容頁面（< 300 字）
- 重複內容（zh/en 頁面是否有非預期的完全重疊）
- 關鍵字蠶食（多頁競爭同一關鍵字）

### Layer 5: 外部信號

- 反向連結概覽（如資料可得）
- 品牌提及但無連結
- App Store / Google Play 列表頁 ← 不納入 lorescape.app 核心稽核，但可作為 off-page 信號

## Phase 4: SEO Lint（搜尋內容）

對 `dictionaries.ts` 文案或任何新增的 SEO 內容，執行 **marketing-gate** 的 SEO Lint 段（§4）— 5 條 Algorithmic Authorship 規則：

1. 條件子句放句末
2. 指示句以動詞起始
3. 句子不超過 20 字（中文 40 字元）
4. 粗體標記答案，不標記查詢詞
5. 段落首句不置連結

**整體品質：** 執行 marketing-gate 完整 pipeline。

## Phase 5: 優先修復清單

| 優先 | 影響 | 工時估算 | 範例 |
|------|------|----------|------|
| **P0** | 高影響、快速修復 | < 1 小時 | 缺 title、canonical 錯誤、重要頁 noindex |
| **P1** | 高影響、中度工作 | 1 天 | CWV 失敗、redirect chains、hreflang 錯誤 |
| **P2** | 中度影響 | 1 週 | Schema markup、內部連結優化 |
| **P3** | 低影響 | 持續 | Alt text 缺口、URL 整理 |

## Phase 6: 輸出格式

```markdown
# SEO 稽核報告：lorescape.app

稽核日期：[YYYY-MM-DD]
GSC 資料範圍：[from – to]（via lorescape-metrics）

## 健康分數：[X]/100

## 關鍵問題（P0）
| 問題 | 影響頁面 | 修復方式 |
|------|----------|----------|

## 高優先（P1）
...

## 中優先（P2）
...

## 低優先（P3）
...

## 技術清單
- [ ] robots.txt：[PASS/FAIL — 細節]
- [ ] XML sitemap：[PASS/FAIL]
- [ ] hreflang（zh/en）：[PASS/FAIL]
- [ ] Canonical tags：[PASS/FAIL]
- [ ] Core Web Vitals：[PASS/FAIL — LCP: Xs, INP: Xms, CLS: X]
- [ ] 行動裝置：[PASS/FAIL]
- [ ] HTTPS：[PASS/FAIL]
- [ ] Schema：[PASS/FAIL]
- [ ] Title tags：[PASS/FAIL]
- [ ] 內部連結：[PASS/FAIL]

## 優化機會（來自 GSC）
[點擊率低但曝光高的關鍵字；position 8–20 的衝榜機會]

## 雙語內容評估（dictionaries.ts）
[zh/en 對應品質、hero/manifesto 是否符合 value prop]

## 資料來源
[每筆來源附 source_tier、retrieved_at]

## 資料缺口
[限制信心的缺少存取或匯出]
```
