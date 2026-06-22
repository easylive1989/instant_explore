---
name: publish-reel
description: Use when the user wants to manually publish a specific day's finished video from outputs/daily_video/<date>/ to Instagram Reels using the local IG token in backend/.env — e.g. "發布某天的影片到 IG reels", "把今天的影片發到 Reels", "publish reel for 2026-06-22". Local-only, does not touch the server's scheduled publish job.
---

# Publish a daily video to Instagram Reels (local)

手動把 `outputs/daily_video/<date>/final.mp4` 用本機 IG token 發布為 IG Reels。
完全在本機執行，不經 server 排程、不寫回 Supabase。

## 前置條件

- `backend/.env` 已填好 `IG_USER_ID`、`META_PAGE_ACCESS_TOKEN`、
  `SUPABASE_URL`、`SUPABASE_SERVICE_ROLE_KEY`（取得方式見
  `docs/social_publisher_setup.md`）。
- 目標日期的 `outputs/daily_video/<date>/final.mp4` 已存在。

## 步驟

1. 跟使用者確認要發布的日期（如 `2026-06-22`）。
2. **先 dry-run** 檢查影片路徑與將送出的 caption：

   ```bash
   cd backend && uv run python -m scripts.publish_reel <date> --dry-run
   ```

   把 caption 念給使用者確認。caption 來源優先序：`--caption` 覆寫 →
   Supabase 當天 zh-TW daily story → 該天 `narration.txt`。

3. 使用者確認後，正式發布：

   ```bash
   cd backend && uv run python -m scripts.publish_reel <date>
   ```

   成功會印出 `Published reel: <ig_post_id>`。

4. 提醒使用者到 Instagram App 確認 Reel 已上架（Reels 處理需要幾秒到幾分鐘）。

## 常用旗標

- `--caption "自訂文案"`：手動覆寫文案。
- `--video /path/to/clip.mp4`：發布非預設檔案。
- `--dry-run`：只印影片與 caption，不實際發布。

## 疑難排解

- `Instagram not configured`：`backend/.env` 缺 `IG_USER_ID` 或
  `META_PAGE_ACCESS_TOKEN`。
- `final.mp4 not found`：確認該天資料夾與檔名，或用 `--video` 指定。
- `No daily_stories row ... and no narration.txt`：用 `--caption` 提供文案。
- 發布失敗會印出 Graph API 的錯誤訊息（多半是 token 過期或帳號未設為
  商業/創作者帳號）。
