from fetch_world_heritage_sites import parse_sparql_response


def test_parse_extracts_qid_name_title_country():
    data = {
        "results": {
            "bindings": [
                {
                    "item": {"value": "http://www.wikidata.org/entity/Q10285"},
                    "itemLabel": {"value": "Colosseum"},
                    "countryLabel": {"value": "Italy"},
                    "enwiki": {"value": "https://en.wikipedia.org/wiki/Colosseum"},
                }
            ]
        }
    }

    rows = parse_sparql_response(data)

    assert rows == [("Q10285", "Colosseum", "Colosseum", "Italy")]


def test_parse_skips_rows_without_enwiki_or_country():
    data = {
        "results": {
            "bindings": [
                {
                    "item": {"value": "http://www.wikidata.org/entity/Q1"},
                    "itemLabel": {"value": "No Wiki"},
                    "countryLabel": {"value": "Nowhere"},
                },
                {
                    "item": {"value": "http://www.wikidata.org/entity/Q2"},
                    "itemLabel": {"value": "No Country"},
                    "enwiki": {"value": "https://en.wikipedia.org/wiki/No_Country"},
                },
                {
                    "itemLabel": {"value": "No Item"},
                    "countryLabel": {"value": "Somewhere"},
                    "enwiki": {"value": "https://en.wikipedia.org/wiki/No_Item"},
                },
            ]
        }
    }

    assert parse_sparql_response(data) == []


def test_parse_returns_empty_for_no_bindings():
    assert parse_sparql_response({"results": {"bindings": []}}) == []


def test_parse_url_decodes_wiki_title():
    data = {
        "results": {
            "bindings": [
                {
                    "item": {"value": "http://www.wikidata.org/entity/Q191"},
                    "itemLabel": {"value": "Mont-Saint-Michel"},
                    "countryLabel": {"value": "France"},
                    "enwiki": {
                        "value": "https://en.wikipedia.org/wiki/Mont-Saint-Michel%20and%20its%20Bay"
                    },
                }
            ]
        }
    }
    assert parse_sparql_response(data) == [
        ("Q191", "Mont-Saint-Michel", "Mont-Saint-Michel and its Bay", "France"),
    ]
