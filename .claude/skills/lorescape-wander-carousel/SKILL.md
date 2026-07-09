---
name: lorescape-wander-carousel
description: Use when the user wants to publish a wander-style (dark
  photo-overlay, person-narrative) IG carousel for a Lorescape daily story —
  e.g. 「今天用 wander 風格發」,「做 wander 圖組」,「茜茜公主那種風格」.
  Covers writing the 7–9 slide beats, rendering, local preview, and sending
  for Discord review. Photos default to the day's
  marketing/outputs/daily_image/<date>/ pool; a user-provided folder can
  override. This is the FIXED carousel style for daily stories (since
  2026-07-06) — lorescape-manual-daily-story Step 8b runs this flow after
  every publish.
---

# Wander 風格 IG Carousel

發布日的 carousel 改用 wander 風格（第三人稱人物敘事 + 暗色壓字）。
送審後由發布 bot 在 Discord 貼按鈕，核准／排程／立即發布皆由操作者決定；
當天預設風格 carousel 會被跳過。
設計 spec：docs/superpowers/specs/2026-07-06-wander-carousel-style-design.md

## 流程

1. **輸入**：日期（預設今天）；照片預設用當天
   `marketing/outputs/daily_image/<date>/` 的 genuine place photos
   （manual daily story Step 5 產出；不足 5 張或使用者另有指定時才要
   資料夾路徑）；故事角度（哪個人物/事件）不明顯時問使用者。
2. **寫文案** `marketing/outputs/daily_carousel/<date>/slides.json` +
   `caption.txt`，**給使用者審稿，改到同意為止**（見下方文案規則）。
3. **渲染**：
   `cd backend && uv run python -m lorescape_backend.social.wander.renderer \
      ../marketing/outputs/daily_carousel/<date> <photos_dir>`
   請使用者打開 `slide_*.jpg` 目視確認；要調整就改 slides.json 重渲染。
4. **送審**：
   `cd scripts && uv run python -m send_carousel_for_review <date>`
   這一步只上傳素材、建立 pending 的 `social_posts` row；發布 bot 約
   一分鐘內會在 Discord 貼出帶四顆按鈕的審核訊息（✅ 核准 / 🕘 排程 /
   🚀 立即發布 / ❌ 拒絕），提醒使用者去操作。
5. ✅ 核准後若沒排程時間不會自動發：用 🕘 排程指定 Asia/Taipei 時間，
   或直接按 🚀 立即發布馬上發。❌ 拒絕或完全不理 = 當天 carousel 不發
   （不會 fallback 到預設風格）。

## 文案規則（slides.json）

- 7–9 頁；每頁 2–4 短句（`lines`），句尾逗號製造翻頁懸念；
  `lines` 中空字串 `""` = 裝飾分隔線。
- 節拍順序：cover 鉤子（含一次反轉）→ beat 起伏 → beat 衝突 →
  beat 彩蛋（「最令人意外的是…」）→ beat 轉折 →
  bright 主題頁（呼應旅行/自由，配最亮的照片）→ ending
  （結局 + 收在普世的讀者投射；品牌區塊模板自帶）。
- 人稱：全篇第三人稱（「她/他/它」），**任何頁都不用「我」**
  （彩蛋頁用「最令人意外的是⋯」「很少人知道，」這類寫法）。
- `highlights` 每頁最多 2 個金色強調詞；一個主題詞（如「自由」）
  貫穿全篇。
- 照片配頁跟情緒走：悲劇配最暗的照片（`overlay: "darker"`）、
  bright 頁配唯一明亮照（`overlay: "light"`）。
- **選圖只用 Unsplash 來源的檔案**：以當天資料夾的
  `unsplash_results.json` 裡列出的檔名為準。資料夾裡可能混有
  Wikipedia 封面等非 Unsplash 檔（reel 參考用），這些不能進 slides
  ——壓字渲染屬改作，CC BY-SA 圖改作需以相同條款釋出，別讓它
  意外發生。若使用者指定要用 CC 授權圖，caption 必須帶完整
  BY+SA 行（規則同 lorescape-manual-daily-story 的 5d）。
- layout 欄位：`cover`（需 tag_zh/tag_en/title/title_en；tag_zh 用
  「國家・城市/省」地點格式，**不要寫「XX 旅行」**）、
  `beat`（可選 title、text_position: left|right|top）、`bright`、`ending`。
- caption.txt：既有貼文 caption 慣例（故事鉤子 + hashtags + @love.lorescape），
  **並附照片 credit 行**：列出 slides 實際用到的攝影師，格式
  `📷 Photos: <名字, 名字, …> / Unsplash`（名字取自
  `unsplash_results.json`；Unsplash License 不強制署名，但固定附上）。
  若有 CC 授權圖則改用該圖的完整 BY+SA 行。

## slides.json 範例（節錄）

    {
      "slides": [
        {"layout": "cover", "photo": "dress.jpg",
         "tag_zh": "奧地利・維也納", "tag_en": "Austria",
         "title": "茜茜公主", "title_en": "Empress Sisi",
         "lines": ["原本安排訂婚的，", "其實是她的姊姊。", "",
                    "沒想到，", "皇帝卻對西西公主一見鍾情。"]},
        {"layout": "beat", "photo": "gym.jpg", "text_position": "left",
         "title": "最令人意外的是⋯", "highlights": ["運動器材"],
         "lines": ["她的房間裡，", "竟然設有運動器材。"]},
        {"layout": "bright", "photo": "palace.jpg",
         "lines": ["比起留在皇宮，", "她更喜歡旅行。"]},
        {"layout": "ending", "photo": "salon.jpg",
         "lines": ["人生難免有許多身不由己。", "",
                    "旅行，不只是走進一個地方。", "也是透過一段故事，",
                    "遇見不同的人生。"]}
      ]
    }

## 每月歸檔

月初跑 `cd scripts && uv run python -m archive_ig_cards`（上個月），
完成後提醒使用者把 `marketing/outputs/ig_cards_archive/<YYYY-MM>/`
備份到 Google Drive。
