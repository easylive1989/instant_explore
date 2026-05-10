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
