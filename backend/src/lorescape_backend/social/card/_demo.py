"""Eiffel demo CardContent for development + manual visual checks."""
from .content import CardContent

EIFFEL_DEMO = CardContent(
    title_ch="討厭鐵塔的文學大師",
    title_ch_sub="莫泊桑的「專屬午餐位」",
    location_ch="艾菲爾鐵塔．巴黎",
    location_en="TOUR EIFFEL · PARIS",
    location_coord="48.8584°N · 2.2945°E",
    anno_roman="MDCCCLXXXIX",
    city_ch="巴",
    city_en="PARIS",
    paragraphs_ch=(
        "西元一八八九年艾菲爾鐵塔甫落成，巴黎的文化圈一致憤怒，"
        "視它為破壞天際線的鋼鐵怪物。其中最痛恨它的，是法國短篇"
        "小說大師——莫泊桑。",
        "莫泊桑曾與多位藝術家聯名抗議，稱鐵塔為「孤獨而荒謬的瞭"
        "望塔」。然而巴黎市民很快發現一個矛盾的景象：每日中午，"
        "莫泊桑準時出現在鐵塔二樓的餐廳。",
        "有人忍不住問他：「您不是最討厭這座塔嗎？」他一邊切著牛"
        "排，沒好氣地回答──",
    ),
    pull_quote_ch="「因為在這裡吃飯，是全巴黎唯一一個我『看不見』艾菲爾鐵塔的地方。」",
    pull_quote_attrib_ch="—— 莫泊桑，一八八九",
    photo_url="https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=1400&q=80&auto=format&fit=crop",
)
