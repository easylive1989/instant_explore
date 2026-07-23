# Lorescape Backlog

專案層級放 features 與 tasks。feature 若服務某個公司 epic，於標題標 `(epic: EN)`；純專案層工作可不標。
feature 編號 `F1`、`F2`…；task 編號 `T1`、`T2`… nested 在所屬 feature 底下。
epic 承接自原公司層 backlog；目前只有 E1（見下方「Epic」）。

## Epic E1: 補齊漏斗上層流量
- 狀態: 進行中
- 目標: 讓落地頁流量從 ~1/天 提升到穩定兩位數/天，並累積到能判斷 PMF 的最小用戶量
- 政策（原 2026-07-07 公司決策）: 現階段主線＝補流量，暫緩「新功能／升級型」產品投入；不受暫緩限制的例外＝bug 修復與維運、直接服務漏斗的產品改動、留存/完成率埋點與量測
- 展開: 下方標 `(epic: E1)` 的 features
- [ ] 2026-08-04 回顧：檢視補流量主線是否推動流量/下載/留存指標，再決定是否解除暫緩、回補產品側投入（原公司決策設定的檢核點）

## ⚠️ 待部署（程式已在 repo，尚未上生產；更新於 2026-07-21）

以下改動已 commit + push 到 master，但**尚未部署到生產**，使用者尚看不到：

- [x] **落地頁**（`landing/`）：已部署到 `lorescape.app`（2026-07-09，Deploy Landing workflow 從 master HEAD 重建，正式站驗證通過）。含 F2/F6 T5 定價 section（廣告 7 天試用）與 F9 景點著陸頁
- [x] **Backend**（`backend/`）：已部署到 VPS（2026-07-09，Deploy Backend workflow `git reset --hard origin/master` + `docker compose up -d --build`）。含 F1 T1 的 Reel caption CTA 文案（已改為固定常數、不吃 CTA_TEXT env）＋ F8 發布 bot
- [x] **Publisher**（`publisher/`）：F11 T2 的 reel video_url fallback 於 2026-07-13 完成，2026-07-20 使用者手動觸發 Deploy Publisher workflow 上 VPS 生效
- [x] **App**（`frontend/`）：新版本已上架商店並顯示「7 天免費試用」字樣（2026-07-20 使用者確認），F6 T4 生效
- [ ] **App**（`frontend/`，下一輪）：待下次 build 送審才生效的累積改動——
  - F10 的 `Info.plist` 相簿權限鍵（2026-07-20 完成）
  - F13 T1a narration 埋點修復（2026-07-21）：**在此之前上架的所有版本，
    narration 事件都收不到**，所以 GA4 要等新版本有安裝量後才會開始有資料
  - F13 T1b `FirebaseAnalyticsObserver`（2026-07-21）：同上，`screen_view`
    在新版本上架前仍會是 `(not set)`
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
- 來源: E1 政策（埋點不受暫緩）；marketing/audits/cro-2026-07-06.md（narration 完成率為 missing_data）
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
- 2026-07-20：App 新版本已上架（見「待部署」段），與 F6 T4 同一次 build，程式改動應已隨之生效——未逐項獨立驗證，若使用者發現 settings 仍殘留舊文案請回報。

## F8: 每日故事 IG 發布改用 Discord bot (epic: E1)

- 狀態: 已完成並上線（2026-07-09）
- 來源: 使用者要求「每日貼文一建立就發布、不需 server 排程」→ 收斂為常駐 Discord 互動 bot
- 設計/計畫: `docs/superpowers/specs/2026-07-09-discord-publish-bot-design.md`、`docs/superpowers/plans/2026-07-09-discord-publish-bot.md`
- 架構: 常駐 Discord Gateway bot（`lorescape_publisher.bot`，publisher 容器；上線當時模組路徑為 `lorescape_backend.social.publisher_bot`，2026-07-11 隨 `docs/adr/0004-split-social-publisher-from-backend.md` 拆到頂層 `publisher/`）取代 `publisher_daemon` 的 21:00/21:10/23:10 固定 cron。本地 send 腳本只上傳素材 + 建 `pending` row；bot 每 ~60s 輪詢 `social_posts`、貼四鈕審核（✅核准／🕘排程 modal／🚀立即發布／❌拒絕），排程迴圈在「到點且已核准」時發 IG。carousel + reel 皆接管；`DAILY_STORY_PUBLISH_ENABLED=0` 只暫停排程迴圈。
- [x] T1: bot 實作（subagent-driven 12 tasks，backend 415 + scripts 107 tests 全綠；雙發防護：process lock + 重讀最新 row，republish 用 `force` 略過）
- [x] T2: 拆分部署 workflow（`deploy-backend.yml` 手動：migration → VPS compose → 健康檢查含 bot Gateway 連線；`deploy.yml`→`deploy-app.yml` 只上架 App、移除週五排程）
- [x] T3: 上線 + 實測（2026-07-09，Deploy Backend workflow 三 job 綠；service-role smoke test 確認 bot 45s 內貼審核訊息並回填 `discord_message_id`，事後清理無痕）
- 已知未做（可選後續）: 計畫 §4 的 `/republish` slash command 未實作——`interactions.republish()` 只是 Python 函式，back-fill 走既有（已於 2026-07-11 拆分時整支刪除的）`publisher.py`／`reel_publisher.py` CLI，目前後者位於 `publisher/src/lorescape_publisher/reel_publisher.py`；approve/reject/schedule 按鈕未先 `defer()`（3s ack，慢查詢理論上顯示 failed 但寫入仍成功）。

## F9: 景點 SEO 著陸頁 (epic: E1)

- 狀態: 進行中（首批已上線 2026-07-09）
- 來源: 2026-07-09 SEO 關鍵字研究——GSC 診斷官網近 90 天僅 9 曝光/0 點擊/2 頁索引，流量太低致查詢字詞被匿名化；改用 Google 自動完成挖出「[景點] 導覽app / 語音導覽」高意圖長尾金礦
- 設計: `landing/src/app/[locale]/place/[slug]` 靜態路由 + `landing/src/lib/places.ts` 資料層，複用每日故事頁版型與 metadata 模式。**新增景點只需在 `places.ts` 加一筆**（zh+en 維基為本故事 + keyword-rich metaTitle/description/keywords），sitemap 自動帶入、無需改程式
- [x] T1: 建 place 路由 + 首批 5 景點（羅浮宮 louvre、故宮 national-palace-museum、大英博物館 british-museum、聖家堂 sagrada-familia、中正紀念堂 chiang-kai-shek-memorial-hall）× zh/en = 10 頁；首頁 zh/en metadata 織入「語音導覽 app / audio tour guide app」等搜尋詞（commit c5358c51，push + Deploy Landing 部署完成，2026-07-09，正式站 10 頁皆 200、sitemap 6→16 URL）
- [x] T2: GSC 對 10 個新網址催索引（加速收錄）
  - 2026-07-10 已催 9/10：5 個 zh 全部 + en louvre/national-palace-museum/british-museum/sagrada-familia；踩到 GSC 每日配額上限
  - 2026-07-11 查證：**10/10 景點頁全部「網頁已編入索引」**（含剩下未手動催的 en/chiang，Google 自然收錄）。部署後 1 天全數進索引，方向驗證通過；下一步等曝光/查詢資料，依 F9 T3 決定擴充
- [ ] T3: 1–4 週後回看 GSC 曝光/查詢，依有反應的景點決定下一批擴充；候選——叢集 B 國外（凡爾賽宮、羅馬競技場、梵谷博物館、米蘭大教堂、國王湖），叢集 C 台灣（九份、淡水紅毛城、台北 101、日月潭）
- 註: 擴充前先確認首批方向對了（有曝光/排名）再大量複製，避免版型或方向要調時改一堆頁

## F11: reel 發布 video_url fallback

- 狀態: 已完成（2026-07-13，待 Deploy Publisher 上 VPS 生效）
- 來源: 2026-07-12 晚 Meta rupload 端點故障——排程與手動發布連吃 7 次泛型
  `ProcessingFailedError`（400），連當天早上剛成功發過的同一檔案也被拒（媒體/
  帳號/配額全排除）；最後手動改建 `video_url` container（Meta 自己抓公開網址，
  不經 rupload）一次成功。細節見 memory `reel-meta-transcode-failure`。
- 目標: publisher 的 reel 發布在 rupload 回**泛型** ProcessingFailedError 時
  自動 fallback 到 video_url 路徑，不再需要人工深夜救火
- 設計注意:
  - 需要一個放得下 reel 的公開 HTTP 位置（當晚是暫調 `ig-cards` bucket 上限
    5MB→50MB 再改回；正式做法建議開專用 bucket 如 `reel-videos`、上限 100MB，
    發布成功後刪檔）
  - fallback 只對「泛型 ProcessingFailedError」觸發；明確的轉碼錯誤（"failed
    to transcode"）代表影片規格問題，fallback 也救不了，應照舊 fail
  - VPS 端 publisher 已有影片檔（`/opt/lorescape-media/daily_video/<date>/`）
    與 Supabase service key，上傳 bucket 無新依賴
- [x] T1: 開 `reel-videos` 專用公開 bucket（2026-07-13 已建：public、
  `video/mp4`、上限 50MB——100MB 超過專案全域上傳上限會 413；見
  `docs/init/2026-07-13-reel-videos-bucket-setup.md`），發布流程結束後刪除
  暫存影片
- [x] T2: rupload 泛型 400 → `ReelUploadGenericError` →
  `reel_publisher.publish_reel_with_fallback` 上傳 bucket → `video_url`
  container（`instagram.publish_reel_from_url`）→ 輪詢 → publish → 清理；
  分流只認 `debug_info.type=ProcessingFailedError` +
  `message=Request processing failed`（轉碼錯誤同 type 但 message 不同，
  照舊 fail）；測試涵蓋兩種錯誤 body 與 fallback 清理
- [x] T3: `publish_reel.py` 加 `--via-url` 旗標直走 video_url；預設路徑也
  自動 fallback
- ⚠️ T2 為 publisher 改動，需 Deploy Publisher workflow 部署後才在 VPS 生效
  （尚未部署）

## F12: reel-remotion story.json 改為 gitignored 工作檔

- 狀態: 已完成（2026-07-12）
- 來源: story.json 為每日 pipeline 重生的工作資料（正式紀錄在 Supabase 與
  marketing/outputs/），逐日 commit 無留史價值，但 tracked 導致 git status
  天天 dirty；也不能單純 gitignore——Remotion 專案要有檔案才能編譯/預覽
- 設計: 執行期檔名維持 `story.json`（所有 import/腳本/skill 文件不動）；
  gitignore `src/data/story.json`，另 track `story.sample.json` 樣本，
  `npm run dev`/`build` 前由 `scripts/ensure_story.mjs` 在缺檔時從樣本複製
  （pipeline 的 prepare_story.mjs 本來就會先寫入真檔，不受影響）
- [x] T1: story.sample.json + ensure_story.mjs + gitignore + package.json
  pre-hooks；CLAUDE.md 專案地圖同步一句

## F10: iOS 相簿儲存權限鍵補齊

- 狀態: 已完成（程式，2026-07-20）；待下次 App build 送審生效
- 來源: 2026-07-11 frontend 依賴規則還債 final review 發現；缺口自 2026-02-05（7ef8771b 移除 `NSPhotoLibraryAddUsageDescription`）即存在，非本次 camera 刪除造成
- 問題: daily story / journey 分享輸出 PNG（share_plus share sheet），使用者在 share sheet 點「儲存影像」時 app 缺 `NSPhotoLibraryAddUsageDescription`，iOS 會使該動作失敗（甚至 crash）
- [x] T1: `frontend/ios/Runner/Info.plist` 補回 `NSPhotoLibraryAddUsageDescription`（文案「將分享圖片儲存到相簿」，2026-07-20 完成）；隨下次 App build 送審才會在生產生效

## F13: App 留存診斷 (epic: E1)

- 狀態: 進行中（2026-07-21 埋點修復完成，待隨下次 App build 上生產驗證；
  T2/T3 仍待辦）
- 來源: marketing/audits/weekly-2026-07-13.md（P0）——本週 App 活躍腰斬
  （iOS+Android 22 vs 46）、新用戶 −56%、D1 留存幾乎全週 0%（僅 07-11
  cohort 20%）、D7 全 0%；流量端反而成長（IG 觸及 +75%、Landing 新用戶
  +40%），問題在留不住不在進不來
- [ ] T1: 跑 marketing-retention 分析流失點（GA4 cohort + narration 完成率
  交叉；narration.csv 目前 0 rows，pre-traffic，一併確認事件有無進來）
  - **2026-07-21 查證：事件沒有進來，「pre-traffic」假設否證。** GA4
    property 514854947 從 2026-05-01 至今出現過的事件只有 14 種
    （first_open / screen_view / session_start / user_engagement /
    app_update / app_remove / app_store_subscription_renew …），
    **`narration_*` 一筆都沒有**。同期 `first_open` 82 次、iOS 下載僅 6 次，
    差距 13 倍——多出來的是開發機／模擬器，也就是說開發期間必然播放過，
    事件卻仍然掛零 ⇒ 是埋點沒送達，不是沒人播。
  - 已排除：consent 預設為 ON（`ConsentState.defaultOn()`）；observer 於
    2026-05-20（6a3653c5）進 main，早於 6 月上線；`app.dart:48` 有
    `ref.watch(narrationAnalyticsObserverProvider)`；`playerControllerProvider`
    非 family，UI 與 observer 用的是同一個 provider；main.dart 已 eager
    override `sharedPreferencesProvider`。靜態檢查看不出斷點。
  - 附帶：`screen_view` 的 `unifiedScreenName` **全部是 `(not set)`**，
    畫面追蹤同樣沒設定，GA4 上無法看任何 App 內漏斗。
  - [x] T1a: 根因已定位並修復（2026-07-21，不需實機）：
    `consentRepositoryProvider` 以 `requireValue` 取 SharedPreferences，而
    `main.dart` 用 async closure override `sharedPreferencesProvider`，因此
    provider 首次被讀取時仍是 `AsyncLoading` → 丟 `StateError`。該 provider
    全 `lib/` 只有 `_consentEnabled()` 一處會讀（第一次播放才觸發），
    Riverpod 又快取 build 失敗並在後續讀取重拋 ⇒ 整個 container 生命週期內
    每個 narration 事件都失敗；emit 是 fire-and-forget 沒人 await，例外落進
    unhandled async gap，所以兩個月完全無聲。修在讀取端（先 await
    `sharedPreferencesProvider.future`）並加 `_fireAndLog`，另補走真實
    consent repository 的回歸測試——既有測試全都 fake 掉它，這正是測試全綠
    而線上全死的原因。
  - [x] T1b: 掛上 `FirebaseAnalyticsObserver`（新增 `routeObserversProvider`
    並接進 GoRouter observers），補回 GA4 畫面名稱
  - [ ] T1c: 下次 App 送審上架後，確認 GA4 開始出現 `narration_*` 與具名的
    `screen_view`（修復要隨版本才會在生產生效）
- [ ] T2: 檢查每日故事推播的實際送達與開啟情況（習慣養成迴路是否真的在
  運作）
- [ ] T3: 下週週報驗證 reel 片尾下載 CTA 成效（2026-07-13 上線
  `Cinematic.tsx` ending CTA，對「IG 觸及 1,923 → iOS 下載 1」的轉化缺口）
  - 2026-07-20 部分驗證：對「追蹤」有效（聖家堂 Reel 24h 帶進 +5 粉絲、
    profile_visits 1，本週唯一破 1 的 CTA 轉換）；對「下載」尚未見效
    （iOS 下載仍持平 2/週，觸及卻 +154%）。轉換斷層在 bio→商店這一段，
    見 F15

## F14: GA4 Android 追蹤斷線診斷 (epic: E1)

- 狀態: 已結案（2026-07-21，原假設否證）——不是追蹤斷線，是 Android 通路
  零獲客（上線一個多月 0 安裝，使用者確認）。獲客問題屬 E1 主線，若要推
  Android 應另開 feature，本 feature 不再追蹤
- 來源: marketing/audits/weekly-2026-07-20.md（P0）——`ga4.csv` 的
  `android_active_users`/`android_new_users` 自 2026-07-11 起連續 9 天全空，
  同期 Play 端無跡象顯示帳號停用，疑追蹤斷線而非真的零活躍
- **2026-07-21 查證：原假設（追蹤斷線）證據反向，Android 應是真的零安裝。**
  Play reports bucket 讀取正常（service account 權限 OK），但
  `com.paulchwu.instantexplore` 全 bucket 只有 **2026-03 一個月**的檔案，
  內容僅一列 `2026-03-29，Daily User Installs 1`（上架前內測）；
  **2026-04 之後零匯出，`stats/ratings/` 該 package 0 個物件**。Play 只在
  有量的月份產月報 ⇒ 沒有月報＝沒有安裝，而非匯出故障。Play 商店頁本身
  存活（HTTP 200）。`store_android.csv` 至今 0 列如實反映此事。
- 據此本 feature 的問題重新定義：不是「追蹤斷線」，是 **Android 通路沒有
  任何獲客**（上線一個多月 0 安裝）。
- [ ] T1: ~~檢查 App 端 Firebase Analytics 初始化與 GA4 Android 資料流設定~~
  → 改為：查 Play 商店頁能否被搜尋到（曝光/可見度）、上架狀態與國家/裝置
  相容性設定，確認是「沒人找得到」還是「找到了不下載」

## F15: IG → 下載轉換優化 (epic: E1)

- 狀態: 進行中（2026-07-21 量出斷層位置：落地頁不漏，損失在 reach→profile；
  T1 bio 文案已定稿待手動貼上，T2 片尾維持已驗證版本）
- 來源: marketing/audits/weekly-2026-07-20.md（P0）——本週 IG 觸及 +154%
  （1,923→4,879）、粉絲 +147%，但 profile_views 轉換率僅 0.6%（30/4,879，
  < 1% 月底檢核門檻）、iOS 下載持平在 2；問題在帳號定位/CTA 不在觸及量
- [x] T1: 改 IG bio 文案（現況「🎧 免費下載 ↓」+ 落地頁連結），加強價值主張
  句，非僅動詞指令
  - **2026-07-21 已套用上線**（瀏覽器手動操作；IG Graph API 無寫入端點），
    以 Graph API 讀回驗證 name / biography / website 皆為新值。
    名稱欄不在 IG 網頁版「編輯個人檔案」，實際位置是帳號管理中心 →
    個人檔案 → 姓名（注意：**14 天內只能變更兩次姓名**）。
  - 定稿內容：
    - 名稱欄：`Lorescape・AI 旅行說書人` → `Lorescape・景點故事語音導覽`
      （名稱欄是 IG 搜尋唯一吃關鍵字的欄位；「AI 旅行說書人」無人搜尋，
      「景點／故事／語音導覽」才是真實查詢詞）
    - 簡介：
      ```
      Google 只給你條目，我們給你故事。
      站在任何景點前，聽一段以 Wikipedia 為本的真實故事。
      🎧 App Store・Google Play ↓
      ```
      第一行改為對比句而非自我描述，直接命中 MARKETING.md 的 pain
      （「查 Google 只有條目式資訊」）；第二行保留 Wikipedia 建立信任。
  - **連結決策（2026-07-21）：`website` 維持 `lorescape.app`，不改直連
    App Store。** 曾評估砍掉「bio → 落地頁 → 商店」中間那一跳（Android
    至今 0 安裝、iOS 是唯一真實通路），但落地頁同時是 SEO 資產，決定保留。
    ⇒ bio→商店的漏損要改從**落地頁**下手（商店按鈕的位置與可見度），
    而非改 bio 連結。
- **2026-07-21 漏斗量測：斷層不在 bio→商店，在 reach→profile。** GA4 近 30 天
  `download_click` 共 **6 次**（hero 3 / footer 1 / navbar 1 / place 1），
  同期 iOS 下載 **6 次**——落地頁的商店按鈕點擊到實際安裝幾乎 1:1，沒有漏。
  落地頁 CTA 本身也已齊備：Hero（首屏）、Navbar、FinalCTA、Footer 都有
  `StoreButtons`，且 `storeUrlFor()` 已帶 App Store `ct` 與 Play install
  referrer 歸因參數。⇒ **不要再投資重做落地頁 CTA**。
  真正的損失全在上游：reach 2349 → profile_visits 16（0.7%）→ 落地頁
  每日僅 1–2 人。修 profile_visits 的槓桿是片尾 CTA 與 caption（見 T2），
  以及 bio 能不能讓人願意點連結（T1）。
  - 這修正了 F13 T3 於 07-20 的判讀（「轉換斷層在 bio→商店這一段」）。
  - 樣本極小（n=6），數字只能當方向不能當結論。
- [ ] T3: 2026-08-04 前後回看 bio 改版成效——比較 `data/metrics/ig.csv` 的
  `profile_views` 與 `ga4.csv` 的 `web_active_users`（bio 連結指向落地頁，
  這段就是 bio 的責任區）。**注意樣本量**：目前落地頁每天僅 1–2 人，
  至少累積兩週才有訊號，別在幾天內就下結論。基準＝07-21 之前 30 天。
- [ ] T2: 統一 Reel 結尾 CTA 為固定模板——聖家堂 Reel（7/19）24h 帶進 +5
  粉絲、profile_visits 1，是本週唯一有效轉換的片尾，複製其結構到後續
  daily reel（見 F13 T3 註記）
  - 2026-07-21 一度把片尾改成「這裡的故事說完了／那你現在站的地方呢？」，
    但那等於換掉本週唯一有實證的版本，且與本 task 的方向相反，**已 revert**
    （e811abc4）。片尾維持 7/13 上線的版本。單獨保留的是字型 subset 缺字
    修復（b6e8598a），與文案無關。

## F19: publisher/.env 是佔位值（維運風險）

- 狀態: 待辦
- 來源: 2026-07-21 開工時發現——`publisher/.env` 內容是範本佔位值
  （`SUPABASE_URL=https://your-project.supabase.co`），真正的憑證只存在
  使用者的 shell 環境變數裡
- 風險: publisher 的程式與 skill 文件都假設「bare `load_dotenv()` 會撈到
  `publisher/.env`」。只要在沒有 export 環境變數的 shell 裡跑
  `cd publisher && uv run python ...`，就會連到不存在的專案；若哪天佔位值
  換成別的真實專案，更可能寫錯資料庫。dashboard 的 config 也會載入這份
  `.env`（`override=False`，目前靠環境變數先存在才沒出事）
- [ ] T1: 把真實憑證寫進 `publisher/.env`（該檔已 gitignore），或改為明確
  要求由環境變數提供並讓 `Config.from_env()` 在讀到佔位值時直接報錯，
  不要靜默連到錯的地方

## F20: Cloudflare www subdomain 轉址到主網域

- 狀態: 已完成（2026-07-22，瀏覽器操作 + curl 實測通過）
- 來源: 使用者要求（2026-07-22）——`www.lorescape.app` 目前未轉址到
  `lorescape.app`，需在 Cloudflare 設定 www → apex 轉址
- 範圍備註: 屬維運工作，不受 E1 暫緩政策限制；www 打不開也會漏接輸入
  `www.` 習慣的使用者與部分外部連結，間接影響漏斗
- 發現: 原本 `www` **根本沒有 DNS 紀錄**（`Could not resolve host`），不只是
  少一條轉址規則；apex 的 A 記錄是 DNS only（灰雲），而 Redirect Rule 只對
  走 proxy 的流量生效，故 www 必須設成 Proxied（橘雲）規則才吃得到
- [x] T1: 兩步完成（2026-07-22）——
  1. DNS 加 `www` CNAME → `lorescape.app`、**Proxied（橘雲）**
  2. Redirect Rule（用 Cloudflare 內建 `redirect-www-to-root` 範本）：
     `https://www.*` → `301` `wildcard_replace(http.request.full_uri,
     "https://www.*", "https://${1}")`，用 `full_uri` 故 path 與 query
     皆由 wildcard 帶過去（不需另勾 Preserve query string，避免 query 重複）
  - 實測（curl `--resolve` 繞過本機 DNS 負快取）：
    `https://www` → 301 → `https://lorescape.app/`（SSL 驗證 0、無警告）；
    `https://www/place/louvre?utm=test` → 301 保留 path+query；
    `http://www` → 兩跳（Always Use HTTPS → 轉址規則）最終落 `lorescape.app/zh` 200

## F21: Reel 略過率是觸及的主要驅動因子 (epic: E1)

- 狀態: 待辦
- 來源: 2026-07-23 開工，把當日三支 checkpoint 快照寫進
  `data/metrics/ig_reels_insights.csv` 後，對全表 33 列做同 checkpoint 比對
- **發現（n=11／checkpoint，三個 checkpoint 一致）：略過率與 views 穩定負相關。**

  | checkpoint | 相關係數 r | 低略過組中位 views | 高略過組中位 views | 倍率 |
  |---|---|---|---|---|
  | 24h | −0.76 | 727（略過 46.7–61.3%） | 212（略過 68.2–81.3%） | 3.4x |
  | 48h | −0.79 | 1,034（45.7–60.1%） | 224（67.5–82.5%） | 4.6x |
  | 7d | −0.64 | 960（38.5–52.5%） | 214（57.9–79.6%） | 4.5x |

  這把 `_reels-place-calendar.md` 於 07-21 用 n=2（布拉格 45.5%→2797、
  金字塔 70.1%→243）提出的「24h 略過率是唯一該盯的先行指標」從觀察
  升級為 n=11、跨三個 checkpoint 都成立的關係。
- **副發現：`avg_watch_time` 是誤導性指標，不要拿來優化。** 它與 views
  的 r 僅 **−0.18**（7d），而且方向是負的——表現最差的兩支平均觀看時間
  最長（撒哈拉 40 秒／略過 79.6%／119 views；佩特拉 26 秒／70.1%／
  250 views）。合理解釋是倖存者偏誤：看的人越少，留下來的越是本來就
  有興趣的，平均秒數反而被推高。
  - 這修正了 2026-07-23 當下對使用者的初步判讀（曾把「低略過 + 長平均
    觀看」並列為蘇州表現好的原因；實際上只有略過率有解釋力）。
- 意涵: 略過率是**前三秒 hook** 的直接產物，不是選點的產物。若此關係成立，
  選點 calendar 的配比調整對觸及的槓桿，遠小於 hook 怎麼寫。
- [ ] T1: 盤點 `ig_reels_insights.csv` 低略過組（<53%）與高略過組（>63%）的
  hook 句，找出可複製的結構差異，寫成 hook 模板進
  `lorescape-daily-reel` skill。
  - 初步觀察（**尚未驗證，不可當結論**）：低略過組多為「具體的人或家戶
    處境 + 明確衝突」（蘇州「一個被貶到底的官員」、白川鄉「一戶人家永遠
    蓋不起來」），高略過組多為抽象或地理性描述（「這座城市曾經富甲沙漠」）。
  - **注意**：句式不是變因。calendar 於 07-21 已證偽「疑問句 hook 拉觸及」，
    本表也一致——疑問句同時出現在低略過（馬丘比丘 38.5%、姬路城 52.5%）
    與高略過（石見銀山 63.7%）兩端。
- [ ] T2: 8/3 期末檢核的方法改用**略過率**當主要應變數，而非 reach/views。
  reach 受發布時間與觀測長度污染，略過率是同一支片內的比率、可直接互比。
  檢核「日韓 > 其他」假設時，先看各類型的略過率中位數是否有差，再看 reach。
- [ ] T3: 每天做 24h checkpoint 快照的優先級提高——它是唯一的先行指標，
  且漏抓不回補（見 lorescape-metrics skill）。目前 33 列已足以支撐上述分析，
  但 hook 模板要驗證需要更多樣本。
- 邊界: 這是相關性不是因果，且三個 checkpoint 的樣本高度重疊（同一批 Reel
  的不同觀測點），實質獨立樣本約 11 支。IG 演算法把略過率當排序訊號是合理
  推測，但無法從本資料證實。

## F22: 每週長篇電子報（官網 SEO 內容） (epic: E1)

- 狀態: 待辦
- 來源: 使用者要求（2026-07-23）——每週產出一篇長篇電子報，放在官網
  lorescape.app 上並做好 SEO
- 範圍備註: 服務漏斗上層流量（SEO 內容資產），屬 E1 主線，不受暫緩政策限制
- 方向: 電子報同時是 SEO 資產——每篇以景點故事／深度旅行知識為題的長文，
  發布在 landing 的獨立路由（如 `/newsletter/[slug]`），複用 F9 景點頁的
  資料層與 metadata 模式；sitemap 自動帶入。與 F9 景點頁互補：F9 吃
  「[景點] 導覽app」高意圖長尾，電子報吃資訊型長尾與品牌信任
- [ ] T1: 規劃內容策略與版型——題材方向（景點深度故事／旅行知識）、
  關鍵字策略（與 F9 分工）、zh/en 雙語與否、每篇結構模板；過 marketing-gate
  品質關卡與 SEO lint
- [ ] T2: landing 新增電子報路由與資料層（列表頁 + 文章頁、keyword-rich
  metadata、結構化標記 Article schema、sitemap 自動帶入），比照 F9
  「新增一篇只需加一筆資料」的模式
- [ ] T3: 每週產製流程——寫進 SCHEDULE.md 每週例行，定義從選題、撰寫、
  品質關卡到發布部署（Deploy Landing）的步驟；評估是否做成 lorescape-* skill
- [ ] T4（可選）: Email 訂閱入口——官網加訂閱表單、寄送管道選型，
  讓電子報除了 SEO 也累積自有名單；待 T1–T3 上線且有流量訊號後再決定

## F16: 後端可觀測性（server 狀態檢測）

- 狀態: 待辦
- 來源: 使用者要求（2026-07-21）——增加 Lorescape 後端的可觀測性，可以檢測
  server 的 CPU、memory、disk、是不是活著等狀態
- 範圍備註: 屬維運工作，不受 E1 暫緩政策限制（政策明列「bug 修復與維運」為
  例外）
- [ ] T1: 規劃可觀測性方案（VPS 上 backend + publisher 容器的 liveness、
  CPU / memory / disk 監控；含通知管道與工具選型），再拆實作 tasks

## F17: 探索頁面重新設計

- 狀態: 已完成（2026-07-21）
- 來源: 使用者要求（2026-07-21）——重新設計 App 探索頁面，參考 Claude Design
- 設計稿: `docs/design/project/Lorescape Redesign v2.html` +
  `docs/design/project/app2/`（Claude Design 專案
  `dcdb2009-b819-4361-8be6-eeb8ba93005b`）。v1（`app/`）＝目前已實作的版本，
  v2（`app2/`）＝這次要做的新版；差異表見 `docs/design/README.md`
- 設計 token 已在 `frontend/lib/app/config/lorescape_tokens.dart`（v1 時落地），
  這次不動 token，只換探索頁的**結構**
- 方向決定（2026-07-21，使用者拍板）: **照設計做全螢幕地圖，導入 flutter_map**
- ⚠️ 風險: OSM 官方 tile server 的 usage policy 明文禁止 app 級別的重度取用，
  T1 必須先決定 tile 來源（自架 / MapTiler / Stadia 等），不能直接把
  設計稿的 `tile.openstreetmap.org` 帶進生產
- ⚠️ 這是 Flutter 改動，需隨下次 App build 送審才生效（與 F13 T1c 同一版）
- [x] T1a: 匯入 v2 handoff bundle 到 `docs/design/`（2026-07-21）
- [x] T1: 選定 tile provider 與授權/成本方案（2026-07-21，
  `docs/adr/0005-map-tile-provider.md`）——**OpenFreeMap 公共實例 + vector
  tiles**（`flutter_map` + `vector_map_tiles` 9.0.0-beta.9）。零成本、無用量
  上限、無 API key，且樣式可完全照 field journal 色票調（vector 的決定性
  優點）。Stadia / MapTiler 的免費方案都**禁止商業使用**，訂閱制 App 不可用。
  plan B ＝ Geoapify Free + raster + sepia 濾鏡
  - ⚠️ ADR 初稿選的是 Geoapify，理由「`vector_map_tiles` 只支援
    flutter_map 7.x」**經查證為錯**（beta 線已相依 `flutter_map ^8.1.1`），
    使用者質疑後修訂；修訂紀錄留在 ADR 文末
- [x] T2: 底圖 widget（2026-07-21）——`flutter_map ^8.1.1` +
  `vector_map_tiles 9.0.0-beta.9`（釘死確切版本）+ `latlong2`；
  `LorescapeMap`（`features/explore/presentation/widgets/lorescape_map.dart`）
  含 loading / error / data 三態與 attribution 角標，`mapStyleProvider`
  以 `StyleReader` 讀 OpenFreeMap positron 樣式並 `keepAlive` 快取。
  4 個 widget test、full suite 543 passed、analyze 乾淨
  - 注意：**不要把 tile URL 寫死**，OpenFreeMap 的 tile 路徑帶每週重建的
    日期段（`/planet/20260621_080001_pt/...`），必須由 style/TileJSON 在
    執行期解析
  - 使用者決定跳過效能 spike，也不保留 raster 退路（ADR 0005 已記）
  - **已在 iPhone 16 Pro simulator 目視驗證通過**（2026-07-21，marionette）：
    vector tile 正常渲染（海岸線、國界、多語地名）、平移流暢無空白 tile、
    attribution 角標可見。驗證方式是暫時把 ExploreScreen 換成地圖，**驗證後
    已完整還原**
  - ⚠️ 還沒接進 ExploreScreen（T5 才接）
- [x] T2b: 依 field journal 色票調整 style JSON（2026-07-21，模擬器目視驗證
  通過）。positron 原樣式是冷灰色系，與設計稿的暖紙感落差明顯，非改不可
  - `tool/build_map_style.py`：抓上游 positron、以「顏色→顏色」對應表遞迴
    重新上色（走整棵樹，才能改到 `["interpolate", ...]` 葉節點裡的顏色）、
    移除沒用到的 raster source，產出 `assets/map/lorescape_style.json`。
    上游若出現未對應的新顏色，腳本**直接失敗**而非默默留下冷灰色
  - `mapStyleProvider` 分工：**配色**用本地 asset，**tile 來源與 sprites**
    仍由上游 `StyleReader` 解析（含每週變動的 tile 路徑）；並把 providers
    過濾成本地樣式真的用到的 source，避免白白下載沒人顯示的 raster PNG
  - **踩到的坑（重要）**：`vector_map_tiles` 的磁碟快取 key 是
    `{z}_{x}_{y}_{source}.pbf`、**不含樣式身分**，TTL 預設 30 天。改了配色
    後畫面完全沒變，手動刪掉快取才生效——代表樣式改版對既有使用者最長
    30 天不會生效。解法：樣式 JSON 帶內容雜湊當版本號，
    `MapTileCacheService` 依版本切快取目錄並清掉舊版本，換樣式＝換目錄。
    已在乾淨建置下驗證新配色自動生效
- [x] T3: 地點 pin（2026-07-21）——`PlaceMapPin` 依設計稿以旋轉 -45° 的圓角
  方塊做水滴造型、紙色描邊與內點，依 `JournalCategory` 上色（設計稿只指定
  urban / heritage，其餘沿用 clay）；點 pin 進地點頁。地圖首次拿到地點座標時
  自動 `fitCamera`（maxZoom 6），只框一次不干擾後續操作
- [x] T4: 浮層 header（2026-07-21）——眼眉線「N 個地點 · Atlas」＋襯線大標
  ＋filter / refresh 圓鈕＋浮起式搜尋列，底下鋪紙色漸層
  - **踩到的 bug**：原本把整個浮層包進 `IgnorePointer` 讓漸層不擋觸控，再用
    巢狀 `IgnorePointer(ignoring: false)` 想收回來——**收不回來**，外層一旦
    排除整個子樹，搜尋/篩選/重新整理全部點不到。三個測試同時掛掉才抓到。
    正解是漸層獨立成一層 `Positioned.fill` + `IgnorePointer`
- [x] T5: 底部橫向卡片列（2026-07-21）——252px 卡片、縮圖／名稱／分類標籤／
  圓形前往鈕；點卡片本體 `flyTo` 該地點，點箭頭才進地點頁
  - **設計稿的缺口**：v2 的 map-card 沒有書籤，但探索頁卡片是**全 App 唯一
    能收藏地點的入口**（`togglePlace` 只有這一個呼叫點），照抄等於靜默刪功能。
    改把書籤壓在縮圖角落（含紙色底盤，否則深色照片上看不見）
- [x] T6: FAB 與 filter sheet 定位（2026-07-21）。設計稿的 `bottom:96` 會讓
  收藏 FAB **正好壓在卡片列上**（實機確認），改成貼著卡片列上緣浮放
- [x] T7: 邊界情境與測試（2026-07-21）——定位失敗 / 無地點 / 樣式載入失敗
  各有可見說明；`fvm flutter analyze --fatal-infos` 乾淨、full suite 545 passed
  - **修回一個 regression**：改版時卡片列的 error 分支回傳空白，把定位被拒的
    錯誤訊息吞掉了（整合測試抓到）。現在錯誤會以說明卡顯示在卡片列位置
  - 測試基礎建設：`test/helpers/fake_map_style.dart` 提供
    `fakeMapStyleOverrides()` 與 `settleMapTimers()`。**任何會渲染地圖的測試
    都要用**——不 override 樣式，`FlutterMap` 根本不會建出來；不跑完
    `vector_map_tiles` 排的 3 秒 timer，測試會以「Timer 尚未結束」失敗，
    而且訊息完全看不出跟地圖有關

## F18: 歷程頁面重新設計

- 狀態: 已完成（2026-07-21）
- 來源: 使用者要求（2026-07-21）——重新設計 App 歷程頁面，參考 Claude Design
- 設計稿: 同 F17（`app2/screens_history.jsx`）
- 方向決定（2026-07-21，使用者拍板）: **照設計，歷程首頁只留旅程書架**，
  移除現有的「全部時間軸 ／ 依旅程」分段控制；時間軸內容改由點進某本
  旅程後的手記翻頁器閱讀。「未分類」（`tripId == null`）沿用既有概念，
  在書架上成為一本書
- ⚠️ 這是 Flutter 改動，需隨下次 App build 送審才生效（與 F13 T1c 同一版）
- [x] T1a: 匯入 v2 handoff bundle 到 `docs/design/`（2026-07-21）
- [x] T1: 手寫體 Long Cang（2026-07-21）——不需打包字型檔，專案已用
  `google_fonts`，`GoogleFonts.longCang()` 直接可用
- [x] T2: `JourneyScreen` 換成 Masthead ＋ 旅程書架（2026-07-21）。
  `TripBookshelf`：凹槽背板、四色書皮、高度 190/204/218 循環、木層板含前緣
  厚度；書名**逐字換行**而非 `RotatedBox`——CJK 的 `writing-mode:vertical-rl`
  是字元直立堆疊，用旋轉會讓中文躺著。未分類仍是一本書（沒有未歸類記錄時
  才隱藏，沿用舊 TripGrid 的判斷）。`Masthead` 抽到 `shared/widgets/journal/`
- [x] T3/T4: 手記翻頁器（2026-07-21，`shared/widgets/journal/notebook_pager.dart`）
  ——紙頁、拍立得（奇偶頁左右交替傾斜、角上膠帶）、Long Cang 手寫圖說、
  日期戳、頁碼、分享/刪除、頁點指示器
  - **偏離設計稿**：翻頁改用 `PageView`，沒有照抄手寫的拖曳邏輯（60px 門檻、
    0.32 阻尼）。自己排一列滿寬頁面會讓 `Row` 永遠 overflow，`ClipRect` 只
    遮得住畫面、遮不住框架斷言，測試直接掛。`PageView` 手感同類且附帶
    無障礙與捲動語意
  - 拍立得尺寸取「可用寬度」與「可用高度扣圖說」的較小者；原本用
    `AspectRatio` 會以寬度為準，頁面矮時爆版 639px
- [x] T5: `TripDetailScreen` 接上翻頁器（2026-07-21）。**多選模式仍走原本的
  列表**——翻頁器一次只看得到一張，沒辦法批次勾選/移動/匯出，硬套會把既有
  功能弄殘。多選、移動到其他旅程、PDF 匯出、刪除全部保留
  - 架構守門測試抓到我讓 trip feature 跨引 journey 的 presentation，
    已把 `NotebookPager` 移到 `shared/widgets/journal/`
- [x] T6: 殘留盤點（2026-07-21）——移除已無人使用的 `JourneyViewMode`、
  `journeyViewModeProvider`、`journeySearchQueryProvider`、
  `filteredJourneyItemsProvider` 與其測試檔，以及 5 個變成孤兒的 i18n key
  （`view_timeline` / `view_by_trip` / `search_hint` / `no_results` /
  `no_entries`）
  - ⚠️ **歷程頁的搜尋功能隨時間軸一起消失了**。這是 v2 設計的取捨，不是疏漏；
    若之後想找特定記錄，需要重新設計入口（例如書架上加搜尋，或旅程內搜尋）
- 驗證: `fvm flutter analyze --fatal-infos` 乾淨、full suite 535 passed

