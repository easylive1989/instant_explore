<!-- .claude/skills/lorescape-metrics/references/google-setup.md -->
# Google API 一次性設定（GSC + GA4）

GSC 與 GA4 都用 Application Default Credentials (ADC)，由使用者本機一次性登入。

## 1. 登入並授權 scope

在 Claude Code 對話框輸入（`!` 會在本機 session 執行）。注意 scope 之間
不能有空格，且 gcloud 規定必須包含 `cloud-platform`：

    ! gcloud auth application-default login --scopes=openid,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/webmasters.readonly

登入帳號須對下列資源有讀取權限：
- Search Console 中的目標網站（property）
- 目標 GA4 property

## 2. 填入 backend/.env

    GA4_PROPERTY_ID_WEB=514854947   # 單一資源，已含 web + iOS + Android 三個串流
    GA4_PROPERTY_ID_APP=            # 留空，否則同一資源被查兩次重複計算
    GSC_SITE_URL=                  # 等 GSC 資源驗證後再填（見下）

## 3. 找出 GA4 numeric property ID

- GA4 後台 → 管理 → 資源設定 → 「資源 ID」（純數字，例如 `514854947`）。
  注意：資料串流畫面上的大數字是「串流 ID」，不是資源 ID。
- web 與 app 若在同一個資源（本專案即如此），只填 `GA4_PROPERTY_ID_WEB`、
  `GA4_PROPERTY_ID_APP` 留空即可；單次查詢會回傳全平台合計。
- 自動探測（GA4 Admin API）為未來功能，目前請從 GA4 後台手動讀 ID。

## 4. GSC_SITE_URL

- 必須先在 Search Console 建立並驗證 lorescape.app 的資源。建議用「網域」
  類型（涵蓋所有子網域與 http/https），以 DNS TXT 驗證。
- 驗證後填 `GSC_SITE_URL=sc-domain:lorescape.app`；若用「網址前置字元」
  類型則填完全一致的 `https://lorescape.app/`（含結尾斜線）。
