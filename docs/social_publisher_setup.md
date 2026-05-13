# Social Publisher Setup Guide

自動發文系統的設定記錄，包含 Meta（Instagram + Threads）API 的取得流程、已完成項目，以及接手人員需要繼續完成的步驟。

---

## 系統架構說明

後端（`backend/`）有一個排程發文系統：
- 每日由 APScheduler cron job 觸發
- 從 Supabase 取出待發文的 story
- 透過 Discord bot 確認（人工 ✅/❌ 審核）後，自動發佈到 Threads 和 Instagram
- 相關程式碼位於 `backend/src/lorescape_backend/social/`

### 需要填入 `backend/.env` 的金鑰

```dotenv
# ── Threads (Meta) ────────────────────────────────────────────────────────────
THREADS_USER_ID=           # love.lorescape 帳號的 Threads User ID（數字）
THREADS_ACCESS_TOKEN=      # 長效存取 token（60 天有效）

# ── Instagram Business via Meta Graph API ─────────────────────────────────────
IG_USER_ID=                # IG Business Account ID（數字）
META_PAGE_ACCESS_TOKEN=    # Facebook Page 長效存取 token（永久有效）

# ── Discord review bot ────────────────────────────────────────────────────────
DISCORD_BOT_TOKEN=
DISCORD_REVIEW_CHANNEL_ID=
DISCORD_APPROVER_IDS=
```

範本見 `backend/.env.example`。

---

## Meta Developer App 資訊

| 欄位 | 值 |
|------|----|
| App 名稱 | Lorescape |
| App ID | `1635287081082476` |
| App Secret | 在 Meta Developer Console 設定頁查看 |
| Business Portfolio | Lorescape（ID: `2469452706849983`）|
| App 狀態 | 調整中（開發模式） |
| Developer Console | https://developers.facebook.com/apps/1635287081082476 |

### 已啟用的 Use Cases

- ✅ 存取 Threads API
- ✅ 管理 Instagram 的訊息和內容
- ✅ 管理粉絲專頁的所有內容

---

## 已完成的項目

### 1. `backend/.env.example` 更新

已加入所有社群發文所需的環境變數（Threads、Instagram、Discord review bot、品牌 handle）。

### 2. `scripts/meta_token_helper.py` 建立

互動式 token 換發工具，支援：

```bash
# Instagram（取得 IG_USER_ID + META_PAGE_ACCESS_TOKEN）
python scripts/meta_token_helper.py --platform instagram

# Threads（取得 THREADS_USER_ID + THREADS_ACCESS_TOKEN）
python scripts/meta_token_helper.py --platform threads

# 刷新即將到期的 Threads token
python scripts/meta_token_helper.py --platform threads --refresh
```

### 3. Meta App 建立與 Use Case 設定

- 在 Meta Developer Console 建立了「Lorescape」App
- 新增 Threads API、Instagram API、Facebook Pages 三個 use case
- 已在 `backend/src/lorescape_backend/social/` 實作 Threads 和 Instagram 的發文邏輯

---

## 尚未完成的項目

### ❌ Threads Token（優先級：中）

**問題描述：** Threads 的 User Token Generator 需要測試帳號先接受 app 邀請，但 `love.lorescape` 帳號在 Threads app 中接受邀請後，Meta 後端仍回傳 `error_code: 1349245`（user has not accepted invite）。

**目前狀態：**
- `love.lorescape` 已加為 Threads 測試人員（App Roles 頁可看到）
- 邀請在 Threads app 的 Apps and Websites → Invites 頁面仍停留在 Invites tab，未移到 Active

**接手步驟：**

1. 前往 https://developers.facebook.com/apps/1635287081082476/roles/roles/
2. 切到「Threads 測試人員」tab，確認 `love.lorescape` 狀態
3. 如果還是 pending，嘗試移除再重新加一次，然後立刻到 Threads app 接受邀請
4. 接受後立刻前往 https://developers.facebook.com/apps/1635287081082476/use_cases/customize/settings/?use_case_enum=THREADS_API&business_id=2469452706849983&selected_tab=settings&product_route=threads-api
5. 在頁面底部「用戶權杖產生器」點擊「產生存取權杖」
6. 授權完成後取得短效 token，執行以下指令換成長效 token：

```bash
cd /path/to/instant_explore
python scripts/meta_token_helper.py --platform threads
```

或手動執行：

```bash
# 短效 → 長效（把 SHORT_TOKEN 替換成實際 token）
curl -X GET "https://graph.threads.net/v1.0/access_token" \
  -d "grant_type=th_exchange_token" \
  -d "client_secret=APP_SECRET" \
  -d "access_token=SHORT_TOKEN"
```

7. 將結果填入 `backend/.env`：
   ```
   THREADS_USER_ID=<user_id from token exchange>
   THREADS_ACCESS_TOKEN=<long_lived_token>
   ```

> ⚠️ Threads token 60 天後過期，需定期刷新：
> `python scripts/meta_token_helper.py --platform threads --refresh`

---

### ❌ Instagram Token（優先級：高）

**接手步驟：**

#### 前置確認

- 確認 `love.lorescape`（或目標帳號）的 Instagram 已設為**商業帳號**或**創作者帳號**
- 確認 IG 帳號已連結到 Facebook 粉絲專頁（FB Page → Professional Dashboard → Linked Accounts → Instagram）

#### 取得短效 User Token

1. 前往 Graph API Explorer：https://developers.facebook.com/tools/explorer/1635287081082476/
2. 確認右側 App 是 **Lorescape**
3. 在「新增權限」欄位逐一加入：
   - `pages_show_list`
   - `pages_read_engagement`
   - `pages_manage_posts`
   - `instagram_basic`
   - `instagram_content_publish`
4. 點「Generate Access Token」，在彈出視窗授權
5. 複製生成的短效 User Token

#### 執行 token 換發 script

```bash
python scripts/meta_token_helper.py --platform instagram
```

Script 會自動：
1. 輸入 App ID（`1635287081082476`）和 App Secret
2. 貼入短效 User Token
3. 換成長效 User Token（60 天）
4. 列出你的 Facebook Pages，選擇對應的 Page
5. 取得永久 Page Access Token
6. 自動解析 IG Business Account ID
7. 印出要填入 `.env` 的兩行

最後填入 `backend/.env`：
```
IG_USER_ID=<數字>
META_PAGE_ACCESS_TOKEN=<長字串>
```

> ℹ️ Page Access Token 只要從長效 User Token 生成，就**永久有效**，不需定期刷新。

---

### ❌ Discord Review Bot（優先級：低）

自動發文系統在排程執行時，會先把待發文章丟到 Discord 頻道，等待人工確認（✅ 通過 / ❌ 拒絕）後才發佈。

**接手步驟：**

1. 在 Discord Developer Portal（https://discord.com/developers/applications）建立一個 Bot
2. 取得 Bot Token → 填入 `DISCORD_BOT_TOKEN`
3. 建立一個審核用的 Discord 頻道，取得 Channel ID → 填入 `DISCORD_REVIEW_CHANNEL_ID`
4. 取得允許審核的 Discord User ID → 填入 `DISCORD_APPROVER_IDS`（逗號分隔）
5. 確保 Bot 已邀請到伺服器並有讀取 / 發送訊息權限

---

## App 上架申請（未來）

目前 App 處於**開發模式（調整中）**，只有加為測試人員的帳號能使用。要讓正式帳號也能發文，需要向 Meta 申請以下權限審核：

- `instagram_content_publish`
- `pages_manage_posts`
- `threads_content_publish`

申請前需要：
1. 提供隱私政策 URL
2. 填寫使用說明（use case description）
3. 錄製展示影片

---

## 相關檔案一覽

| 檔案 | 說明 |
|------|------|
| `backend/.env.example` | 所有環境變數範本 |
| `scripts/meta_token_helper.py` | Meta/Threads token 互動換發工具 |
| `backend/src/lorescape_backend/social/threads.py` | Threads 發文邏輯 |
| `backend/src/lorescape_backend/social/instagram.py` | Instagram 發文邏輯 |
| `backend/src/lorescape_backend/config.py` | 設定載入（含 threads_enabled / instagram_enabled 判斷）|
