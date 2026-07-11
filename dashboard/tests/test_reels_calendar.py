"""reels_calendar collector 的解析測試。"""
from lorescape_dashboard.collectors.reels_calendar import parse_calendar

SAMPLE = """\
# 每日景點故事 Reel — 選點 Calendar（2026/12/29 – 01/04）

**目的：** 測試用。

## 每週配比模板

| 週幾 | 類型 | 理由 |
|------|------|------|
| 一 | 世界級名勝 | 週初衝觸及 |

## Week 1（12/29 – 1/4）

| 日期 | 景點 | DB 標題（wikipedia_title_en） | 類型 |
|------|------|------|------|
| 12/29 一 | 馬丘比丘 | Historic Sanctuary of Machu Picchu | 世界名勝 |
| 12/31 三 | 姬路城 | Himeji Castle | 日本 |
| 1/2 五 | 龍坡邦 | Luang Prabang | 東南亞 |

## 備援池

- 日韓：Namhansanseong（南漢山城）
"""


class TestParseCalendar:
    def test_解析排程列與跨年年份(self):
        result = parse_calendar(SAMPLE)
        entries = result["entries"]
        assert [e["date"] for e in entries] == [
            "2026-12-29", "2026-12-31", "2027-01-02",  # 跨年自動 +1
        ]
        assert entries[0]["place"] == "馬丘比丘"
        assert entries[0]["db_title"] == "Historic Sanctuary of Machu Picchu"
        assert entries[0]["category"] == "世界名勝"

    def test_不誤抓配比模板表(self):
        result = parse_calendar(SAMPLE)
        assert all(e["place"] != "世界級名勝" for e in result["entries"])
        assert len(result["entries"]) == 3

    def test_range_與標題(self):
        assert parse_calendar(SAMPLE)["range"] == "2026/12/29 – 01/04"
