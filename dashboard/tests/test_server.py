"""serve 模式輔助函式測試：md 檔 mtime 偵測。"""
from lorescape_dashboard.server import section_mtimes


def test_回傳存在檔案的mtime(tmp_path):
    f = tmp_path / "BACKLOG.md"
    f.write_text("x")
    result = section_mtimes({"backlog": f})
    assert result["backlog"] == f.stat().st_mtime


def test_缺檔給_none(tmp_path):
    result = section_mtimes({"schedule": tmp_path / "missing.md"})
    assert result["schedule"] is None


def test_多個區塊各自對應(tmp_path):
    a = tmp_path / "a.md"
    a.write_text("a")
    missing = tmp_path / "b.md"
    result = section_mtimes({"backlog": a, "reels": missing})
    assert result["backlog"] == a.stat().st_mtime
    assert result["reels"] is None
