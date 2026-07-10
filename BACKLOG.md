# Lorescape Backlog

專案層級放 features 與 tasks。feature 若服務某個公司 epic，於標題標 `(epic: EN)`；純專案層工作可不標。
feature 編號 `F1`、`F2`…；task 編號 `T1`、`T2`… nested 在所屬 feature 底下。
公司 epics 見 `../BACKLOG.md`（company repo）。

## ⚠️ 待部署（程式已在 repo，尚未上生產，2026-07-08）

以下改動已 commit + push 到 master，但**尚未部署到生產**，使用者尚看不到：

- [x] **落地頁**（`landing/`）：已部署到 `lorescape.app`（2026-07-09，Deploy Landing workflow 從 master HEAD 重建，正式站驗證通過）。含 F2/F6 T5 定價 section（廣告 7 天試用）與 F9 景點著陸頁
- [x] **Backend**（`backend/`）：已部署到 VPS（2026-07-09，Deploy Backend workflow `git reset --hard origin/master` + `docker compose up -d --build`）。含 F1 T1 的 Reel caption CTA 文案（已改為固定常數、不吃 CTA_TEXT env）＋ F8 發布 bot
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
- 狀態: 已完成（含 live GA4 驗證）
- 來源: decisions/2026-07-07-現階段主線補流量暫緩新功能.md（埋點不受暫緩）；cro-2026-07-06.md（narration 完成率為 missing_data）
- 註: narration 四種事件（started/progress/completed/abandoned，含 completion_rate）已埋，見 docs/adr/0003；缺的是彙整視圖與留存量測
- live 驗證（2026-07-08，`lorescape-metrics --only narration,retention`）：retention 寫入 13 rows 真實 cohort 資料；narration 查詢正確、事件名（narration_started/completed/abandoned）與 App logEvent 相符，目前 0 rows（pre-traffic，尚無播放事件，有流量後自動填）。兩來源已在 metrics Sheet。
- [x] T1: 從既有 Firebase narration 事件彙整「聆聽完成率」視圖（scripts/metrics/narration.py，GA4 completed/started；單元測試通過 + live 驗證）
- [x] T2: 次日/7日留存量測（scripts/metrics/retention.py，GA4 cohort D1/D7，回溯 14 天重算；單元測試通過 + live 驗證 13 rows）

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

## F8: 每日故事 IG 發布改用 Discord bot (epic: E1)

- 狀態: 已完成並上線（2026-07-09）
- 來源: 使用者要求「每日貼文一建立就發布、不需 server 排程」→ 收斂為常駐 Discord 互動 bot
- 設計/計畫: `docs/superpowers/specs/2026-07-09-discord-publish-bot-design.md`、`docs/superpowers/plans/2026-07-09-discord-publish-bot.md`
- 架構: 常駐 Discord Gateway bot（`lorescape_backend.social.publisher_bot`，publisher 容器）取代 `publisher_daemon` 的 21:00/21:10/23:10 固定 cron。本地 send 腳本只上傳素材 + 建 `pending` row；bot 每 ~60s 輪詢 `social_posts`、貼四鈕審核（✅核准／🕘排程 modal／🚀立即發布／❌拒絕），排程迴圈在「到點且已核准」時發 IG。carousel + reel 皆接管；`DAILY_STORY_PUBLISH_ENABLED=0` 只暫停排程迴圈。
- [x] T1: bot 實作（subagent-driven 12 tasks，backend 415 + scripts 107 tests 全綠；雙發防護：process lock + 重讀最新 row，republish 用 `force` 略過）
- [x] T2: 拆分部署 workflow（`deploy-backend.yml` 手動：migration → VPS compose → 健康檢查含 bot Gateway 連線；`deploy.yml`→`deploy-app.yml` 只上架 App、移除週五排程）
- [x] T3: 上線 + 實測（2026-07-09，Deploy Backend workflow 三 job 綠；service-role smoke test 確認 bot 45s 內貼審核訊息並回填 `discord_message_id`，事後清理無痕）
- 已知未做（可選後續）: 計畫 §4 的 `/republish` slash command 未實作——`interactions.republish()` 只是 Python 函式，back-fill 走既有 `publisher.py`／`reel_publisher.py` CLI；approve/reject/schedule 按鈕未先 `defer()`（3s ack，慢查詢理論上顯示 failed 但寫入仍成功）。

## F9: 景點 SEO 著陸頁 (epic: E1)

- 狀態: 進行中（首批已上線 2026-07-09）
- 來源: 2026-07-09 SEO 關鍵字研究——GSC 診斷官網近 90 天僅 9 曝光/0 點擊/2 頁索引，流量太低致查詢字詞被匿名化；改用 Google 自動完成挖出「[景點] 導覽app / 語音導覽」高意圖長尾金礦
- 設計: `landing/src/app/[locale]/place/[slug]` 靜態路由 + `landing/src/lib/places.ts` 資料層，複用每日故事頁版型與 metadata 模式。**新增景點只需在 `places.ts` 加一筆**（zh+en 維基為本故事 + keyword-rich metaTitle/description/keywords），sitemap 自動帶入、無需改程式
- [x] T1: 建 place 路由 + 首批 5 景點（羅浮宮 louvre、故宮 national-palace-museum、大英博物館 british-museum、聖家堂 sagrada-familia、中正紀念堂 chiang-kai-shek-memorial-hall）× zh/en = 10 頁；首頁 zh/en metadata 織入「語音導覽 app / audio tour guide app」等搜尋詞（commit c5358c51，push + Deploy Landing 部署完成，2026-07-09，正式站 10 頁皆 200、sitemap 6→16 URL）
- [ ] T2: GSC 對 10 個新網址逐一「要求建立索引」（加速收錄）
  - 2026-07-10 已催 9/10：5 個 zh 全部 + en louvre/national-palace-museum/british-museum/sagrada-familia；踩到 GSC 每日配額上限
  - [ ] 明天（2026-07-11 後）補催剩下 1 個：`https://lorescape.app/en/place/chiang-kai-shek-memorial-hall`（低優先，已在 sitemap，Google 遲早自爬）
- [ ] T3: 1–4 週後回看 GSC 曝光/查詢，依有反應的景點決定下一批擴充；候選——叢集 B 國外（凡爾賽宮、羅馬競技場、梵谷博物館、米蘭大教堂、國王湖），叢集 C 台灣（九份、淡水紅毛城、台北 101、日月潭）
- 註: 擴充前先確認首批方向對了（有曝光/排名）再大量複製，避免版型或方向要調時改一堆頁
