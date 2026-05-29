"""Diagnose + recover the daily story pipeline for a given date.

Mirrors the 8-step health check from .claude/skills/lorescape-debug
(skipping steps 1+2 which need gh CLI / git on host), then offers an
interactive recovery plan for the common failure patterns.

Run from inside the backend container so secrets are read from .env:

    docker exec -it lorescape-backend \\
        python -m scripts.diagnose_daily_story --date 2026-05-28

Defaults to today's Asia/Taipei date. Pass --apply to actually execute
recovery actions (without it everything is dry-run). Pass
--non-interactive to skip y/n confirmations (intended for cron / CI;
combine with --apply for an unattended self-heal).
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
from dataclasses import dataclass, field
from datetime import date, datetime, time, timedelta, timezone
from typing import Any, Literal, Sequence

from supabase import create_client

from lorescape_backend.config import Config
from lorescape_backend.daily_story import discord_review, job, place_picker
from lorescape_backend.social.card import mapper

logger = logging.getLogger(__name__)

TAIPEI = timezone(timedelta(hours=8))
LANGUAGES = ("zh-TW", "en")
REVIEW_LANGUAGE = job.REVIEW_LANGUAGE

Severity = Literal["ok", "info", "warn", "fail"]
_SEVERITY_ICON = {"ok": "✅", "info": "ℹ️ ", "warn": "⚠️ ", "fail": "❌"}


@dataclass
class Finding:
    """A single diagnostic observation."""

    step: str
    severity: Severity
    message: str
    detail: dict[str, Any] = field(default_factory=dict)


@dataclass
class DiagnosisReport:
    target_date: date
    findings: list[Finding] = field(default_factory=list)
    rows_by_language: dict[str, dict[str, Any]] = field(default_factory=dict)
    place_row: dict[str, Any] | None = None

    @property
    def severity(self) -> Severity:
        if any(f.severity == "fail" for f in self.findings):
            return "fail"
        if any(f.severity == "warn" for f in self.findings):
            return "warn"
        return "ok"

    @property
    def is_healthy(self) -> bool:
        return self.severity == "ok"


# ---------------------------------------------------------------------------
# Diagnostic checks (skill steps 3-8)
# ---------------------------------------------------------------------------

def _fetch_today_rows(
    supabase, target_date: date
) -> dict[str, dict[str, Any]]:
    response = (
        supabase.table("daily_stories")
        .select("*")
        .eq("publish_date", target_date.isoformat())
        .execute()
    )
    return {row["language"]: row for row in (response.data or [])}


def _fetch_place(supabase, place_id: str) -> dict[str, Any] | None:
    response = (
        supabase.table("daily_story_places")
        .select("*")
        .eq("id", place_id)
        .limit(1)
        .execute()
    )
    rows = response.data or []
    return rows[0] if rows else None


def check_rows_exist(report: DiagnosisReport) -> None:
    """Step 3a: rows for both languages exist."""
    missing = [lang for lang in LANGUAGES if lang not in report.rows_by_language]
    if not report.rows_by_language:
        report.findings.append(Finding(
            step="rows_exist",
            severity="fail",
            message=(
                f"No daily_stories rows for {report.target_date.isoformat()} — "
                "generate job did not run or failed before insert"
            ),
        ))
    elif missing:
        report.findings.append(Finding(
            step="rows_exist",
            severity="fail",
            message=f"Missing language rows: {', '.join(missing)}",
            detail={"present": sorted(report.rows_by_language)},
        ))
    else:
        report.findings.append(Finding(
            step="rows_exist",
            severity="ok",
            message="Both en and zh-TW rows present",
        ))


def _row_content_empty(row: dict[str, Any]) -> dict[str, bool]:
    """Identify which content fields are empty on a single row."""
    paragraphs = row.get("card_paragraphs") or []
    return {
        "card_title": not (row.get("card_title") or "").strip(),
        "card_title_sub": not (row.get("card_title_sub") or "").strip(),
        "card_paragraphs": not paragraphs or not all(
            (p or "").strip() for p in paragraphs
        ),
        "card_pull_quote": not (row.get("card_pull_quote") or "").strip(),
        "card_pull_quote_attrib": not (
            row.get("card_pull_quote_attrib") or ""
        ).strip(),
        "hashtags": not (row.get("hashtags") or []),
    }


def check_rows_populated(report: DiagnosisReport) -> None:
    """Step 3b: detect Gemini soft-refusal empty content."""
    if not report.rows_by_language:
        return
    any_empty = False
    for lang, row in report.rows_by_language.items():
        empties = _row_content_empty(row)
        empty_fields = sorted(k for k, v in empties.items() if v)
        if empty_fields:
            any_empty = True
            report.findings.append(Finding(
                step="rows_populated",
                severity="fail",
                message=(
                    f"{lang} row has empty content fields: "
                    f"{', '.join(empty_fields)} — "
                    "Gemini likely returned a schema-compliant but empty "
                    "response (soft refusal pattern)"
                ),
                detail={
                    "language": lang,
                    "row_id": row["id"],
                    "place_id": row.get("place_id"),
                    "empty_fields": empty_fields,
                },
            ))
    if not any_empty:
        report.findings.append(Finding(
            step="rows_populated",
            severity="ok",
            message="All content fields populated on both rows",
        ))


def check_place_metadata(report: DiagnosisReport) -> None:
    """Step 4: place row carries every IG-card-required field."""
    if not report.place_row:
        if report.rows_by_language:
            report.findings.append(Finding(
                step="place_metadata",
                severity="fail",
                message="place_id referenced by today's rows not found in "
                        "daily_story_places",
            ))
        return
    p = report.place_row
    nulls = {
        "card_location_en": p.get("card_location_en") in (None, ""),
        "card_city_ch": p.get("card_city_ch") in (None, ""),
        "card_city_en": p.get("card_city_en") in (None, ""),
        "latitude": p.get("latitude") is None,
        "longitude": p.get("longitude") is None,
    }
    missing = sorted(k for k, v in nulls.items() if v)
    if missing:
        report.findings.append(Finding(
            step="place_metadata",
            severity="fail",
            message=(
                f"Place '{p.get('name')}' missing IG-card fields: "
                f"{', '.join(missing)}"
            ),
            detail={"place_id": p["id"], "missing": missing},
        ))
    else:
        report.findings.append(Finding(
            step="place_metadata",
            severity="ok",
            message=f"Place '{p.get('name')}' metadata complete",
        ))


def check_card_renderable(report: DiagnosisReport) -> None:
    """Step 3+4 combined: would mapper.build_card_content succeed?"""
    review_row = report.rows_by_language.get(REVIEW_LANGUAGE)
    if not review_row or not report.place_row:
        return
    content = mapper.build_card_content(review_row, report.place_row)
    if content is None:
        report.findings.append(Finding(
            step="card_renderable",
            severity="fail",
            message=(
                f"mapper.build_card_content returns None — IG card cannot "
                f"render; this is what triggers the 'missing IG card content' "
                f"alert for row {review_row['id']}"
            ),
            detail={"row_id": review_row["id"]},
        ))
    else:
        report.findings.append(Finding(
            step="card_renderable",
            severity="ok",
            message="IG card content would render successfully",
        ))


def check_discord_review_posted(
    config: Config, report: DiagnosisReport
) -> None:
    """Step 5: Discord review message exists for the REVIEW_LANGUAGE row."""
    if not config.review_enabled:
        report.findings.append(Finding(
            step="discord_review",
            severity="info",
            message="Discord review not configured (skipping)",
        ))
        return
    review_row = report.rows_by_language.get(REVIEW_LANGUAGE)
    if not review_row:
        return
    message_id = review_row.get("discord_message_id")
    if not message_id:
        report.findings.append(Finding(
            step="discord_review",
            severity="warn",
            message=(
                f"{REVIEW_LANGUAGE} row has no discord_message_id — review "
                "card was not posted (or post step failed)"
            ),
            detail={"row_id": review_row["id"]},
        ))
        return

    import requests
    url = (
        f"https://discord.com/api/v10/channels/"
        f"{config.discord_review_channel_id}/messages/{message_id}"
    )
    headers = {"Authorization": f"Bot {config.discord_bot_token}"}
    response = requests.get(url, headers=headers, timeout=10)
    if response.status_code == 404:
        report.findings.append(Finding(
            step="discord_review",
            severity="fail",
            message=(
                f"Discord message {message_id} returns 404 — deleted or "
                "discord_message_id is stale"
            ),
            detail={"message_id": message_id},
        ))
        return
    response.raise_for_status()
    data = response.json()
    report.findings.append(Finding(
        step="discord_review",
        severity="ok",
        message=f"Discord review posted at {data.get('timestamp')}",
        detail={"message_id": message_id},
    ))


def check_discord_reactions(
    config: Config, report: DiagnosisReport
) -> None:
    """Step 6: predict the 21:00 verdict from current reactions."""
    if not config.review_enabled:
        return
    review_row = report.rows_by_language.get(REVIEW_LANGUAGE)
    if not review_row:
        return
    message_id = review_row.get("discord_message_id")
    if not message_id:
        return
    if review_row.get("review_state") not in ("pending", None):
        report.findings.append(Finding(
            step="reactions",
            severity="info",
            message=(
                f"Row already in state '{review_row.get('review_state')}' — "
                "publisher has acted; reactions no longer change outcome"
            ),
        ))
        return

    verdict = discord_review.check_reaction(
        bot_token=config.discord_bot_token,
        channel_id=config.discord_review_channel_id,
        message_id=message_id,
        approver_ids=config.discord_approver_ids,
    )
    if verdict == "approved":
        sev: Severity = "ok"
        msg = "Approver ✅ present — publisher will PUBLISH at 21:00"
    elif verdict == "rejected":
        sev = "warn"
        msg = "Approver ❌ only — publisher will REJECT at 21:00"
    else:
        sev = "warn"
        msg = (
            "No approver reaction yet — without one before 21:00 the row "
            "will be SKIPPED. Bot-seeded ✅/❌ do not count."
        )
    report.findings.append(Finding(
        step="reactions",
        severity=sev,
        message=msg,
        detail={"verdict": verdict},
    ))


def check_recent_failures(
    supabase, report: DiagnosisReport, lookback_days: int = 14
) -> None:
    """Step 7: list rows in failed state or with publish_error."""
    cutoff = report.target_date - timedelta(days=lookback_days)
    response = (
        supabase.table("daily_stories")
        .select(
            "publish_date,language,review_state,publish_error,"
            "ig_post_id"
        )
        .or_("review_state.eq.failed,publish_error.not.is.null")
        .gte("publish_date", cutoff.isoformat())
        .order("publish_date", desc=True)
        .limit(10)
        .execute()
    )
    rows = response.data or []
    if not rows:
        report.findings.append(Finding(
            step="recent_failures",
            severity="ok",
            message=f"No failed rows in the last {lookback_days} days",
        ))
        return
    real_failures = [r for r in rows if r.get("review_state") == "failed"]
    skip_signals = [
        r for r in rows
        if (r.get("publish_error") or "").startswith("ig_skipped_")
    ]
    sev: Severity = "warn" if real_failures else "info"
    report.findings.append(Finding(
        step="recent_failures",
        severity=sev,
        message=(
            f"{len(rows)} rows with failure markers in last "
            f"{lookback_days} days "
            f"({len(real_failures)} real failures, "
            f"{len(skip_signals)} recoverable skips)"
        ),
        detail={"rows": rows},
    ))


def check_timezone_drift(supabase, report: DiagnosisReport) -> None:
    """Step 8: created_at + reviewed_at hour-of-day pattern."""
    response = (
        supabase.table("daily_stories")
        .select("publish_date,created_at,reviewed_at")
        .eq("language", "en")
        .order("publish_date", desc=True)
        .limit(7)
        .execute()
    )
    rows = response.data or []
    if not rows:
        return
    create_hours = []
    review_hours = []
    for r in rows:
        if r.get("created_at"):
            create_hours.append(
                datetime.fromisoformat(
                    r["created_at"].replace("Z", "+00:00")
                ).astimezone(timezone.utc).hour
            )
        if r.get("reviewed_at"):
            review_hours.append(
                datetime.fromisoformat(
                    r["reviewed_at"].replace("Z", "+00:00")
                ).astimezone(timezone.utc).hour
            )
    avg_create = sum(create_hours) / len(create_hours) if create_hours else None
    avg_review = sum(review_hours) / len(review_hours) if review_hours else None

    if avg_create is None:
        return
    # 09:00 Asia/Taipei == 01:00 UTC (tzdata fix live)
    # 09:00 UTC == 17:00 Asia/Taipei (pre-fix, 8h drift)
    if 0 <= avg_create <= 2:
        report.findings.append(Finding(
            step="timezone",
            severity="ok",
            message=(
                f"created_at avg hour ≈ {avg_create:.1f} UTC "
                "→ scheduler running on Asia/Taipei (tzdata fix live)"
            ),
        ))
    elif 8 <= avg_create <= 10:
        report.findings.append(Finding(
            step="timezone",
            severity="warn",
            message=(
                f"created_at avg hour ≈ {avg_create:.1f} UTC "
                "→ scheduler in UTC (8h drift; tzdata fix not deployed)"
            ),
        ))
    else:
        report.findings.append(Finding(
            step="timezone",
            severity="warn",
            message=(
                f"created_at avg hour ≈ {avg_create:.1f} UTC (review "
                f"≈ {avg_review}) — unexpected pattern, investigate"
            ),
        ))


def run_diagnostics(
    supabase, config: Config, target_date: date
) -> DiagnosisReport:
    report = DiagnosisReport(target_date=target_date)
    report.rows_by_language = _fetch_today_rows(supabase, target_date)
    place_id = next(
        (r.get("place_id") for r in report.rows_by_language.values()
         if r.get("place_id")),
        None,
    )
    if place_id:
        report.place_row = _fetch_place(supabase, place_id)

    check_rows_exist(report)
    check_rows_populated(report)
    check_place_metadata(report)
    check_card_renderable(report)
    check_discord_review_posted(config, report)
    check_discord_reactions(config, report)
    check_recent_failures(supabase, report)
    check_timezone_drift(supabase, report)
    return report


# ---------------------------------------------------------------------------
# Recovery actions
# ---------------------------------------------------------------------------

@dataclass
class RecoveryAction:
    """Base recovery action — subclasses override `describe` and `_execute`."""

    def describe(self) -> str:
        raise NotImplementedError

    def execute(self, supabase, config: Config, dry_run: bool) -> None:
        prefix = "[DRY-RUN] " if dry_run else ""
        print(f"{prefix}→ {self.describe()}")
        if dry_run:
            return
        self._execute(supabase, config)
        print("   done.")

    def _execute(self, supabase, config: Config) -> None:
        raise NotImplementedError


@dataclass
class DisablePlace(RecoveryAction):
    place_id: str
    place_name: str
    reason: str

    def describe(self) -> str:
        return (
            f"Disable place '{self.place_name}' "
            f"(id={self.place_id[:8]}…, reason: {self.reason})"
        )

    def _execute(self, supabase, config: Config) -> None:
        (
            supabase.table("daily_story_places")
            .update({"is_active": False})
            .eq("id", self.place_id)
            .execute()
        )


@dataclass
class DeleteRows(RecoveryAction):
    target_date: date
    row_ids: list[str]

    def describe(self) -> str:
        return (
            f"Delete {len(self.row_ids)} daily_stories row(s) for "
            f"{self.target_date.isoformat()}"
        )

    def _execute(self, supabase, config: Config) -> None:
        (
            supabase.table("daily_stories")
            .delete()
            .in_("id", self.row_ids)
            .execute()
        )


@dataclass
class ClearUsedAt(RecoveryAction):
    place_id: str
    place_name: str

    def describe(self) -> str:
        return (
            f"Clear used_at on '{self.place_name}' so picker can re-select it"
        )

    def _execute(self, supabase, config: Config) -> None:
        (
            supabase.table("daily_story_places")
            .update({"used_at": None})
            .eq("id", self.place_id)
            .execute()
        )


@dataclass
class RerunGenerate(RecoveryAction):
    target_date: date

    def describe(self) -> str:
        return (
            f"Re-run generate + Discord review for "
            f"{self.target_date.isoformat()} (in-process)"
        )

    def _execute(self, supabase, config: Config) -> None:
        job.run_generate_and_review(config, self.target_date)


@dataclass
class ResendDiscordReview(RecoveryAction):
    target_date: date

    def describe(self) -> str:
        return (
            f"Re-post Discord review for {self.target_date.isoformat()} "
            "(content already in DB, just push to Discord)"
        )

    def _execute(self, supabase, config: Config) -> None:
        job.send_today_for_review(config, self.target_date)


# ---------------------------------------------------------------------------
# Pattern detection → recovery plan
# ---------------------------------------------------------------------------

def build_recovery_plan(report: DiagnosisReport) -> list[RecoveryAction]:
    """Map detected failure patterns to ordered recovery actions.

    Order matters: disable place → delete rows → rerun.
    Returns [] for healthy or unknown patterns.
    """
    findings_by_step = {f.step: f for f in report.findings}
    actions: list[RecoveryAction] = []

    rows_exist_fail = (
        findings_by_step.get("rows_exist")
        and findings_by_step["rows_exist"].severity == "fail"
    )
    rows_empty = any(
        f.step == "rows_populated" and f.severity == "fail"
        for f in report.findings
    )
    metadata_fail = (
        findings_by_step.get("place_metadata")
        and findings_by_step["place_metadata"].severity == "fail"
    )
    card_fail = (
        findings_by_step.get("card_renderable")
        and findings_by_step["card_renderable"].severity == "fail"
    )
    discord_missing = (
        findings_by_step.get("discord_review")
        and findings_by_step["discord_review"].severity in ("warn", "fail")
        and not rows_empty and not metadata_fail
    )

    # Pattern A: no rows → simple rerun
    if rows_exist_fail and not report.rows_by_language:
        actions.append(RerunGenerate(target_date=report.target_date))
        return actions

    # Pattern B: empty content (today's incident) → disable place + reset + rerun
    if rows_empty and report.place_row:
        place_id = report.place_row["id"]
        place_name = report.place_row.get("name", place_id)
        row_ids = [r["id"] for r in report.rows_by_language.values()]
        actions.append(DisablePlace(
            place_id=place_id,
            place_name=place_name,
            reason="Gemini soft-refusal empty content",
        ))
        actions.append(DeleteRows(
            target_date=report.target_date,
            row_ids=row_ids,
        ))
        actions.append(RerunGenerate(target_date=report.target_date))
        return actions

    # Pattern C: place metadata missing → disable place + reset + rerun
    if metadata_fail and report.place_row:
        place_id = report.place_row["id"]
        place_name = report.place_row.get("name", place_id)
        row_ids = [r["id"] for r in report.rows_by_language.values()]
        actions.append(DisablePlace(
            place_id=place_id,
            place_name=place_name,
            reason="missing IG card metadata on place row",
        ))
        if row_ids:
            actions.append(DeleteRows(
                target_date=report.target_date,
                row_ids=row_ids,
            ))
        actions.append(RerunGenerate(target_date=report.target_date))
        return actions

    # Pattern D: rows + card render OK, but Discord review never posted
    if discord_missing and not card_fail:
        actions.append(ResendDiscordReview(target_date=report.target_date))
        return actions

    return actions


# ---------------------------------------------------------------------------
# CLI / interactive runner
# ---------------------------------------------------------------------------

def _print_findings(report: DiagnosisReport) -> None:
    print(f"\nDiagnosis for {report.target_date.isoformat()}:")
    print("-" * 60)
    for f in report.findings:
        icon = _SEVERITY_ICON.get(f.severity, "?")
        print(f"  {icon} [{f.step}] {f.message}")
    print("-" * 60)
    print(f"Overall: {_SEVERITY_ICON[report.severity]} {report.severity.upper()}")


def _print_plan(actions: Sequence[RecoveryAction]) -> None:
    print("\nRecovery plan:")
    for i, action in enumerate(actions, 1):
        print(f"  {i}. {action.describe()}")
    print()


def _confirm(prompt: str, *, default: bool = False) -> bool:
    suffix = " [Y/n] " if default else " [y/N] "
    try:
        answer = input(prompt + suffix).strip().lower()
    except EOFError:
        return default
    if not answer:
        return default
    return answer in ("y", "yes")


def _resolve_target_date(arg: str | None) -> date:
    if arg:
        return date.fromisoformat(arg)
    return datetime.now(TAIPEI).date()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        prog="diagnose_daily_story",
        description="Diagnose + recover the daily story pipeline.",
    )
    parser.add_argument(
        "--date", help="YYYY-MM-DD; defaults to today's Asia/Taipei date"
    )
    parser.add_argument(
        "--apply", action="store_true",
        help="Actually run recovery actions (default: dry-run)",
    )
    parser.add_argument(
        "--non-interactive", action="store_true",
        help="Skip y/n confirmations (for cron / CI)",
    )
    parser.add_argument(
        "--verbose", action="store_true",
        help="Log INFO from underlying modules",
    )
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.INFO if args.verbose else logging.WARNING,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )

    target_date = _resolve_target_date(args.date)
    config = Config.from_env()
    supabase = create_client(
        config.supabase_url, config.supabase_service_role_key
    )

    report = run_diagnostics(supabase, config, target_date)
    _print_findings(report)

    if report.is_healthy:
        print("\nNo issues found. Nothing to do.")
        return 0

    plan = build_recovery_plan(report)
    if not plan:
        print(
            "\nIssues detected but no automated recovery available for "
            "this pattern. Inspect findings above and use lorescape-debug "
            "skill for further investigation."
        )
        return 1

    _print_plan(plan)

    if args.non_interactive:
        if not args.apply:
            print("Dry-run mode (no --apply). Exiting without changes.")
            return 0
        for action in plan:
            action.execute(supabase, config, dry_run=False)
        print("\nRecovery complete. Re-run without --apply to verify.")
        return 0

    # Interactive: confirm whole plan, then per-action confirm
    if not _confirm(
        f"Execute this plan? "
        f"({'APPLY' if args.apply else 'DRY-RUN'})",
        default=False,
    ):
        print("Aborted.")
        return 0

    for action in plan:
        if not _confirm(f"  Run step: {action.describe()}?", default=True):
            print("  Skipped — stopping (downstream steps depend on this).")
            return 0
        action.execute(supabase, config, dry_run=not args.apply)

    if args.apply:
        print("\nRecovery complete. Re-run without --apply to verify state.")
    else:
        print(
            "\nDry-run complete. Re-run with --apply to execute for real."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
