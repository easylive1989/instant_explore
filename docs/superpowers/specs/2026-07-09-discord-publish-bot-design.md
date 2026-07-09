# Discord 發布 Bot 設計

- 日期：2026-07-09
- 狀態：設計定案（待寫 implementation plan）
- 範圍：carousel + reel 的 Instagram 發布流程

## 1. 背景與目標

目前 Instagram 發布由 `publisher` 容器（`lorescape_backend.social.publisher_daemon`）
承擔，用 APScheduler 在**固定時間**被動輪詢一次 Discord 反應：

- 21:00 Asia/Taipei — carousel：讀審核訊息 ✅/❌ → 發布
- 21:10 — reel：讀 reel 審核訊息 ✅/❌ → 發布
- 23:10 — reel 補發：晚到的 ✅ 再給一次機會，仍無反應標 `skipped`

缺點：

1. 發布時間寫死在程式碼，無法從外部調整。
2. 反應是「固定時間讀一次」，不是即時；審核與發布之間有僵固的等待。
3. 想改時間或補發都要動程式碼或跑手動 CLI。

**目標**：把 `publisher` 升級成一個常駐、連著 Discord Gateway 的 **bot 服務**，
成為唯一負責「連結 Discord ↔ Instagram 發布」的元件。審核、排程、發布全部
從 Discord 的**按鈕/modal 互動**操作，carousel 與 reel 都由它接管，移除
`publisher_daemon` 的三個固定 cron。

**非目標 / 不影響的部分**：

- App 可見性：App 只看 `daily_stories` 最新 `publish_date`，本來就沒有審核
  關卡。這個 bot 只管 IG 發布，不動 App。
- 內容產製：本地 `/lorescape-manual-daily-story` 的渲染流程不變。

## 2. 分工（本地產製 → server bot 發布）

延續現有的「本地做、上傳 server」模式，只把 Discord 貼文那一步從本地搬到 bot。

### 你的電腦（`/lorescape-manual-daily-story`，維持現狀 + 一處簡化）

- **carousel**：渲染 wander 圖組 → slides 上傳 Supabase `ig-cards` bucket
  （`wander/<date>/slide_NN.jpg`）→ 寫一筆 `pending` 的 `social_posts` row
  （`media_type=carousel`，含 `slide_urls` + `caption`）。
- **reel**：渲染 `final.mp4` → rsync 到 VPS volume（`DAILY_VIDEO_DIR/<date>/`，
  含 `narration.txt`）→ 寫一筆 `pending` 的 `social_posts` row（`media_type=reel`）。
- **變動**：本地**不再貼 Discord**（原本 `send_carousel_for_review` /
  `send_reel_for_review` 貼審核訊息的動作移除；改由 bot 貼帶按鈕的訊息）。

「放到 server」對 carousel = 上傳 Supabase + 寫 row；對 reel = rsync 到 VPS +
寫 row。這兩個上傳管道現在就有，bot 靠輪詢這些 row 接手，不需對外開端點。

### Server 上的 bot（新的常駐服務）

1. 每分鐘掃 Supabase `social_posts`，找「`status=pending` 且 `discord_message_id`
   為空」的 row → 讀素材（carousel 從 `slide_urls` 下載；reel 從 VPS volume 讀
   `final.mp4` 並轉 720p 預覽）→ 在審核頻道貼**帶按鈕的審核訊息** → 回填
   `discord_message_id` 並把 View 註冊為 persistent view。
2. 處理按鈕互動（見 §4）。
3. 排程迴圈（每分鐘）：到點且已核准的 row → 發布（見 §5）。
4. 發布沿用既有 `instagram.publish_carousel` 與 reel 發布邏輯，重構成
   「依 row 狀態決定」而非「當下重讀反應」。

## 3. 資料模型

沿用 `social_posts`（一筆 = 一組 `publish_date` + `media_type`）。新增欄位
（Supabase migration）：

| 欄位 | 型別 | 說明 |
|---|---|---|
| `review_decision` | text null | `approved` / `rejected` / null（審核意圖，與排程正交） |
| `scheduled_at` | timestamptz null | 排程發布時間（UTC 儲存） |
| `reviewed_by` | text null | 按下決定的 Discord user id（稽核用，選填） |
| `reviewed_at` | timestamptz null | 決定時間（稽核用，選填） |

`status` 語意調整：

- `pending` — 已建立、等 bot 貼審核 / 等互動
- `scheduled` — 已設 `scheduled_at`，等排程迴圈
- `published` / `rejected` / `failed` — 終態（`failed` 會在下輪重試）

`review_decision` 與 `status` 正交：可以「已核准但還沒排程」（等你按🚀或設時間），
也可以「已排程但還沒核准」（到點不發，見 §5）。

既有欄位 `slide_urls` / `caption` / `discord_message_id` / `ig_post_id` /
`error` / `published_at` 語意不變。

## 4. Discord UX（按鈕 + modal）

審核訊息由 bot 貼出（附 persistent View），掛四顆按鈕：

| 按鈕 | 行為 |
|---|---|
| ✅ 核准 | `review_decision=approved`。若已有 `scheduled_at` → 到點自動發；否則等「🚀 立即發布」 |
| 🕘 排程 | 開 modal 輸入日期時間（預設帶當天 21:00 Asia/Taipei）→ 寫 `scheduled_at`、`status=scheduled` |
| 🚀 立即發布 | 隱含核准並**馬上**發（不等排程迴圈） |
| ❌ 拒絕 | `review_decision=rejected`、`status=rejected` |

補一個 slash command：

- `/republish <date> <carousel|reel>` — 補發 / 重試（把終態 row 重置回可發狀態並
  即時發布，供 back-fill 用）。

**權限 / 設定**：沿用現有 `DISCORD_BOT_TOKEN`。需在 Discord 開發者後台啟用
application commands，並開啟 Gateway intents（guild messages、reactions；
message content 非必要，因為互動走 component/command，不讀訊息內文）。互動只接受
`DISCORD_APPROVER_IDS` 名單內的使用者，其餘按下按鈕回覆 ephemeral 拒絕訊息。

## 5. 狀態機（排程迴圈，每分鐘）

掃描 `status in (pending, scheduled)` 的 row：

- `scheduled_at` 已到 且 `review_decision == approved` → 發布
  - 成功 → `status=published`、記 `ig_post_id` / `published_at`
  - 失敗 → `status=failed`、記 `error`，下一輪重試
- `scheduled_at` 已到 但 `review_decision != approved` → **不發**，維持原狀並在
  Discord 提醒「排程時間到但尚未核准」（每個 row 只提醒一次，避免洗頻）
- 未設 `scheduled_at` → 迴圈不動它（只靠按鈕即時路徑）

即時路徑（不等迴圈）：

- 「🚀 立即發布」→ 設 `review_decision=approved` 後直接發布
- `/republish` → 重置 + 直接發布

`DAILY_STORY_PUBLISH_ENABLED=0` 時，bot 保持 Gateway 連線但排程迴圈與發布動作
全部 no-op（容器不 restart-loop）。

## 6. 元件切分

```
lorescape_backend/social/
  publisher_bot.py        # bot 進入點：Gateway 連線、註冊 View/commands、啟動迴圈
  bot/
    views.py              # 審核訊息的 persistent View（四顆按鈕）+ 排程 modal
    interactions.py       # 按鈕/modal/command → 純粹的狀態轉移（吃 supabase，不碰 Discord SDK 細節）
    review_poster.py      # 掃 pending row、下載素材、貼審核訊息、回填 message_id
    scheduler.py          # 每分鐘迴圈：找到點且核准的 row → 呼叫 executor
    executor.py           # 實際發布（carousel / reel），重構自現有 publisher / reel_publisher
```

設計原則：**Discord SDK 只出現在 `publisher_bot.py` / `views.py`**；
`interactions.py` / `scheduler.py` / `executor.py` 收「純資料 + supabase client」，
不 import discord.py，方便對 fake supabase 單元測試（Gateway 本身不寫整合測試）。

`executor.py` 盡量重用既有 `instagram.publish_carousel`、`_handle_prerendered`
的發布主體與 reel 發布主體，只把「決策來源」從「重讀反應」換成「讀 row 狀態」。

## 7. 部署與依賴

- `backend/docker-compose.yml`：`publisher` 服務改跑
  `python -m lorescape_backend.social.publisher_bot`（沿用同 image、
  `restart: unless-stopped`、維持掛載 `daily_video` volume）。
- 新增依賴 `discord.py>=2.4`（`backend/pyproject.toml`）。
- image 需含 `ffmpeg`（reel 720p 預覽轉檔從本地搬進 bot）。若目前 image 未內含，
  Dockerfile 加裝。
- 移除 `publisher_daemon` 的三個 cron（carousel 21:00 / reel 21:10 / reel 23:10）。
  `publisher_daemon.py` 可刪除或保留為 back-fill CLI 薄殼（實作計畫再定）。

## 8. 本地端與文件變動

- `scripts/send_carousel_for_review.py`：簡化為「上傳 slides + 寫 pending row」，
  移除 Discord 貼文；輸出訊息改成「已上傳，等 bot 在 Discord 貼審核」。
- `scripts/send_reel_for_review.py` / `upload_reel_to_vps.sh`：rsync 影片後
  改為只寫 pending reel row（移除 Discord 貼文與本地 ffmpeg 預覽轉檔）。
- Skill 文件更新：`lorescape-manual-daily-story`（Step 8b、reel Step 11）、
  `lorescape-wander-carousel`、以及 `backend/README.md` 的發布/back-fill 說明。

## 9. 測試策略

- `interactions.py`：核准 / 排程 / 拒絕 / 立即發布 對 fake supabase 的狀態轉移。
- `scheduler.py`：到點+已核准→發；到點未核准→不發+提醒一次；未到點→不動；
  `DAILY_STORY_PUBLISH_ENABLED=0`→ no-op。
- `review_poster.py`：pending 無 message_id → 貼審核 + 回填；已貼過 → 不重貼。
- `executor.py`：沿用並改寫既有 `test_publisher_*` / `test_reel_publisher`。
- 權限：非 approver 按按鈕 → 拒絕、不改狀態。
- Gateway 連線與 discord.py 本身用可注入的 fake client 包一層，不寫真連線整合測試。

## 10. 已定案的取捨

- **A（觸發方式）**：本地→bot 用 **DB 輪詢**（bot 每分鐘掃 pending row 自動貼審核），
  不對外開端點。
- **B（Discord 貼文歸屬）**：貼審核訊息**完全交給 bot**（本地不再貼），以符合
  「bot 專責連結 Discord 與發文」。本地維持產製 + 上傳 server。
- **C（reel 預覽轉檔）**：720p 預覽轉檔搬進 bot，image 內含 ffmpeg。
- **排程語意**：🕘 排程（按鈕 + modal）只設時間，發布前仍需 `review_decision==approved`；
  未核准則到點不發。排程動作沒有對應的 slash command（唯一的 slash command 是
  `/republish`）。

## 11. 風險與待驗證

- Gateway 連線穩定性：discord.py 自動重連 + 容器 `restart: unless-stopped`；
  persistent View 需在啟動時重新註冊才能處理重啟前訊息的按鈕。
- 輪詢延遲：最壞 1 分鐘才貼審核 / 才發布，對每日一則的節奏可接受。
- 重複發布防護：發布前檢查 `status`，終態不再發；`ig_post_id` 已存在則不重發。
- reel 影片大小：>9.5MB 走 720p 預覽（僅供審核），實際發布用 volume 上的原檔。
