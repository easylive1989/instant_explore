---
name: lorescape-scheduler
description: Use when the user starts the day's work on Lorescape — 「開工」「開始今天的工作」「先處理 scheduler」「今天要做什麼」/lorescape-scheduler — to read SCHEDULE.md, verify from artifacts which routine items are already done, list today's todos, and drive them in order by invoking each item's skill.
---

# Lorescape Scheduler：每日開工入口

讀 repo 根目錄的 `SCHEDULE.md`，算出今日待辦，由產出物查證完成度，
依序帶著做。本 skill 是純入口：不重複實作任何流程，只做排程判斷、
完成度查證、依序調度。SCHEDULE.md 是唯一資料源，項目增刪改一律改該檔。

## 步驟

### 1. 算出今日待辦

- 每日表：全列。
- 每週表：今天是週一才列。
- 每月表：今天是 1 號才列。
- 表格外的「註記」不是待辦項（如 reels calendar 期末檢核，跟期別結束日走）。

### 2. 查證哪些已完成（不靠狀態檔，看產出物）

| 項目 | 查證方式 |
|---|---|
| 每日故事 | 用 /lorescape-debug 的今日狀態查法看 Supabase 今天是否已有發布記錄 |
| wander 圖組 / reel | 同上看今日 posts 的 media type；reel 另看 `marketing/outputs/daily_video/<今天>/` 是否有成品 |
| metrics | `data/metrics/*.csv` 各檔最新日期是否已含昨日 |
| 週：下週 calendar | `marketing/content-calendar/_reels-place-calendar.md` 的範圍是否已涵蓋下週 |
| 週報 / 月報 | `marketing/audits/` 是否已有本期報告檔；沒有落地檔就直接問使用者 |
| 手動項（寫 BACKLOG） | 問使用者或看 `BACKLOG.md` 當日 diff |

### 3. 列清單並依序執行

- 以 checklist 列出每項：時間、工作、狀態（✅ 已完成 / ⬜ 待做）。
- 依表格順序逐項做：每項呼叫「指令 / skill」欄對應的 skill，
  一項完成再進下一項。
- 「手動」項：提出具體建議內容，請使用者確認後代為執行。
- 同一天重跑：已完成項直接跳過，不重做。
