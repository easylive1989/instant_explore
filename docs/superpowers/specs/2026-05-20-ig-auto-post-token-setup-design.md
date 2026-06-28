# IG 自動發文 — Token 取得與設定

**Date:** 2026-05-20
**Status:** Design approved
**Scope:** Operational setup only — no production code changes

---

## 背景

`backend/` 已經有一套完整的 IG 自動發文 pipeline，包含：

- `daily_story/job.py` — 09:00 cron，產生每日故事寫入 `daily_stories` 表，並 push 到 Discord 給人工審核
- `social/publisher.py` — 21:00 cron，讀 Discord ✅/❌ 反應，把通過的 row 發到 Threads + Instagram
- `social/instagram.py` — Meta Graph API 的兩階段發文（create container → publish）
- `social/caption.py` — 組合 caption + hashtags + CTA
- `config.py` — 從 env 讀取所有設定，`Config.instagram_enabled` 判斷是否啟用
- `scripts/meta_token_helper.py --platform instagram` — 互動式 token 換發工具
- `docs/init/social_publisher_setup.md` — 完整設定流程文件

唯一卡住自動發文的，是 `backend/.env` 內 `IG_USER_ID` 與 `META_PAGE_ACCESS_TOKEN` 兩個變數還沒填值。

## 目標

讓 `backend/.env` 內的 IG 相關欄位填上有效值，且 `Config.from_env()` 在載入後 `instagram_enabled` 為 `True`，使代碼能跑（loadable，不一定要實際發文驗證）。

## 非目標

- 不做端到端發文驗證（不會推任何 post 到 IG）
- 不處理 Discord review bot 設定（雖然這是讓 21:00 publisher 真正觸發 IG 的前提，但本 spec 範圍只到 token）
- 不處理 Threads token
- 不寫新程式碼、不改既有程式碼

## 系統現況檢查表

| 檔案 | 狀態 |
|------|------|
| `backend/src/lorescape_backend/social/instagram.py` | ✅ 完整實作 publish() |
| `backend/src/lorescape_backend/social/publisher.py` | ✅ 完整 orchestrator，含 IG 分支 |
| `backend/src/lorescape_backend/config.py` | ✅ 含 `ig_user_id`、`meta_page_access_token`、`instagram_enabled` |
| `backend/.env.example` | ✅ 與 `config.py` 一致 |
| `scripts/meta_token_helper.py` | ✅ `--platform instagram` 流程完整 |
| `docs/init/social_publisher_setup.md` | ✅ 含 IG 設定步驟 |
| `backend/.env` 內的 `IG_USER_ID` | ❌ 空白 |
| `backend/.env` 內的 `META_PAGE_ACCESS_TOKEN` | ❌ 空白 |

## 執行步驟（總共 3 步）

### Step 1 — 取得 token（使用者手動，瀏覽器步驟）

跑：

```bash
cd /Users/paulwu/Documents/Github/instant_explore
python scripts/meta_token_helper.py --platform instagram
```

Script 會引導完成：
1. 輸入 App ID（`1635287081082476`）與 App Secret
2. 開啟 Graph API Explorer，授權並複製短效 User Token
3. 把短效 token 換成長效 User Token（60 天）
4. 列出 Facebook Pages，選擇 Lorescape 對應的 Page
5. 取得永久 Page Access Token
6. 解析 IG Business Account ID
7. 印出兩行要貼到 `.env` 的內容

前置條件（依 `docs/init/social_publisher_setup.md`）：
- IG 帳號（`love.lorescape`）已設為 Business / Creator
- IG 已連結到 Facebook Page
- Meta App 已啟用 `pages_show_list`、`pages_read_engagement`、`pages_manage_posts`、`instagram_basic`、`instagram_content_publish` 權限

### Step 2 — 寫入 `backend/.env`

若 `backend/.env` 不存在：

```bash
cp backend/.env.example backend/.env
```

把 Step 1 印出的兩行貼到 `IG_USER_ID=` 與 `META_PAGE_ACCESS_TOKEN=` 欄位。

### Step 3 — 驗證 config 能載入

```bash
cd backend
uv run python -c "from lorescape_backend.config import Config; c = Config.from_env(); print('IG enabled:', c.instagram_enabled)"
```

預期輸出：

```
IG enabled: True
```

完成。

## 成功判準

- `Config.from_env()` 載入時不丟例外
- `Config.instagram_enabled` 回傳 `True`
- `backend/.env` 中 `IG_USER_ID` 與 `META_PAGE_ACCESS_TOKEN` 皆為非空、實際有效值

## 風險與已知副作用

1. **`backend/.env` 不可入版本控制** — 已在 `.gitignore`，確認步驟 2 之後沒有意外 commit。
2. **IG token 設好不等於會自動發文** — `publisher.py` 在 `review_enabled` 為 False 時，會把所有 pending row 直接標成 `skipped`，不會呼叫 IG API。若想真的讓 21:00 cron 觸發 IG，仍需另外設好 Discord review bot（`DISCORD_BOT_TOKEN` / `DISCORD_REVIEW_CHANNEL_ID` / `DISCORD_APPROVER_IDS`）。此項已**明確排除**於本 spec 範圍外，作為下次任務候選。
3. **Page Access Token 永久有效**，不需排程刷新；但若 `love.lorescape` 從 Facebook Page 解除連結、或 App 權限被撤銷，token 仍會失效。

## 參考檔案

- `backend/.env.example`
- `backend/src/lorescape_backend/config.py`
- `backend/src/lorescape_backend/social/publisher.py`
- `backend/src/lorescape_backend/social/instagram.py`
- `scripts/meta_token_helper.py`
- `docs/init/social_publisher_setup.md`
