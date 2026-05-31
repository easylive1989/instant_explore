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
            ]
        }
    }

    assert parse_sparql_response(data) == []
