# 故事素材豐富度比較：Gemini+Google Search vs Perplexica vs SearXNG

> 日期：2026-06-10　範圍：spike / 評估，未接入正式流程
> 用途情境：要給前端**一個地點顯示多個故事**，因此評估重點是「能產出多少個**有具名人/事/年代、彼此不同**的故事角度」。

---

## 1. 背景

目前正式後端（每日故事 `daily_story`、使用者導覽 `narration`）產故事時**完全不上網**——只用 Wikipedia + Wikidata 純文字餵 Gemini（結構化 JSON 輸出，無任何 web search / grounding tool）。

為了評估「加入網路搜尋能不能讓素材更豐富」，比較兩條**網搜路線**：

- **A：Gemini + 原生 Google Search grounding**
  讓 Gemini 用內建的 Google Search 工具（`tools=[Tool(google_search=...)]`）自己一邊搜一邊產出角度。**單層 LLM、單次呼叫、零額外基礎設施。**

- **B：Perplexica → Gemini**
  自架的 Perplexica（SearxNG 網搜 + 一層 LLM 把網頁摘要成研究文）先產出研究素材，再交給 Gemini 從中抽出角度。**兩層 LLM、需 Docker（Perplexica + SearxNG + chat/embedding provider）。**

- **C：SearXNG 直接 → Gemini**
  跳過 Perplexica 的摘要層，直接拿 SearXNG 的**原始搜尋結果片段**（每筆 title + url + 一兩句 snippet，兩組 query、最多 12 筆去重）餵給 Gemini 抽角度。**單層 LLM、只需 SearXNG 一個容器。**

---

## 2. 測試方法

腳本：`backend/scripts/source_quality_compare.py`

對同一地點，兩個方法都被要求：

> 「為一個文化／旅遊 App（一個地點會顯示多個故事）提出最多 N 個**不同**的短篇故事角度。每個角度**必須**圍繞一個具體的具名真實人物**或**有記載的事件，要有具體的人名、日期或地點，禁止『歷史悠久』這類空泛填充。」

- **A** 用 `google_search` grounding，要求輸出固定格式
  `N || 標題 || teaser || entity1; entity2; ...`，再解析；同時記錄 grounding 來源數。
- **B** 先呼叫 `sources/perplexica.py:fetch_web_research()` 取得研究文，再用 Gemini 結構化輸出（schema：`angles[] = {title, teaser, entities[]}`）。

兩者皆 `gemini-2.5-flash`、`temperature=0.4`、`n=8`。

**量化指標**：角度數、不重複具名實體數（彙整所有 `entities` 去重）、平均 teaser 長度、來源數。

### 重現指令

```bash
cd backend
uv run python -m scripts.source_quality_compare \
  --place "Arles" --wikidata-id Q48292 --location "Provence, France" \
  --language en --n 8            # 跑 A+B+C；--skip a,b 可只跑部分
uv run python -m scripts.source_quality_compare \
  --place "鹿陶洋江家聚落" --location "台南市楠西區" --language zh-TW --n 8
```
（需 `backend/.env` 有可用的 `GEMINI_API_KEY`；B 需要本機 Perplexica 在跑；C 需要 SearXNG——compose 已把 Perplexica 內建的 SearXNG 發布在 `localhost:8081`，可用 `--searxng-url` 覆寫。見同目錄 README。）

---

## 3. 測試例子

| 例子 | 為什麼選它 | 測了哪些方法 |
|---|---|---|
| **Arles**（法國普羅旺斯），n=8，en | 素材豐富（羅馬遺跡、梵谷、人瑞 Jeanne Calment…），比「抽角度」能力上限 | A、B、C |
| **鹿陶洋江家聚落**（台南楠西），n=8，zh-TW | **冷門／維基條目很薄**——正是現在 narration 品質閘門會擋掉的類型，最能驗證網搜補料能力 | A、B、C |

---

## 4. 結果一：Arles（豐富地點）

### 4.1 量化摘要

| 方法 | 角度數 | 不重複具名實體 | 來源數 |
|---|---|---|---|
| **A：Gemini + Google Search** | 8 | **32** | （見註）|
| **B：Perplexica → Gemini** | 8 | 26 | 8 |
| **C：SearXNG 直接 → Gemini** | **4** | 14 | 12 |

> 註：A 的來源數在第一輪腳本中顯示為 0，是**擷取 grounding metadata 的 bug**，非真的沒有——單獨測 grounding 時可拿到 9 個來源（第二輪測試已修正，見結果二）。**三邊都有來源**。

### 4.2 A：Gemini + Google Search 的 8 個角度

1. **The Yellow House Dream and Its Shattering** — 梵谷在亞爾的創作期、藝術家聚落之夢，及 1888/12/23 割耳事件。
   `entities: Vincent van Gogh, Paul Gauguin, Yellow House, December 23, 1888`
2. **Jeanne Calment: Arles' Centenarian Witness** — 1875 生於亞爾、史上最長壽認證者，年輕時據稱見過梵谷。
   `entities: Jeanne Calment, February 21, 1875, August 4, 1997, 122 years and 164 days`
3. **Constantine's Imperial City: The Council of Arles** — 羅馬帝國行宮、君士坦丁浴場、314 AD 第一次亞爾會議。
   `entities: Emperor Constantine I, 314 AD, Constantine Baths, Council of Arles`
4. **Caesar's Reward: The Birth of Roman Arles** — 因內戰中支持凱撒而成羅馬殖民地，前 46 年為第六軍團退伍兵設立。
   `entities: Julius Caesar, 46 BC, Colonia Julia Paterna Arelate Sextanorum, Sixth Legion`
5. **The Lens of Arles: Founding a Photography Legacy** — 1970 年 Lucien Clergue 等人創辦 Rencontres d'Arles 攝影節。
   `entities: Lucien Clergue, Michel Tournier, Jean-Maurice Rouquette, 1970, Rencontres d'Arles`
6. **Barbarossa's Coronation: A Medieval Imperial Moment** — 1178 年神聖羅馬皇帝紅鬍子腓特烈一世在 Saint-Trophime 主教座堂加冕勃艮第王。
   `entities: Frederick I Barbarossa, 1178, Saint-Trophime Cathedral`
7. **The Arena's Many Lives: From Gladiators to Bullfights** — 競技場 90 年代落成、5 世紀變中世紀堡壘、1830 起辦鬥牛。
   `entities: Arles Amphitheatre, 90s AD, 5th century, 1830`
8. **Gauguin's Brief, Turbulent Stay** — 高更 1888/10–12 短居、與梵谷激烈合作與決裂。
   `entities: Paul Gauguin, Vincent van Gogh, October 23, 1888, December 23, 1888, Yellow House`

### 4.3 B：Perplexica → Gemini 的 8 個角度

（Perplexica 原始研究文 6065 字、約 8 筆來源）

1. **Echoes of the Arena: Arles' Roman Spectacle** — 競技場、羅馬殖民地。
   `entities: Arles Amphitheatre, Roman colony, 1st century BC, UNESCO World Heritage List`
2. **Van Gogh's Golden Light** — 亞爾的光與風景啟發梵谷。
   `entities: Vincent Van Gogh, Arles`　← **無任何具體事實**
3. **Jeanne Calment: Arles's Century-Spanning Storyteller** — 亞爾出身的超級人瑞。
   `entities: Jeanne Calment, supercentenarian, Arles`　← **丟失 122 歲等關鍵數字**
4. **Arles's Brief Eastern Breeze: The Moorish Occupation** — 735–739 摩爾人占領、併入加洛林帝國。
   `entities: Moorish occupation, 735 AD, 739 AD, Provence, Carolingian empire`
5. **Christian Lacroix: The Arlesian Roots of Couture** — 時裝設計師 Christian Lacroix 的亞爾根源。
   `entities: Christian Lacroix, Arles, French fashion designer`
6. **Imperial Indulgence: The Baths of Constantine** — 隆河畔的君士坦丁浴場。
   `entities: Baths of Constantine, Roman baths, Rhône River`
7. **Eternal Rest: The Ancient Beauty of Les Alyscamps** — 羅馬墓園 Les Alyscamps。
   `entities: Les Alyscamps, necropolis, Roman, Arles`
8. **Faith and Power: Arles in the 6th Century Religious Strife** — 6 世紀亞略派西哥德與羅馬教會的角力。
   `entities: 6th century AD, Arian Visigoth kings, Church of Rome`

### 4.4 C：SearXNG 直接 → Gemini 的 4 個角度

（12 筆原始 snippet，但每筆只有一兩句話，深度不足以撐滿 8 個角度）

1. **Arles' Roman Golden Age** — 4 世紀的「第二黃金時代」、競技場/劇場/cryptoporticus。
   `entities: 1st century B.C., 4th century, Arles Amphitheatre, Roman theatre, cryptoporticus`
2. **Van Gogh's Arles** — 梵谷與高更。`entities: Van Gogh, Gauguin`　← 偏空泛
3. **Picasso's Passion: Bullfighting and Art** — 畢卡索為亞爾鬥牛畫了 **2 幅畫＋57 張素描**。
   `entities: Picasso`　← A/B 都沒挖到的事實
4. **1944: Arles Rises** — 1944 年普羅旺斯解放戰、亞爾反抗軍驅逐德軍。
   `entities: 1944, World War II, liberation of Provence`　← A/B 都沒有的角度

**Arles 小結**：C 在豐富地點明顯吃虧——snippet 太淺，嚴格接地下只能擠出 4 個角度；但它也独家挖到畢卡索 57 素描、1944 解放這類角度。

---

## 5. 結果二：鹿陶洋江家聚落（冷門地點，zh-TW）

這是關鍵測試：維基條目很薄、現行 narration 幾乎做不出故事的地點。**結果三條網搜路線全部大放異彩**，撈到大量維基沒有的素材。

### 5.1 量化摘要

| 方法 | 角度數 | 不重複具名實體 | 來源數 |
|---|---|---|---|
| **A：Gemini + Google Search** | **8** | **33** | **18** |
| **B：Perplexica → Gemini** | 7 | 28 | 8 |
| **C：SearXNG 直接 → Gemini** | 7 | 30 | 12 |

### 5.2 A 的亮點（8 角度，深度與精確度最高）

- **江如南 1721（康熙 60）年自漳州詔安渡台**，帶香火與卜杯開基
- 江如南曾是**「鴨母王」朱一貴起義的軍師**（傳奇角度）
- **江寬山（東峰大帝）1561（明嘉靖）年率鄉勇抗匪首張連**，戰死成神
- 「不分家」祖訓、建築不得高於祖祠堂
- 宋江陣：1996 重組、2010 登錄傳統藝術
- 1993 社造起點、1995 賴佳宏老師＋成大王明蘅教授投入
- **2010 甲仙大地震重創宗祠、2017/11 啟動修復**

### 5.3 B 的亮點（7 角度，最會挖「人味」與新聞）

- **客家身世之謎**：林俊賢之妻從半月池發現江家其實是詔安客家（獨家角度）
- **江晉清的童年記憶**：宗祠前曾是牛車交易市集（獨家、最有故事感）
- **2025 年初地震重創 + 賴清德總統視察、九成重建經費、半月池重建**（最新時事）
  ⚠️ 但它把地震寫成「M6.4 **甲埔**地震」——名稱疑似漂移（2025 初震央在嘉義大埔/台南楠西一帶），**體現了 B 兩層 LLM 的事實漂移風險，採用前需查核**
- 獨特祭儀盤點：開公媽龕、田都元帥聖誕、入丁…

### 5.4 C 的亮點（7 角度，譜系精確度驚人）

- **最完整的家族譜系**：長子**江日服**隨父渡台；次子**江日溝（會川公）1739（乾隆 5）年**來台尋父兄，娶**鄭式**、育五子、奠定**四大房**——A/B 都沒挖到這層
- **歷經 24 代、10 餘代未分家**
- 2009 登錄台南市文化資產；**半月池 2025/11/15 落成**（極新的時事）
- **電影《總舖師》拍攝場景**（獨家角度）

**冷門地點小結**：與 Arles 相反，C 在冷門地點表現驚艷——本地內容的 snippet 資訊密度高（廟誌、文資網頁、新聞），單層直餵反而保留最多精確譜系。B 挖到最有「人味」的獨家（牛車市集、客家身世）與最新新聞，但出現名稱漂移。A 依然是整體最穩：8 個角度全有名有姓有年代。

---

## 6. 分析

- **整體精確度／穩定度：A 勝。** 兩個地點 A 都拿滿 8 個角度、實體數最高（32/33），且普遍帶確切日期與全名（1888/12/23、122 歲 164 天、前 46 年第六軍團、1721 渡台、1561 抗匪…）。
- **為什麼 B 會掉細節：兩層 LLM 的「傳話損耗」。** Perplexica 先把網頁**摘要**成研究文，這一步會把精確數字洗掉（Arles 的梵谷/Calment 角度丟失關鍵事實），甚至產生**名稱漂移**（冷門地點把地震名寫成「甲埔地震」）。但 B 的綜合敘事也最會挖**人味與時事**（牛車市集、客家身世、總統視察）。
- **C 的表現高度取決於 snippet 密度。** 豐富地點（Arles）snippet 淺、只擠出 4 個角度；**冷門地點反而驚艷**——在地內容（廟誌、文資頁、新聞）的 snippet 資訊密度高，單層直餵保留了最完整的譜系細節（江日溝 1739、四大房、24 代），還抓到極新的時事（半月池 2025/11/15 落成）。
- **廣度：三邊各有獨家。** A 深（朱一貴軍師、1178 加冕）；B 人味（牛車市集、客家身世）；C 譜系與冷知識（會川公、《總舖師》、畢卡索 57 素描、1944 解放）。**若要「多個故事」極大化，A+C 聯集的 CP 值最高。**
- **基礎設施與成本：A 壓倒性簡單。** A＝一次 Gemini 呼叫、零基礎設施。C＝一個 SearXNG 容器＋一次 Gemini 呼叫（無 Perplexica 的 LLM 層）。B＝整套 Docker + 兩層 LLM，最重。
- **可信度：A > C > B。** A 單層 grounding 漂移最少；C 原文直餵、不改寫；B 的摘要層有實證的漂移案例，需查核。

---

## 7. 結論與建議

**就「給前端顯示多個豐富故事」這個用途，主推 A：Gemini + 原生 Google Search grounding；若想再擴大角度數，可低成本加上 C 當補充。B（Perplexica）不建議。**

| 面向 | A：Gemini+Search | B：Perplexica | C：SearXNG 直接 |
|---|---|---|---|
| 豐富地點表現 | ✅ 8 角度/32 實體 | ✅ 8/26 | ⚠️ 4/14（snippet 太淺）|
| 冷門地點表現 | ✅ 8 角度/33 實體 | ✅ 7/28 | ✅ 7/30（譜系最細）|
| 細節保真 | ✅ 單層 grounding | ⚠️ 摘要層洗細節＋名稱漂移實證 | ✅ 原文直餵 |
| 時事新鮮度 | ✅ 好 | ✅ 很好 | ✅ 很好 |
| 基礎設施 | ✅ 無 | ❌ Docker 全套＋一堆相容性坑 | ◐ 一個 SearXNG 容器 |
| 每次成本 | ✅ 1 次 LLM | ❌ 2 層 LLM | ✅ 1 次 LLM |
| Provider 綁定 | 綁 Google | 可換 | 可換（搜尋端）|

- **單選**：A。最穩、最豐、最簡單。
- **進階**：A + C 聯集去重——兩個地點的實測中，C 都貢獻了 A 沒有的獨家角度（會川公譜系、《總舖師》、畢卡索 57 素描、1944 解放），而 C 的成本只是一個 SearXNG 容器＋一次 Gemini 呼叫。
- **B 的定位**：兩層 LLM 成本最高、有實證的名稱漂移，基礎設施也最重；其「人味角度」優勢不足以抵掉這些缺點。

### 一次呼叫產多個完整故事（已驗證，2026-06-10）

針對「前端只打一次 API 拿多個故事」的需求，補測兩件事：

1. **grounding + `response_schema` 確認不能同呼叫**：API 回
   `400 "Tool use with a response mime type: 'application/json' is unsupported"`。
2. **一次 grounded 呼叫＋prompt 要求 JSON，可直接產 3 個完整故事**：
   以鹿陶洋江家聚落實測（13 個 grounding 來源），一次拿到 3 個角度互異的完整故事
   （拓墾／建築傳承／宋江陣），每篇 3 段、每段 200–300 字、漢字數字與 pull_quote
   全符合現有 narration 規格，JSON 一次 parse 成功；年代事實（康熙六十年、乾隆五年、
   民國八十五年）與先前研究相互印證。

建議後端設計：`前端 1 次 API → 後端 1 次 grounded Gemini（prompt 要求 N 篇 JSON）→
parse 驗證 → 失敗才用一次「無工具 + response_schema」整形補救`。正常路徑 1 次 LLM
完成 N 篇；注意單次延遲較長（搜尋＋9 段文字約 1 分鐘）。

### 後續可做
- 若加 C，正式環境需自架/託管一個 SearXNG（注意上游引擎被擋的限流問題，本測試中 Google/Startpage 引擎在 Docker IP 下常 403/CAPTCHA，靠其餘引擎仍可用）。
- 網搜素材（尤其 B/C 的時事）進故事前的**事實查核策略**（例如要求兩個來源相互印證才可進 FACT BOUNDARY）。

---

## 8. 附錄：這次 spike 踩到並已解決的坑（供日後參考）

1. **主機 port 3000/3001 被占用** — `lorescape-screenshots-editor` 的 `next dev` 搶走，導致 Perplexica 一直回 500。
2. **Next standalone `HOSTNAME` 綁錯** — Docker 自動把 `HOSTNAME` 設成容器 ID，Next 綁到該 hostname 而非 `0.0.0.0`，port-forward 連不到。已在 `docker-compose.yml` 釘 `HOSTNAME=0.0.0.0`。
3. **Vane(Perplexica) + freellmapi 的 `generateObject` 不相容** — 走 OpenAI 相容端點時結構化輸出解析必崩（llama 多逗號、推理模型吐 `<think>`），換什麼模型都一樣。
4. **原生 Groq 也不相容** — `llama-3.3-70b-versatile` 不支援 `json_schema`；`llama-4-scout` 的 tool-call schema 驗證失敗。
5. **只有原生 Gemini 連線可驅動 Perplexica**（generateObject + tool call 全過）。
6. **免費 Gemini 有每分鐘/每日配額** — 密集測試會打到 429/503；正式環境用有額度的 key 即可。
