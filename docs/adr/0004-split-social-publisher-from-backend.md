# ADR 0004：將社群發布（Discord bot / daily story / IG 發布）拆成獨立的 publisher 專案

- 狀態：Accepted
- 日期：2026-07-11
- 影響範圍：`backend/`、新增的頂層 `publisher/`、`scripts/`（依賴與 `.env` 來源）、
  `.github/workflows/deploy-backend.yml`、新增 `.github/workflows/deploy-publisher.yml`

## 背景

`backend/src/lorescape_backend/` 原本同時裝著兩件事：

1. App 直接呼叫的 narration API（含 RevenueCat 訂閱 402 驗證、webhook、
   reconcile）——這是唯一有真正「上線 SLA」要求的部分。
2. 每日故事產線、常駐 Discord Gateway 審核 bot（四鈕核准／排程／立即發布／
   拒絕）、IG 圖卡與 wander carousel 渲染、IG Reels 發布——這是操作者手動
   觸發、非同步、允許延遲重試的批次/互動流程。

兩者共用同一個 Python 套件、同一個 Docker image、同一支 `docker-compose.yml`、
同一份 `.env`。這造成幾個實際問題：

- **部署耦合**：改 bot 的按鈕文案也要重建、重啟 narration API 的 container，
  App 端有停機風險，即使 narration 程式碼完全沒動。
- **邊界不清**：`lorescape_backend.social.*`、`lorescape_backend.daily_story.*`
  與 `lorescape_backend.narration.*` 混在同一個套件命名空間下，import 圖沒有
  強制邊界，容易互相滲透依賴。
- **權限與密鑰混雜**：Discord token、Meta/IG token、Gemini key 與 App 端的
  Supabase / RevenueCat 密鑰全部寫在同一份 `backend/.env`，任何一邊要輪替
  密鑰都要動到另一邊的部署。

## 決策

拆出頂層 `publisher/`（套件名 `lorescape-publisher`），與 `backend/`（`frontend/`
`landing/` 同級）平行存在：

- **`backend/`** 之後只服務 App：narration API（含 402 驗證）、訂閱 webhook、
  訂閱 reconcile。`lorescape_backend.social`、`lorescape_backend.daily_story`
  已整批移除。
- **`publisher/`**（`lorescape_publisher` 套件）收納 daily story 產線
  （`daily_story/`）、Discord Gateway 審核 bot（`bot.py` + `bot_flows/`）、
  IG 圖卡與 wander carousel 渲染（`card/`、`wander/`）、IG Reels 發布
  （`reel_publisher.py`）。獨立 `pyproject.toml`、`uv.lock`、`Dockerfile`、
  `docker-compose.yml`、`.env` / `.env.example`。
- **`story_prompt.py` / `genai.py` 刻意複製兩份**（`backend/` 與
  `publisher/` 各一份），不共用套件、不抽公用 library。兩邊各自需要的
  Gemini prompt/呼叫方式已經開始分岔（narration 走使用者即時互動、daily
  story 走批次產線），抽共用層的耦合成本高於維護兩份複製的成本。**接受
  分岔**：換取兩個專案完全解耦、各自能獨立升級依賴、獨立部署。之後改動
  其中一份的 prompt 邏輯，需要人工判斷另一份是否要同步。
- **`scripts/` 依賴改指 `publisher`**：`scripts/pyproject.toml` 的 path
  dependency 從 `../backend` 改成 `../publisher`；六支發布相關腳本
  （`publish_reel.py`、`send_carousel_for_review.py`、
  `send_reel_for_review.py`、`daily_video_post.py`、`manual_daily_story.py`、
  `archive_ig_cards.py`）改讀 `publisher/.env`（原本讀 `backend/.env`）。
  metrics/unsplash 腳本（`scripts/metrics/stores.py`、
  `scripts/unsplash_images.py`）讀的是 `scripts/.env`，不受此次搬遷影響。
- **部署 workflow 各自獨立**：`deploy-backend.yml` 只建置/重啟
  `backend/`；新增 `deploy-publisher.yml` 只建置/重啟 `publisher/`。兩者可
  各自手動觸發，互不影響對方的 container。

## VPS 一次性遷移步驟

現有 VPS 上跑的是拆分前的舊 image（`lorescape-backend` 同時含 bot / daily
story）。切換到新架構需要在 VPS 上手動做一次遷移；**操作者本機**也要建立
對應的 `publisher/.env`（`scripts/` 的六支發布腳本已改讀 `publisher/.env`
——把本機 `backend/.env` 裡的 `DISCORD_*` / `IG_*` / `META_*` /
`BRAND_HANDLE_IG` / `GEMINI_*` 等值搬過去；metrics/unsplash 腳本讀的是
`scripts/.env`（`UNSPLASH_ACCESS_KEY`、`METRICS_SHEET_ID` 等行銷工具設定），
不受此次搬遷影響）：

```
1. ssh VPS → cd /opt/lorescape && git pull
2. 建立 publisher/.env：自 backend/.env 搬走 DISCORD_*、IG_USER_ID、
   META_PAGE_ACCESS_TOKEN、BRAND_HANDLE_IG、DAILY_STORY_*，並複製
   SUPABASE_URL、SUPABASE_SERVICE_ROLE_KEY、GEMINI_*（對照
   publisher/.env.example）
3. 若 GEMINI_BACKEND=vertex：cp backend/service-account.json publisher/
4. cd backend && docker compose up -d --build --remove-orphans
   （--remove-orphans 會清掉舊的 lorescape-publisher 容器）
5. cd ../publisher && docker compose up -d --build
6. 驗證：docker compose logs publisher | grep -i "connected to gateway"
7. backend/.env 中已搬走的變數可刪（保留亦無害，backend 不再讀取）
```

## 後果

- 改 `story_prompt.py` 的 prompt 邏輯，需要人工判斷 `backend/` 與
  `publisher/` 兩份是否都要同步修改；沒有自動化機制防止兩邊分岔到不一致
  的狀態，仰賴 code review 把關。
- 新增 publisher 部署前，VPS 必須先完成上述手動遷移步驟（尤其是
  `publisher/.env` 建好），否則 `deploy-publisher.yml` 建出的 container 會
  因缺少必要環境變數而無法啟動 Discord bot（`Config.review_enabled` 會擋
  住 `main()`）。
- 部署順序固定為：先 `Deploy Backend`（`--remove-orphans` 清掉舊的合併式
  publisher 容器）→ 手動完成 `.env` 遷移 → 再 `Deploy Publisher`。順序顛倒
  時 `container_name` 重名會讓 `docker compose up` 直接啟動失敗（hard-fail），
  不會有新舊容器短暫並存的風險，但仍需先完成遷移才能正常啟動。
- `backend/` 的套件體積、依賴數（尤其 `discord.py`、圖片渲染相關套件）與
  測試數明顯縮小，`publisher/` 則獨立擁有這些依賴；兩邊 CI 可以分開跑、
  互不拖慢對方。
