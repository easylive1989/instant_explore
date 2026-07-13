# 建立 `reel-videos` Supabase Storage bucket（F11 video_url fallback）

Reel 發布在 Meta rupload 端點回泛型 `ProcessingFailedError` 時，會 fallback
到 `video_url` container 路徑：影片暫存到公開的 `reel-videos` bucket，讓
Meta 自己抓公開網址（不經 rupload），發布流程結束後即刪除暫存檔（詳見
BACKLOG F11 與 `lorescape_publisher/reel_video_storage.py`）。

此步驟**每個環境一次性**（已於 2026-07-13 在 prod 以 Storage API 建立）。
bucket 被刪除時才需重做。

## 設定

- **Name**: `reel-videos`
- **Public bucket**: ✅ 啟用（Meta 伺服器匿名抓取）
- **File size limit**: `50 MB`（backlog 原建議 100MB，但專案全域上傳上限為
  50MB，Storage API 會回 413；每日 reel 約 33MB，50MB 足夠）
- **Allowed MIME types**: `video/mp4`

## 以 Storage API 建立（Dashboard 亦可）

```bash
curl -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id":"reel-videos","name":"reel-videos","public":true,
       "file_size_limit":52428800,"allowed_mime_types":["video/mp4"]}' \
  "https://<project-ref>.supabase.co/storage/v1/bucket"
```

## 驗證

1. `GET /storage/v1/bucket/reel-videos` 確認 `public: true` 與 50MB 上限。
2. 上傳任一小檔後，匿名開
   `/storage/v1/object/public/reel-videos/<path>` 應回 200，驗畢刪除。

## 生命週期

- 檔案路徑：`<publish_date>/final.mp4`，upsert 覆寫，重試冪等。
- 發布嘗試結束（成功或失敗）即刪除暫存檔；FINISHED 的 Meta container 已有
  自己的副本，失敗的 container 約 24h 自動過期。
- 平時 bucket 應為空；若殘留檔案代表某次 fallback 的清理失敗（publisher
  log 會有 `Could not delete temp reel video` 警告），手動刪除即可。
