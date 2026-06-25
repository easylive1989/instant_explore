# Landing Page 雙語（中／英）設計

日期：2026-06-25
範圍：`landing/`（Next.js 14 App Router，靜態匯出，部署於 Firebase Hosting）

## 目標

讓 landing page 支援繁體中文與英文，**首訪自動偵測**瀏覽器語言顯示對應版本，
使用者亦可手動切換，且每個語言有**獨立網址**以利 SEO。

## 現況（修正後的正確認知）

語言目前是混的：

- **首頁** `src/app/page.tsx` 與其 section component（Hero / Manifesto /
  LocalStories / ManyAngles / ExploreNearby / JourneyJournal / FinalCTA）以及
  **Navbar / Footer** → 繁體中文，字串寫死在 component 內。
- **`/privacy`、`/terms`、`/support`、`/credits`** → **已經是英文**。
- 既有不一致：英文法律頁仍套用中文的 Navbar / Footer，本次順手修正為語言對應。

技術前提：

- `next.config.mjs` 為 `output: "export"`（純靜態），`images.unoptimized`。
- Firebase Hosting `public: landing/out`，`cleanUrls: true`、`trailingSlash: false`。
- 無伺服器可依 `Accept-Language` 重導；自動偵測改由前端 JS 完成。

## 決策摘要

| 項目 | 決定 |
| --- | --- |
| 偵測方式 | 首訪前端 JS 偵測 `navigator.language`，記憶於 `localStorage`，可手動切換 |
| 部署平台 | Firebase Hosting（靜態匯出），排除 Firebase 原生 i18n（同 URL 換內容，不利 SEO） |
| 英文文案 | 由 Claude 起草 transcreation（依品牌調性重新創譯，非逐字直譯），交使用者審閱 |
| URL 結構 | 方案 A：`[locale]` 路由 → `/zh` ＋ `/en`，根目錄 `/` 偵測後重導 |
| i18n 機制 | 自製型別化字典，不引入 `next-intl`（5 頁行銷站，相依最少、最相容靜態匯出） |
| 法律/support/credits | 維持英文單一版本、網址不變（`/privacy` 等）；中英兩語言 footer 都連到這幾頁 |

## 架構

### 路由結構

```
src/app/
  layout.tsx              # root pass-through，只 return children（html 交由下層渲染）
  page.tsx                # "/" 偵測頁：渲染最小 html + inline redirect script
  [locale]/
    layout.tsx            # generateStaticParams → ['zh','en']；渲染 <html lang>；generateMetadata（hreflang/canonical）
    page.tsx              # 首頁；getDictionary(locale) 後傳給各 section
  (legal)/                # route group（不影響 URL）
    layout.tsx            # 渲染 <html lang="en">
    privacy/page.tsx      # 內容不變（英文）
    terms/page.tsx        # 內容不變
    support/page.tsx      # 內容不變
    credits/page.tsx      # 內容不變
```

- 採 next-intl 官方建議的「root layout 不渲染 html、交由下層 layout 渲染」寫法，
  解決 App Router 中每頁 `<html lang>` 需不同的問題（`/zh`→`zh-Hant`、`/en`→`en`、
  legal→`en`）。Next 對此會有 lint 提醒但可正常運作。
- **URL 變動最小**：法律頁網址完全不變（route group 不影響路徑），故**無需** firebase
  redirect；唯一語意變動是中文首頁 canonical 由 `/` 移到 `/zh`，由 hreflang/canonical 處理。
- `/` 偵測頁不需 404 任何路徑，因此 `firebase.json` 不需新增 redirects。

### 共用站體外殼

抽出 `src/components/SiteHtml.tsx`，封裝 `<html lang><head>…<body>{children}</body></html>`，
含字型 CSS variable、Material Symbols head link、GoogleAnalytics、JSON-LD。
`[locale]/layout.tsx` 與 `(legal)/layout.tsx` 共用之，避免重複。

- 字型（`Noto_Serif_TC` / `Noto_Sans_TC`）以 `next/font` 在模組層宣告，移到
  `src/app/fonts.ts` 供 `SiteHtml` 套用 className。

### i18n 內容層

```
src/i18n/
  config.ts        # locales = ['zh','en'] as const；defaultLocale = 'zh'；type Locale；isLocale(x) 守衛
  dictionaries.ts  # type Dict + zh/en 兩個物件 + getDictionary(locale): Dict
```

- `Dict` 形狀對應首頁區塊與站體 chrome：`nav`、`hero`、`manifesto`、`localStories`、
  `manyAngles`、`exploreNearby`、`journeyJournal`、`finalCTA`、`footer`、`metadata`
  （title / description / keywords / og）。
- 法律頁不進字典（維持頁內既有英文）。

### Component 改動

- **各 section component**（Hero 等）：由寫死字串改為接收對應的 `dict` slice 作為 prop，
  純展示、不含語言判斷。
- **Navbar / Footer**：改為接收 `dict` 與 `homeHref`（`/zh` 或 `/en`）。
  - 頁內錨點需 locale 感知：在首頁用 `#stories`，在法律頁等非首頁則為 `${homeHref}#stories`，
    確保點擊能回到正確語言首頁的區塊。
  - legal layout 傳入英文 dict 與 `homeHref="/en"`（修正英文頁顯示中文 chrome 的舊問題）。
- **LocaleSwitch.tsx**（新增）：Navbar 內「中／EN」切換，連到另一語言的對應頁，
  並寫入 `localStorage.lorescape_locale`。

### 自動偵測（`/` 偵測頁）

`src/app/page.tsx` 為 server component，於 `<head>` 注入同步 inline script：

1. 讀 `localStorage.lorescape_locale`，若為 `zh`/`en` 直接 `location.replace` 對應路徑。
2. 否則看 `navigator.language`：開頭 `zh` → `/zh`，其餘 → `/en`。
3. 無 JS 後備：`<meta http-equiv="refresh" content="0;url=/zh">`（預設中文）。

script 於 paint 前同步執行以降低閃爍。

### SEO

- `[locale]/layout.tsx` 的 `generateMetadata`：
  - `alternates.canonical` 指向自身（`/zh` 或 `/en`）。
  - `alternates.languages`：`{ 'zh-Hant': '/zh', en: '/en', 'x-default': '/' }`。
  - title / description / keywords / openGraph 依 locale 取自字典。
- `src/app/sitemap.ts`：輸出 `/zh`、`/en`（首頁兩語言）＋ 不變的 `/privacy`、`/terms`、
  `/support`、`/credits`。
- 法律頁為英文單一版本，self-canonical，無 hreflang alternates。

## 不做（YAGNI）

- 不引入 `next-intl` 或任何 i18n 套件。
- 不做 privacy/terms 的中文化（法律敏感，維持英文單一版）。
- 不做 support/credits 中文化（本次聚焦首頁雙語）。
- 不動 Firebase i18n 設定、不加 firebase redirects。
- 不做語言以外的視覺/版面改版。

## 驗證

- `cd landing && npm run build` 成功，`out/` 須含 `zh/`、`en/`（含各自 `index.html`）與
  不變的 `privacy`、`terms`、`support`、`credits`。
- `npm run lint` 通過。
- 手動：`/` 在中文瀏覽器導向 `/zh`、非中文導向 `/en`；切換鈕雙向可用且記憶；
  `/zh` 顯示 `lang="zh-Hant"`、`/en` 顯示 `lang="en"`；英文法律頁顯示英文 Navbar/Footer。
- 英文首頁文案交使用者審閱後再定稿。

## 開放項（實作中確認）

- 英文 transcreation 文案最終措辭由使用者審閱。
- root layout 不渲染 html 的 Next lint 提醒若造成 build 失敗，退而在 root layout 渲染
  中性 `<html lang="zh-Hant">` 並於下層以 script 覆寫 `document.documentElement.lang`。
