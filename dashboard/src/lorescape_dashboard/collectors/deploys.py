"""部署狀態：各 deploy workflow 最近一次成功 run 與落後 master 的 commits 數。"""
from __future__ import annotations

import json
import subprocess
from collections.abc import Callable

from ..config import REPO_ROOT

_WORKFLOWS = {
    "backend": "deploy-backend.yml",
    "publisher": "deploy-publisher.yml",
    "landing": "deploy-landing.yml",
    "app": "deploy-app.yml",
}


def _gh_last_success(workflow_file: str) -> dict | None:
    """該 workflow 最近一次成功 run（無則 None）。"""
    proc = subprocess.run(
        [
            "gh", "api",
            f"repos/{{owner}}/{{repo}}/actions/workflows/{workflow_file}/runs"
            "?status=success&per_page=1",
        ],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    runs = json.loads(proc.stdout).get("workflow_runs", [])
    return runs[0] if runs else None


def _behind_count(sha: str) -> int:
    """部署 commit 落後 origin/master 幾個 commits。"""
    subprocess.run(
        ["git", "fetch", "origin", "master", "--quiet"],
        cwd=REPO_ROOT,
        capture_output=True,
    )
    proc = subprocess.run(
        ["git", "rev-list", "--count", f"{sha}..origin/master"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return int(proc.stdout.strip())


def collect(
    gh_last_success: Callable[[str], dict | None] = _gh_last_success,
    behind_count: Callable[[str], int] = _behind_count,
) -> dict:
    services = []
    for service, workflow_file in _WORKFLOWS.items():
        run = gh_last_success(workflow_file)
        if run is None:
            services.append(
                {
                    "service": service,
                    "deployed_at": None,
                    "commit": None,
                    "behind_master": None,
                    "run_url": None,
                }
            )
            continue
        sha = run["head_sha"]
        services.append(
            {
                "service": service,
                "deployed_at": run.get("run_started_at"),
                "commit": sha[:7],
                "behind_master": behind_count(sha),
                "run_url": run.get("html_url"),
            }
        )
    return {"services": services}
