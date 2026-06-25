# Google API 設定（GSC + GA4）

> ⚠️ 早期版本教的 `gcloud auth application-default login` 做法**已棄用**——
> `analytics.readonly` / `webmasters.readonly` 是敏感 scope，會被 Google 擋
> 「系統已封鎖這個應用程式」。改用 **service account**。

完整步驟（建 service account、啟用 API、授權資源、GA4 單一資源、GSC 網域
驗證）見專案根目錄文件：

**`docs/metrics-setup.md` §A（Google）與 §B（Instagram）**

重點：
- `backend/.env` 設 `GOOGLE_APPLICATION_CREDENTIALS=<service account JSON 金鑰路徑>`。
- `GA4_PROPERTY_ID_WEB=514854947`（web/app 同一資源，`GA4_PROPERTY_ID_APP` 留空）。
- `GSC_SITE_URL=sc-domain:lorescape.app`（網域類型，Cloudflare DNS 驗證）。
- 在 service account 所屬 GCP 專案啟用 `searchconsole.googleapis.com` 與
  `analyticsdata.googleapis.com`。
