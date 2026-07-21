# CODING AGENTS: READ THIS FIRST

This is a **handoff bundle** from Claude Design (claude.ai/design).

A user mocked up designs in HTML/CSS/JS using an AI design tool, then exported this bundle so a coding agent can implement the designs for real.

## What you should do — IMPORTANT

**Read `lorescape/project/Lorescape 官網.html` in full.** The user had this file open when they triggered the handoff, so it's almost certainly the primary design they want built. Read it top to bottom — don't skim. Then **follow its imports**: open every file it pulls in (shared components, CSS, scripts) so you understand how the pieces fit together before you start implementing.

**If anything is ambiguous, ask the user to confirm before you start implementing.** It's much cheaper to clarify scope up front than to build the wrong thing.

## About the design files

The design medium is **HTML/CSS/JS** — these are prototypes, not production code. Your job is to **recreate them pixel-perfectly** in whatever technology makes sense for the target codebase (React, Vue, native, whatever fits). Match the visual output; don't copy the prototype's internal structure unless it happens to fit.

**Don't render these files in a browser or take screenshots unless the user asks you to.** Everything you need — dimensions, colors, layout rules — is spelled out in the source. Read the HTML and CSS directly; a screenshot won't tell you anything they don't.

## Bundle contents

- `lorescape/README.md` — this file
- `lorescape/project/` — the `Lorescape` project files (HTML prototypes, assets, components)

## Redesign v2（2026-07-21 追加匯入）

`project/Lorescape Redesign v2.html` + `project/app2/` 是**第二版**設計稿，
對應 BACKLOG 的 F17（探索頁）與 F18（歷程頁）。`project/app/`（v1）是目前
App 已實作的版本，`app2/` 是要往前推的新版。

v1 → v2 的主要差異：

| 畫面 | v1（已實作） | v2（新設計） |
|---|---|---|
| 探索 | 直式地點列表 + 搜尋列 | **全螢幕世界地圖**（Leaflet + OSM，sepia 濾鏡）＋浮在地圖上的標題/搜尋列＋底部橫向 `map-card` 卡片列（點卡片 fly-to、點箭頭進地點頁）＋收藏 FAB |
| 歷程 | 分段控制：全部時間軸 / 依旅程（磁磚格） | **Masthead ＋ 旅程書架**（`.shelf` 立體書背，點書進旅程）；時間軸從首頁移除 |
| 旅程詳情 | 直式時間軸列表 | **手記翻頁器**（`nb-*`：紙張質感、拍立得照片＋膠帶、Long Cang 手寫標題、左右滑動 + 頁點） |

僅匯入 F17/F18 需要的檔案：`app2/ls2.css`、`app2/ui.jsx`、
`app2/screens_explore.jsx`、`app2/screens_history.jsx`。其餘 app2 檔案
（icons / data / app / screens_story / stories2 / settings / paywall）留在
Claude Design 專案 `dcdb2009-b819-4361-8be6-eeb8ba93005b`，需要時再匯入。

程式面對應：設計 token 已落在 `frontend/lib/app/config/lorescape_tokens.dart`
（由 `ls2.css` 的 `:root` 變數轉出），共用元件在
`frontend/lib/shared/widgets/journal/`。
