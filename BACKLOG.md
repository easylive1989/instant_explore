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

## ⚠️ 待部署（程式已在 repo，尚未上生產，2026-07-08）

以下改動已 commit + push 到 master，但**尚未部署到生產**，使用者尚看不到：

- [x] **落地頁**（`landing/`）：已部署到 `lorescape.app`（2026-07-09，Deploy Landing workflow 從 master HEAD 重建，正式站驗證通過）。含 F2/F6 T5 定價 section（廣告 7 天試用）與 F9 景點著陸頁
- [x] **Backend**（`backend/`）：已部署到 VPS（2026-07-09，Deploy Backend workflow `git reset --hard origin/master` + `docker compose up -d --build`）。含 F1 T1 的 Reel caption CTA 文案（已改為固定常數、不吃 CTA_TEXT env）＋ F8 發布 bot
- [x] **Publisher**（`publisher/`）：F11 T2 的 reel video_url fallback 於 2026-07-13 完成，2026-07-20 使用者手動觸發 Deploy Publisher workflow 上 VPS 生效
- [x] **App**（`frontend/`）：新版本已上架商店並顯示「7 天免費試用」字樣（2026-07-20 使用者確認），F6 T4 生效
- [ ] **App**（`frontend/`，下一輪）：F10 的 `Info.plist` 相簿權限鍵已於 2026-07-20 完成但**尚未包含在已上架版本**，待下次 build 送審才生效
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

- 狀態: 待辦
- 來源: marketing/audits/weekly-2026-07-13.md（P0）——本週 App 活躍腰斬
  （iOS+Android 22 vs 46）、新用戶 −56%、D1 留存幾乎全週 0%（僅 07-11
  cohort 20%）、D7 全 0%；流量端反而成長（IG 觸及 +75%、Landing 新用戶
  +40%），問題在留不住不在進不來
- [ ] T1: 跑 marketing-retention 分析流失點（GA4 cohort + narration 完成率
  交叉；narration.csv 目前 0 rows，pre-traffic，一併確認事件有無進來）
- [ ] T2: 檢查每日故事推播的實際送達與開啟情況（習慣養成迴路是否真的在
  運作）
- [ ] T3: 下週週報驗證 reel 片尾下載 CTA 成效（2026-07-13 上線
  `Cinematic.tsx` ending CTA，對「IG 觸及 1,923 → iOS 下載 1」的轉化缺口）
  - 2026-07-20 部分驗證：對「追蹤」有效（聖家堂 Reel 24h 帶進 +5 粉絲、
    profile_visits 1，本週唯一破 1 的 CTA 轉換）；對「下載」尚未見效
    （iOS 下載仍持平 2/週，觸及卻 +154%）。轉換斷層在 bio→商店這一段，
    見 F15

## F14: GA4 Android 追蹤斷線診斷 (epic: E1)

- 狀態: 待辦
- 來源: marketing/audits/weekly-2026-07-20.md（P0）——`ga4.csv` 的
  `android_active_users`/`android_new_users` 自 2026-07-11 起連續 9 天全空，
  同期 Play 端無跡象顯示帳號停用，疑追蹤斷線而非真的零活躍
- [ ] T1: 檢查 App 端 Firebase Analytics 初始化與 GA4 Android 資料流設定
  （`docs/init/metrics-setup.md`），確認事件是否仍在送出

## F15: IG → 下載轉換優化 (epic: E1)

- 狀態: 待辦
- 來源: marketing/audits/weekly-2026-07-20.md（P0）——本週 IG 觸及 +154%
  （1,923→4,879）、粉絲 +147%，但 profile_views 轉換率僅 0.6%（30/4,879，
  < 1% 月底檢核門檻）、iOS 下載持平在 2；問題在帳號定位/CTA 不在觸及量
- [ ] T1: 改 IG bio 文案（現況「🎧 免費下載 ↓」+ 落地頁連結），加強價值主張
  句，非僅動詞指令
- [ ] T2: 統一 Reel 結尾 CTA 為固定模板——聖家堂 Reel（7/19）24h 帶進 +5
  粉絲、profile_visits 1，是本週唯一有效轉換的片尾，複製其結構到後續
  daily reel（見 F13 T3 註記）

## F16: 後端可觀測性（server 狀態檢測）

- 狀態: 待辦
- 來源: 使用者要求（2026-07-21）——增加 Lorescape 後端的可觀測性，可以檢測
  server 的 CPU、memory、disk、是不是活著等狀態
- 範圍備註: 屬維運工作，不受 E1 暫緩政策限制（政策明列「bug 修復與維運」為
  例外）
- [ ] T1: 規劃可觀測性方案（VPS 上 backend + publisher 容器的 liveness、
  CPU / memory / disk 監控；含通知管道與工具選型），再拆實作 tasks

## F19: 落地頁 sitemap SEO 修正 (epic: E1)

- 狀態: 待辦
- 來源: 2026-07-22 sitemap 體檢——結構正確（robots 指向、canonical URL、
  place 頁自動收錄）但有兩個缺陷：(1) `/story/[date]` 每日故事頁雖為
  index,follow 且每日累積，卻不在 sitemap、站內也無任何連結指向（孤兒頁，
  Google 無途徑發現）；(2) 全 sitemap 缺 `lastModified`，只帶 Google 明文
  忽略的 `changeFrequency`/`priority`
- 註: lastmod 亂給比不給更糟（全部蓋 build 時間會被 Google 不信任）——
  story 頁用故事日期、place 頁用內容實際最後編輯日
- [ ] T1: `sitemap.ts` 改 async，用既有 `getPublishedStorySlugs()` 把
  story 頁納入 sitemap
- [ ] T2: sitemap 各頁補正確的 `lastModified`（story＝故事日期、place＝
  內容編輯日）；`changeFrequency`/`priority` 可順手移除
- [ ] T3: story 頁 metadata 補 zh/en hreflang `languages` alternates
  （目前只有 canonical；同日 zh/en 故事互為翻譯才補，先確認）
- 相關（不在本 feature 範圍）: place/story 頁的內部連結（首頁連最新故事、
  景點頁互連、city hub 頁）是 sitemap 修完後真正影響排名的下一步，屬
  landing page 語意地圖工作，另立 feature 處理

## F17: 探索頁面重新設計

- 狀態: 待辦
- 來源: 使用者要求（2026-07-21）——重新設計 App 探索頁面，參考 Claude Design
- 備註: 設計稿以 Claude Design 產出，handoff bundle 依慣例放 `docs/design/`
- [ ] T1: 以 Claude Design 產出探索頁新版 mockup，與使用者確認方向後拆
  實作 tasks

## F18: 歷程頁面重新設計

- 狀態: 待辦
- 來源: 使用者要求（2026-07-21）——重新設計 App 歷程頁面，參考 Claude Design
- 備註: 設計稿以 Claude Design 產出，handoff bundle 依慣例放 `docs/design/`
- [ ] T1: 以 Claude Design 產出歷程頁新版 mockup，與使用者確認方向後拆
  實作 tasks
