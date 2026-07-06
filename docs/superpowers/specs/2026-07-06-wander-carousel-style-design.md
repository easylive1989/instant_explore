# Wander 風格 IG Carousel（可選風格）設計

日期：2026-07-06
狀態：已與使用者確認方向（方案 A：Supabase Storage + Discord 審核 + 21:00 publisher 發布）

## 背景與目標

現有 IG carousel 只有一種風格：`social/card/` 的三頁式（cover / story / cta），
由 server 在 21:00 依 `daily_stories.card_*` 欄位渲染發布。

本設計新增第二種可選風格「**wander**」，仿
`docs/ig/ig-post-example/`（wanderwithann 的茜茜公主圖組）的
「第三人稱人物敘事 + 暗色壓字」風格：7–9 頁、每頁一張不同背景實拍照、
劇情節拍式短句文案。使用者可以逐日選擇當天要發預設風格（不做事，
維持現行自動流程）或 wander 風格（走本設計的手動產製流程）。

### 已確認的需求決策

| 決策點 | 結論 |
|---|---|
| 接入點 | 手動流程優先（`lorescape-manual-daily-story` 之後的本機產製），server 只加一個發布分支 |
| 照片來源 | 使用者手動指定本機照片資料夾（每頁一張，Claude 只負責配頁與排版） |
| 文案來源 | Claude 現場寫 7–9 拍分頁文案（可參考既有 daily story + 額外研究），使用者審稿後才渲染 |
| 發布路徑 | 本機渲染 → 上傳 Supabase `ig-cards` bucket → Discord 圖組送審 → 21:00 publisher 發布（IG carousel API 只收公開 URL，不收檔案上傳） |
| Storage 額度 | 新增每月歸檔 script：下載到本機（使用者自行備份到 Google Drive）後刪除 bucket 舊物件 |

## Wander 風格規格

### 敘事結構（7–9 頁）

每頁一個劇情節拍、2–4 個短句，句尾逗號留懸念驅動翻頁：

1. `cover` — 海報式封面：地點標籤（國旗+國名）、特大主標、英文手寫副標、3 行鉤子（含一次反轉 + 開放懸念）
2. `beat` ×4–6 — 敘事頁：起（建立期待再打破）→ 承（衝突具體化/內在化）→
   彩蛋（第一人稱「最讓我意外的是…」冷知識，節奏換氣）→ 轉（命運轉折）
3. `bright` — 主題頁：明亮 + 置中對稱排版，人物出路呼應「旅行」主題
4. `ending` — 結局 + 說書人詮釋 + 讀者投射（「她」→「我們」）+ Lorescape
   slogan 與下載導流（取代現行 cta 頁的功能）

人稱規則：以「她/他」第三人稱為主，第一人稱「我」只在彩蛋頁與結局詮釋出現。

### 視覺系統

- 1080×1350（同現有卡片）
- 背景實拍照 + 深色 overlay（棕黑/酒紅調，把照片亮度壓到約 30–50%；
  `bright` 頁例外用淺色調）
- 文字雙色：米白正文 + 金色強調詞/小標（每頁 0–2 個金色強調詞）
- 明體（NotoSerifTC，字型已在 `card/template/fonts/`）三層字級：
  大標 / 正文 / 英文襯線小字
- 四周細金線框、分隔線 + 花紋裝飾符
- 每頁固定 `Lorescape` 落款（取代範例的 wanderwithann 浮水印）
- 文字排在照片低資訊區（layout variants：左欄 / 右欄 / 上區 / 置中）

## 架構

### 1. 本機渲染模組 `backend/src/lorescape_backend/social/wander/`

沿用 card 的 Jinja2 + Playwright 架構，獨立模組不動現有 `card/`：

- `template/wander.html.j2` + `wander.css`：實作上述視覺系統。
  layout variants：`cover` / `beat`（text_position: left|right|top）/
  `bright` / `ending`。長文沿用 card renderer 的 auto-fit `--fit` 縮放模式。
- `content.py`：`WanderSlide`（layout、title、lines、highlight 詞、
  photo 檔名、overlay 深淺）與 `WanderCarousel`（slides、caption、date）。
  來源檔為 `marketing/outputs/daily_carousel/<date>/slides.json`。
- `renderer.py`：讀 slides.json + 照片資料夾（`file://` 本機路徑）→
  輸出 `marketing/outputs/daily_carousel/<date>/slide_01.jpg …`
  （JPEG，控制檔案大小）。提供 CLI 供手動流程呼叫，
  參數：日期 + 照片資料夾路徑（slides.json 內的 photo 檔名
  相對於該資料夾解析）。

文案產生不寫程式：手動流程中 Claude 依 wander 敘事規格寫 `slides.json`
與 `caption.txt`，使用者審稿後才渲染。

### 2. 送審 script `scripts/send_carousel_for_review.py`（本機）

比照 `send_reel_for_review.py`：

1. 上傳 `slide_*.jpg` 到 `ig-cards` bucket，路徑
   `wander/<date>/slide_NN.jpg`（upsert，可重傳覆蓋）
2. 把整組圖貼進 Discord 審核頻道單則訊息（≤10 張；超過 Discord
   附件上限時壓縮預覽，發布仍用 bucket 原圖）、種 ✅/❌
3. `social_posts` upsert `pending` row：`media_type='carousel'`、
   `discord_message_id`、`slide_urls`（公開 URL 陣列）、`caption`

### 3. DB migration

`social_posts` 加兩欄：

- `slide_urls jsonb`（NULL = 非預渲染，走預設流程）
- `caption text`

含 service_role grant（依本專案慣例，參照既有 social_posts grant migration）。

### 4. Server publisher 分支（唯一的 server 改動）

21:00 `publisher.run_publish_job` 處理當天 row 前，先查 `social_posts`
carousel row：

- **預渲染模式**（row 為 `pending` 且 `slide_urls` 非空）：
  改讀該圖組訊息的 ✅/❌ →
  - ✅：`instagram.publish_carousel(slide_urls)` + row 的 caption，
    記錄 published；`daily_stories` 當天 row 同步標 published，
    避免隔天 back-fill 重發
  - ❌：標 rejected（當天 carousel 不發，語意同 reel）
  - 無反應：21:00 過後標 skipped（carousel 只有一次 pass，維持現行語意）
  - 發布失敗：標 failed + Discord webhook 通知（同現行）
  - 無論結果為何，預渲染 row 存在時**不會** fall through 到預設流程，
    且 `daily_stories` 當天 row 同步標為對應狀態
    （published / rejected / skipped），避免殘留 pending 造成
    隔天 back-fill 重發
- **無預渲染 row**：走現行預設流程，行為 byte-for-byte 不變

### 5. 歸檔 script `scripts/archive_ig_cards.py`（本機、每月手動跑）

下載 bucket 內指定月份（預設上個月）的所有 `ig-cards` 物件
（wander 與預設風格都含）到
`marketing/outputs/ig_cards_archive/<YYYY-MM>/`，逐檔核對下載成功後
刪除 bucket 端物件。使用者自行把資料夾備份到 Google Drive。

## 操作流程（每篇）

1. 使用者：「今天用 wander 風格」+ 指定照片資料夾
2. Claude 寫 `slides.json` + `caption.txt` → 使用者審稿/修改
3. 渲染 → 使用者本機預覽 JPEG
4. 跑 `send_carousel_for_review.py` → Discord 出現圖組
5. 使用者按 ✅ → 21:00 自動發布（❌ 或不按 = 當天不發 carousel）

不選 wander 的日子：什麼都不做，預設流程照舊。

## 錯誤處理

- slides.json 欄位缺漏 / 照片檔不存在：渲染 CLI 直接報錯退出（本機、審稿前）
- 上傳 bucket 失敗：script 報錯，不建 pending row（不會出現「送審了但沒圖」）
- 發布時 URL 抓不到（物件被誤刪）：IG API 報錯 → failed + webhook 通知，
  重傳後可重跑（pending/failed 可重試，同 reel 語意）
- 歸檔 script：任何一檔下載失敗即中止，不刪任何 bucket 物件

## 測試

- `wander/` 渲染 unit tests：比照 `test_card_renderer.py`
  （各 layout variant、auto-fit 長文、金色強調詞 markup、落款/邊框存在）
- publisher 分支 unit tests：比照 `test_reel_publisher.py`
  （pending+✅ / ❌ / 無反應 / slide_urls 為空走預設 / 發布失敗 →
  failed 可重試 / daily_stories 同步標記）
- `send_carousel_for_review` / `archive_ig_cards` unit tests：
  mock supabase + discord
- 端到端驗證：歷史日期 dry-run（publisher CLI）確認 URL 可達與 caption，
  再實發一篇

## 不在本次範圍

- 全自動 wander pipeline（server 自己寫文案/選圖）
- 預設風格 carousel 的既有 Storage 用量改造（歸檔 script 已順帶清理）
- 第三種風格；但 renderer/模板以「一風格一模組」隔離，之後新增風格
  只需加模板模組，不動 publisher
