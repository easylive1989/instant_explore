#!/usr/bin/env python3
"""把 OpenFreeMap 的 positron 樣式重新上色成 Lorescape 的 field journal 色票。

產出 `assets/map/lorescape_style.json`，由 `mapStyleProvider` 讀取（見
`lib/features/explore/providers.dart`）。色票來源＝`docs/design/project/app2/ls2.css`
的 `:root` 變數，與 `lib/app/config/lorescape_tokens.dart` 同源。

用法（只需 stdlib）：

    python3 tool/build_map_style.py

上游 positron 更新後重跑即可。若上游新增了未列在 `COLOUR_MAP` 的顏色，腳本會
**直接失敗**並列出來——寧可噴錯，也不要默默留下一塊冷灰色破壞整頁調性。

選型與授權義務見 `docs/adr/0005-map-tile-provider.md`。
"""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

SOURCE_STYLE_URL = "https://tiles.openfreemap.org/styles/positron"
OUTPUT_PATH = Path(__file__).resolve().parent.parent / "assets/map/lorescape_style.json"

# positron 的原色 → field journal 色票。
# 註解寫的是該顏色在地圖上的角色，方便日後調整時知道動到什麼。
COLOUR_MAP: dict[str, str] = {
    # --- 底與地表 ---
    "rgb(242,243,240)": "#F7F1E6",  # background / 棧橋：paper
    "rgb(194, 200, 202)": "#DFD3BD",  # 水體：暖砂色（設計稿 .leaflet-container 底色）
    "hsl(195,17%,78%)": "#D4C7AE",  # 河道線
    "rgb(230, 233, 229)": "#E6E8D5",  # 公園：cat-nature-bg
    "rgb(220,224,220)": "#E1E4CE",  # 林地
    "hsl(0,0%,98%)": "#FDFAF3",  # 冰川 / 冰棚：paper-raised
    "rgb(234, 234, 230)": "#F1E9DA",  # 住宅區
    # --- 建築 ---
    "rgb(234, 234, 229)": "#ECE3D3",  # 建築填色：paper-sunk
    "rgb(219, 219, 218)": "#E0D5C0",  # 建築外框
    # --- 道路 ---
    # 注意：對應表是「顏色 → 顏色」而非「角色 → 顏色」，所以同一個字面值在不同
    # 角色上只能給同一個結果。`#fff` 同時是道路內線與文字光暈；paper-raised 比
    # 背景亮一階，兩種角色都合用，故不另外拆開。
    "#fff": "#FDFAF3",  # 道路內線 / 文字光暈：paper-raised
    "rgba(255, 255, 255, 1)": "#FDFAF3",  # 機坪 / 跑道
    "rgb(213, 213, 213)": "#E4DAC8",  # 主要道路外框：line
    "hsl(0,0%,88%)": "#EBE1CF",  # 次要道路 / 滑行道
    "rgb(234,234,234)": "#F3EBDB",  # 隧道內線
    "rgb(234, 234, 234)": "#F3EBDB",  # 步道（上游同色不同寫法）
    "hsla(0,0%,85%,0.53)": "rgba(205,191,166,0.53)",  # 低 zoom 快速道路
    "hsla(0,0%,85%,0.69)": "rgba(205,191,166,0.69)",  # 低 zoom 主要道路
    "#dddddd": "#DED3BC",  # 鐵路
    "#fafafa": "#FBF6EC",  # 鐵路虛線
    # --- 界線 ---
    "hsl(0,0%,70%)": "#CDBFA6",  # 國界 / 行政界：line-strong
    # --- 文字 ---
    "#000": "#221C14",  # 城市 / 國家標籤：ink
    "#333": "#5E5341",  # 州 / 其他標籤：ink-2
    "#666": "#6E6250",  # 道路 / 機場標籤
    "hsl(0,0%,66%)": "#A2957F",  # 河道標籤
    "hsl(30,0%,62%)": "#918471",  # 步道標籤：ink-3
    "#495e91": "#8A7A5E",  # 水域名稱（原為藍色，改為暖褐以免跳色）
    # --- 文字外光暈 ---
    "rgba(255,255,255,0.7)": "rgba(247,241,230,0.75)",  # paper 半透明
    "#f8f4f0": "#F7F1E6",  # 步道標籤光暈
    "#ffffff": "#F7F1E6",  # 機場標籤光暈
}

_COLOUR_LITERAL = re.compile(r"^(#[0-9a-fA-F]{3,8}|rgb\(|rgba\(|hsl\(|hsla\()")


def _is_colour(value: str) -> bool:
    return bool(_COLOUR_LITERAL.match(value.strip()))


def recolour(node, unmapped: set[str]):
    """遞迴替換顏色字面值。

    走訪整棵樹而不是只看 `paint`，是因為顏色可能藏在 `["interpolate", ...]`
    這類運算式的葉節點裡（例如 highway_motorway_inner 就是）。
    """
    if isinstance(node, str):
        text = node.strip()
        if not _is_colour(text):
            return node
        if text in COLOUR_MAP:
            return COLOUR_MAP[text]
        unmapped.add(text)
        return node
    if isinstance(node, list):
        return [recolour(item, unmapped) for item in node]
    if isinstance(node, dict):
        return {key: recolour(value, unmapped) for key, value in node.items()}
    return node


def main() -> int:
    print(f"讀取上游樣式：{SOURCE_STYLE_URL}")
    # 用 curl 而非 urllib：macOS 上 python.org 版的 Python 沒有系統 CA bundle，
    # urllib 會直接 CERTIFICATE_VERIFY_FAILED。curl 兩邊都有，也不必多裝 certifi。
    result = subprocess.run(
        ["curl", "-fsSL", SOURCE_STYLE_URL],
        capture_output=True,
        text=True,
        timeout=30,
    )
    if result.returncode != 0:
        print(f"下載失敗（curl exit {result.returncode}）：{result.stderr}", file=sys.stderr)
        return 1
    style = json.loads(result.stdout)

    # ne2_shaded 是 Natural Earth 的 raster 圖層來源，positron 並未用到任何
    # 引用它的圖層；留著只會讓 vector_map_tiles 多解析一個沒用的 source。
    dropped = [
        name
        for name, source in style.get("sources", {}).items()
        if source.get("type") == "raster"
    ]
    for name in dropped:
        del style["sources"][name]
    style["layers"] = [
        layer for layer in style["layers"] if layer.get("source") not in dropped
    ]

    unmapped: set[str] = set()
    style["layers"] = recolour(style["layers"], unmapped)

    if unmapped:
        print("\n上游出現未對應的顏色，請補進 COLOUR_MAP 後重跑：", file=sys.stderr)
        for colour in sorted(unmapped):
            print(f"  {colour}", file=sys.stderr)
        return 1

    style["name"] = "Lorescape Field Journal"
    style["id"] = "lorescape-field-journal"

    # 內容雜湊當版本號。`vector_map_tiles` 的磁碟快取 key 只有
    # `{z}_{x}_{y}_{source}.pbf`、不含樣式身分，且預設 TTL 30 天——樣式改版後
    # 既有使用者會繼續吃到舊配色（2026-07-21 實測確認）。App 端以這個版本號
    # 隔離快取目錄，改樣式即自動換一份乾淨快取。
    digest = hashlib.sha256(
        json.dumps(style["layers"], sort_keys=True, ensure_ascii=False).encode()
    ).hexdigest()[:12]
    style["metadata"] = {"version": digest}

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(
        json.dumps(style, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"已寫出 {OUTPUT_PATH.relative_to(Path.cwd())}")
    print(f"  圖層 {len(style['layers'])} 個，移除的 raster source：{dropped or '無'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
