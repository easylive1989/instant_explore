# Daily Story「探索更多故事」→ 同地點生成頁 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓每日故事詳情頁的「探索更多故事」CTA 導向 `/config` 生成頁，針對同一篇故事的地點生成更多歷史故事 hooks。

**Architecture:** 在 `daily_story_places` 新增 `wikidata_id` 欄並補資料；前端透過既有 join 讀出，組成帶 `wikidata:Qxxx` id 的 `Place`（對映放在 `app/` 層以維持 feature 隔離）後 `push('/config')`。缺 id 時隱藏 CTA。每日生成 job 不動。

**Tech Stack:** Flutter / Dart（前端、go_router、Riverpod）、Supabase（Postgres）、Python（seed / backfill 腳本，pytest + requests-mock）。

設計 spec：`docs/superpowers/specs/2026-05-31-daily-story-more-stories-same-place-design.md`

---

## File Structure

**新增**
- `supabase/migrations/20260531000000_add_wikidata_id_to_daily_story_places.sql` — 加欄位
- `scripts/daily_story_setup/backfill_wikidata_ids.py` — 一次性 backfill
- `scripts/daily_story_setup/test_fetch_world_heritage_sites.py` — seed parse 測試
- `scripts/daily_story_setup/test_backfill_wikidata_ids.py` — backfill resolver 測試
- `frontend/lib/app/utils/daily_story_config_launcher.dart` — `DailyStory → Place` 對映 + 導航
- `frontend/test/app/utils/daily_story_config_launcher_test.dart` — 對映單元測試

**修改**
- `scripts/daily_story_setup/fetch_world_heritage_sites.py` — 保留 Q-id
- `scripts/daily_story_setup/README.md` — `\copy` 欄位
- `scripts/daily_story_setup/requirements.txt` — 加測試相依
- `frontend/lib/features/daily_story/domain/models/daily_story.dart` — 加 `wikidataId`
- `frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart` — `_select` + mapper
- `frontend/test/features/daily_story/data/supabase_daily_story_repository_test.dart` — mapper 測試
- `frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart` — CTA 顯示 + 導航
- `frontend/test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart` — widget 測試

任務順序：T1→T6 為建議序；T1–T3（後端）與 T4–T6（前端）彼此獨立，前端 T4 必須先於 T5/T6。

---

### Task 1: DB migration — `daily_story_places.wikidata_id`

**Files:**
- Create: `supabase/migrations/20260531000000_add_wikidata_id_to_daily_story_places.sql`

- [ ] **Step 1: 確認時間戳在最新 migration 之後**

Run: `ls supabase/migrations | sort | tail -3`
Expected: 列出的最新檔名時間戳 < `20260531000000`。若已有 ≥ 此時間戳的檔案，將新檔名改為比它更大的時間戳。

- [ ] **Step 2: 建立 migration 檔**

```sql
-- Add a Wikidata Q-id to each daily-story place so the App can build a
-- `wikidata:`-prefixed Place and route the "explore more stories" CTA into
-- the on-demand story generation page (/config) for the SAME place.
--
-- Nullable: existing rows stay NULL until backfilled; the App hides the CTA
-- when wikidata_id is missing.

alter table public.daily_story_places
  add column wikidata_id text;
```

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260531000000_add_wikidata_id_to_daily_story_places.sql
git commit -m "feat(db): add wikidata_id to daily_story_places"
```

---

### Task 2: Seed 腳本保留 Q-id

`fetch_world_heritage_sites.py` 目前丟棄 SPARQL 的 `?item`（entity URI）。改成擷取 `Qxxx` 並寫入 CSV。

**Files:**
- Modify: `scripts/daily_story_setup/fetch_world_heritage_sites.py`
- Modify: `scripts/daily_story_setup/requirements.txt`
- Modify: `scripts/daily_story_setup/README.md`
- Test: `scripts/daily_story_setup/test_fetch_world_heritage_sites.py`

- [ ] **Step 1: 加測試相依**

在 `scripts/daily_story_setup/requirements.txt` 末尾追加（保留既有內容）：

```
pytest>=8,<9
requests-mock>=1.12,<2
```

- [ ] **Step 2: 寫失敗測試**

Create `scripts/daily_story_setup/test_fetch_world_heritage_sites.py`:

```python
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
```

- [ ] **Step 3: 跑測試確認失敗**

Run: `cd scripts/daily_story_setup && python -m pytest test_fetch_world_heritage_sites.py -v`
Expected: FAIL — `parse_sparql_response` 目前回傳 3-tuple `(name, title, country)`，無 qid。

- [ ] **Step 4: 改 `parse_sparql_response`、`write_csv` 與型別**

在 `scripts/daily_story_setup/fetch_world_heritage_sites.py`：

把 `parse_sparql_response` 整個函式替換為：

```python
def parse_sparql_response(data: dict) -> list[tuple[str, str, str, str]]:
    """Extract (wikidata_id, name, wikipedia_title_en, country) from SPARQL JSON.

    Skips rows without enwiki sitelink or country (incomplete entries).
    Returns title with spaces (URL-decoded, underscores normalised to spaces)
    — Wikipedia REST API accepts both forms; spaces is canonical.
    """
    rows = []
    for binding in data.get("results", {}).get("bindings", []):
        if "enwiki" not in binding or "countryLabel" not in binding:
            continue
        if "itemLabel" not in binding:
            continue
        qid = binding["item"]["value"].rsplit("/", 1)[-1]
        name = binding["itemLabel"]["value"]
        country = binding["countryLabel"]["value"]
        wiki_url = binding["enwiki"]["value"]
        # https://en.wikipedia.org/wiki/<title> → <title>, URL-decoded with spaces
        title = unquote(wiki_url.rsplit("/", 1)[-1]).replace("_", " ")
        rows.append((qid, name, title, country))
    return rows
```

把 `write_csv` 的簽章與 header 列替換為：

```python
def write_csv(rows: Iterable[tuple[str, str, str, str]], path: Path) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["wikidata_id", "name", "wikipedia_title_en", "country"])
        for row in rows:
            writer.writerow(row)
            count += 1
    return count
```

- [ ] **Step 5: 跑測試確認通過**

Run: `cd scripts/daily_story_setup && python -m pytest test_fetch_world_heritage_sites.py -v`
Expected: PASS（2 passed）

- [ ] **Step 6: 更新 README 的 `\copy` 欄位**

在 `scripts/daily_story_setup/README.md` 把流程第 3 步替換為：

```markdown
3. 跑 `psql <CONN_STR> -c "\copy public.daily_story_places(wikidata_id, name, wikipedia_title_en, country) FROM 'output/filtered.csv' WITH (FORMAT csv, HEADER true)"`
```

- [ ] **Step 7: Commit**

```bash
git add scripts/daily_story_setup/fetch_world_heritage_sites.py \
        scripts/daily_story_setup/test_fetch_world_heritage_sites.py \
        scripts/daily_story_setup/requirements.txt \
        scripts/daily_story_setup/README.md
git commit -m "feat(setup): keep wikidata qid in WHS seed script"
```

---

### Task 3: 一次性 backfill 腳本

針對 `wikidata_id IS NULL` 的列，用 `wikipedia_title_en` 透過 MediaWiki `pageprops.wikibase_item` 反查 Q-id 後更新。

**Files:**
- Create: `scripts/daily_story_setup/backfill_wikidata_ids.py`
- Test: `scripts/daily_story_setup/test_backfill_wikidata_ids.py`

- [ ] **Step 1: 寫失敗測試**

Create `scripts/daily_story_setup/test_backfill_wikidata_ids.py`:

```python
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
    assert sent["titles"] == ["colosseum"]


def test_resolve_returns_none_when_no_pageprops():
    payload = {"query": {"pages": {"-1": {"title": "Nope", "missing": ""}}}}
    with requests_mock.Mocker() as m:
        m.get(API, json=payload)
        assert resolve_qid_from_title("Nope") is None
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd scripts/daily_story_setup && python -m pytest test_backfill_wikidata_ids.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'backfill_wikidata_ids'`

- [ ] **Step 3: 實作腳本**

Create `scripts/daily_story_setup/backfill_wikidata_ids.py`:

```python
"""Backfill daily_story_places.wikidata_id from wikipedia_title_en.

One-shot maintenance script. Resolves each place still missing a
`wikidata_id` via the MediaWiki `pageprops.wikibase_item` API, then updates
the row. Rows that can't be resolved are logged and left untouched.

Env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (service-role key required to
update rows under RLS).

Run: `python backfill_wikidata_ids.py`
"""

from __future__ import annotations

import os
import sys

import requests

WIKIPEDIA_API_URL = "https://en.wikipedia.org/w/api.php"
USER_AGENT = (
    "lorescape-daily-story-setup/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)


def resolve_qid_from_title(title: str) -> str | None:
    """Return the Wikidata Q-id for an enwiki page title, or None."""
    response = requests.get(
        WIKIPEDIA_API_URL,
        params={
            "action": "query",
            "prop": "pageprops",
            "ppprop": "wikibase_item",
            "redirects": "1",
            "titles": title,
            "format": "json",
        },
        headers={"User-Agent": USER_AGENT},
        timeout=30,
    )
    response.raise_for_status()
    pages = response.json().get("query", {}).get("pages", {})
    for page in pages.values():
        qid = page.get("pageprops", {}).get("wikibase_item")
        if qid:
            return qid
    return None


def _create_client():
    from supabase import create_client

    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    return create_client(url, key)


def main() -> int:
    client = _create_client()
    response = (
        client.table("daily_story_places")
        .select("id, wikipedia_title_en")
        .is_("wikidata_id", "null")
        .execute()
    )
    rows = response.data or []
    print(f"{len(rows)} places missing wikidata_id")

    resolved = 0
    for row in rows:
        title = row["wikipedia_title_en"]
        qid = resolve_qid_from_title(title)
        if qid is None:
            print(f"  UNRESOLVED: {title!r}")
            continue
        client.table("daily_story_places").update({"wikidata_id": qid}).eq(
            "id", row["id"]
        ).execute()
        resolved += 1
        print(f"  {title!r} -> {qid}")

    print(f"Backfilled {resolved}/{len(rows)} places")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: 跑測試確認通過**

Run: `cd scripts/daily_story_setup && python -m pytest test_backfill_wikidata_ids.py -v`
Expected: PASS（2 passed）

- [ ] **Step 5: Commit**

```bash
git add scripts/daily_story_setup/backfill_wikidata_ids.py \
        scripts/daily_story_setup/test_backfill_wikidata_ids.py
git commit -m "feat(setup): add wikidata_id backfill script"
```

> 執行（非本計畫自動跑，待 migration 上線後手動）：
> `cd scripts/daily_story_setup && SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... python backfill_wikidata_ids.py`

---

### Task 4: 前端 model + `_select` + mapper

**Files:**
- Modify: `frontend/lib/features/daily_story/domain/models/daily_story.dart`
- Modify: `frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart`
- Test: `frontend/test/features/daily_story/data/supabase_daily_story_repository_test.dart`

- [ ] **Step 1: 寫失敗測試**

在 `supabase_daily_story_repository_test.dart` 的 `group(...)` 內，最後一個 `test(...)` 之後加入：

```dart
    test(
      'given a place join with wikidata_id, '
      'when parsed, '
      'then DailyStory.wikidataId carries it',
      () {
        final row = <String, dynamic>{
          'publish_date': '2026-05-25',
          'language': 'zh-TW',
          'place_name': '羅馬競技場',
          'place_location': '義大利羅馬',
          'era': '公元 70-80 年',
          'story': 'x',
          'image_url': null,
          'wikipedia_url': 'https://zh.wikipedia.org/wiki/Colosseum',
          'daily_story_places': {
            'card_location_en': 'COLOSSEUM',
            'card_city_ch': '羅馬',
            'card_city_en': 'Rome',
            'wikidata_id': 'Q10285',
          },
        };
        final story = SupabaseDailyStoryRepository.rowToStory(row);
        expect(story.wikidataId, 'Q10285');
      },
    );

    test(
      'given a row without place join, '
      'when parsed, '
      'then DailyStory.wikidataId is null',
      () {
        final row = <String, dynamic>{
          'publish_date': '2026-05-25',
          'language': 'en',
          'place_name': 'Colosseum',
          'place_location': 'Rome, Italy',
          'era': '70-80 CE',
          'story': 'x',
          'image_url': null,
          'wikipedia_url': 'https://en.wikipedia.org/wiki/Colosseum',
        };
        final story = SupabaseDailyStoryRepository.rowToStory(row);
        expect(story.wikidataId, isNull);
      },
    );
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd frontend && fvm flutter test test/features/daily_story/data/supabase_daily_story_repository_test.dart`
Expected: FAIL — `DailyStory` 沒有 `wikidataId` getter（編譯錯誤）。

- [ ] **Step 3: 在 `DailyStory` 加欄位**

在 `daily_story.dart`：

在欄位區（`cardCityEn` 宣告之後）加入：

```dart
  /// Wikidata Q-id of the place (e.g. "Q10285"), joined from
  /// `daily_story_places`. Null when the place hasn't been resolved yet;
  /// the App hides the "explore more stories" CTA in that case.
  final String? wikidataId;
```

在 constructor 參數列（`this.cardCityEn,` 之後）加入：

```dart
    this.wikidataId,
```

在 `props` 清單（`cardCityEn,` 之後）加入：

```dart
    wikidataId,
```

- [ ] **Step 4: 在 mapper 與 `_select` 讀欄位**

在 `supabase_daily_story_repository.dart`：

把 `_select` 常數替換為：

```dart
  static const _select =
      '*, daily_story_places!left(card_location_en, card_city_ch, '
      'card_city_en, wikidata_id)';
```

在 `rowToStory` 的 `return DailyStory(` 內，於 `cardCityEn: place?['card_city_en'] as String?,` 之後加入：

```dart
      wikidataId: place?['wikidata_id'] as String?,
```

- [ ] **Step 5: 跑測試確認通過**

Run: `cd frontend && fvm flutter test test/features/daily_story/data/supabase_daily_story_repository_test.dart`
Expected: PASS（全部 test 通過）

- [ ] **Step 6: 靜態分析**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/daily_story/domain/models/daily_story.dart lib/features/daily_story/data/supabase_daily_story_repository.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/daily_story/domain/models/daily_story.dart \
        frontend/lib/features/daily_story/data/supabase_daily_story_repository.dart \
        frontend/test/features/daily_story/data/supabase_daily_story_repository_test.dart
git commit -m "feat(daily-story): map wikidata_id from place join"
```

---

### Task 5: App 層 `DailyStory → Place` 對映 + launcher

放在 `app/` 層以避免 daily_story feature 依賴 explore feature 的 `Place`。

**Files:**
- Create: `frontend/lib/app/utils/daily_story_config_launcher.dart`
- Test: `frontend/test/app/utils/daily_story_config_launcher_test.dart`

- [ ] **Step 1: 寫失敗測試（純對映函式）**

Create `frontend/test/app/utils/daily_story_config_launcher_test.dart`:

```dart
import 'package:context_app/app/utils/daily_story_config_launcher.dart';
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:flutter_test/flutter_test.dart';

DailyStory _story({String? wikidataId, String? imageUrl}) => DailyStory(
  publishDate: DateTime(2026, 5, 25),
  language: 'zh-TW',
  placeName: '羅馬競技場',
  placeLocation: '義大利羅馬',
  era: '公元 70-80 年',
  story: 'x',
  imageUrl: imageUrl,
  wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
  wikidataId: wikidataId,
);

void main() {
  group('placeFromDailyStory', () {
    test(
      'given a story with wikidataId, '
      'when mapped, '
      'then Place.id is wikidata-prefixed with name/address/category',
      () {
        final place = placeFromDailyStory(_story(wikidataId: 'Q10285'));

        expect(place, isNotNull);
        expect(place!.id, 'wikidata:Q10285');
        expect(place.name, '羅馬競技場');
        expect(place.address, '義大利羅馬');
        expect(place.category, PlaceCategory.historicalCultural);
      },
    );

    test(
      'given a story with an imageUrl, '
      'when mapped, '
      'then the Place has one photo using that url',
      () {
        final place = placeFromDailyStory(
          _story(wikidataId: 'Q10285', imageUrl: 'https://x/y.jpg'),
        );

        expect(place!.photos, hasLength(1));
        expect(place.primaryPhoto?.url, 'https://x/y.jpg');
      },
    );

    test(
      'given a story without imageUrl, '
      'when mapped, '
      'then the Place has no photos',
      () {
        final place = placeFromDailyStory(_story(wikidataId: 'Q10285'));
        expect(place!.photos, isEmpty);
      },
    );

    test(
      'given a story without wikidataId, '
      'when mapped, '
      'then it returns null',
      () {
        expect(placeFromDailyStory(_story()), isNull);
      },
    );
  });
}
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd frontend && fvm flutter test test/app/utils/daily_story_config_launcher_test.dart`
Expected: FAIL — 找不到 `daily_story_config_launcher.dart` / `placeFromDailyStory`。

- [ ] **Step 3: 實作對映 + launcher**

Create `frontend/lib/app/utils/daily_story_config_launcher.dart`:

```dart
import 'package:context_app/features/daily_story/domain/models/daily_story.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Builds an explore [Place] from a [DailyStory] so the daily-story screen can
/// reuse the on-demand generation page (`/config`) for the SAME place.
///
/// Lives in `app/` because it bridges two features (daily_story → explore);
/// features must not depend on each other directly.
///
/// Returns null when [DailyStory.wikidataId] is missing — generation requires
/// a `wikidata:`-prefixed id, so the caller should hide the CTA instead.
Place? placeFromDailyStory(DailyStory story) {
  final wikidataId = story.wikidataId;
  if (wikidataId == null) return null;
  final imageUrl = story.imageUrl;
  return Place(
    id: 'wikidata:$wikidataId',
    name: story.placeName,
    address: story.placeLocation,
    // Coordinates are unused by hook/narration generation and by the
    // /config screen UI; a placeholder keeps the value object valid.
    location: const PlaceLocation(latitude: 0, longitude: 0),
    tags: const [],
    photos: imageUrl != null
        ? [
            PlacePhoto(
              url: imageUrl,
              width: 0,
              height: 0,
              attributions: const [],
            ),
          ]
        : const [],
    // Daily story places are UNESCO World Heritage Sites.
    category: PlaceCategory.historicalCultural,
  );
}

/// Navigates to the on-demand generation page for the daily story's place.
///
/// No-op when the place can't be built (missing wikidata id) — callers should
/// already gate on that, this is a defensive guard.
void launchSamePlaceStories(BuildContext context, DailyStory story) {
  final place = placeFromDailyStory(story);
  if (place == null) return;
  context.push('/config', extra: place);
}
```

- [ ] **Step 4: 跑測試確認通過**

Run: `cd frontend && fvm flutter test test/app/utils/daily_story_config_launcher_test.dart`
Expected: PASS（4 passed）

- [ ] **Step 5: 靜態分析**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/app/utils/daily_story_config_launcher.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/app/utils/daily_story_config_launcher.dart \
        frontend/test/app/utils/daily_story_config_launcher_test.dart
git commit -m "feat(app): map DailyStory to Place for /config launch"
```

---

### Task 6: 詳情頁導航 + CTA 顯示

CTA 只在 `wikidataId != null` 時顯示，點擊改為 `launchSamePlaceStories`。

**Files:**
- Modify: `frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart`
- Test: `frontend/test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart`

- [ ] **Step 1: 改 widget 測試**

在 `daily_story_detail_screen_test.dart`：

1) 補一個帶 `wikidataId` 的 helper，放在 `_cardStory()` 之後：

```dart
DailyStory _cardStoryWithWikidata() => DailyStory(
  publishDate: DateTime(2026, 5, 11),
  language: 'zh-TW',
  placeName: '羅馬競技場',
  placeLocation: '義大利羅馬',
  era: '公元 70-80 年',
  story: 'p1\n\np2\n\np3',
  imageUrl: null,
  wikipediaUrl: 'https://zh.wikipedia.org/wiki/Colosseum',
  cardTitle: '血腥的盛宴',
  cardTitleSub: '從石灰岩堆砌的命運舞台',
  cardParagraphs: const ['p1...', 'p2...', 'p3...'],
  wikidataId: 'Q10285',
);
```

2) 把既有 `'... then it navigates to the explore tab (/?tab=explore)'` 測試整段替換為下面兩個測試：

```dart
    testWidgets(
      'given a story with wikidataId, when the user taps 探索更多故事, '
      'then it navigates to /config with a wikidata-prefixed Place',
      (tester) async {
        Object? configExtra;
        await pumpRouterApp(
          tester,
          initialLocation: '/daily-story/detail',
          initialExtra: _cardStoryWithWikidata(),
          routes: [
            GoRoute(
              path: '/daily-story/detail',
              builder: (_, state) =>
                  DailyStoryDetailScreen(story: state.extra as DailyStory),
            ),
            GoRoute(
              path: '/config',
              builder: (_, state) {
                configExtra = state.extra;
                return const Scaffold(body: Center(child: Text('config-stub')));
              },
            ),
          ],
        );

        final cta = find.text('daily_story.explore_more');
        expect(cta, findsOneWidget);
        await tester.ensureVisible(cta);
        await tester.pumpAndSettle();
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(find.text('config-stub'), findsOneWidget);
        expect(configExtra, isA<Place>());
        expect((configExtra! as Place).id, 'wikidata:Q10285');
      },
    );

    testWidgets(
      'given a story without wikidataId, when the screen renders, '
      'then the 探索更多故事 CTA is hidden',
      (tester) async {
        await _pumpDetail(tester, story: _cardStory());

        expect(find.text('daily_story.explore_more'), findsNothing);
      },
    );
```

3) 在檔案頂端 import 區加入（供上面的 `Place` 型別使用）：

```dart
import 'package:context_app/features/explore/domain/models/place.dart';
```

- [ ] **Step 2: 跑測試確認失敗**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart`
Expected: FAIL — 目前 CTA 永遠顯示且導向 `/?tab=explore`，無 `/config`；「hidden」測試也會失敗（CTA 仍出現）。

- [ ] **Step 3: 改詳情頁 CTA 顯示與導航**

在 `daily_story_detail_screen.dart`：

1) 把 import 區的 `go_router` import 之後加入：

```dart
import 'package:context_app/app/utils/daily_story_config_launcher.dart';
```

2) 移除 `_exploreMore` 方法（連同其上方兩行註解）：

```dart
  /// Takes the reader to the Explore tab to discover places and generate
  /// more stories.
  void _exploreMore(BuildContext context) => context.go('/?tab=explore');
```

3) 把 `build` 方法整段替換為：

```dart
  @override
  Widget build(BuildContext context) {
    // Only offer "explore more stories" when the place can be resolved to a
    // wikidata-prefixed Place; generation needs it. Otherwise hide the CTA.
    final onExploreMore = story.wikidataId != null
        ? () => launchSamePlaceStories(context, story)
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(story.placeName)),
      body: story.hasCardLayout
          ? CardLayoutBody(story: story, onExploreMore: onExploreMore)
          : _LegacyLayoutBody(story: story, onExploreMore: onExploreMore),
    );
  }
```

4) 移除現在未使用的 `go_router` import（若 `context.go` 已無其他使用者）。先確認：

Run: `cd frontend && grep -n "context.go\|GoRouter\|context.push" lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart`
Expected: 無 `context.go` / `context.push` 直接呼叫（導航已移到 launcher）。若如此，刪除 `import 'package:go_router/go_router.dart';`。

- [ ] **Step 4: 跑測試確認通過**

Run: `cd frontend && fvm flutter test test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart`
Expected: PASS（全部 test 通過，含 navigate-to-/config 與 hidden-CTA）

- [ ] **Step 5: 靜態分析**

Run: `cd frontend && fvm flutter analyze --fatal-infos lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart`
Expected: `No issues found!`（無 unused import 警告）

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/daily_story/presentation/screens/daily_story_detail_screen.dart \
        frontend/test/features/daily_story/presentation/screens/daily_story_detail_screen_test.dart
git commit -m "feat(daily-story): explore-more CTA opens /config for same place"
```

---

## 完成後驗證

- [ ] 全前端測試：`cd frontend && fvm flutter test`，預期全綠。
- [ ] 全前端分析：`cd frontend && fvm flutter analyze --fatal-infos`，預期 `No issues found!`。
- [ ] 腳本測試：`cd scripts/daily_story_setup && python -m pytest -v`，預期全綠。
- [ ] 手動（待 migration 部署 + backfill 跑完後）：開一篇有 `wikidata_id` 的每日故事 → 點「探索更多故事」→ 進到 `/config` 看到同地點的故事 hooks。
```
