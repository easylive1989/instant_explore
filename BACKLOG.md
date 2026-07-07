# Lorescape Backlog

專案層級放 features 與 tasks。feature 若服務某個公司 epic，於標題標 `(epic: EN)`；純專案層工作可不標。
feature 編號 `F1`、`F2`…；task 編號 `T1`、`T2`… nested 在所屬 feature 底下。
公司 epics 見 `../BACKLOG.md`（company repo）。

## F1: IG 導流 CTA (epic: E1)
- 狀態: 未開始
- 來源: marketing/audits/cro-2026-07-06.md（P0）
- [ ] T1: Reel 結尾加明確 CTA，把 reach 導向 profile/商店
- [ ] T2: IG bio 連結補上商店按鈕與導引文案

## F2: 落地頁與商店定價/試用透明度 (epic: E1)
- 狀態: 未開始
- 來源: cro-2026-07-06.md（P1，Offer 層目前最弱）
- [ ] T1: 落地頁新增方案與試用區塊（Free/週/月/年）
- [ ] T2: 確認 RevenueCat 是否已設免費試用，未設則導入或凸顯 Free 方案深度

## F3: 落地頁「以 Wikipedia 為據」信任區塊 (epic: E1)
- 狀態: 未開始
- 來源: cro-2026-07-06.md（P1，異議處理 + proof）
- [ ] T1: 新增「AI 說的，是真的嗎？」異議處理區塊，附 Wikipedia 出處 proof
- [ ] T2: 商店描述前 3 行改以「痛點→Wikipedia 為據的解法」開場

## F4: 落地頁初始社會證明徽章 (epic: E1)
- 狀態: 未開始
- 來源: cro-2026-07-06.md（P1）
- [ ] T1: Hero 下方放「App Store 5.0 ★」徽章

## F5: 留存/完成率量測 (epic: E1)
- 狀態: 未開始
- 來源: decisions/2026-07-07-現階段主線補流量暫緩新功能.md（埋點不受暫緩）；cro-2026-07-06.md（narration 完成率為 missing_data）
- 註: narration 四種事件（started/progress/completed/abandoned，含 completion_rate）已埋，見 docs/adr/0003；缺的是彙整視圖與留存量測
- [ ] T1: 從既有 Firebase narration 事件彙整「聆聽完成率」視圖（非重新埋點）
- [ ] T2: 確認並補齊次日/7日留存的量測與檢視
