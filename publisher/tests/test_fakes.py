from tests._fakes import FakeSupabase


def test_upsert_then_select_by_key():
    sb = FakeSupabase()
    sb.table("social_posts").upsert(
        {"publish_date": "d1", "media_type": "carousel", "status": "pending"},
        on_conflict="publish_date,media_type",
    ).execute()

    got = (
        sb.table("social_posts").select("*")
        .eq("publish_date", "d1").eq("media_type", "carousel").execute()
    )
    assert got.data[0]["status"] == "pending"


def test_update_mutates_matching_rows():
    sb = FakeSupabase([
        {"publish_date": "d1", "media_type": "reel", "status": "pending"},
    ])
    sb.table("social_posts").update({"status": "scheduled"}).eq(
        "publish_date", "d1"
    ).eq("media_type", "reel").execute()
    assert sb.rows[0]["status"] == "scheduled"


def test_is_null_and_lte_filters():
    sb = FakeSupabase([
        {"id": "a", "status": "pending", "discord_message_id": None},
        {"id": "b", "status": "pending", "discord_message_id": "m"},
    ])
    got = (
        sb.table("social_posts").select("*")
        .eq("status", "pending").is_("discord_message_id", "null").execute()
    )
    assert [r["id"] for r in got.data] == ["a"]
