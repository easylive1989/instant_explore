# Social Publisher 拆分設計

日期：2026-07-11
狀態：已核可

## 目標

把所有社群發布相關程式從 `backend/` 拆出，成為與 backend 平級的頂層專案
`publisher/`（social publisher）。拆分後：

- **backend 只專注於服務 App**：narration API、subscriptions、sources、auth。
- **publisher 是獨立服務**：IG 內容產線（daily story 產生）＋ Discord 審核
  bot ＋ IG 發布，有自己的 `.env`、pyproject、Docker image、compose project
  與部署 workflow。
- 兩專案完全解耦：不互相 import、不共用套件；刻意共用的
  `story_prompt.py` / `genai.py` 以「複製兩份」處理（使用者決策，接受
  分岔風險）。

## 背景：拆分前的共用面

`social/` 與 `daily_story/` 目前住在 `lorescape_backend` 內，被三方共用：

| 使用方 | 用到什麼 |
|---|---|
| publisher bot（VPS container） | `social/*` 全部、`config.py`、`daily_story/discord_notify、discord_review` |
| api container | `daily_story/job.py`（09:00 generate cron，已由 `DAILY_STORY_ENABLED=0` 停用）、`social/card`（審核卡渲染）、`sources/pipeline.py` 引用 `daily_story/wikipedia.fetch_intro_extract`（legacy App 路徑） |
| 本機 `scripts/` | `social/{caption,instagram,reel_cover,post_log,card_storage,wander}`、`daily_story`、`shared/genai`、`Config`，透過 path dependency |

另外 `shared/story_prompt.py`（271 行）是 narration（App）與 daily_story
（IG）刻意共用的故事品質單一來源；`shared/genai.py`（50 行）是 Gemini
client 工廠。

## 新結構

```
backend/     ← 只服務 App：narration、subscriptions、sources、auth
publisher/   ← social publisher：IG 內容產線 + Discord 審核 bot + 發布
scripts/     ← 不變，但依賴從 lorescape-backend 改為 lorescape-publisher
```

### publisher/（套件名 `lorescape_publisher`）

搬家時把多餘的 `social.` 層級攤平：

```
publisher/
├── pyproject.toml            # lorescape-publisher（uv 管理）
├── Dockerfile                # python-slim + tzdata + ffmpeg + Playwright Chromium
├── docker-compose.yml        # 獨立 compose project，env_file: 自己的 .env
├── .env.example              # publisher 專用環境變數
├── src/lorescape_publisher/
│   ├── config.py             # publisher 自己的 Config
│   ├── genai.py              # 從 backend shared/ 複製
│   ├── story_prompt.py       # 從 backend shared/ 複製
│   ├── bot.py                # 原 social/publisher_bot.py；進入點
│   │                         #   python -m lorescape_publisher.bot
│   ├── bot_flows/            # 原 social/bot/（scheduler、review_poster、
│   │                         #   interactions、views）
│   ├── executor.py、instagram.py、post_log.py、caption.py、
│   │   card_storage.py、reel_cover.py、reel_publisher.py
│   ├── card/、wander/        # 渲染引擎
│   └── daily_story/          # 整包搬入（job、story_writer、wikipedia、
│                             #   gemini_client、prompts、place_picker、
│                             #   discord_notify、discord_review、__main__）
└── tests/                    # backend/tests 的 social + daily_story 測試搬入
```

### backend/ 瘦身後

- 保留：`narration/`、`subscriptions/`、`sources/`、`auth.py`、`api.py`、
  `config.py`、`shared/`（narration 仍用 genai + story_prompt，保留原位）。
- `api.py`：移除 daily_story 09:00 generate cron 的註冊與 import；保留
  subscriptions reconcile cron。daily story 產生改為 publisher 的 CLI
  （`python -m lorescape_publisher.daily_story`），伺服器端排程本次不
  重建，維持現行手動流程。
- `sources/pipeline.py`：`fetch_intro_extract` 在 `sources/` 內留一份自己
  的實作（單一函式，legacy App 路徑），移除對 `daily_story` 的 import。
- `config.py`：刪除 Discord bot / IG / daily_story / DAILY_VIDEO_DIR 相關
  欄位與 properties（`review_enabled`、`instagram_enabled` 等移去 publisher
  Config）。
- Dockerfile：移除 Playwright、ffmpeg；依賴移除 discord.py、jinja2
  （已確認僅 card / wander 模板使用）、playwright。
- 順手清理：刪除被 bot 取代的舊 `social/publisher.py`（404 行 legacy
  reaction-check CLI）。`reel_publisher.py` 保留（executor 用其
  `build_reel_caption`），僅更新 import。

## 設定與 .env 切分

| | backend/.env | publisher/.env |
|---|---|---|
| 共同 | SUPABASE_URL、SUPABASE_SERVICE_ROLE_KEY | 同左（兩份各自維護） |
| 各自 | GEMINI\*（narration）、REVENUECAT\*、NARRATION_WEB_SEARCH | GEMINI\*（故事產生）、DISCORD_BOT_TOKEN、DISCORD_REVIEW_CHANNEL_ID、DISCORD_APPROVER_IDS、DISCORD_WEBHOOK_URL、IG_USER_ID、META_PAGE_ACCESS_TOKEN、BRAND_HANDLE_IG、DAILY_STORY\*、DAILY_VIDEO_DIR |

- publisher Config 自 `Config.from_env()` 拆出 publisher 需要的欄位；
  backend Config 移除 social 欄位。
- VPS 一次性手動步驟：建立 `/opt/lorescape/publisher/.env`（自現有
  backend/.env 拆值過去）。

## 部署

- `publisher/docker-compose.yml`：獨立 compose project；`lorescape-publisher`
  container、`/opt/lorescape-media/daily_video` volume 掛載照舊；
  `depends_on: api` 移除（bot 不呼叫 api）。
- `backend/docker-compose.yml`：移除 `publisher` service。
- 新 `.github/workflows/deploy-publisher.yml`：SSH → git pull →
  `cd publisher && docker compose up -d --build`。
- `deploy-backend.yml`：不再提及 publisher。
- Supabase db push job 兩條 workflow 都放（冪等，避免部署互相等待）。

## 測試

- 搬移的測試在 `publisher/` 下 `uv run pytest` 全綠。
- backend 剩餘測試 `uv run pytest` 全綠。
- `scripts/` 的 import 全改 `lorescape_publisher.*`，pyproject path
  dependency 改指 `../publisher`，其測試照跑。

## 收尾

- 更新根目錄 `CLAUDE.md` 的 repo 結構表（新增 `publisher/` 一列、更新
  backend 描述）。
- `docs/adr/` 補一篇拆分決策紀錄。

## 決策紀錄

1. 拆分動機：程式碼邊界清晰＋部署獨立（非追求獨立 repo）。
2. 部署 workflow 各自獨立（`deploy-publisher.yml` / `deploy-backend.yml`）。
3. 共用的 `story_prompt.py` / `genai.py`：**複製兩份**，接受未來分岔
   （使用者明確選擇，優先完全解耦）。
4. publisher 有自己的 `.env`。
5. 頂層目錄名 `publisher/`。
