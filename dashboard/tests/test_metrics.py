"""metrics collector 的整形測試。"""
from datetime import date

from lorescape_dashboard.collectors.metrics import shape_tab

VALUES = [
    ["date", "clicks", "impressions", "note"],
    ["2026-06-01", "1", "10", "old"],
    ["2026-07-04", "2", "20", ""],
    ["2026-07-09", "4", "38", ""],
    ["2026-07-10", "5", "50", "x"],
]

TODAY = date(2026, 7, 11)


class TestShapeTab:
    def test_最新值與一週前差異(self):
        tab = shape_tab("gsc", VALUES, today=TODAY)
        assert tab["name"] == "gsc"
        assert tab["latest_date"] == "2026-07-10"
        clicks = tab["stats"]["clicks"]
        assert clicks["latest"] == 5.0
        # 一週前 = 2026-07-03，取當日或之前最近一列 → 2026-06-01
        assert clicks["week_ago"] == 1.0
        assert clicks["delta"] == 4.0

    def test_非數值欄位不進統計(self):
        tab = shape_tab("gsc", VALUES, today=TODAY)
        assert "note" not in tab["stats"]

    def test_近七列供表格顯示_新到舊(self):
        tab = shape_tab("gsc", VALUES, today=TODAY, days=60)
        assert tab["headers"] == ["date", "clicks", "impressions", "note"]
        assert [r[0] for r in tab["recent_rows"]] == [
            "2026-07-10", "2026-07-09", "2026-07-04", "2026-06-01",
        ]

    def test_預設三十天窗排除更舊的列(self):
        tab = shape_tab("gsc", VALUES, today=TODAY)
        assert [r[0] for r in tab["recent_rows"]] == [
            "2026-07-10", "2026-07-09", "2026-07-04",
        ]

    def test_只留近三十天的資料算統計(self):
        # 6/1 在 30 天外 → week_ago 找不到 30 天內更早的列時仍可用界外列補
        tab = shape_tab("gsc", VALUES, today=TODAY, days=7)
        assert [r[0] for r in tab["recent_rows"]] == ["2026-07-10", "2026-07-09", "2026-07-04"]

    def test_空分頁回_none(self):
        assert shape_tab("gsc", [], today=TODAY) is None
        assert shape_tab("gsc", [["date", "clicks"]], today=TODAY) is None

    def test_無效值容忍(self):
        values = [["date", "v"], ["2026-07-10", ""], ["2026-07-09", "3"]]
        tab = shape_tab("x", values, today=TODAY)
        assert tab["stats"]["v"]["latest"] is None
