"""cli orchestrator 的收集/快取/錯誤隔離測試。"""
import json

from lorescape_dashboard.cli import gather


def test_成功收集並寫入快取(tmp_path):
    registry = {"backlog": lambda: {"features": []}}
    data = gather(registry, refresh={"backlog"}, data_dir=tmp_path)
    assert data["backlog"] == {"features": []}
    assert data["errors"] == {}
    cached = json.loads((tmp_path / "backlog.json").read_text())
    assert cached["data"] == {"features": []}
    assert "collected_at" in cached


def test_不刷新時用快取(tmp_path):
    (tmp_path / "tests.json").write_text(
        json.dumps({"collected_at": "2026-07-10 09:00", "data": {"suites": []}})
    )
    boom = lambda: (_ for _ in ()).throw(RuntimeError("不該被呼叫"))
    data = gather({"tests": boom}, refresh=set(), data_dir=tmp_path)
    assert data["tests"] == {"suites": []}
    assert "tests" not in data["errors"]


def test_收集失敗時退回快取並記錯誤(tmp_path):
    (tmp_path / "metrics.json").write_text(
        json.dumps({"collected_at": "2026-07-10 09:00", "data": {"tabs": []}})
    )

    def failing():
        raise RuntimeError("API down")

    data = gather({"metrics": failing}, refresh={"metrics"}, data_dir=tmp_path)
    assert data["metrics"] == {"tabs": []}  # 退回快取
    assert "API down" in data["errors"]["metrics"]
    assert "2026-07-10" in data["errors"]["metrics"]  # 註明快取時間


def test_失敗且無快取時_data_為_none(tmp_path):
    def failing():
        raise RuntimeError("no creds")

    data = gather({"deploys": failing}, refresh={"deploys"}, data_dir=tmp_path)
    assert data["deploys"] is None
    assert "no creds" in data["errors"]["deploys"]
