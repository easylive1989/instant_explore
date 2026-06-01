import requests_mock

from backfill_wikidata_ids import resolve_qid_from_title

API = "https://en.wikipedia.org/w/api.php"


def test_resolve_returns_qid_from_pageprops():
    payload = {
        "query": {
            "pages": {
                "10285": {
                    "pageid": 10285,
                    "title": "Colosseum",
                    "pageprops": {"wikibase_item": "Q10285"},
                }
            }
        }
    }
    with requests_mock.Mocker() as m:
        m.get(API, json=payload)
        qid = resolve_qid_from_title("Colosseum")
        sent = m.request_history[0].qs

    assert qid == "Q10285"
    assert sent["action"] == ["query"]
    assert sent["prop"] == ["pageprops"]
    assert sent["ppprop"] == ["wikibase_item"]
    assert sent["redirects"] == ["1"]
    assert sent["titles"] == ["colosseum"]


def test_resolve_returns_none_when_no_pageprops():
    payload = {"query": {"pages": {"-1": {"title": "Nope", "missing": ""}}}}
    with requests_mock.Mocker() as m:
        m.get(API, json=payload)
        assert resolve_qid_from_title("Nope") is None
