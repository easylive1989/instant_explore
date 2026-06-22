# Publish Reel Skill — Design

手動把 `outputs/daily_video/<date>/` 的成品影片，用本機 IG token 發布到
Instagram Reels。不經 server 排程，不依賴 Discord 審核狀態機。

## 目標與範圍

- 指定某一天（如 `2026-06-22`），把該天的 `final.mp4` 發布為 IG Reels。
- 完全在本機執行，使用既有 `backend/.env` 的 IG 憑證。
- Caption 預設取 Supabase 當天 `daily_stories`（zh-TW）那筆，重用既有
  caption 組裝邏輯；支援手動覆寫與 `narration.txt` fallback。

### 非目標

- 不做自動排程（server 那條 21:00 publish job 不在此範圍）。
- 不寫回 Supabase 狀態（手動發布視為與 server 狀態機獨立）。
- 不處理影片轉檔／裁切；假設 `final.mp4` 已是合規的 Reels 影片。

## 整體流程

```
使用者: 發布 2026-06-22 的影片到 IG Reels
  → skill 觸發
  → python backend/scripts/publish_reel.py 2026-06-22
       1. 解析 outputs/daily_video/2026-06-22/final.mp4
       2. 從 Supabase daily_stories 撈當天 (zh-TW) row，
          用既有 caption.build_full_caption() 組文案
          （撈不到 → fallback 讀 narration.txt）
       3. IG Reels resumable upload：
          建 container → 直傳 bytes 到 rupload.facebook.com
          → 輪詢 status_code 直到 FINISHED → media_publish
       4. 印出 IG post id（不寫回 Supabase）
```

## 元件

### `backend/scripts/publish_reel.py`（新增）

薄 CLI，職責拆成小函式：

- `_resolve_video(date, override)` — 回傳要上傳的影片路徑。預設
  `outputs/daily_video/<date>/final.mp4`；`--video` 可覆寫。找不到時報錯並
  列出該資料夾現有檔案。
- `_build_caption(supabase, config, date, override)` — 回傳 caption 字串。
  優先序：`--caption` 覆寫 → Supabase `daily_stories`（zh-TW）那筆經
  `caption.build_full_caption()` 組裝 → fallback 讀該天 `narration.txt`。
- `main()` — argparse：
  - `date`（必填，`YYYY-MM-DD`）
  - `--caption "..."`（手動覆寫文案）
  - `--video <path>`（覆寫影片檔）
  - `--dry-run`（只印 caption 與將上傳的檔案，不實際發布）

### `backend/src/lorescape_backend/social/instagram.py`（擴充）

新增 `publish_reel(...)`，與既有圖片版 `publish()` 並存，封裝 Reels
resumable 三步驟，使邏輯可被單元測試、讓 script 保持薄。

```python
def publish_reel(
    *,
    ig_user_id: str,
    access_token: str,
    video_path: str,
    caption: str,
) -> str:
    """Create + resumable-upload + publish an IG Reel. Returns the IG post id."""
```

## IG Reels resumable upload（核心）

純本機上傳，不需公開網址、不需任何 server 或 storage。

1. **建 container**：`POST {GRAPH}/{ig_user_id}/media`
   - params：`media_type=REELS`、`upload_type=resumable`、`caption`、
     `access_token`
   - 回傳 `container_id`（`id`）與 rupload URL。若回應未含 URL，依
     `https://rupload.facebook.com/ig-api-upload/v21.0/{container_id}` 構造。
2. **直傳 bytes**：`POST {rupload_url}`
   - headers：`Authorization: OAuth {access_token}`、`offset: 0`、
     `file_size: {bytes}`
   - body：影片原始 bytes
3. **輪詢狀態**：`GET {GRAPH}/{container_id}?fields=status_code`
   - 直到 `FINISHED`；遇 `ERROR` / `EXPIRED` 立即報錯；含整體 timeout。
4. **發布**：`POST {GRAPH}/{ig_user_id}/media_publish`
   - params：`creation_id={container_id}` → 回傳 IG post id。

Graph API 版本沿用既有 `META_GRAPH_API = v21.0`。

## 設定與憑證

重用 `backend/.env` 既有變數，透過 `Config.from_env()` 載入：

- `IG_USER_ID`
- `META_PAGE_ACCESS_TOKEN`
- `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY`

不新增任何金鑰。發布前以 `config.instagram_enabled` 檢查憑證齊備。

## 錯誤處理

- 缺 token／IG 未設定 → 明確報錯（沿用 `config.instagram_enabled`）。
- 影片不存在 → 報錯並列出該天資料夾內容。
- Supabase 無當天 story → fallback `narration.txt`；都沒有則報錯要求
  `--caption`。
- 上傳／輪詢／發布任一步 raise → 印出 Graph API 回傳的錯誤內容以利除錯。

## 預設值（可由參數覆寫）

- 發布檔案：`final.mp4`（已加浮水印／品牌 lockup 的成品）。
- caption 語言：zh-TW。
- 不寫回 Supabase。

## 測試

- `instagram.publish_reel()`：mock `requests`，驗證三步驟的呼叫順序、URL 與
  關鍵參數（`media_type=REELS`、`upload_type=resumable`、`creation_id`），
  沿用 `backend/tests/test_instagram_client.py` 風格。
- `publish_reel.py`：
  - caption 優先序（覆寫 / Supabase / narration fallback）各一測試。
  - `_resolve_video` 找檔與找不到檔的行為。

## Skill 包裝

`.claude/skills/publish-reel/SKILL.md`：
- 描述觸發情境（「發布某天的影片到 IG Reels」「publish reel」等）。
- 說明前置條件（`backend/.env` 已填 IG 憑證）、指令用法、`--dry-run` 建議
  先試跑、發布後人工到 IG 確認。
