from unittest.mock import patch

import pytest

from lorescape_backend.narration import service as narration_service
from lorescape_backend.narration.models import (
    HookItem,
    HooksRequest,
    NarrationRequest,
)
from lorescape_backend.sources.models import SourceBundle, SourceExtract


_INTRO_EXTRACT = "Roman colony; Van Gogh painted here in 1888."


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _sufficient_bundle() -> SourceBundle:
    extract_text = "马卡龙公园是位于桃园市的主题公园，建于2020年。" * 10
    return SourceBundle(
        wikidata_id="Q108234567", place_name="馬卡龍公園",
        extracts=[SourceExtract(
            provider="wikipedia_zh", title="馬卡龍公園", text=extract_text,
            char_count=len(extract_text), has_named_entity=True,
        )],
        total_chars=len(extract_text), is_sufficient=True,
    )


def _insufficient_bundle() -> SourceBundle:
    return SourceBundle(
        wikidata_id="Q1", place_name="x", extracts=[],
        total_chars=0, is_sufficient=False,
    )


# ---------------------------------------------------------------------------
# Legacy (web_search=False, kill-switch) path — behaviour must stay identical
# to the pre-grounding implementation.
# ---------------------------------------------------------------------------

@patch("lorescape_backend.narration.service.legacy_single_source_bundle")
@patch("lorescape_backend.narration.service.gemini_client.generate_structured")
def test_generate_hooks_returns_parsed_hooks(gen_mock, bundle_mock):
    bundle_mock.return_value = _sufficient_bundle()
    gen_mock.return_value = {
        "hooks": [
            {"id": "h1", "title": "T1", "teaser": "Te1"},
            {"id": "h2", "title": "T2", "teaser": "Te2"},
        ],
        "insufficient_source": False,
    }

    result = narration_service.generate_hooks(
        api_key="K",
        web_search=False,
        request=HooksRequest(
            place_name="Arles",
            location="Provence",
            wikipedia_title="Arles",
            language="zh-TW",
        ),
    )

    assert len(result.hooks) == 2
    assert result.hooks[0].id == "h1"
    assert result.insufficient_source is False
    bundle_mock.assert_called_once_with(title="Arles")


@patch("lorescape_backend.narration.service.legacy_single_source_bundle")
@patch("lorescape_backend.narration.service.gemini_client.generate_structured")
def test_generate_hooks_handles_insufficient_source(gen_mock, bundle_mock):
    bundle_mock.return_value = _insufficient_bundle()
    gen_mock.return_value = {"hooks": [], "insufficient_source": True}

    result = narration_service.generate_hooks(
        api_key="K",
        web_search=False,
        request=HooksRequest(
            place_name="x", wikipedia_title="x", language="en",
        ),
    )

    assert result.hooks == []
    assert result.insufficient_source is True


def test_generate_hooks_rejects_unsupported_language():
    with pytest.raises(narration_service.UnsupportedLanguageError):
        narration_service.generate_hooks(
            api_key="K",
            request=HooksRequest(
                place_name="x", wikipedia_title="x", language="ja",
            ),
        )


@patch("lorescape_backend.narration.service.legacy_single_source_bundle")
@patch("lorescape_backend.narration.service.gemini_client.generate_structured")
def test_generate_narration_returns_parsed_response(gen_mock, bundle_mock):
    bundle_mock.return_value = _sufficient_bundle()
    gen_mock.return_value = {
        "place_name": "亞爾",
        "place_location": "法國普羅旺斯",
        "era": "十九世紀末",
        "paragraphs": ["一", "二", "三"],
        "pull_quote": "「我看見麥田」",
        "insufficient_source": False,
    }

    result = narration_service.generate_narration(
        api_key="K",
        web_search=False,
        request=NarrationRequest(
            place_name="Arles",
            location="Provence",
            wikipedia_title="Arles",
            language="zh-TW",
            hook=HookItem(id="h", title="梵谷的黃色小屋",
                          teaser="444 天的悲劇"),
        ),
    )

    assert result.place_name == "亞爾"
    assert result.paragraphs == ["一", "二", "三"]
    assert result.pull_quote == "「我看見麥田」"
    assert result.insufficient_source is False
    bundle_mock.assert_called_once_with(title="Arles")
    # Hook content should reach the LLM via the user prompt
    call_kwargs = gen_mock.call_args.kwargs
    assert "梵谷的黃色小屋" in call_kwargs["user_prompt"]
    assert "444 天的悲劇" in call_kwargs["user_prompt"]


@patch("lorescape_backend.narration.service.legacy_single_source_bundle")
@patch("lorescape_backend.narration.service.gemini_client.generate_structured")
def test_generate_narration_without_hook_invites_self_pick(gen_mock, bundle_mock):
    bundle_mock.return_value = _sufficient_bundle()
    gen_mock.return_value = {
        "place_name": "Arles",
        "place_location": "Provence",
        "era": "Late 19th c.",
        "paragraphs": ["a", "b", "c"],
        "pull_quote": "",
        "insufficient_source": False,
    }

    narration_service.generate_narration(
        api_key="K",
        web_search=False,
        request=NarrationRequest(
            place_name="Arles", wikipedia_title="Arles", language="en",
        ),
    )

    call_kwargs = gen_mock.call_args.kwargs
    # When no hook is provided, the prompt must NOT include a hook section.
    assert "HOOK to expand" not in call_kwargs["user_prompt"]


@patch("lorescape_backend.narration.service.legacy_single_source_bundle")
@patch("lorescape_backend.narration.service.gemini_client.generate_structured")
def test_generate_narration_forces_empty_paragraphs_when_insufficient_source(
    gen_mock, bundle_mock,
):
    """If the model flags insufficient_source, the service MUST discard
    whatever it put in `paragraphs` and `pull_quote` — observed failure
    mode: model regurgitates the in-prompt positive example."""
    bundle_mock.return_value = _sufficient_bundle()
    gen_mock.return_value = {
        "place_name": "Fake Place",
        "place_location": "",
        "era": "",
        # Model leaked the positive example into paragraphs anyway.
        "paragraphs": [
            "一八八八年二月，文森·梵谷踏上亞爾...",
            "一八八八年二月，文森·梵谷踏上亞爾...",
            "一八八八年二月，文森·梵谷踏上亞爾...",
        ],
        "pull_quote": "「我看見麥田」",
        "insufficient_source": True,
    }

    result = narration_service.generate_narration(
        api_key="K",
        web_search=False,
        request=NarrationRequest(
            place_name="Fake", wikipedia_title="Fake", language="zh-TW",
        ),
    )

    assert result.insufficient_source is True
    assert result.paragraphs == []
    assert result.pull_quote == ""


def test_generate_narration_rejects_unsupported_language():
    with pytest.raises(narration_service.UnsupportedLanguageError):
        narration_service.generate_narration(
            api_key="K",
            request=NarrationRequest(
                place_name="x", wikipedia_title="x", language="ja",
            ),
        )


# ---------------------------------------------------------------------------
# New tests: wikidata_id path, pre-Gemini gate, legacy logging
# ---------------------------------------------------------------------------

def test_generate_narration_with_wikidata_id_invokes_pipeline_and_gemini(monkeypatch):
    gemini_calls = []
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _sufficient_bundle(),
    )

    def fake_generate_structured(**kwargs):
        gemini_calls.append(kwargs)
        return {
            "place_name": "馬卡龍公園", "place_location": "桃園", "era": "modern",
            "paragraphs": ["a", "b", "c"], "pull_quote": "「q」",
            "insufficient_source": False,
        }

    monkeypatch.setattr(narration_service.gemini_client, "generate_structured", fake_generate_structured)

    req = NarrationRequest(
        wikidata_id="Q108234567", place_name="馬卡龍公園",
        location="桃園", language="zh-TW",
    )
    res = narration_service.generate_narration(
        api_key="k", request=req, web_search=False,
    )

    assert len(gemini_calls) == 1
    assert res.insufficient_source is False
    assert res.paragraphs == ["a", "b", "c"]


def test_generate_narration_pre_gemini_gate_short_circuits(monkeypatch):
    gemini_calls = []
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _insufficient_bundle(),
    )

    def fake_generate_structured(**kwargs):
        gemini_calls.append(kwargs)
        return {}

    monkeypatch.setattr(narration_service.gemini_client, "generate_structured", fake_generate_structured)

    req = NarrationRequest(
        wikidata_id="Q1", place_name="x", location="y", language="en",
    )
    res = narration_service.generate_narration(
        api_key="k", request=req, web_search=False,
    )

    assert gemini_calls == []  # critical: Gemini NOT called
    assert res.insufficient_source is True
    assert res.paragraphs == []


def test_generate_narration_legacy_title_path_uses_single_source_bundle(monkeypatch, caplog):
    monkeypatch.setattr(
        narration_service, "legacy_single_source_bundle",
        lambda *, title: _sufficient_bundle(),
    )
    monkeypatch.setattr(
        narration_service.gemini_client, "generate_structured",
        lambda **kw: {
            "place_name": "Macaron Park", "place_location": "Taoyuan", "era": "modern",
            "paragraphs": ["a", "b", "c"], "pull_quote": "q",
            "insufficient_source": False,
        },
    )

    req = NarrationRequest(
        wikipedia_title="Macaron Park", place_name="Macaron Park",
        location="Taoyuan", language="en",
    )
    with caplog.at_level("WARNING"):
        narration_service.generate_narration(
            api_key="k", request=req, web_search=False,
        )

    assert any("narration.legacy_title_path" in rec.message for rec in caplog.records)


def test_generate_hooks_with_wikidata_id_uses_pipeline(monkeypatch):
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _sufficient_bundle(),
    )

    def fake_generate_structured(**kw):
        return {
            "hooks": [{"id": "a", "title": "T", "teaser": "tz"}],
            "insufficient_source": False,
        }
    monkeypatch.setattr(narration_service.gemini_client, "generate_structured", fake_generate_structured)

    req = HooksRequest(
        wikidata_id="Q1", place_name="x", location="y", language="en",
    )
    res = narration_service.generate_hooks(
        api_key="k", request=req, web_search=False,
    )
    assert len(res.hooks) == 1


def test_generate_hooks_pre_gemini_gate_short_circuits(monkeypatch):
    calls = []
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _insufficient_bundle(),
    )
    monkeypatch.setattr(narration_service.gemini_client, "generate_structured",
                        lambda **kw: calls.append(kw) or {})

    req = HooksRequest(wikidata_id="Q1", place_name="x", location="y", language="en")
    res = narration_service.generate_hooks(
        api_key="k", request=req, web_search=False,
    )

    assert calls == []
    assert res.hooks == []
    assert res.insufficient_source is True


# ---------------------------------------------------------------------------
# Grounded (web_search=True, default) path
# ---------------------------------------------------------------------------

_NARRATION_PAYLOAD = {
    "place_name": "Arles", "place_location": "Provence", "era": "1888",
    "paragraphs": ["a", "b", "c"], "pull_quote": "q",
    "insufficient_source": False,
}


def test_narration_default_uses_grounded_with_web_prompts(monkeypatch):
    calls = []
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _sufficient_bundle(),
    )
    monkeypatch.setattr(
        narration_service.gemini_client, "generate_grounded",
        lambda **kw: calls.append(kw) or _NARRATION_PAYLOAD,
    )

    req = NarrationRequest(
        wikidata_id="Q1", place_name="Arles", location="Provence",
        language="en",
    )
    res = narration_service.generate_narration(api_key="k", request=req)

    assert len(calls) == 1
    assert "google_search" in calls[0]["system_instruction"]
    assert "OUTPUT FORMAT (STRICT)" in calls[0]["user_prompt"]
    assert calls[0]["response_schema"] is not None
    assert res.paragraphs == ["a", "b", "c"]


def test_narration_thin_bundle_no_longer_short_circuits(monkeypatch):
    """Web search can rescue thin-Wikipedia places: the gate must NOT
    short-circuit when web_search is on (the default)."""
    calls = []
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _insufficient_bundle(),
    )
    monkeypatch.setattr(
        narration_service.gemini_client, "generate_grounded",
        lambda **kw: calls.append(kw) or _NARRATION_PAYLOAD,
    )

    req = NarrationRequest(
        wikidata_id="Q1", place_name="x", location="y", language="en",
    )
    res = narration_service.generate_narration(api_key="k", request=req)

    assert len(calls) == 1  # grounded Gemini WAS called despite thin wiki
    assert res.insufficient_source is False
    assert res.paragraphs == ["a", "b", "c"]


def test_hooks_default_uses_grounded_and_thin_bundle_proceeds(monkeypatch):
    calls = []
    monkeypatch.setattr(
        narration_service, "build_source_bundle",
        lambda *, wikidata_id, language, place_name: _insufficient_bundle(),
    )
    monkeypatch.setattr(
        narration_service.gemini_client, "generate_grounded",
        lambda **kw: calls.append(kw) or {
            "hooks": [{"id": "a", "title": "T", "teaser": "tz"}],
            "insufficient_source": False,
        },
    )

    req = HooksRequest(
        wikidata_id="Q1", place_name="x", location="y", language="en",
    )
    res = narration_service.generate_hooks(api_key="k", request=req)

    assert len(calls) == 1
    assert "google_search" in calls[0]["system_instruction"]
    assert len(res.hooks) == 1
