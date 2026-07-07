# Lorescape Backlog

專案層級放 features 與 tasks。feature 若服務某個公司 epic，於標題標 `(epic: EN)`；純專案層工作可不標。
feature 編號 `F1`、`F2`…；task 編號 `T1`、`T2`… nested 在所屬 feature 底下。
公司 epics 見 `../BACKLOG.md`（company repo）。

## F1: IG 導流 CTA (epic: E1)
- 狀態: 已完成
- 來源: marketing/audits/cro-2026-07-06.md（P0）
- [x] T1: Reel caption 預設 CTA 改為導向個人檔案連結/App（config.py `_DEFAULT_CTA_TEXT`）
- [x] T2: IG bio 導引文案與連結（既有 bio 已含「🎧 免費下載 ↓」＋ lorescape.app 落地頁連結，2026-07-08 查證，維持現狀不新增直連商店按鈕以保留落地頁歸因）

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

## F6: 7 天免費試用 (epic: E1)
- 狀態: 進行中（暫停於 App Store Connect 設定，2026-07-08）
- 來源: F2 延伸；使用者決定導入 7 天試用（CRO P1「若無 trial，導入免費試用」）
- 決定: 試用套用**月方案＋年方案**，週方案不加（7 天≈整個週期）；地區全部、eligibility 新訂閱者
- 依賴: T4/T5 依賴 T1–T3 完成；商店設定（T1/T2）需使用者操作登入與同意協議，AI 不代做
- ⚠️ 落地頁（T5）在 T1–T2 真正設好前不得先廣告試用（避免誇大不實）
- [ ] T1: App Store Connect — Premium Monthly / Yearly 各建 7 天免費試用介紹性優惠（今日停在 Premium Monthly 訂閱頁找「介紹性優惠」入口，尚未建立任何 offer、未送出任何設定）
- [ ] T2: Google Play — 月/年訂閱設 7 天免費試用
- [ ] T3: 確認 RevenueCat offering 帶出 intro offer
- [ ] T4: App paywall 顯示「7 天免費試用」（SubscriptionPlan 目前無試用欄位，需讀 RevenueCat package 的 intro offer）
- [ ] T5: 落地頁定價區塊廣告 7 天試用（依賴 T1–T2）
