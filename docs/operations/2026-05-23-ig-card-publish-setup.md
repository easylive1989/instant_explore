# IG 圖卡自動發文 — Operator 設定步驟

把 Phase 0 / Phase 2 / Phase 3 累積下來、Operator（你）要在 Dashboard 上手動做的事整理成一份從頭到尾的 checklist。**程式碼已全部 merge 進 master 並 push 到 origin**；下面 4 步做完就能跑。

順序很重要：1 → 2 → 3 → 4。前一步沒做完，後一步會跳過或報錯。

---

## 前置：確認程式碼已部署

GitHub Actions → **Deploy** workflow 在 master 上跑成功（每週五 10:00 台灣自動 / 也可手動 Run workflow）。三個 sub-job 都要綠：

- `push-supabase-db` — 把 migration 推到 production Postgres
- `deploy-backend` — 把後端 image 重啟到 VPS
- `firebase-hosting-*` — 跟本流程無關，可忽略

確認方式：

```bash
# 應該看到 daily_stories 多 6 個 card_* 欄位、daily_story_places 多 5 個
supabase db psql --linked -c "
  select column_name from information_schema.columns
  where table_schema = 'public'
    and table_name = 'daily_story_places'
    and (column_name like 'card_%' or column_name in ('latitude', 'longitude'))
  order by column_name;
"
```

預期看到 5 列：`card_city_ch`、`card_city_en`、`card_location_en`、`latitude`、`longitude`。

如果欄位還沒出現 → Deploy workflow 還沒跑成功，先處理那個再回來。

---

## Step 1 — 拿 IG Meta token（最重要，全卡這個）

**為什麼**：沒這兩個值，後端的 `config.instagram_enabled` 永遠是 `False`，整個 IG 流程跳過。

這步分兩個 sub-step：1.A 是把帳號身份準備好（一次性、Meta 平台架構強制要求），1.B 才是跑 script 換 token。

### Step 1.A — IG 帳號改成 Business + 連 Facebook Page（首次設定）

如果你的 `love.lorescape` 已經是 Business / Creator **且**已連 FB Page，跳到 Step 1.B。

如果不確定：開 IG mobile app → 個人檔案頁 → 看右上角 hamburger menu 裡有沒有 **Insights**（洞察報告）、**Professional dashboard** 這類選項——有就是 Business / Creator，沒有就是 Personal。

> **為什麼一定要 Facebook Page**：Meta Graph API 不接受純個人 IG 帳號發文。API 的 OAuth 流程靠 **Page Access Token** 授權，而 Page Token 只能從「你管理的 FB Page」拿；Meta 又規定 IG 升級成 Business 必須掛到某個 FB Page 之下。Page 不需要實際發 FB 文，純粹當 administrative parent。

#### 1.A.1 — 先準備一個 Facebook Page（如果還沒有）

Page 必須由「將來會跑 token-helper 的那個 Facebook 帳號」當 admin。

1. 用 desktop browser 登入 https://facebook.com（用會管 Lorescape 的個人 Facebook 帳號）
2. 左側 sidebar 找 **Pages** → 點 **Create new Page**（或直接開 https://www.facebook.com/pages/create）
3. 填：
   - **Page name**：`Lorescape`（任意，但選好之後改名很麻煩）
   - **Category**：選 `Travel Service` / `Media & News Company` / `Travel Company` 任一即可
   - **Bio**（可選）：一句介紹
4. 點 **Create Page**
5. 後續它會引導加大頭貼、cover 圖、連結等——這些**全部可以跳過 / 之後再補**，因為這 Page 不需要實際內容
6. 確認你（當前登入的 FB 帳號）的角色是 **Admin** → Page 設定 → **Page access** 應該寫 "You have full control"

#### 1.A.2 — 把 `love.lorescape` IG 切成 Business 並連到 Page

這步要在 **IG 手機 app** 操作，web 版選項不完整。

1. 打開 IG app → 切到 `love.lorescape` 帳號
2. 個人檔案頁 → 右上角 hamburger menu (≡) → **Settings and activity**
3. 滾下去找 **For professionals** 段 → 點 **Account type and tools**（舊版可能叫 **Switch to professional account**）
4. 點 **Switch to professional account**（如果已經是 Creator，先按 **Switch account type → Switch to business account** 也行——Creator 也能用 API，但 Business 對 content publish 權限最齊）
5. 選類別（Category）：選 `Travel & Transportation` / `Personal Blog` / `Media` 任一
6. 跳出 **Are you a business or a creator?** → **選 Business**
   - Business vs Creator：兩者都能用 Graph API 發 IG 文。但 Business 還支援 Shopping、Insights tab 比較完整，未來擴充比較不卡。如果之前已經是 Creator 也可以不換、跳到下一步
7. 接下來 IG 會引導加 contact info（email / phone / address）——**全部可以 Skip**
8. 重點來了：**Connect to Facebook** 那一頁
   - **Connect an existing Page** → 選剛剛在 1.A.1 建的 `Lorescape` Page
   - （如果沒有 Page 可選：IG app 內也提供「Create new Page」入口，但流程比 desktop 簡陋，推薦用 1.A.1 在 desktop 先建好）
9. 完成。回到個人檔案，hamburger menu 裡會多出 **Insights** 和 **Professional dashboard**

#### 1.A.3 — 驗證 IG ↔ Page 雙向都掛好

**從 Page 那邊看**：

1. desktop facebook.com → 切到 `Lorescape` Page 身份（左上角頭像下拉）
2. Page 設定 → **Linked accounts** → **Instagram** → 應該看到 `@love.lorescape` 已連結

**從 IG 那邊看**：

IG app → 個人檔案 → **Edit profile** → 滾到底 → **Page** 欄位應該顯示 `Lorescape`

兩邊都對才能繼續到 Step 1.B。

#### 1.A.4 — Meta App 給權限（一次性）

確認 https://developers.facebook.com/apps/1635287081082476 的 App Review 頁面已經啟用：

- ✅ `pages_show_list`
- ✅ `pages_read_engagement`
- ✅ `pages_manage_posts`
- ✅ `instagram_basic`
- ✅ `instagram_content_publish`

這些 Lorescape App 應該已啟用（見 `docs/init/social_publisher_setup.md` 的 use cases）。如果有變動就回那邊勾。

### Step 1.B — 跑 `meta_token_helper.py` 換 token

1.A 全綠之後才跑這步：

```bash
cd /Users/paulwu/Documents/Github/instant_explore
python scripts/meta_token_helper.py --platform instagram
```

Script 會引導你完成：

1. 輸入 App ID `1635287081082476` 與 App Secret（在 Meta Developer Console 設定頁查）
2. 開 Graph API Explorer、授權、複製短效 User Token 貼回 script
3. Script 自動換成 60 天長效 User Token
4. Script 列出你的 Facebook Pages → 選 `Lorescape`（如果 1.A 有確實連上，這裡會出現；沒出現就回 1.A 檢查）
5. Script 換出永久 Page Access Token
6. Script 解析出 IG Business Account ID
7. Script 在終端機印出兩行，類似：
   ```
   IG_USER_ID=17841...
   META_PAGE_ACCESS_TOKEN=EAAX...
   ```

完整背景見 `docs/init/social_publisher_setup.md`。

### 寫入兩個地方

**地方 1（本機開發 / 測試）**：`backend/.env`

```dotenv
IG_USER_ID=17841...
META_PAGE_ACCESS_TOKEN=EAAX...
```

**地方 2（production VPS）**：SSH 到 VPS、編輯 `/opt/lorescape/.env`、貼同樣兩行、`docker compose up -d` 讓新 env 生效。

⚠️ Page Access Token 看起來像「永久」但實務上 Meta 偶爾會回收，每年看一次。

---

## Step 2 — 建 `ig-cards` Supabase Storage bucket

**為什麼**：publisher 把渲染好的 PNG 上傳這裡、再把 public URL 餵給 IG API。沒這個 bucket → publisher 一上傳就 500、row 落 `failed` 狀態、Discord 噴錯。

完整步驟見 `docs/operations/2026-05-21-ig-cards-bucket-setup.md`。摘要：

1. Supabase Dashboard（**production** 那個專案，URL 含 `kypcxxjqsinamcqrjeog`） → 左側 **Storage** → **New bucket**
2. 填入：
   - **Name**: `ig-cards`（精確大小寫）
   - **Public bucket**: ✅ **打開**（Meta 要匿名讀）
   - **File size limit**: 5 MB
   - **Allowed MIME types**: `image/png`
3. 點進新 bucket → **Configuration** 確認 `Public` 是 on
4. 驗證 public：上傳任意 PNG 當測試 → 點圖 → **Get URL** → 開無痕貼網址 → 應該直接顯示出來。驗完刪掉測試圖

⚠️ 如果本機開發也想跑 publisher 試試，本機 Supabase 也要建一份同名 bucket。

---

## Step 3 — Backfill 現有 places 的 5 個 card 欄位

**為什麼**：Phase 2 migration 只加欄位、不填值。現有 active places 的這 5 個欄位都還是 NULL，publisher 遇到會跳過 IG（Threads 還是會發）。

**Step 3.1 — 列出需要填的景點**

Supabase Dashboard → **SQL Editor** → 新建 query → 貼：

```sql
select id, name, country
from public.daily_story_places
where is_active = true
  and (card_location_en is null
    or card_city_ch is null
    or card_city_en is null
    or latitude is null
    or longitude is null)
order by created_at;
```

跑完應該列出所有 active 但尚未 backfill 的景點。

**Step 3.2 — 一筆筆填**

每個景點查 Wikipedia 找：
- 英文名（給 `card_location_en`）
- 經緯度（Wikipedia 頁面右上角座標連結，或用 GeoHack）

然後跑（用 Eiffel Tower 為範例，其他景點照樣改）：

```sql
update public.daily_story_places
set card_location_en = 'TOUR EIFFEL · PARIS',
    card_city_ch     = '巴',
    card_city_en     = 'PARIS',
    latitude         =  48.8584,
    longitude        =   2.2945
where name = 'Eiffel Tower';
```

**填法慣例**（很重要，圖卡視覺一致性靠這個）：

| 欄位 | 規則 | 例子 |
|---|---|---|
| `card_location_en` | 全大寫、`<景點> · <城市>`、用 middle dot `·`（U+00B7，不是 ASCII period） | `TOUR EIFFEL · PARIS`、`COLOSSEUM · ROME`、`TOKYO TOWER · TOKYO` |
| `card_city_ch` | **1 個** 繁體中文字（最具代表性的那個） | Paris → `巴`、Tokyo → `東`、Rome → `羅`、London → `倫`、Kyoto → `京` |
| `card_city_en` | 城市名、全大寫、不含國家 | `PARIS`、`TOKYO`、`ROME` |
| `latitude` | 十進位度、有正負號（南為負）、**4 位小數** | `48.8584`、`-33.8688` |
| `longitude` | 十進位度、有正負號（西為負）、**4 位小數** | `2.2945`、`-70.6483` |

**Step 3.3 — 驗證**

重跑 Step 3.1 那段 select，預期 0 列（所有 active 景點都填完了）。

### 未來新增景點

從 Dashboard 加 `daily_story_places` row 時，這 5 個欄位要一起填，**不能再留 NULL**。不然新景點被 cron 選到當天 IG 就會 graceful skip。

---

## Step 4 — 觀察首次跑起來

設定都做完之後（理想情況：傍晚前都搞定），等晚上 21:00 的 publisher cron 自動跑。

**那天早上 9 點之後**——驗證 zh-TW row 的 Gemini 有產出 card 欄位：

```sql
select publish_date, place_name, card_title_ch, card_anno_roman,
       array_length(card_paragraphs_ch, 1) as para_count
from public.daily_stories
where publish_date = current_date
  and language = 'zh-TW';
```

預期：
- `card_title_ch` 有值（≤14 字的中文主標）
- `card_anno_roman` 是羅馬數字字串（例：`MDCCCLXXXIX`）
- `para_count` 是 `3`

如果 `card_*` 全空 → 早上 09:00 cron 出問題，看 Discord channel 有沒有 `notify_failure`。

**晚上 9 點 publisher 跑完之後**——驗證最終狀態：

```sql
select id, place_name, review_state, threads_post_id, ig_post_id, publish_error
from public.daily_stories
where publish_date = current_date
  and language = 'en';
```

四種結果：

| 結果 | 意思 | 處理 |
|---|---|---|
| `published` + 兩個 post_id + `publish_error=null` | 完美 | 🎉 沒事 |
| `published` + threads_post_id + ig_post_id=null + `publish_error='ig_skipped_missing_card_content'` | Threads 發了、IG 跳過 | 該景點的 backfill 沒做完（Step 3）或 zh-TW Gemini 漏欄位。回去檢查 |
| `failed` + `publish_error` 含 storage / upload 字樣 | bucket 沒建好或權限錯 | 回 Step 2 檢查 bucket 是 public、名字精確 `ig-cards` |
| `failed` + `publish_error` 含 Meta API 字樣 | token 過期 / 沒權限 / 圖片下載不到 | 回 Step 1 重新跑 token helper |

`failed` 的 row 可以手動 reset 來重跑：

```sql
update public.daily_stories
set review_state = 'pending',
    publish_error = null,
    threads_post_id = null,
    ig_post_id = null
where id = '<failed-row-id>';
```

然後手動再跑一次 publisher：

```bash
# 本機（會用本機 .env）
cd backend && uv run python -m lorescape_backend.social.publisher <YYYY-MM-DD>

# 或 SSH 進 VPS
ssh root@<vps> 'cd /opt/lorescape && docker compose exec backend python -m lorescape_backend.social.publisher <YYYY-MM-DD>'
```

---

## TL;DR

```
[ ] Deploy workflow 跑過、migration 上 production
[ ] Step 1.A.1: desktop FB 建 Lorescape Page (admin = 你本人 FB)
[ ] Step 1.A.2: IG app 把 love.lorescape 切 Business + 連上面那個 Page
[ ] Step 1.A.3: 雙向驗證 IG ↔ Page 都掛好
[ ] Step 1.A.4: Meta App 5 個 IG/Page 權限已啟用
[ ] Step 1.B:   跑 meta_token_helper.py → .env + VPS env
[ ] Step 2:     Supabase Dashboard → Storage → New bucket "ig-cards" (Public)
[ ] Step 3.1:   SQL Editor → 跑 backfill listing query
[ ] Step 3.2:   一筆筆 update（找 Wikipedia 抓 lat/lng）
[ ] Step 3.3:   重跑 listing query，預期 0 列
[ ] Step 4:     隔天觀察 daily_stories 跟 IG 帳號實際發文
```

四步全綠之後，從那天起每天 09:00 產文、晚上 21:00 經 Discord 審核後自動發 Threads + IG 圖卡。
