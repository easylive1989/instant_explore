# Reel 縮短長度 + 零秒 Hook 設計

日期：2026-07-13
狀態：設計定案，待實作

## 背景與動機

2026-07-13 的數據分析發現：換成 Remotion Cinematic 風格（07-09 起）後，
reel 的 reach / views 並未變好，而最大的結構性變數是**影片長度暴增**：

| 風格 | 影片長度 |
|---|---|
| 舊 Google Flow（~07-07 前） | 10–12 秒 |
| 新 Remotion（07-09 起） | 33 → 62 → 58 → 77 秒（07-13 更達 103 秒） |

Reels 演算法吃完播率，影片愈長愈難完播，新片略過率 67–81%（vs 舊爆款
馬丘比丘 38.5%）。長度是目前最可能壓低表現的單一變數。此外開場缺乏
「零秒 hook」——目前 cover 是 kicker → 標題 → 文字依序淡入，抓不住前
1–2 秒。

本設計把 reel pipeline 改成**目標 20–30 秒**並加入**零秒拋問句 hook**。

## 範圍

- 套用範圍：**pipeline 永久化**，從實作後的每日 reel 生效。
- **不重做** 2026-07-13 已送審的 103 秒版（維持原樣）。
- 不動 carousel（wander 固定 9 拍照舊）、不動 `prepare_story.mjs` 的
  scaffold 行為（仍輸出全 9 拍，由 Claude 在濃縮步驟挑子集）。

## 設計

### 1. 長度：目標 20–30 秒（砍拍數 + 精煉旁白）

- carousel 固定 9 拍，但 reel 不必全用。`lorescape-daily-reel` skill 的
  Step 2（濃縮）改為指示 Claude 挑選 **hook cover ＋ 3–4 個最強拍 ＋
  ending**（合計 5–6 拍），其餘捨棄。挑選原則：保留反轉/懸念/彩蛋，
  丟掉鋪陳與次要細節。
- 每拍旁白從「完整複句」收成「一句短 clause」（口說唸完約 3–4 秒）。
- 長度由 `reel_voiceover` 依 TTS 實測長度回填 `durationFrames`，寫短了
  片子自然短，**不需硬性上限**。skill 註明：算下來若超過 ~35 秒，
  再砍一拍或縮句。

### 2. 零秒 Hook：cover 版面改造

- **文案規則**（skill Step 2）：cover 的 hook 用一句話講完反轉/懸念，
  例：「全世界最著名的建築，其實是一座墳墓。」放在 cover 的第一
  `lines`。
- **render 改造**（`Cinematic.tsx` 的 cover layout）：
  - hook 句（cover `lines` 第一句）以**最大字級、最早淡入**（第一幀就在）。
  - 地區標籤（`kicker`）與英文名（`subtitle` / `titleEn`）**降級成小字**，
    排在 hook 之後淡入。
  - 中文大標題（`title`）仍保留，但退居 hook 句之下、非第一視覺焦點。
  - 只影響 `layout === "cover"`；beat / bright / ending 版面不動。

### 3. ending CTA 在短片裡不被犧牲

- 2026-07-13 加入的片尾下載 CTA（lockup ＋「更多景點故事，下載
  Lorescape」＋商店行）在 20–30 秒短片裡佔比變大。
- ending 拍設**最短停留下限**：即使 ending 旁白很短（TTS 回填的
  `durationFrames` 偏小），也保證停留足夠讓 CTA 完整淡入且讀得完
  （不被下一個 cut 切掉）。具體下限值在實作計畫中依 CTA 淡入時序
  （目前 reveal delay ≈ last-line + 18 frames）估算。

## 不做（YAGNI）

- 不加「專用 hook 拍」（使用者選零秒拋問句，不是多一拍）。
- 不改 carousel 拍數或 wander 風格。
- 不對 reel 長度做硬性程式上限（靠旁白長度自然收斂即可）。
- 不重跑歷史 reel。

## 影響檔案（預估）

| 檔案 | 改動 |
|---|---|
| `.claude/skills/lorescape-daily-reel/SKILL.md`（Step 2） | 長度目標、挑拍規則、hook 文案規則 |
| `marketing/tools/reel-remotion/src/styles/Cinematic.tsx` | cover layout 零秒 hook；ending 停留下限 |
| `marketing/tools/reel-remotion/src/data/story.ts` | ending `durationFrames` 下限（若採此路徑） |
| `marketing/tools/reel-remotion/src/types.ts` | 視需要為 cover hook 加欄位（或沿用 `lines[0]`） |

## 驗證

- 用 07-13 泰姬瑪哈陵素材重跑一支**測試** reel（不送審），確認：
  總長 20–30 秒、cover 第一幀即見 hook 大字、片尾 CTA 完整可讀。
- 隔日起正式 reel 依此產出；一週後以同 checkpoint（24h/48h）的略過率
  與 views 對比舊片，驗證完播是否改善。
