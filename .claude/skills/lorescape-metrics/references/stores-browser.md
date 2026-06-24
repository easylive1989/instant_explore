# App Store / Play 瀏覽器抓取

App Store Connect 與 Play Console 第一版用 Chrome 自動化抓（沿用使用者
已登入的 session）。用 `claude-in-chrome` MCP 工具操作。

## 流程

1. 先 `tabs_context_mcp` 看現有分頁；用 `tabs_create_mcp` 開新分頁。
2. **App Store Connect**：開
   `https://appstoreconnect.apple.com/analytics` →
   選 Lorescape app → 區間對齊報告的 start/end → 讀「下載次數」與
   App Store 評分。用 `read_page` / 截圖取值。
3. **Play Console**：開 `https://play.google.com/console` →
   選 app → 「統計資料」讀安裝數，「評分」讀平均星等與評論數。
4. 把抓到的數字附加到 `docs/metrics/<結束日>/summary.md` 的
   `## stores` 段落，截圖存同資料夾（如 `stores-appstore.png`）。

## 注意

- 若未登入或要求二階段驗證，提醒使用者手動登入後再繼續，不要嘗試輸入密碼。
- 不要點任何會跳出 confirm/alert 對話框的按鈕（會卡住擴充功能）。
- 數字以網頁顯示為準，純人工核對，不寫回任何後端。
