# Reels 洞察快照欄位定義（`data/metrics/ig_reels_insights.csv`）

由 Claude 讀使用者提供的 IG App「Reel 洞察報告」截圖後寫入。
key = (`media_id`, `checkpoint`)，同 key 重寫覆蓋；
排序：`posted_date` → `media_id` → `checkpoint`（24h → 48h → 7d）。
數字照截圖原樣記（百分比去掉 `%` 只記數值；`--` 或未提供＝留空）。

## CSV header（固定順序）

```
media_id,checkpoint,obs_date,posted_date,permalink,caption,views,reach,avg_watch_time_s,new_followers,skip_rate_pct,share_rate_pct,like_rate_pct,save_rate_pct,repost_rate_pct,comment_rate_pct,src_reels_pct,src_explore_pct,src_feed_pct,src_profile_pct,src_other_pct,profile_visits,likes,comments,reposts,shares,saves,follower_pct,age_13_17_pct,age_18_24_pct,age_25_34_pct,age_35_44_pct,age_45_54_pct,age_55_64_pct,age_65_plus_pct,gender_male_pct,gender_female_pct,gender_other_pct,countries
```

## 識別欄

| 欄 | 來源 |
| --- | --- |
| `media_id`、`posted_date`、`permalink`、`caption` | 直接抄 `ig_posts.csv` 同貼文的列（caption 沿用其截斷格式） |
| `checkpoint` | `24h` / `48h` / `7d`（posted_date 的 +1 / +2 / +7 天觀測） |
| `obs_date` | 記錄當天（today） |

## 總覽 tab

| 欄 | 截圖項目 |
| --- | --- |
| `views` | 摘要「觀看次數」 |
| `reach` | 摘要「觸及的帳號數量」 |
| `avg_watch_time_s` | 摘要「平均觀看時間」，換算成秒（如 `7 秒`→`7`、`1 分 5 秒`→`65`） |
| `new_followers` | 摘要「粉絲人數」（此 Reel 帶來的追蹤；與互動 tab 的「粉絲人數」同值） |
| `skip_rate_pct` … `comment_rate_pct` | 「影響你瀏覽次數的因素」六列：略過率、分享率、按讚率、儲存率、轉發率、留言率 |
| `src_reels_pct` / `src_explore_pct` / `src_feed_pct` / `src_profile_pct` | 「瀏覽/觀看次數主要來源」的 Reels 頁籤／探索／動態消息／個人檔案 |
| `src_other_pct` | 來源出現上述四項以外的項目時，加總記這欄 |

（觀看時間長度曲線、長期瀏覽次數曲線為圖形，不記錄。）

## 互動次數 tab

| 欄 | 截圖項目 |
| --- | --- |
| `profile_visits` | 瀏覽後的動作次數「個人檔案瀏覽次數」 |
| `likes` / `comments` / `reposts` / `shares` / `saves` | 互動次數：按讚數／留言數／轉發次數／分享次數／儲存次數 |

## 觀眾 tab

互動帳號 <100 時 IG 只給粉絲比、不給輪廓——輪廓欄全部留空，不算漏抓。

| 欄 | 截圖項目 |
| --- | --- |
| `follower_pct` | 看過你 Reel 的用戶「粉絲人數」%（非粉絲 = 100 − 此值，不另記） |
| `age_*_pct` 七欄 | 年齡分布 13-17 / 18-24 / 25-34 / 35-44 / 45-54 / 55-64 / 65+ |
| `gender_male_pct` / `gender_female_pct` / `gender_other_pct` | 性別分布（IG 顯示「未指定」記 other） |
| `countries` | 國家/地區分布打包成一欄：`名稱:百分比` 以 `\|` 相連、照截圖順序，如 `日本:34.9\|台灣:20.4\|美國:8.1` |

## 寫入時自我檢查

- 三個 tab 是否都齊？缺 tab 先向使用者要，不要留半列。
- 截圖裡的按讚數（頂部 icon 列）應與互動 tab `likes` 一致，不一致以互動 tab 為準並向使用者提示。
- 寫完讀回該貼文的列，把 views / skip_rate / like_rate / follower_pct 念給使用者核對。
