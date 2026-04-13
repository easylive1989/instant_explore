# Firebase Hosting 部署設定教學

本文說明如何將 Landing Page（Next.js 靜態站）部署到 Firebase Hosting，以及如何設定 GitHub Actions 自動部署。

---

## 目錄

1. [架構概覽](#1-架構概覽)
2. [前置準備](#2-前置準備)
3. [本地手動部署](#3-本地手動部署)
4. [GitHub Actions 自動部署](#4-github-actions-自動部署)
5. [自訂網域（選用）](#5-自訂網域選用)
6. [檢查清單](#6-檢查清單)

---

## 1. 架構概覽

```
landing/                  # Next.js 14 靜態站（原始碼）
  ├── src/app/            # 頁面與元件
  ├── public/images/      # 靜態圖片
  ├── next.config.mjs     # 已設定 output: "export"
  └── package.json

firebase.json             # Firebase Hosting 配置
.firebaserc               # Firebase 專案綁定（instant-explore-7b442）

.github/workflows/
  └── deploy-landing.yml  # 自動部署 workflow
```

### 部署流程

```
npm run build (Next.js)
       ↓
  landing/out/            # 靜態 HTML/CSS/JS
       ↓
firebase deploy --only hosting
       ↓
instant-explore-7b442.web.app
```

Next.js 使用 `output: "export"` 模式，build 後產出純靜態 HTML，搜尋引擎可直接爬取，對 SEO 友好。

---

## 2. 前置準備

### 需要的工具

- [Node.js](https://nodejs.org/) 20+
- [Firebase CLI](https://firebase.google.com/docs/cli)：`npm install -g firebase-tools`

### Firebase 專案資訊

| 項目 | 值 |
|------|-----|
| Project ID | `instant-explore-7b442` |
| 預設網域 | `instant-explore-7b442.web.app` |
| 備用網域 | `instant-explore-7b442.firebaseapp.com` |

---

## 3. 本地手動部署

### 3.1 登入 Firebase

```bash
firebase login
```

### 3.2 Build Landing Page

```bash
cd landing
npm install
npm run build
cd ..
```

build 完成後，靜態檔案會產出在 `landing/out/` 目錄。

### 3.3 部署到 Firebase Hosting

```bash
firebase deploy --only hosting
```

部署完成後，終端會顯示可存取的 URL：

```
✔ Deploy complete!

Hosting URL: https://instant-explore-7b442.web.app
```

### 3.4 預覽部署（不影響正式環境）

如果想先預覽再上線，可以用 preview channel：

```bash
firebase hosting:channel:deploy preview
```

這會產出一個臨時預覽 URL，不會影響正式站。

---

## 4. GitHub Actions 自動部署

### 4.1 觸發條件

自動部署 workflow（`.github/workflows/deploy-landing.yml`）在以下條件觸發：

- 推送到 `master` 分支
- 且變更包含 `landing/**`、`firebase.json` 或 `.firebaserc`

### 4.2 設定 Service Account（一次性）

GitHub Actions 需要 Firebase Service Account 才能部署。

#### 方式一：Firebase CLI 自動設定（推薦）

```bash
firebase init hosting:github
```

依照提示操作，CLI 會自動：
1. 在 Google Cloud 建立 Service Account 並賦予 Firebase Hosting Admin 權限
2. 將 Service Account JSON 寫入 GitHub repo 的 Secrets（名稱為 `FIREBASE_SERVICE_ACCOUNT`）

> 當 CLI 問是否要建立 workflow 檔案時，選 **No**（我們已經有了）。

#### 方式二：手動設定

1. 到 [Google Cloud Console](https://console.cloud.google.com) → 選擇專案 `instant-explore-7b442`
2. **IAM & Admin** → **Service Accounts** → **Create Service Account**
   - 名稱：`github-actions-deploy`
   - 角色：`Firebase Hosting Admin`
3. 點進 Service Account → **Keys** → **Add Key** → **Create new key** → 選 **JSON**
4. 下載的 JSON 檔案內容，複製貼到 GitHub repo：
   - **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
   - Name: `FIREBASE_SERVICE_ACCOUNT`
   - Value: JSON 檔案的完整內容

### 4.3 驗證自動部署

設定完 Secret 後，推送任何 `landing/` 的變更到 `master`，即可在 GitHub Actions 頁面看到 deploy job 執行。

---

## 5. 自訂網域（選用）

如果要綁定自訂網域：

1. 到 [Firebase Console](https://console.firebase.google.com) → Hosting → **Add custom domain**
2. 輸入你的網域（例如 `www.conexture.com`）
3. 依照指示到你的 DNS 供應商新增驗證用的 TXT record
4. 驗證通過後，新增 A record 指向 Firebase 提供的 IP
5. Firebase 會自動配發 SSL 憑證

---

## 6. 檢查清單

### 首次部署

- [ ] 已安裝 Firebase CLI（`firebase --version`）
- [ ] 已登入 Firebase（`firebase login`）
- [ ] 本地 `npm run build` 在 `landing/` 目錄成功
- [ ] `firebase deploy --only hosting` 成功
- [ ] 可在 `https://instant-explore-7b442.web.app` 看到 Landing Page

### GitHub Actions 自動部署

- [ ] GitHub Secrets 已設定 `FIREBASE_SERVICE_ACCOUNT`
- [ ] 推送 `landing/` 變更到 `master` 後，workflow 成功執行
- [ ] 部署後網站內容正確更新
