<!-- .claude/skills/lorescape-metrics/references/google-setup.md -->
# Google API 一次性設定（GSC + GA4）

GSC 與 GA4 都用 Application Default Credentials (ADC)，由使用者本機一次性登入。

## 1. 登入並授權 scope

在 Claude Code 對話框輸入（`!` 會在本機 session 執行）：

    ! gcloud auth application-default login --scopes=openid,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/webmasters.readonly

登入帳號須對下列資源有讀取權限：
- Search Console 中的目標網站（property）
- 目標 GA4 property

## 2. 填入 backend/.env

    GSC_SITE_URL=https://lorescape.app/        # 或 sc-domain:lorescape.app
    GA4_PROPERTY_ID_WEB=<numeric property id>   # landing (G-TCYSEZX8T6 對應的 property)
    GA4_PROPERTY_ID_APP=<numeric property id>   # Firebase app (instant-explore-7b442)

## 3. 找出 GA4 numeric property ID

- GA4 後台 → 管理 → 資源設定 → 「資源 ID」（純數字）。
- 自動探測（GA4 Admin API）為未來功能，目前請從 GA4 後台手動讀 ID。
- `GSC_SITE_URL` 必須與 Search Console 顯示的 property 完全一致（含 `https://`、
  結尾斜線，或 `sc-domain:` 前綴）。
