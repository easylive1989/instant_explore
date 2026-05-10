# Daily Place Story — P1: Schema + 景點清單匯入 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 Supabase 兩張新表與 RLS、寫景點清單匯入 script，並把篩選過的世界遺產景點匯入資料庫，作為 P2 (cron job) 與 P3 (Flutter UI) 的基礎。

**Architecture:** 一個 Supabase migration 檔案處理 schema + RLS。一個獨立的 Python 一次性 script 從 Wikidata SPARQL 抓 World Heritage Sites，產出 CSV 給人工 review，再用 `\copy` 匯入。

**Tech Stack:** PostgreSQL (Supabase)、Supabase CLI、Python 3 + `requests` + `pytest`、Wikidata SPARQL endpoint。

**Source spec:** `docs/superpowers/specs/2026-05-10-daily-place-story-design.md`

---

## File Structure

```
supabase/
└── migrations/
    └── 20260510000000_create_daily_story_tables.sql   # NEW: tables + RLS

scripts/
└── daily_story_setup/                                  # NEW directory
    ├── README.md                                       # NEW: setup steps
    ├── requirements.txt                                # NEW: python deps
    ├── fetch_world_heritage_sites.py                   # NEW: SPARQL → CSV
    ├── test_fetch_world_heritage_sites.py              # NEW: pytest
    ├── verify_rls.sql                                  # NEW: RLS smoke test
    └── output/                                         # NEW (gitignored)
        ├── raw.csv                                     # script output
        └── filtered.csv                                # human-curated input
```

**檔案分工**：
- Migration 一個檔案就夠：兩張表都不大、RLS 也只有一個 policy，集中比較好讀
- Python 把抓取/解析/寫檔分開：`fetch_world_heritage_sites.py` 中拆成 `parse_sparql_response()`(純函式可測) 與 `fetch_and_write_csv()`(IO)
- 驗證 RLS 用 SQL script (`verify_rls.sql`)，不用引入 supabase-py 依賴
- `output/` 加進 `.gitignore`，避免大 CSV 進 repo

---

## Task 1: Migration 檔案 (schema + RLS)

**Files:**
- Create: `supabase/migrations/20260510000000_create_daily_story_tables.sql`

- [ ] **Step 1: 建立 migration 檔案**

```sql
-- Daily story places: master list (admin-curated via Supabase Dashboard)
create table public.daily_story_places (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  wikipedia_title_en text not null,
  country text not null,
  is_active boolean not null default true,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

-- Index for picking next unused active place
create index daily_story_places_pickable_idx
  on public.daily_story_places (is_active, used_at nulls first, created_at);

-- Daily stories: server writes one row per (date, language)
create table public.daily_stories (
  id uuid primary key default gen_random_uuid(),
  publish_date date not null,
  language text not null,
  place_id uuid not null references public.daily_story_places(id),
  place_name text not null,
  place_location text not null,
  era text not null,
  story text not null,
  image_url text,
  image_attribution text,
  wikipedia_url text not null,
  created_at timestamptz not null default now(),
  unique (publish_date, language)
);

create index daily_stories_publish_date_lang_idx
  on public.daily_stories (publish_date desc, language);

-- RLS
alter table public.daily_story_places enable row level security;
alter table public.daily_stories enable row level security;

-- daily_stories: anon and authenticated can read stories whose publish_date
-- has reached today in Asia/Taipei (so future-dated rows stay hidden)
create policy "anon can read published stories"
  on public.daily_stories for select to anon, authenticated
  using (publish_date <= ((now() at time zone 'Asia/Taipei')::date));

-- daily_story_places: no policy = no anon access. Service role bypasses RLS.
```

- [ ] **Step 2: 確認檔案存在且 SQL 沒有 syntax error 的「肉眼檢查」**

Run: `cat supabase/migrations/20260510000000_create_daily_story_tables.sql | head -10`
Expected: 顯示前面幾行（避免空檔或路徑寫錯）

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260510000000_create_daily_story_tables.sql
git commit -m "feat(daily-story): add tables and RLS for daily story feature"
```

---

## Task 2: 本機套用 migration + 驗證 schema

**前提：** local Docker 已啟動、Supabase CLI 已安裝。

**Files:**
- 沒有新檔案，純驗證

- [ ] **Step 1: 啟動 local Supabase**

Run: `supabase start` (從 repo 根目錄)
Expected: 列出 API URL / DB URL / anon key 等。如果已啟動會顯示「project already running」也 OK。

- [ ] **Step 2: 套用 migration**

Run: `supabase db reset`
Expected: 會清空本地 DB 然後重跑所有 migration，包含新建的這個。最後一行會顯示「Finished supabase db reset」。

- [ ] **Step 3: 驗證 schema 結構正確**

Run:
```bash
psql postgresql://postgres:postgres@localhost:54322/postgres -c "\d public.daily_story_places"
psql postgresql://postgres:postgres@localhost:54322/postgres -c "\d public.daily_stories"
```
Expected: 兩張表都顯示完整欄位、索引、RLS Enabled。

- [ ] **Step 4: 驗證 indexes 與 unique constraint 存在**

Run:
```bash
psql postgresql://postgres:postgres@localhost:54322/postgres -c "
SELECT indexname FROM pg_indexes
WHERE tablename IN ('daily_story_places', 'daily_stories')
  AND schemaname = 'public';"
```
Expected: 列出至少 4 個 index，包含 `daily_story_places_pickable_idx`、`daily_stories_publish_date_lang_idx` 與兩個 primary key、一個 unique constraint。

---

## Task 3: 驗證 RLS 行為（SQL smoke test）

**Files:**
- Create: `scripts/daily_story_setup/verify_rls.sql`

- [ ] **Step 1: 寫 verify_rls.sql**

```sql
-- Verify RLS on daily_story_places + daily_stories
-- Run with: psql <CONN_STR> -v ON_ERROR_STOP=1 -f verify_rls.sql

\echo '=== Setup: insert one place + two daily_stories rows ==='

-- service role can write
insert into public.daily_story_places (id, name, wikipedia_title_en, country)
values ('11111111-1111-1111-1111-111111111111', 'Test Place', 'Test_Place', 'Testland')
on conflict (id) do nothing;

insert into public.daily_stories
  (publish_date, language, place_id, place_name, place_location, era,
   story, wikipedia_url)
values
  -- past story: should be visible to anon
  (current_date - 1, 'en',
   '11111111-1111-1111-1111-111111111111',
   'Test', 'Testland', '1000 BCE',
   'Test story past',
   'https://en.wikipedia.org/wiki/Test_Place'),
  -- future story: should NOT be visible to anon
  (current_date + 1, 'en',
   '11111111-1111-1111-1111-111111111111',
   'Test future', 'Testland', '2000 CE',
   'Test story future',
   'https://en.wikipedia.org/wiki/Test_Place')
on conflict (publish_date, language) do nothing;

\echo '=== Test 1: anon should see ONLY published (past) stories ==='
set role anon;
select count(*) as visible_to_anon from public.daily_stories;
-- Expected: 1 (only the past story)

\echo '=== Test 2: anon CANNOT insert into daily_stories ==='
do $$
begin
  begin
    insert into public.daily_stories
      (publish_date, language, place_id, place_name, place_location, era,
       story, wikipedia_url)
    values (current_date, 'en',
            '11111111-1111-1111-1111-111111111111',
            'X', 'X', 'X', 'X',
            'https://example.com');
    raise exception 'FAIL: anon insert should have been blocked';
  exception
    when insufficient_privilege or others then
      raise notice 'PASS: anon insert blocked';
  end;
end $$;

\echo '=== Test 3: anon CANNOT read daily_story_places ==='
select count(*) as places_visible_to_anon from public.daily_story_places;
-- Expected: 0 (no policy = denied)

\echo '=== Cleanup ==='
reset role;
delete from public.daily_stories
  where place_id = '11111111-1111-1111-1111-111111111111';
delete from public.daily_story_places
  where id = '11111111-1111-1111-1111-111111111111';

\echo '=== ALL CHECKS DONE ==='
```

- [ ] **Step 2: 跑 verify_rls.sql**

Run:
```bash
psql postgresql://postgres:postgres@localhost:54322/postgres \
  -v ON_ERROR_STOP=1 \
  -f scripts/daily_story_setup/verify_rls.sql
```
Expected (重點檢查)：
- `visible_to_anon` 顯示 `1`
- 出現 `NOTICE: PASS: anon insert blocked`
- `places_visible_to_anon` 顯示 `0`
- 最後出現 `ALL CHECKS DONE` 而沒有 error

如果任何一行失敗，回去檢查 migration RLS 設定。

- [ ] **Step 3: Commit**

```bash
git add scripts/daily_story_setup/verify_rls.sql
git commit -m "test(daily-story): add RLS smoke test SQL script"
```

---

## Task 4: 建立 Python script 骨架 + 依賴

**Files:**
- Create: `scripts/daily_story_setup/requirements.txt`
- Create: `scripts/daily_story_setup/README.md`
- Create: `scripts/daily_story_setup/.gitignore`

- [ ] **Step 1: 建 requirements.txt**

```
requests>=2.32,<3
pytest>=8,<9
```

- [ ] **Step 2: 建 .gitignore**

```
output/
__pycache__/
.pytest_cache/
.venv/
```

- [ ] **Step 3: 建 README.md（簡要說明）**

```markdown
# Daily Story — One-time Setup

匯入 World Heritage Sites 到 `daily_story_places` 表。一次性流程。

## 前置

```bash
cd scripts/daily_story_setup
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 流程

1. 跑 `python fetch_world_heritage_sites.py` → 產生 `output/raw.csv`
2. 人工 review `output/raw.csv` → 篩選後另存為 `output/filtered.csv`
3. 跑 `psql <CONN_STR> -c "\copy public.daily_story_places(name, wikipedia_title_en, country) FROM 'output/filtered.csv' WITH (FORMAT csv, HEADER true)"`
4. 用 SQL 確認 row 數合理：`SELECT count(*) FROM public.daily_story_places;`
```

- [ ] **Step 4: 確認 venv 可建、套件可裝**

Run:
```bash
cd scripts/daily_story_setup && python3 -m venv .venv && \
  source .venv/bin/activate && \
  pip install -q -r requirements.txt && \
  python -c "import requests; import pytest; print('ok')"
```
Expected: 印出 `ok`。

- [ ] **Step 5: Commit**

```bash
git add scripts/daily_story_setup/requirements.txt \
        scripts/daily_story_setup/README.md \
        scripts/daily_story_setup/.gitignore
git commit -m "chore(daily-story): scaffold setup script (venv, deps, readme)"
```

---

## Task 5: 寫 SPARQL 解析的純函式 + 測試 (TDD)

**Files:**
- Create: `scripts/daily_story_setup/fetch_world_heritage_sites.py`
- Create: `scripts/daily_story_setup/test_fetch_world_heritage_sites.py`

- [ ] **Step 1: 寫失敗的 test**

```python
# test_fetch_world_heritage_sites.py
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
        ("Acropolis of Athens", "Acropolis_of_Athens", "Greece"),
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
                    # URL-encoded title
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
```

- [ ] **Step 2: 跑 test 確認失敗（function 還沒寫）**

Run: `cd scripts/daily_story_setup && source .venv/bin/activate && pytest test_fetch_world_heritage_sites.py -v`
Expected: ImportError / ModuleNotFoundError 或 `AttributeError: module 'fetch_world_heritage_sites' has no attribute 'parse_sparql_response'`

- [ ] **Step 3: 寫最小實作讓 test 過**

```python
# fetch_world_heritage_sites.py
"""Fetch World Heritage Sites from Wikidata SPARQL and write CSV.

One-shot setup script. Run with `python fetch_world_heritage_sites.py`.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path
from typing import Iterable
from urllib.parse import unquote

import requests

WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"

SPARQL_QUERY = """
SELECT ?item ?itemLabel ?countryLabel ?enwiki WHERE {
  ?item wdt:P1435 wd:Q9259.
  OPTIONAL { ?item wdt:P17 ?country. }
  OPTIONAL {
    ?enwiki schema:about ?item ;
            schema:isPartOf <https://en.wikipedia.org/> .
  }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
}
ORDER BY ?itemLabel
"""

# Wikidata properties used:
#   P1435 = heritage designation (use this to filter "is a UNESCO WHS")
#   P17   = country
#   Q9259 = World Heritage Site (the designation itself)

USER_AGENT = (
    "lorescape-daily-story-setup/1.0 "
    "(https://github.com/easylive1989/instant_explore)"
)

OUTPUT_PATH = Path(__file__).parent / "output" / "raw.csv"


def parse_sparql_response(data: dict) -> list[tuple[str, str, str]]:
    """Extract (name, wikipedia_title_en, country) from SPARQL JSON.

    Skips rows without enwiki sitelink or country (incomplete entries).
    Returns title with spaces (URL-decoded) — Wikipedia REST API accepts both.
    """
    rows = []
    for binding in data.get("results", {}).get("bindings", []):
        if "enwiki" not in binding or "countryLabel" not in binding:
            continue
        if "itemLabel" not in binding:
            continue
        name = binding["itemLabel"]["value"]
        country = binding["countryLabel"]["value"]
        wiki_url = binding["enwiki"]["value"]
        # https://en.wikipedia.org/wiki/<title> → <title>, URL-decoded with spaces
        title = unquote(wiki_url.rsplit("/", 1)[-1]).replace("_", " ")
        rows.append((name, title, country))
    return rows


def fetch_sparql() -> dict:
    response = requests.get(
        WIKIDATA_SPARQL_URL,
        params={"query": SPARQL_QUERY, "format": "json"},
        headers={"User-Agent": USER_AGENT, "Accept": "application/sparql-results+json"},
        timeout=120,
    )
    response.raise_for_status()
    return response.json()


def write_csv(rows: Iterable[tuple[str, str, str]], path: Path) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["name", "wikipedia_title_en", "country"])
        for row in rows:
            writer.writerow(row)
            count += 1
    return count


def main() -> int:
    print(f"Fetching SPARQL from {WIKIDATA_SPARQL_URL}...")
    data = fetch_sparql()
    rows = parse_sparql_response(data)
    written = write_csv(rows, OUTPUT_PATH)
    print(f"Wrote {written} rows to {OUTPUT_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

注意：因為 `Mont-Saint-Michel and its Bay` 的測試裡用了 `%20` 空格，URL-decode 後是空格——程式中先 `unquote()` 再 `replace("_", " ")`，順序很重要：URL 中既有 `%20`（空格）也有 `_`（Wikipedia 慣例分隔），都會被轉成空格。

- [ ] **Step 4: 跑 test 確認通過**

Run: `cd scripts/daily_story_setup && source .venv/bin/activate && pytest test_fetch_world_heritage_sites.py -v`
Expected: 3 passed

- [ ] **Step 5: Commit**

```bash
git add scripts/daily_story_setup/fetch_world_heritage_sites.py \
        scripts/daily_story_setup/test_fetch_world_heritage_sites.py
git commit -m "feat(daily-story): add Wikidata SPARQL fetcher for World Heritage Sites"
```

---

## Task 6: 跑 script 抓真實資料 + 人工 review

**注意：** 這個 task 包含人工步驟。完成 Step 4 後讓使用者實際看 CSV、決定要保留哪些景點。

**Files:**
- 沒有新檔案；產出 `scripts/daily_story_setup/output/raw.csv` 與 `filtered.csv`（gitignored）

- [ ] **Step 1: 跑 fetch script**

Run:
```bash
cd scripts/daily_story_setup && source .venv/bin/activate && \
  python fetch_world_heritage_sites.py
```
Expected: 印出 `Wrote N rows to ...`，N 應該是 800-1500 之間（UNESCO 約 1200+ 個世界遺產）。

- [ ] **Step 2: 確認 CSV 內容看起來正常**

Run:
```bash
head -10 scripts/daily_story_setup/output/raw.csv
wc -l scripts/daily_story_setup/output/raw.csv
```
Expected: 第一行是 header `name,wikipedia_title_en,country`，後面是合理的景點名稱與國家。

- [ ] **Step 3: 把 raw.csv 複製成 filtered.csv 並讓使用者人工 review**

Run:
```bash
cp scripts/daily_story_setup/output/raw.csv scripts/daily_story_setup/output/filtered.csv
```

然後通知使用者：
> "raw.csv 有 N 筆。請打開 `scripts/daily_story_setup/output/filtered.csv`，刪除你不想加入每日故事的景點（例如純自然遺產、敏感地點、或你覺得歷史故事素材不足的）。完成後告訴我繼續。"

**WAIT** for user confirmation before proceeding to Task 7.

---

## Task 7: 匯入 CSV 到 local Supabase + 驗證

**Files:**
- 沒有新檔案

- [ ] **Step 1: 匯入 filtered.csv**

Run:
```bash
psql postgresql://postgres:postgres@localhost:54322/postgres -c "
\copy public.daily_story_places(name, wikipedia_title_en, country)
FROM 'scripts/daily_story_setup/output/filtered.csv'
WITH (FORMAT csv, HEADER true);"
```
Expected: 印出 `COPY <number>`，數字等於 filtered.csv 的 row 數（不算 header）。

- [ ] **Step 2: 驗證 row 數**

Run:
```bash
psql postgresql://postgres:postgres@localhost:54322/postgres -c \
  "SELECT count(*) FROM public.daily_story_places;"
```
Expected: 跟 Step 1 一樣的數字。

- [ ] **Step 3: 抽樣檢查資料**

Run:
```bash
psql postgresql://postgres:postgres@localhost:54322/postgres -c \
  "SELECT name, country FROM public.daily_story_places ORDER BY random() LIMIT 5;"
```
Expected: 5 筆隨機景點，看起來都是合理的世界遺產。

- [ ] **Step 4: 驗證 picking query 可用**

模擬 P2 (cron job) 會用的 query：

Run:
```bash
psql postgresql://postgres:postgres@localhost:54322/postgres -c "
SELECT id, wikipedia_title_en
FROM public.daily_story_places
WHERE is_active = true AND used_at IS NULL
ORDER BY created_at
LIMIT 1;"
```
Expected: 回傳 1 筆景點（這是 P2 的 Step 1）。

---

## Task 8: 推 migration 到 remote Supabase + 匯入 production CSV

**注意：** 這個 task 影響 production database。執行前確認 spec 與本機驗證都 OK。

- [ ] **Step 1: 確認當前 supabase project 連接的是 production**

Run: `supabase projects list 2>&1 | head -10`
Expected: 確認 linked project ref 是 `kypcxxjqsinamcqrjeog`（spec 中 production 的 ref）。

- [ ] **Step 2: 推 migration**

Run: `supabase db push`
Expected: 顯示「pending migration: 20260510000000_create_daily_story_tables.sql」並成功 push。如果有 confirmation prompt，回 `Y`。

- [ ] **Step 3: 用 Supabase Dashboard 或 psql 連線 production 確認 schema 存在**

如果有 production 連線字串（建議透過 Supabase Dashboard → Project Settings → Database → Connection string）：

Run:
```bash
psql "<production_conn_str>" -c "\d public.daily_story_places"
psql "<production_conn_str>" -c "\d public.daily_stories"
```
Expected: 兩張表都存在。

或：用 Supabase Dashboard 的 Table Editor 確認兩張表出現在 public schema。

- [ ] **Step 4: 匯入 filtered.csv 到 production**

**選擇 A** — psql `\copy`（如果有 production 連線字串）：
```bash
psql "<production_conn_str>" -c "
\copy public.daily_story_places(name, wikipedia_title_en, country)
FROM 'scripts/daily_story_setup/output/filtered.csv'
WITH (FORMAT csv, HEADER true);"
```

**選擇 B** — 用 Supabase Dashboard 的「Insert → Import data from CSV」UI 上傳。

Expected: row 數跟本機一致。

- [ ] **Step 5: production 抽樣驗證**

Run（或在 Dashboard SQL Editor）：
```sql
SELECT count(*) FROM public.daily_story_places;
SELECT name, country FROM public.daily_story_places ORDER BY random() LIMIT 5;
```
Expected: count 跟本機一致；抽樣景點合理。

---

## Self-Review Checklist

實作完整個 P1 之後，逐項確認：

- [ ] **Spec 對齊**：spec 中提到的兩張表、所有欄位、index、unique constraint、RLS policy 都有實作？
- [ ] **RLS 行為**：anon 只能讀過去的故事、不能寫、不能讀景點主表 — `verify_rls.sql` 全部通過？
- [ ] **景點清單**：production 有實際 row 數，且抽樣資料合理？
- [ ] **下一步準備**：P2 cron job 可以用 `wikipedia_title_en` 抓 Wikipedia、可以用 `is_active = true AND used_at IS NULL` 挑景點？
- [ ] **無 placeholder**：plan 中所有 step 都有具體 code/command/expected output？

---

## 關於 P2 / P3 的銜接

完成 P1 之後：
- **P2 (backend cron job)** 可以開始：schema 與資料都齊備，cron job 只需要做 SELECT/UPDATE/INSERT
- **P3 (Flutter UI)** 也可以開始：anon SELECT 已驗證可用，初期可手動在 Supabase 插一兩筆假的 `daily_stories` 來開發 UI（不必等 P2 完成）
