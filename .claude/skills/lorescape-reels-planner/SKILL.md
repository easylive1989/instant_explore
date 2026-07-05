---
name: lorescape-reels-planner
description: Use when the user wants to plan or refresh the daily place-story Reels calendar — deciding which 景點 to feature each day/week, rebalancing the theme mix after a metrics review, doing the period-end 檢核 (e.g. 8/3), or when lorescape-metrics IG analysis finishes and next period's selection is due. Triggers on 「規劃景點 calendar」「排 Reels 景點」「下週/下月選點」「調整題材配比」「月底檢核」. Local, read-only on Supabase; writes only marketing/content-calendar/.
---

# Lorescape 每週景點 Reels 選點規劃

依 **IG 實際成效數據** 規劃每日景點故事 Reel 的選點 calendar，
取代 `daily_story_places` 預設的字母序 FIFO（place_picker 程式不改，
只在跑 lorescape-manual-daily-story 時指定 `wikipedia_title_en`）。

**產出**：`marketing/content-calendar/_reels-place-calendar.md`
（唯一的 calendar 檔，續寫新期程、保留舊期程當歷史）。

## 資料依據

1. **成效數據**：metrics Google Sheet 的 `ig_posts` 分頁。
   若今天還沒更新，先跑 lorescape-metrics（`--only ig,ig_posts`）。
2. **景點庫存**：Supabase `daily_story_places`（唯讀）。

## 題材類型分類

每則已發 Reel 與每個候選景點都歸入一類：

| 類型 | 定義 |
|------|------|
| 日韓 | 日本、韓國景點（台灣受眾最高親和度） |
| 世界名勝 | 全球高辨識度地標（馬丘比丘、金字塔級） |
| 華語圈 | 中國、港澳（文化親近、低理解門檻） |
| 東南亞 | 台灣人短程旅遊圈（泰、寮、印尼、斯里蘭卡…） |
| 歐洲經典 | 自由行熱門城市（佛羅倫斯、布拉格級） |
| 冷門深度 | 其他（品牌「隱藏故事」定位，但觸及最低） |

## 步驟

1. **算各類型成效**：讀 `ig_posts` 分頁，只取 REELS，按上表分類，
   算每類的平均 reach 與 avg_watch_time。樣本 < 3 的類型標「樣本不足」。

2. **決定週配比**：每週 7 檔。規則——
   - 平均觸及最高的類型每週 2 檔，排**週三、週六**（週末高峰）。
   - 次高類型 2 檔，排**週一、週日**，兼作對照組。
   - 其餘 3 檔輪換，讓每類持續累積樣本（沒有數據就沒有下次的判斷）。
   - 配比與上一期不同時，必須在 calendar 檔寫一句數據理由。

3. **撈庫存並核對標題**：從 `daily_story_places` 撈 active 且未用的景點，
   calendar 上的每個 `wikipedia_title_en` 都必須與 DB 逐字一致
   （跑 daily story 時靠它查詢，錯一字就查不到）。查詢方式：

   ```python
   # cd scripts && uv run python - <<'EOF'
   from pathlib import Path
   from dotenv import load_dotenv
   load_dotenv(Path("../backend/.env"))
   from lorescape_backend.config import Config
   from supabase import create_client
   config = Config.from_env()
   sb = create_client(config.supabase_url, config.supabase_service_role_key)
   rows = (sb.table("daily_story_places")
           .select("wikipedia_title_en, is_active, used_at")
           .execute()).data
   unused = [r["wikipedia_title_en"] for r in rows
             if r["is_active"] and not r["used_at"]]
   # EOF
   ```

4. **寫 calendar**：續寫 `_reels-place-calendar.md`，每期包含——
   - 期程（起訖日期，預設 4 週）與本期配比的數據依據
   - 每週一張表：日期、景點中文名、DB 標題、類型
   - 備援池：每類型 2–3 個同類可互換的景點
   - 期末檢核段：檢核日期 + 判準（各類型平均觸及對比、
     profile_views/reach 轉換率門檻）

5. **更新記憶**：改寫 memory `reels-place-calendar` 的期程與重點，
   讓每日 daily story session 知道當期 calendar 在哪、何時檢核。

## 期末檢核（calendar 檔內指定的日期到期時）

1. 用最新 `ig_posts` 算本期各類型平均觸及與觀看秒數。
2. 假設驗證：最強類型是否仍最強？對照組（世界名勝）是否同樣有效？
   若是，驅動因素可能是「辨識度」而非「地緣」，下期選點邏輯要改。
3. profile_views / reach 若 < 1%，問題在帳號定位不在選點——
   優先建議改 bio 與 Reel 結尾 CTA，而不是繼續換題材。
4. 據此產出下一期 calendar（回到步驟 2）。

## 注意

- **不改程式**：place_picker 的 FIFO 邏輯保留當 fallback，不動。
- **不寫 Supabase**：`daily_story_places` 只讀；`used_at` 由發文流程更新。
- 已排進 calendar 但當天臨時換點時，從備援池同類型互換，
  並在 calendar 檔上直接改，保持檔案與實際發文一致。
- 品牌補充貼文（若有）由 marketing-content-calendar 另行規劃，
  與本 skill 的每日選點層互不衝突。
