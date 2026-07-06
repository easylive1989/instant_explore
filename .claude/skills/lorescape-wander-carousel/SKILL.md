---
name: lorescape-wander-carousel
description: Use when the user wants to publish a wander-style (dark
  photo-overlay, person-narrative) IG carousel for a Lorescape daily story —
  e.g. 「今天用 wander 風格發」,「做 wander 圖組」,「茜茜公主那種風格」.
  Covers writing the 7–9 slide beats, rendering, local preview, and sending
  for Discord review. Requires a user-provided photos folder.
---

# Wander 風格 IG Carousel

發布日的 carousel 改用 wander 風格（第三人稱人物敘事 + 暗色壓字）。
送審後 21:00 自動發布；當天預設風格 carousel 會被跳過。
設計 spec：docs/superpowers/specs/2026-07-06-wander-carousel-style-design.md

## 流程

1. **向使用者要**：日期（預設今天）、照片資料夾路徑（5–9 張同景點實拍）、
   故事角度（哪個人物/事件）。
2. **寫文案** `marketing/outputs/daily_carousel/<date>/slides.json` +
   `caption.txt`，**給使用者審稿，改到同意為止**（見下方文案規則）。
3. **渲染**：
   `cd backend && uv run python -m lorescape_backend.social.wander.renderer \
      ../marketing/outputs/daily_carousel/<date> <photos_dir>`
   請使用者打開 `slide_*.jpg` 目視確認；要調整就改 slides.json 重渲染。
4. **送審**：
   `cd scripts && uv run python -m send_carousel_for_review <date>`
   提醒使用者到 Discord 按 ✅（21:00 Asia/Taipei 前）。
5. ❌ 或不按 = 當天 carousel 不發（不會 fallback 到預設風格）。

## 文案規則（slides.json）

- 7–9 頁；每頁 2–4 短句（`lines`），句尾逗號製造翻頁懸念；
  `lines` 中空字串 `""` = 裝飾分隔線。
- 節拍順序：cover 鉤子（含一次反轉）→ beat 起伏 → beat 衝突 →
  beat 彩蛋（第一人稱「最讓我意外的是…」）→ beat 轉折 →
  bright 主題頁（呼應旅行/自由，配最亮的照片）→ ending
  （結局 + 「她」→「我們」的讀者投射；品牌區塊模板自帶）。
- 人稱：以「她/他」為主；「我」只出現在彩蛋頁與結局詮釋。
- `highlights` 每頁最多 2 個金色強調詞；一個主題詞（如「自由」）
  貫穿全篇。
- 照片配頁跟情緒走：悲劇配最暗的照片（`overlay: "darker"`）、
  bright 頁配唯一明亮照（`overlay: "light"`）。
- layout 欄位：`cover`（需 tag_zh/tag_en/title/title_en；tag_zh 用
  「國家・城市/省」地點格式，**不要寫「XX 旅行」**）、
  `beat`（可選 title、text_position: left|right|top）、`bright`、`ending`。
- caption.txt：既有貼文 caption 慣例（故事鉤子 + hashtags + @love.lorescape）。

## slides.json 範例（節錄）

    {
      "slides": [
        {"layout": "cover", "photo": "dress.jpg",
         "tag_zh": "奧地利・維也納", "tag_en": "Austria",
         "title": "茜茜公主", "title_en": "Empress Sisi",
         "lines": ["原本安排訂婚的，", "其實是她的姊姊。", "",
                    "沒想到，", "皇帝卻對西西公主一見鍾情。"]},
        {"layout": "beat", "photo": "gym.jpg", "text_position": "left",
         "title": "最讓我意外的是⋯", "highlights": ["運動器材"],
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
