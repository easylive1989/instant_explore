"""deploys collector 測試（gh / git 以注入的 fake 取代）。"""
from lorescape_dashboard.collectors.deploys import collect


_RUNS = {
    "deploy-backend.yml": {
        "head_sha": "abc1234def",
        "run_started_at": "2026-07-09T12:00:00Z",
        "html_url": "https://github.com/x/y/actions/runs/1",
    },
    "deploy-publisher.yml": {
        "head_sha": "eee5678fff",
        "run_started_at": "2026-07-10T08:00:00Z",
        "html_url": "https://github.com/x/y/actions/runs/2",
    },
    # landing 從未成功跑過；app 只有改名前的 deploy.yml 有歷史
    "deploy.yml": {
        "head_sha": "0ld5678fff",
        "run_started_at": "2026-07-08T14:00:00Z",
        "html_url": "https://github.com/x/y/actions/runs/3",
    },
}


def _fake_gh(workflow_file: str) -> dict | None:
    return _RUNS.get(workflow_file)


def _fake_behind(sha: str) -> int:
    return {"abc1234def": 3}.get(sha, 0)


def test_彙整各服務最後部署與落後_commits():
    result = collect(gh_last_success=_fake_gh, behind_count=_fake_behind)
    services = {s["service"]: s for s in result["services"]}

    backend = services["backend"]
    assert backend["commit"] == "abc1234"  # 短 sha
    assert backend["behind_master"] == 3
    assert backend["deployed_at"] == "2026-07-09T12:00:00Z"
    assert backend["run_url"].endswith("/runs/1")

    assert services["landing"]["deployed_at"] is None
    assert services["publisher"]["behind_master"] == 0
    assert set(services) == {"backend", "publisher", "landing", "app（商店上架）"}


def test_改名前的舊_workflow_歷史作為_fallback():
    result = collect(gh_last_success=_fake_gh, behind_count=_fake_behind)
    app = next(s for s in result["services"] if s["service"] == "app（商店上架）")
    assert app["deployed_at"] == "2026-07-08T14:00:00Z"
    assert app["commit"] == "0ld5678"
