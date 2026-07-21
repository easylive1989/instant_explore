# 每日景點故事 Reel — 選點 Calendar（2026/07/06 – 08/02）

**目的：** 取代目前 `daily_story_places` 的字母序 FIFO 選點，改為依 IG 數據規劃的主題排程。
**依據（截至 7/4 的 ig_posts 數據）：**
- 日本題材觸及最高：奈良 Reel 469（平均觀看 10.5 秒）、嚴島神社 184
- 冷門歐洲修道院/教堂類觸及僅 1–5
- 結論：觀眾（台灣為主）對「去過或想去的地方」反應最強

**7/6 期初驗證（用截至 7/5 的 ig_posts，本期不重排配比）：**
- 日韓 3 樣本 平均 reach 256 / 觀看 6.3s；冷門深度 4 樣本 reach 96 / 3.3s；
  世界名勝、歐洲、華語圈、東南亞仍樣本不足。
- 日韓仍壓倒性最強（reach 為冷門類 2.6 倍），本期每週 2 檔日韓配比維持不變。
- 觀察：新採「疑問句 hook」開頭的 Reel（嚴島、紹修、康沃爾礦業、百年廳）
  reach 普遍偏高，疑似 hook 格式本身也在拉觸及 —— 8/3 檢核時應把
  「辨識度 vs 地緣」的假設，一併對照「hook 格式 vs 內容題材」再判讀。

**7/21 期中觀察（本期 17 支 Reel，截至 7/20 的 ig_posts；配比不動）：**

| 類型 | n | 中位 reach | 平均 reach |
|---|---|---|---|
| 歐洲經典 | 2 | 1432 | 1432 |
| 華語圈 | 2 | 551 | 551 |
| 日韓 | 5 | 343 | 406 |
| 世界名勝 | 5 | 214 | 428 |
| 東南亞 | 2 | 182 | 182 |
| 冷門深度 | 1 | 168 | 168 |

- **配比維持不動。** 歐洲經典的 1432 完全來自布拉格天文鐘一支（reach 2349，
  次高的佛羅倫斯只有 515）。n=2 且被單一離群值主導，此時改配比等於追逐雜訊。
- **期初「疑問句 hook 拉觸及」的假設不成立。** 疑問句 6 支中位 274、
  陳述反轉 11 支中位 239——差距在誤差內，平均值的差異全由布拉格造成。
- 「人物主詞 vs 地方主詞」的 hook 差異（中位 431 vs 233）同樣是布拉格效應：
  剔除該支後兩組中位為 239 vs 233，等於沒有差別。**目前沒有任何 hook 假設
  在統計上站得住腳。**
- 唯一穩健的觀察：reach 前四名（布拉格 2349 / 聖家堂 1031 / 蘇州 863 /
  白川鄉 714）的 hook 都具備「具體的人或家戶處境 + 明確衝突」，後段班則多為
  抽象或地理性描述。可當寫作方向，不可當數據結論。
- **Reels 命運在 48 小時內決定**：布拉格 48h→7d 只成長 2%（2733→2797）。
  因此 24h 略過率是唯一該盯的先行指標（布拉格 45.5% → 2797 views；
  金字塔 70.1% → 243 views）。
- 轉換率仍是最大問題：布拉格觸及 2349 只換到 16 次個人檔案瀏覽（0.7%），
  遠低於 1% 門檻。**瓶頸在帳號定位與 Reel 結尾 CTA，不在選點。**

**8/3 檢核時的方法修正：** 一律用**中位數**並標註離群值，n<5 的類型不下結論。

**用法：** 每天跑 lorescape-manual-daily-story 時，指定當日 `wikipedia_title_en`
（表中「DB 標題」欄，與 `daily_story_places.wikipedia_title_en` 完全一致）。

---

## 每週配比模板

| 週幾 | 類型 | 理由 |
|------|------|------|
| 一 | 世界級名勝 | 週初用高辨識度題材衝觸及 |
| 二 | 歐洲經典 | 自由行熱門城市，維持廣度 |
| 三 | 日本／韓國 | 驗證中的最強題材 |
| 四 | 華語圈熟悉（中港澳） | 文化親近感、低理解門檻 |
| 五 | 東南亞近程 | 台灣人短程旅遊圈 |
| 六 | 日本／韓國 | 週末流量高峰配最強題材 |
| 日 | 世界級名勝 | 週末收尾維持觸及 |

每週固定 2 檔日韓 + 2 檔世界名勝，其餘輪換 —— 4 週後可用 ig_posts
數據直接對比各類型平均觸及，驗證「地緣親近度決定觸及」假設。

---

## Week 1（7/6 – 7/12）

| 日期 | 景點 | DB 標題（wikipedia_title_en） | 類型 |
|------|------|------|------|
| 7/6 一 | 馬丘比丘 | Historic Sanctuary of Machu Picchu | 世界名勝 |
| 7/7 二 | 佛羅倫斯歷史中心 | Historic Centre of Florence | 歐洲經典 |
| 7/8 三 | 姬路城 | Himeji Castle | 日本 |
| 7/9 四 | 北京紫禁城 | Imperial Palaces of the Ming and Qing Dynasties in Beijing and Shenyang | 華語圈 |
| 7/10 五 | 龍坡邦 | Luang Prabang | 東南亞 |
| 7/11 六 | 富士山 | Fujisan, sacred place and source of artistic inspiration | 日本 |
| 7/12 日 | 佩特拉 | Petra | 世界名勝 |

## Week 2（7/13 – 7/19）

| 日期 | 景點 | DB 標題（wikipedia_title_en） | 類型 |
|------|------|------|------|
| 7/13 一 | 泰姬瑪哈陵 | Taj Mahal | 世界名勝 |
| 7/14 二 | 布拉格舊城 | Old Town (Prague) | 歐洲經典 |
| 7/15 三 | 白川鄉合掌村 | Historic Villages of Shirakawa-gō and Gokayama | 日本 |
| 7/16 四 | 蘇州古典園林 | Classical Gardens of Suzhou | 華語圈 |
| 7/17 五 | 素可泰古城 | Historic Town of Sukhothai and Associated Historic Towns | 東南亞 |
| 7/18 六 | 慶州歷史區 | Gyeongju Historic Areas | 韓國 |
| 7/19 日 | 聖家堂 | Sagrada Família | 世界名勝 |

## Week 3（7/20 – 7/26）

| 日期 | 景點 | DB 標題（wikipedia_title_en） | 類型 |
|------|------|------|------|
| 7/20 一 | 吉薩金字塔群 | Memphis and its Necropolis – the Pyramid Fields from Giza to Dahshur | 世界名勝 |
| 7/21 二 | 薩爾斯堡歷史中心 | Historic Centre of the City of Salzburg | 歐洲經典 |
| 7/22 三 | 琉球王國城跡（沖繩） | Gusuku Sites and Related Properties of the Kingdom of Ryukyu | 日本 |
| 7/23 四 | 福建土樓 | Fujian tulou | 華語圈 |
| 7/24 五 | 獅子岩 | Sigiriya | 東南亞 |
| 7/25 六 | 京都 | Kyoto Prefecture | 日本 |
| 7/26 日 | 凡爾賽宮 | Palace of Versailles | 世界名勝 |

## Week 4（7/27 – 8/2）

| 日期 | 景點 | DB 標題（wikipedia_title_en） | 類型 |
|------|------|------|------|
| 7/27 一 | 伊斯坦堡歷史區 | Historic Areas of Istanbul | 世界名勝 |
| 7/28 二 | 阿瑪菲海岸 | Amalfi Coast | 歐洲經典 |
| 7/29 三 | 平泉 | Historic Monuments and Sites of Hiraizumi | 日本 |
| 7/30 四 | 澳門歷史城區 | Historic Centre of Macau | 華語圈 |
| 7/31 五 | 婆羅浮屠 | Borobudur Temple Compounds | 東南亞 |
| 8/1 六 | 百濟歷史區 | Baekje Historic Areas | 韓國 |
| 8/2 日 | 巨石陣 | Stonehenge, Avebury and Associated Sites | 世界名勝 |

---

## 備援池（當日素材不足時替換，同類型互換）

- 日韓：Namhansanseong（南漢山城）、Iwami Ginzan Silver Mine（石見銀山）、
  Jōmon Prehistoric Sites in Northern Japan
- 世界名勝：Bagan（蒲甘）、Hampi、Kathmandu Valley
- 華語圈：Grand Canal (China)、Beijing Central Axis
- 歐洲：Bruges City Hall、Gardens of Versailles（與凡爾賽宮擇一）
- 東南亞：Singapore Botanic Gardens

## 月底檢核（8/3）

1. 用 `ig_posts` 分頁算各類型平均觸及與平均觀看秒數
2. 若「日韓 > 其他」成立 → 8 月提高日韓比重至每週 3 檔
3. 若「世界名勝」同樣有效 → 假設修正為「辨識度」而非「地緣」，
   選點改以 Wikipedia 中文版流量／知名度排序
4. 觸及 → 追蹤轉換率（profile_views / reach）若仍 < 1%，
   問題在帳號定位而非選點，優先改 bio 與 Reel 結尾 CTA
