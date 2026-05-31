# Google Analytics 設定指南

Landing 站已經透過 [`@next/third-parties`](https://nextjs.org/docs/app/building-your-application/optimizing/third-party-libraries#google-analytics) 接好 GA4，且正式 Measurement ID（`G-TCYSEZX8T6`）已寫進 `.env.production`，每次 `pnpm build` 都會自動套用，**不需額外設定**。

以下為背景說明與日後換 ID / 本地驗證時的參考。

## 運作方式

- 追蹤碼由 `src/app/layout.tsx` 中的 `<GoogleAnalytics />` 元件注入。
- Measurement ID 從環境變數 `NEXT_PUBLIC_GA_ID` 讀取。
- **若環境變數沒設定（留空），就完全不會載入 GA**，不影響站台運作。
- 本站是靜態匯出（`output: export`），環境變數會在 **build 當下** 被寫死進產物，所以一定要在 build 之前設定好。

## 步驟一：取得 GA4 Measurement ID

1. 登入 [Google Analytics](https://analytics.google.com/)。
2. 建立（或選用既有的）GA4 資源（Property）。
3. 在「管理 → 資料串流」新增一個 **Web** 串流，網址填 landing 站正式網域。
4. 複製該串流的 **Measurement ID**，格式為 `G-XXXXXXXXXX`。

## 步驟二：設定環境變數

### 本地開發 / 測試

複製範本並填入 ID：

```bash
cd landing
cp .env.example .env.local
# 編輯 .env.local，填入：
# NEXT_PUBLIC_GA_ID=G-XXXXXXXXXX
```

`.env.local` 已被 `.gitignore` 排除，不會進版控。

驗證方式：

```bash
pnpm build
grep -o "gtag/js?id=G-XXXXXXXXXX" out/index.html   # 有印出代表注入成功
```

或 `pnpm dev` 後，用瀏覽器開發者工具的 Network 面板確認有對 `googletagmanager.com/gtag/js` 的請求；GA4 後台「即時」報表也應出現自己的造訪。

### 正式部署

正式 ID 已寫在版控內的 `landing/.env.production`，任何環境執行 `pnpm build` 都會自動帶上，**無需在部署平台另設環境變數**。

若要更換 ID，直接編輯 `.env.production` 的 `NEXT_PUBLIC_GA_ID` 後重新 build 即可。部署平台若另外設了同名環境變數，會覆蓋此檔的值。

> ⚠️ 改了 ID 一定要 **重新 build**，舊產物裡的 ID 不會自動更新。

## 注意事項

- `NEXT_PUBLIC_` 開頭的變數會被打包進前端、對外公開。GA Measurement ID 本來就是公開資訊，這沒有安全疑慮。
- 若日後要正式上線並涉及歐盟 / 台灣使用者，建議再評估 Cookie 同意（consent banner）需求；目前實作為「載入即追蹤」。
