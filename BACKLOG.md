# Lorescape Backlog

專案層級放 features 與 tasks。feature 若服務某個公司 epic，於標題標 `(epic: EN)`；純專案層工作可不標。
feature 編號 `F1`、`F2`…；task 編號 `T1`、`T2`… nested 在所屬 feature 底下。
公司 epics 見 `../BACKLOG.md`（company repo）。

## ⚠️ 待部署（程式已在 repo，尚未上生產，2026-07-08）

以下改動已 commit + push 到 master，但**尚未部署到生產**，使用者尚看不到：

- [ ] **落地頁**（`landing/`）：build 並部署到 `lorescape.app`。含 F2/F6 T5 定價 section（廣告 7 天試用）
- [ ] **Backend**（`backend/`）：部署到 VPS。含 F1 T1 的 Reel caption CTA 文案（已改為固定常數、不吃 CTA_TEXT env）
- [ ] **App**（`frontend/`）：重新 build 並送商店審核上架（新版本），才會顯示 F6 T4 的「7 天免費試用」字樣
  - 註：商店端 7 天試用本身已對現有 App 生效（RevenueCat 自動帶出）；此步只影響 paywall 上「顯示那行字」
- 已是生產狀態、不需部署：App Store / Google Play 的試用設定、RevenueCat offering

## F1: IG 導流 CTA (epic: E1)
- 狀態: 已完成
- 來源: marketing/audits/cro-2026-07-06.md（P0）
- [x] T1: Reel caption 預設 CTA 改為導向個人檔案連結/App（config.py `_DEFAULT_CTA_TEXT`）
- [x] T2: IG bio 導引文案與連結（既有 bio 已含「🎧 免費下載 ↓」＋ lorescape.app 落地頁連結，2026-07-08 查證，維持現狀不新增直連商店按鈕以保留落地頁歸因）

## F2: 落地頁與商店定價/試用透明度 (epic: E1)
- 狀態: 已完成
- 來源: cro-2026-07-06.md（P1，Offer 層目前最弱）
- [x] T1: 落地頁新增方案與試用區塊（Free/週/月/年，2026-07-08，見 landing Pricing 元件，與 F6 T5 同一提交）
- [x] T2: 免費試用已導入（見 F6：月/年 7 天試用已在兩商店啟用），定價區塊明列試用

## F3: 落地頁「以 Wikipedia 為據」信任區塊 (epic: E1)
- 狀態: 已完成
- 來源: cro-2026-07-06.md（P1，異議處理 + proof）
- [x] T1: 新增「AI 說的，是真的嗎？」異議處理區塊，附 Wikipedia 出處 proof（2026-07-08，landing Trust 元件，置於 JourneyJournal 後、Pricing 前；本機視覺驗證通過）
- 註：原 T2（商店描述改 Wikipedia 為據開場）經使用者決定不做，已移除。

## F5: 留存/完成率量測 (epic: E1)
- 狀態: 未開始
- 來源: decisions/2026-07-07-現階段主線補流量暫緩新功能.md（埋點不受暫緩）；cro-2026-07-06.md（narration 完成率為 missing_data）
- 註: narration 四種事件（started/progress/completed/abandoned，含 completion_rate）已埋，見 docs/adr/0003；缺的是彙整視圖與留存量測
- [x] T1: 從既有 Firebase narration 事件彙整「聆聽完成率」視圖（2026-07-08，scripts/metrics/narration.py 查 GA4 事件算 completed/started 完成率，累積進 metrics Sheet；單元測試 21 passed；⚠️ live 抓取待 GA4 憑證放入 scripts/.env 後由 lorescape-metrics 實跑驗證）
- [ ] T2: 確認並補齊次日/7日留存的量測與檢視

## F6: 7 天免費試用 (epic: E1)
- 狀態: 已完成（2026-07-08，全部子步驟完成）
- 來源: F2 延伸；使用者決定導入 7 天試用（CRO P1「若無 trial，導入免費試用」）
- 決定: 試用套用**月方案＋年方案**，週方案不加（7 天≈整個週期）；地區全部、eligibility 新訂閱者
- 依賴: T4/T5 依賴 T1–T3 完成；商店設定（T1/T2）需使用者操作登入與同意協議，AI 不代做
- ⚠️ 落地頁（T5）在 T1–T2 真正設好前不得先廣告試用（避免誇大不實）
- [x] T1: App Store Connect — Premium Monthly / Yearly 各建 7 天免費試用介紹性優惠（2026-07-08 完成，首週免費、175 地區、新訂閱者、2026-07-08～2027-07-08、到期前需延長）
- [x] T2: Google Play — 月/年訂閱各建並啟用 7 天免費試用優惠（2026-07-08 完成，offer id free-trial-7d、獲取新客、從未訂閱任何項目、174 地區、狀態有效）
- [x] T3: 確認 RevenueCat offering 帶出 intro offer（2026-07-08 查證：offering「default」active，3 packages 正確對應月/年/週的 iOS 產品與 Android 基本方案；未綁特定 offer=標準做法，RevenueCat 執行期自動帶出符合資格的 free-trial-7d／iOS 介紹性優惠，RC 無需額外設定，新優惠可能需數分鐘同步）
- [x] T4: App paywall 顯示「7 天免費試用」（2026-07-08 完成，TDD；SubscriptionPlan 加 freeTrialDays、資料層讀 iOS introductoryPrice / Android freePhase、卡片顯示、free_trial_days 翻譯；subscription 30 tests + full suite pass）
- [x] T5: 落地頁定價區塊廣告 7 天試用（2026-07-08 完成，Pricing 元件，月/年標「7 天免費試用」、年標推薦；本機視覺驗證通過）

## F7: 免費方案文案/程式一致性查核

- 狀態: 已完成（2026-07-08）
- 來源: 落地頁定價修正時發現免費文案不一致
- 查核結論: 真實政策＝完整故事訂閱者專屬（後端 `narration/routes.py` 回 402 enforced）；免費可瀏覽故事角度＋每日精選故事，**無每日 on-demand 次數**。本地 `_dailyFreeLimit = 1` 只是顯示用計數器（非 enforcement），且免費用戶產生完整故事一律 402、`consumeUsage` 到不了，導致 settings 永遠顯示「剩餘 1 次」卻用不到。
- [x] T1/T2/T3: 移除 settings「每日使用」區塊；清掉沒在用的殘留翻譯（paywall_title/subtitle/remaining_usage、daily_usage/remaining_today）。App full suite 552 passed。
- 可選後續（未做）：本地 usage 計數器（`_dailyFreeLimit`/`consumeUsage`）移除顯示後成為內部殘留，若要一併移除需動 narration use case 與其測試，留待需要時再清。
- ⚠️ 此為 Flutter 改動，需隨「待部署 → App」一起重新 build 送審才會生效。
