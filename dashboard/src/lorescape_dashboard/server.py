"""--serve 模式：本地 server，GET / 從快取渲染、POST /api/section/<key> 重收集。"""
from __future__ import annotations

import re
from collections.abc import Callable
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from . import render

_SECTION_PATH_RE = re.compile(r"^/api/section/([a-z_]+)$")


def _now() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M")


class _Handler(BaseHTTPRequestHandler):
    """所有狀態都在 out/data 快取；每個請求即時從快取（或重收集後）渲染。"""

    registry: dict[str, Callable[[], dict]]
    gather: Callable
    data_dir: Path

    def _send(self, status: int, body: str, content_type: str = "text/html") -> None:
        payload = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", f"{content_type}; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(payload)

    def _data(self, refresh: set[str]) -> dict:
        data = self.gather(self.registry, refresh=refresh, data_dir=self.data_dir)
        data["generated_at"] = _now()
        return data

    def do_GET(self) -> None:  # noqa: N802（http.server 介面）
        if self.path.split("#")[0].split("?")[0] != "/":
            self._send(404, "not found", "text/plain")
            return
        self._send(200, render.build_html(self._data(refresh=set())))

    def do_POST(self) -> None:  # noqa: N802
        m = _SECTION_PATH_RE.match(self.path)
        if not m or m.group(1) not in self.registry:
            self._send(404, "unknown section", "text/plain")
            return
        key = m.group(1)
        data = self._data(refresh={key})
        self._send(200, render.section_body(key, data))

    def log_message(self, format: str, *args) -> None:
        print(f"  [{_now()}] {self.command} {self.path}")


def serve(
    registry: dict[str, Callable[[], dict]],
    gather: Callable,
    data_dir: Path,
    port: int,
) -> None:
    handler = type(
        "Handler", (_Handler,),
        # gather 是普通函式，需 staticmethod 避免被綁定成 method（self 會佔掉第一個參數）
        {"registry": registry, "gather": staticmethod(gather), "data_dir": data_dir},
    )
    server = ThreadingHTTPServer(("127.0.0.1", port), handler)
    print(f"面板 server：http://localhost:{port}（Ctrl+C 停止）")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n已停止")
