---
name: publish-reel
description: Use when the user wants to manually publish a specific day's finished video from marketing/outputs/daily_video/<date>/ to Instagram Reels using the local IG token in backend/.env — e.g. "發布某天的影片到 IG reels", "把今天的影片發到 Reels", "publish reel for 2026-06-22". Local-only, does not touch the server's scheduled publish job.
---

# Publish a daily video to Instagram Reels (local, manual fallback)

手動把 `marketing/outputs/daily_video/<date>/final.mp4` 用本機 IG token 發布為 IG Reels。
完全在本機執行，不寫回 Supabase 的發布狀態。

**這是手動 fallback / 補發工具。** 正常流程是
`scripts/upload_reel_to_vps.sh <date>` 把影片 rsync 上 VPS 並送進
Discord 審核（影片訊息，與 carousel 審核**各自獨立**）；✅ 後 publisher
容器在 21:10（Asia/Taipei）自動發布，23:10 再檢查一次，仍無反應標
`skipped`。只有自動發布錯過（skipped）、被誤 ❌、或發布失敗排查後才走
這裡。注意：本 skill 發布成功**不會**寫 `social_posts`，若該日 reel 列
還在 pending 且之後被按 ✅，publisher 可能重複發——手動補發前先確認該列
已是 skipped/rejected，或補發後不要再對審核訊息按 ✅。

## 前置條件

- `backend/.env` 已填好 `IG_USER_ID`、`META_PAGE_ACCESS_TOKEN`、
  `SUPABASE_URL`、`SUPABASE_SERVICE_ROLE_KEY`（取得方式見
  `docs/init/social_publisher_setup.md`）。
- 目標日期的 `marketing/outputs/daily_video/<date>/final.mp4` 已存在。

## 步驟

1. 跟使用者確認要發布的日期（如 `2026-06-22`）。
2. **先 dry-run** 檢查影片路徑與將送出的 caption：

   ```bash
   cd scripts && uv run python -m publish_reel <date> --dry-run
   ```

   把 caption 念給使用者確認。caption 來源優先序：`--caption` 覆寫 →
   Supabase 當天 zh-TW daily story → 該天 `narration.txt`。

   **確認授權（BY + SA）**：caption 結尾的 `📷` 署名來自故事的
   `image_attribution`。若封面是 **CC BY-SA**（如維基百科主圖），只有署名
   還不夠——那張圖疊字後的封面是「改作」，SA 條款要求同時宣告封面依相同
   CC BY-SA 版本釋出並註明改作。正確做法是把 BY+SA 寫進故事的
   `image_attribution`（見 lorescape-manual-daily-story 的 §5d），讓輪播與
   reel 兩邊 caption 自動帶到；臨時發布可用 `--caption` 覆寫補上，例如：
   `📷 封面圖：<作者> / CC BY-SA <版本> (via Wikimedia Commons)｜本封面為改作，同依 CC BY-SA <版本> 釋出，歡迎在相同條款下轉載、改作。`
   影片素材若來自 Unsplash 則無 SA 義務，SA 只鎖封面、且不需強調 AI 生成。

3. 使用者確認後，正式發布：

   ```bash
   cd scripts && uv run python -m publish_reel <date>
   ```

   成功會印出 `Published reel: <ig_post_id>`。

4. 提醒使用者到 Instagram App 確認 Reel 已上架（Reels 處理需要幾秒到幾分鐘）。

## 常用旗標

- `--caption "自訂文案"`：手動覆寫文案。
- `--video /path/to/clip.mp4`：發布非預設檔案。
- `--dry-run`：只印影片與 caption，不實際發布。

## 疑難排解

**自動發布沒發？** 依序檢查（前三步可用 lorescape-debug skill 的
service-role curl）：

1. **VPS 上有沒有影片**：`ssh lorescape-vps ls /opt/lorescape-media/daily_video/<date>/`
   —— 沒有就是本機忘了跑 `scripts/upload_reel_to_vps.sh`。
2. **social_posts 狀態**：查該日 `media_type=reel` 列——
   - 沒有列 = 沒送審（upload script 的送審步驟失敗或沒跑）
   - `pending` = 還沒人對影片訊息按 ✅（21:10/23:10 前補按即可）
   - `skipped` = 23:10 前都沒反應，已停止自動發布 → 用本 skill 補發
   - `rejected` = 被按了 ❌
   - `failed` 的 `error` 欄有 Graph API 錯誤訊息；`published` 表示其實已發出
3. **Discord 審核訊息**：確認 ✅ 是核准者本人按的（bot 種的 ✅ 不算）。
4. **publisher log**：`ssh lorescape-vps "cd /opt/lorescape/backend && docker compose logs --since 24h publisher"`。

手動發布問題：

- `Instagram not configured`：`backend/.env` 缺 `IG_USER_ID` 或
  `META_PAGE_ACCESS_TOKEN`。
- `final.mp4 not found`：確認該天資料夾與檔名，或用 `--video` 指定。
- `No daily_stories row ... and no narration.txt`：用 `--caption` 提供文案。
- 發布失敗會印出 Graph API 的錯誤訊息（多半是 token 過期或帳號未設為
  商業/創作者帳號）。
