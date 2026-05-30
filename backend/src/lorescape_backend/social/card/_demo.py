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

# A 1×1 transparent PNG so layout tests need no network (the photo is a
# decorative background; its bytes never affect text layout).
_BLANK_PNG = (
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0"
    "lEQVR42mNk+M8AAAMBAQDJ/pLvAAAAAElFTkSuQmCC"
)

# Long-content demo (three full three-line paragraphs + a long pull-quote)
# that overflows the fixed text-plate slot unless the renderer's `--fit`
# auto-shrink kicks in. Mirrors the real 巴姆古城 card that surfaced the bug.
LONG_DEMO = CardContent(
    title_ch="兩千年城堡的震慟",
    title_ch_sub="伊朗巴姆古城的歷史與重生",
    location_ch="巴姆古城．伊朗",
    location_en="BAM, IRAN · CENTRAL DISTRICT",
    location_coord="29.1061°N · 58.3569°E",
    anno_roman="MMIII",
    city_ch="巴",
    city_en="BAM",
    paragraphs_ch=(
        "姆古城矗立於伊朗克爾曼省，擁有約兩千年的悠久歷史。現代的巴姆市環繞著這座宏偉的"
        "古老城堡而建，並作為巴姆縣與中心區的首府。這座城堡不僅是備受矚目的世界遺產，更"
        "是吸引全球遊客前來探訪的旅遊勝地。",
        "官方統計顯示，在二〇〇三年那場破壞性的地震發生之前，這座城市大約有四萬三千名居"
        "民。人們在古老城堡的守護下生活，然而一場突如其來的強烈地震，卻在瞬間重創了這座"
        "歷史悠久的古城，帶來了無法抹滅的傷痛。",
        "世界遺產巴姆城堡雖然在二〇〇三年的地震中受損，但其殘存的遺跡依然矗立於克爾曼省。"
        "這座擁有兩千年歷史的古老城堡，至今仍是巴姆不朽的文化象徵，持續向世人展示著歷史"
        "的韌性與波斯文明的獨特魅力。",
    ),
    pull_quote_ch="「現代城市環繞著這座擁有兩千年歷史的古老城堡。」",
    pull_quote_attrib_ch="——《維基百科》",
    photo_url=_BLANK_PNG,
)
