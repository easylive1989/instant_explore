"""Tests for the RevenueCat REST client."""
from __future__ import annotations

from datetime import datetime, timezone

import requests_mock

from lorescape_backend.subscriptions.revenuecat import RevenueCatClient

_SUBSCRIBER_URL = "https://api.revenuecat.com/v1/subscribers/user-1"


def _client() -> RevenueCatClient:
    return RevenueCatClient(api_key="rc-secret")


def test_active_entitlement_with_future_expiry():
    body = {
        "subscriber": {
            "entitlements": {
                "premium": {
                    "expires_date": "2999-01-01T00:00:00Z",
                    "product_identifier": "premium_yearly",
                }
            }
        }
    }
    with requests_mock.Mocker() as m:
        m.get(_SUBSCRIBER_URL, json=body)
        status = _client().get_subscriber("user-1")

    assert status.is_active is True
    assert status.entitlement == "premium"
    assert status.product_id == "premium_yearly"
    assert status.expires_at == datetime(
        2999, 1, 1, tzinfo=timezone.utc
    )


def test_expired_entitlement_is_inactive():
    body = {
        "subscriber": {
            "entitlements": {
                "premium": {
                    "expires_date": "2000-01-01T00:00:00Z",
                    "product_identifier": "premium_yearly",
                }
            }
        }
    }
    with requests_mock.Mocker() as m:
        m.get(_SUBSCRIBER_URL, json=body)
        status = _client().get_subscriber("user-1")

    assert status.is_active is False
    assert status.entitlement == "premium"


def test_no_entitlements_is_inactive():
    with requests_mock.Mocker() as m:
        m.get(_SUBSCRIBER_URL, json={"subscriber": {"entitlements": {}}})
        status = _client().get_subscriber("user-1")

    assert status.is_active is False
    assert status.entitlement is None
    assert status.product_id is None


def test_lifetime_entitlement_without_expiry_is_active():
    body = {
        "subscriber": {
            "entitlements": {
                "premium": {
                    "expires_date": None,
                    "product_identifier": "lifetime",
                }
            }
        }
    }
    with requests_mock.Mocker() as m:
        m.get(_SUBSCRIBER_URL, json=body)
        status = _client().get_subscriber("user-1")

    assert status.is_active is True
    assert status.expires_at is None


def test_sends_bearer_authorization_header():
    with requests_mock.Mocker() as m:
        m.get(_SUBSCRIBER_URL, json={"subscriber": {"entitlements": {}}})
        _client().get_subscriber("user-1")
        assert m.last_request.headers["Authorization"] == "Bearer rc-secret"
