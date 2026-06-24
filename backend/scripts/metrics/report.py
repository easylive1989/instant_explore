"""Orchestrate metrics sources into a dated report under docs/metrics/."""
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Callable

from dotenv import load_dotenv

from scripts.metrics._common import (
    REPO_ROOT,
    MetricsConfig,
    SourceResult,
    date_range,
    report_dir,
    rows_to_md_table,
    write_csv,
)

Source = Callable[[MetricsConfig, str, str], SourceResult]

# Later tasks register "gsc", "ga4", "ig" here.
SOURCES: dict[str, Source] = {}

# Minimum config each source needs to even attempt a fetch.
_REQUIRED: dict[str, tuple[str, ...]] = {
    "gsc": ("gsc_site_url",),
    "ga4": ("ga4_property_id_web",),
    "ig": ("ig_user_id", "meta_page_access_token"),
}


def _repo_root() -> Path:
    return REPO_ROOT


def check_lines(cfg: MetricsConfig, names: list[str]) -> list[str]:
    """One readiness line per source; pure, no network."""
    lines: list[str] = []
    for name in names:
        required = _REQUIRED.get(name, ())
        missing = [f for f in required if not getattr(cfg, f)]
        if missing:
            lines.append(f"- {name}: missing config → {', '.join(missing)}")
        else:
            lines.append(f"- {name}: ready")
    return lines


def build_summary(
    results: list[SourceResult], start: str, end: str
) -> str:
    """Render the cross-source markdown summary."""
    out = [f"# Lorescape 數據報告 {start} → {end}", ""]
    for r in results:
        out.append(f"## {r.name}")
        if not r.ok:
            out.append(f"- skipped: {r.skipped_reason}")
            out.append("")
            continue
        out.extend(f"- {line}" for line in r.summary_lines)
        if r.csv_rows:
            out.append("")
            out.append(
                rows_to_md_table(r.csv_headers, r.csv_rows[:10])
            )
        out.append("")
    return "\n".join(out)


def run(
    cfg: MetricsConfig,
    names: list[str],
    start: str,
    end: str,
    root: Path,
) -> Path:
    """Fetch each named source, write summary.md + per-source CSVs."""
    results: list[SourceResult] = []
    for name in names:
        fetch = SOURCES.get(name)
        if fetch is None:
            results.append(SourceResult.skipped(name, "not implemented"))
            continue
        try:
            results.append(fetch(cfg, start, end))
        except Exception as exc:  # isolate per-source failures
            results.append(SourceResult.skipped(name, f"error: {exc}"))

    out_dir = report_dir(end, root=root)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "summary.md").write_text(
        build_summary(results, start, end), encoding="utf-8"
    )
    for r in results:
        if r.ok and r.csv_rows:
            write_csv(
                out_dir / f"{r.name}.csv", r.csv_headers, r.csv_rows
            )
    return out_dir


def main(argv: list[str] | None = None) -> int:
    load_dotenv(_repo_root() / "backend" / ".env")
    parser = argparse.ArgumentParser(description="Fetch Lorescape metrics.")
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument("--start")
    parser.add_argument("--end")
    parser.add_argument("--only", help="comma-separated subset of sources")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)

    cfg = MetricsConfig.from_env()
    all_names = list(SOURCES.keys()) or ["gsc", "ga4", "ig"]
    names = args.only.split(",") if args.only else all_names
    start, end = date_range(
        days=args.days, start=args.start, end=args.end
    )

    if args.check:
        print(f"range: {start} → {end}")
        print("\n".join(check_lines(cfg, names)))
        return 0

    out_dir = run(cfg, names, start, end, root=_repo_root())
    print(f"report written: {out_dir / 'summary.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
