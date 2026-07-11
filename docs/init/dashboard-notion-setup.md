# 產品面板 Notion 一次性設置

`dashboard/` 工具會把面板內容整頁重寫到一個 Notion 頁面。首次使用前需要：

## 1. 建立 Notion internal integration

1. 開 <https://www.notion.so/my-integrations> → 「New integration」。
2. 名稱例如 `Lorescape Dashboard`，Workspace 選你的工作區，Type 維持 Internal。
3. Capabilities 勾 **Read content / Update content / Insert content**。
4. 建立後複製 **Internal Integration Secret**（`ntn_` 或 `secret_` 開頭）。

## 2. 指定面板頁面並分享給 integration

1. 在 Notion 建（或選）一個空白頁面當面板。
   ⚠️ 此頁內容**每次更新會被整頁清空重寫**，不要放手動筆記。
2. 頁面右上 `…` → 「Connections」→ 加入剛建立的 integration。
3. 從頁面 URL 取得 page ID：網址結尾的 32 碼 hex（有無 `-` 皆可）。

## 3. 填入 dashboard/.env

```bash
NOTION_TOKEN=ntn_xxx
NOTION_DASHBOARD_PAGE_ID=<32 碼 hex>
```

## 4. 其他資料來源的憑證（沿用既有設定，通常已存在）

| 區塊 | 來源 | 設定位置 |
|---|---|---|
| 產品數據 | metrics Google Sheet | `scripts/.env` 的 `METRICS_SHEET_ID` + `GOOGLE_APPLICATION_CREDENTIALS`（見 `docs/init/metrics-setup.md`） |
| 每日故事 | Supabase `social_posts` | `publisher/.env` 的 `SUPABASE_URL` + service key |
| 部署狀態 | GitHub Actions | `gh` CLI 已登入即可 |

缺任一憑證時只有對應區塊顯示錯誤卡片，其餘照常更新。

## 5. 執行

```bash
cd dashboard && uv run lorescape-dashboard            # 跑測試 + 全區塊更新
uv run lorescape-dashboard --skip-tests               # 跳過跑測試（用上次結果）
```
