# 產品面板設置

`dashboard/` 工具在本地收集 backlog / 測試 / 部署 / 產品數據，產生單一 HTML
面板（`dashboard/out/index.html`）並自動開瀏覽器。不部署、不上傳。

## 資料來源憑證（沿用既有設定，通常已存在）

| 區塊 | 來源 | 設定位置 |
|---|---|---|
| 產品數據 | metrics Google Sheet | `scripts/.env` 的 `METRICS_SHEET_ID` + `GOOGLE_APPLICATION_CREDENTIALS`（見 `docs/init/metrics-setup.md`） |
| 每日故事 | Supabase `social_posts` | `publisher/.env` 的 `SUPABASE_URL` + service key |
| 部署狀態 | GitHub Actions | `gh` CLI 已登入即可 |
| backlog / 測試 / E2E | repo 本身 | 無需設定 |

缺任一憑證時只有對應區塊顯示錯誤卡片，其餘照常產生。

## 執行

```bash
cd dashboard && uv run lorescape-dashboard            # 跑三套測試 + 全區塊更新
uv run lorescape-dashboard --skip-tests               # 跳過跑測試（用上次結果）
uv run lorescape-dashboard --only metrics,daily_story # 只刷新指定區塊
uv run lorescape-dashboard --no-open                  # 不自動開瀏覽器
```

各區塊收集結果快取在 `dashboard/out/data/*.json`（gitignore），跳過的區塊
沿用上次快取。
