from fetch_world_heritage_sites import parse_sparql_response

SAMPLE_SPARQL_JSON = {
    "results": {
        "bindings": [
            {
                "itemLabel": {"value": "Acropolis of Athens"},
                "countryLabel": {"value": "Greece"},
                "enwiki": {"value": "https://en.wikipedia.org/wiki/Acropolis_of_Athens"},
            },
            {
                "itemLabel": {"value": "Colosseum"},
                "countryLabel": {"value": "Italy"},
                "enwiki": {"value": "https://en.wikipedia.org/wiki/Colosseum"},
            },
            {
                # Missing enwiki -> should be filtered out
                "itemLabel": {"value": "Some site"},
                "countryLabel": {"value": "Nowhere"},
            },
            {
                # Missing country -> should be filtered out
                "itemLabel": {"value": "Foo"},
                "enwiki": {"value": "https://en.wikipedia.org/wiki/Foo"},
            },
        ]
    }
}


def test_parse_sparql_response_extracts_name_country_and_wiki_title():
    rows = parse_sparql_response(SAMPLE_SPARQL_JSON)
    assert rows == [
        ("Acropolis of Athens", "Acropolis of Athens", "Greece"),
        ("Colosseum", "Colosseum", "Italy"),
    ]


def test_parse_sparql_response_returns_empty_for_no_bindings():
    assert parse_sparql_response({"results": {"bindings": []}}) == []


def test_parse_sparql_response_url_decodes_wiki_title():
    data = {
        "results": {
            "bindings": [
                {
                    "itemLabel": {"value": "Mont-Saint-Michel"},
                    "countryLabel": {"value": "France"},
                    "enwiki": {
                        "value": "https://en.wikipedia.org/wiki/Mont-Saint-Michel%20and%20its%20Bay"
                    },
                }
            ]
        }
    }
    rows = parse_sparql_response(data)
    assert rows == [
        ("Mont-Saint-Michel", "Mont-Saint-Michel and its Bay", "France"),
    ]
