# Narration 多源故事 Pipeline 設計

**Date**: 2026-05-29
**Status**: Draft — awaiting user review
**Scope**: 把 on-demand narration (`/api/hooks`、`/api/narration`) 的單源英文 Wikipedia 流程改成以 Wikidata Q-id 為錨點的多源 pipeline，解掉中文地名 + 英文 wiki 體系的 contract bug

---

## 1. 背景與動機

使用者打開馬卡龍公園這類**台灣地方公園**時，narration 頁顯示「這裡沒有故事可講 — 我們在維基百科上找不到這個景點的歷史人物或事件記錄」。

實際 root cause 不是「沒有資料」，而是 **contract bug + 單一資料源**：

1. App 端 `narration_api_service.dart:31` 直接 `wikipediaTitle: place.name`，把中文景點名（如「馬卡龍公園」）原樣往後送
2. Backend `daily_story/wikipedia.py:18` 寫死 `_REST_BASE = "https://en.wikipedia.org/api/rest_v1"`
3. 中文 title 去英文 wiki 直查 → 必然 miss → Gemini 拿到空 extract → 回 `insufficient_source=true`
4. **諷刺的是**：「馬卡龍公園」這個名字本來就是 App 端先用中文 Wikipedia geo search 撈到的（`places_repository_impl.dart:36-39`），所以中文 wiki **百分之百有這個條目**

換句話說，每個 `Place` 在 App 端已經是 Wikidata-backed（`id = 'wikidata:Q...'`、`name = Wikipedia article title`），但這資訊在打 narration API 時全被丟掉，重新降級成「拿名字字串去英文 wiki 碰運氣」。

本設計把整條 narration pipeline 升級為**以 Q-id 為錨點、並行抓多源（中文 wiki + 英文 wiki + Wikidata 結構化 facts）+ pre-Gemini 品質擋線**。

## 2. 目標

- 馬卡龍公園這類「中文 wiki 有條目、英文 wiki 沒有」的台灣地方景點能順利講出故事
- 即使兩個 wiki extract 都很短，光憑 Wikidata 結構化 facts（建造年、命名由來、所在地）也能撐起一個有起承轉合的故事
- API contract 演進向下相容，老 App 版本不被打掛
- 沒料的景點走 pre-Gemini 擋線、不浪費 LLM 成本，並提供清楚的 insufficient UI（沿用既有 `_HookInsufficientSourceState`）

## 3. 設計決策（brainstorming 結論）

| 決策 | 選項 | 理由 |
| --- | --- | --- |
| API contract 演進 | **A：App 改傳 Q-id，後端向下相容老 title** | Place.id 已含 Q-id；零成本可取得；contract 乾淨 |
| 老 App 反查 Q-id 與否 | **不反查** | 老路徑越單純越快 deprecate；新 App 推上線後新使用者立即受益 |
| 反相容追蹤方式 | **Field deprecated + 日誌 warning** | 不加 metric/counter；使用者定期手動掃 log 決定何時拆 |
| 多源編排 | **並行抓** | API 都快 < 500ms；一次給 Gemini 最豐富 context；省一輪 LLM 重試成本 |
| Wikidata claims 角色 | **獨立第三 source（結構化 facts）** | 即使 wiki extract 短也能撐故事；P31/P571/P138/P131/P17/P361 |
| 品質擋線位置 | **Pre-Gemini，在 pipeline 內判** | 太貧瘠時不打 Gemini、節省成本；Gemini defence-in-depth 仍保留 |
| `_extractWikidataId` 放哪 | **B：narration 內部 helper** | 不公開化 explore 的 id 格式慣例；之後改格式改一處 |
| App 端老參數 | **直接砍掉 `wikipediaTitle`** | App 端控制所有 caller；不留 deprecated path |
| 快取 | **B：in-memory TTLCache 7d** | 同 process 內熱門 Q-id 重複命中機率高；實作成本極低 |
| 可觀測性 | **僅結構化 log** | 使用者偏好不加 metric/counter |
| 重構 `daily_story/wikipedia.py` | **不動** | 獨立流程運作正常；重複代碼成本可接受 |

## 4. API Contract 演進

### 新 contract（新版 App 一定送）

```jsonc
POST /api/hooks
POST /api/narration
{
  "wikidata_id": "Q108234567",
  "place_name": "馬卡龍公園",
  "location": "桃園市青埔",
  "language": "zh-TW",
  "hook": { ... }  // /narration only
}
```

### 老 contract（舊版 App 仍會送）

```jsonc
{
  "wikipedia_title": "馬卡龍公園",  // ← deprecated, kept for old clients
  "place_name": "馬卡龍公園",
  "location": "桃園市青埔",
  "language": "zh-TW",
  "hook": { ... }
}
```

### Pydantic model 變更（`narration/models.py`）

```python
class NarrationRequest(BaseModel):
    wikidata_id: str | None = Field(default=None, description="Wikidata Q-id, e.g. 'Q12345'")
    wikipedia_title: str | None = Field(
        default=None,
        deprecated=True,
        description=(
            "Deprecated since 2026-05-29. Old App versions only. "
            "Remove after legacy clients phase out."
        ),
    )
    place_name: str
    location: str
    language: str
    hook: HookInput | None = None

    @model_validator(mode="after")
    def _at_least_one_identity(self):
        if not self.wikidata_id and not self.wikipedia_title:
            raise ValueError("Either wikidata_id or wikipedia_title must be provided")
        return self
```

`HooksRequest` 同樣處理。

### 後端路徑分支（`narration/service.py`）

```
if wikidata_id:
    → 走新 pipeline（多源 + claims + pre-Gemini 擋線）
else (legacy):
    → 用 wikipedia_title 抓英文 wiki extract（保留現狀）
    → 包成 single-source SourceBundle
    → 用新 prompt 結構送 Gemini
    → logger.warning("narration.legacy_title_path", ...)
```

老路徑也用**新 prompt 結構**（只是 bundle 內只含 1 個 en source），這樣不用維護兩套 prompt。

## 5. Backend：`sources/` 新模組

### 5.1 目錄結構

```
backend/src/lorescape_backend/sources/
├── __init__.py
├── models.py        # SourceExtract, SourceBundle
├── pipeline.py      # build_source_bundle, legacy_single_source_bundle
├── wikipedia.py     # 中/英 Wikipedia extract by sitelinks (with TTL cache)
├── wikidata.py      # Claims + sitelinks (with TTL cache)
└── quality.py       # assess_bundle
```

放在和 `narration/`、`daily_story/`、`social/` 同層，作為跨 feature 的 infrastructure。

### 5.2 資料結構

```python
# sources/models.py
@dataclass(frozen=True)
class SourceExtract:
    provider: Literal["wikipedia_zh", "wikipedia_en", "wikidata_facts"]
    title: str | None
    text: str
    char_count: int
    has_named_entity: bool

@dataclass(frozen=True)
class SourceBundle:
    wikidata_id: str | None    # None for legacy path
    place_name: str
    extracts: list[SourceExtract]
    total_chars: int
    is_sufficient: bool
```

### 5.3 主編排（`sources/pipeline.py`）

```python
def build_source_bundle(
    *, wikidata_id: str, language: str, place_name: str
) -> SourceBundle:
    """
    1. wbgetentities(Q-id, props=sitelinks|claims) — 一次拿完
    2. 並行抓 zh + en wikipedia extract（從 sitelinks 解出 title）
    3. 把 Wikidata claims (P31, P571, P138, P131, P17, P361) 轉成 narrative facts
    4. quality.assess_bundle 判 sufficient
    """

def legacy_single_source_bundle(title: str) -> SourceBundle:
    """
    老 App 路徑：用 daily_story.wikipedia.fetch_intro_extract 抓英文 wiki。
    """
```

### 5.4 並行 vs 容錯

- 三個 source（zh wiki / en wiki / wikidata facts）用 `asyncio.gather(..., return_exceptions=True)` 或 thread pool 並行抓
- 任一 source 失敗（5xx、timeout、entity 不存在）→ 不 raise、不阻斷其他 source、只是該 provider 不進 bundle
- 三個全失敗 → bundle.extracts 為空 → `quality.assess_bundle` 必然回 False → 走 insufficient

### 5.5 Wikidata claims → narrative facts

| Property | 中文含意 | Narrative 範例 |
| --- | --- | --- |
| P31 (instance of) | 是什麼 | "Type: urban park" |
| P571 (inception) | 建立時間 | "Founded: 2020" |
| P138 (named after) | 名字由來 | "Named after: macaron (French pastry)" |
| P131 (located in) | 所在行政區 | "Located in: Zhongli District, Taoyuan" |
| P17 (country) | 國家 | "Country: Taiwan" |
| P361 (part of) | 屬於 | "Part of: Taoyuan Aerotropolis" |

實作上用 `wbgetentities(props=claims|labels)` 一次撈，label 解析優先用 request language、fallback en。

### 5.6 品質擋線（`sources/quality.py`）

```python
def assess_bundle(bundle: SourceBundle) -> bool:
    """規則（OR 邏輯）：
    1. 任一 wiki extract ≥ 300 字
    2. 兩個 wiki extract 加總 ≥ 400 字
    3. wikidata_facts 含至少 (P31 ∧ P571) OR (P31 ∧ P138)
    """
```

不過擋線 → 直接回 `insufficient_source=true`、不打 Gemini。

### 5.7 快取（`sources/wikipedia.py`、`sources/wikidata.py`）

```python
from cachetools import TTLCache, cached
from cachetools.keys import hashkey

_extract_cache: TTLCache = TTLCache(maxsize=5000, ttl=7 * 86400)  # 7 days
_entity_cache:  TTLCache = TTLCache(maxsize=5000, ttl=7 * 86400)

@cached(_extract_cache, key=lambda qid, lang: hashkey(qid, lang))
def fetch_extract_by_qid(qid: str, lang: str) -> str | None: ...

@cached(_entity_cache, key=lambda qid: hashkey(qid))
def fetch_entity_claims(qid: str) -> EntityClaims | None: ...
```

- 同 process 內重複請求 < 1ms 回
- 重啟丟掉 cache 沒關係（外部 API 是 source of truth）
- 5000 entry × ~2KB ≈ 10MB 記憶體，VPS 完全吃得下
- `cachetools` 已是輕量依賴；若 `pyproject.toml` 還沒，加上即可

## 6. Backend：Prompt rework

### 6.1 `shared/story_prompt.py:build_story_user_prompt` 改 signature

```python
# Before
def build_story_user_prompt(
    *, place_name, location, wikipedia_title, wikipedia_extract, hook
) -> str

# After
def build_story_user_prompt(
    *, place_name, location, source_bundle: SourceBundle, hook
) -> str
```

### 6.2 新 prompt 樣板

```
Place: 馬卡龍公園
Location: 桃園市青埔
Wikidata ID: Q108234567

Source materials (multiple providers; use any/all to ground the story):

[1] Chinese Wikipedia extract (zh) — title: "馬卡龍公園"
<<<
{zh extract; 缺則略過整段}
>>>

[2] English Wikipedia extract (en) — title: "Macaron Park"
<<<
{en extract; 缺則略過整段}
>>>

[3] Structured facts (Wikidata)
- Type: urban park
- Founded: 2020
- Named after: macaron (French pastry)
- Located in: Zhongli District, Taoyuan
- Country: Taiwan

GROUNDING RULES:
- Prefer concrete facts (years, named entities, events) from the sources above.
- If sources are in a different language than the output, translate facts; do NOT invent.
- Treat structured facts as ground truth even if Wiki extracts are short.
- If you cannot find at least one named entity (person/year/event) to ground the story, return insufficient_source=true.
```

### 6.3 Output spec 措辭

`narration/prompts.py:_en_output_spec` 與 `_zh_tw_output_spec` 中：
- `"Wikipedia extract is too thin"` → `"the provided sources are too thin"`
- `"當 Wikipedia 內容不足"` → `"當提供的來源內容不足"`

其餘輸出欄位定義不變。

## 7. Frontend 變更

### 7.1 動到的檔案

| 檔案 | 改什麼 |
| --- | --- |
| `narration_api_client.dart` | method signature：移除 `wikipediaTitle`、新增 `wikidataId`；JSON key 改 `wikidata_id` |
| `narration_api_service.dart` | 新增 `_extractWikidataId(placeId)` helper；改呼叫 client 方式 |
| `story_hook_api_service.dart` | 同上模式 |
| 對應的測試 | 同步更新 |

### 7.2 `_extractWikidataId` helper

直接放在 `narration_api_service.dart` 與 `story_hook_api_service.dart` 各自檔內當 top-level private 函式（兩處實作相同、各一份）：

```dart
// narration_api_service.dart 與 story_hook_api_service.dart 各檔內
String? _extractWikidataId(String placeId) {
  const prefix = 'wikidata:';
  if (!placeId.startsWith(prefix)) return null;
  return placeId.substring(prefix.length);
}
```

不公開化、不放 Place model 或 shared extension。兩個 service 各保留一份重複（< 5 行），優於建立一個僅這兩處用的 shared module。若未來第三個地方要用，再 promote。

### 7.3 防呆路徑

```dart
Future<...> generate(Place place, ...) async {
  final wikidataId = _extractWikidataId(place.id);
  if (wikidataId == null) {
    logger.severe('Place without wikidata_id reached narration: ${place.id}');
    return NarrationGenerationState.insufficientSource();
  }
  return _client.fetchNarration(
    wikidataId: wikidataId,
    placeName: place.name,
    location: ...,
    language: ...,
  );
}
```

目前 Explore 流程 100% 是 `wikidata:` 開頭；防呆路徑不該被觸發，僅作為意外保險。

### 7.4 不動的東西

- `Place` model 維持現狀（id 格式不變）
- UI flow、routing、controller、provider 全部不動
- `_HookInsufficientSourceState` UI 沿用（commit `3a8a459`）

## 8. 可觀測性

只用結構化 log，不加 metric/counter：

```python
# sources/pipeline.py
logger.info(
    "narration.source_bundle_built",
    extra={
        "wikidata_id": qid,
        "providers_succeeded": ["wikipedia_zh", "wikidata_facts"],
        "total_chars": bundle.total_chars,
        "is_sufficient": bundle.is_sufficient,
    },
)
logger.info("narration.pre_gemini_gate", extra={"wikidata_id": qid})

# narration/service.py
logger.warning(
    "narration.legacy_title_path",
    extra={"title": title, "deprecated_remove_after": "2026-XX-XX"},
)
```

事後分析直接 grep VPS log。

## 9. 測試策略

### 9.1 Backend 新增/修改測試

| 測試檔 | 涵蓋 | 關鍵案例 |
| --- | --- | --- |
| `tests/sources/test_wikipedia.py`（新） | `sources/wikipedia.py` | mock HTTP；zh extract OK / en extract OK / 兩個都 miss / API 5xx |
| `tests/sources/test_wikidata.py`（新） | `sources/wikidata.py` | mock HTTP；P31+P571+P138 claims 解析；entity 不存在 |
| `tests/sources/test_pipeline.py`（新） | `sources/pipeline.py` | 並行抓、SourceBundle 組裝、單一 source 失敗時 graceful degrade |
| `tests/sources/test_quality.py`（新） | `sources/quality.py` | 規則 1-3 各觸發一例 + 邊界（300 字 -1 / +1） |
| `tests/test_narration_service.py`（擴充） | `narration/service.py` | 新 path / 老 path / pre-Gemini 擋線觸發 / Gemini defence-in-depth |
| `tests/test_prompts.py`（擴充） | prompts 模組 | 3 個 source 都有 / 缺 zh / 缺 en / 缺 facts；output spec 措辭 |
| `tests/test_api.py`（擴充） | `narration/routes.py` | 新 contract 200 / 只傳 title 走老 path / 都沒傳 400 |

### 9.2 關鍵 Given/When/Then 案例

**Happy path**
> Given Wikidata Q108234567 在中英文都有 wiki + 完整 claims
> When App 打 /api/narration with `wikidata_id=Q108234567`, `language="zh-TW"`
> Then SourceBundle 含 3 種 source、`is_sufficient=True`、Gemini prompt 含三區、回應 paragraphs 非空

**Pre-Gemini 擋線**
> Given Q-id 只在 en wiki 有 50 字 stub + P31=park（沒 P571/P138）
> When pipeline.build_source_bundle
> Then `quality.assess_bundle` 回 False；Gemini API 不被呼叫（assert mock call_count == 0）；回應 `paragraphs=[]`、`insufficient_source=true`

**老 App fallback**
> Given 舊版 App 只傳 `wikipedia_title="Macaron Park"`
> When 後端收到
> Then 走 `legacy_single_source_bundle`；log warning `narration.legacy_title_path`；行為等同現狀

**Contract 400**
> Given request 既沒 `wikidata_id` 也沒 `wikipedia_title`
> When 打 /api/narration
> Then 回 400 with model_validator 訊息

**外部 API graceful degrade**
> Given Wikidata API 5xx、Wikipedia API 200
> When pipeline.build_source_bundle
> Then 不 raise；bundle 只含 wiki extract、無 wikidata_facts；若 wiki extract 夠長仍 sufficient

### 9.3 Frontend 測試

| 測試檔 | 案例 |
| --- | --- |
| `narration_api_client_test.dart` | request body 含 `wikidata_id`、不含 `wikipedia_title` |
| `narration_api_service_test.dart` | `_extractWikidataId`：`'wikidata:Q123'`→`'Q123'`、`'foo:Q123'`→null、空字串→null |
| `story_hook_api_service_test.dart` | 同上模式 |

### 9.4 不寫的測試

- 真 Wikipedia / Wikidata 端到端測試（避免 CI flaky；改用手動 smoke test）
- Gemini 真實呼叫（本來就沒測）
- 效能測試（假設 < 500ms/source；實機慢明顯再另開 ticket）

### 9.5 手動 smoke test（merge 前）

1. App 在桃園青埔附近找到「馬卡龍公園」→ 進 narration → 看到實際故事
2. App 找 "Sydney Opera House" → 看到實際故事（驗證 en 路徑沒壞）
3. 後端 log 無 `narration.legacy_title_path`（驗證新 App 不走老路徑）
4. 手動改 App 端送老 contract → 後端 handle、log 有 warning
5. 真的沒料的偏門地方 → 顯示 insufficient UI

## 10. Rollout

```
Day 0   Backend deploy（向下相容）
        ├ 老 App 仍正常（走 legacy path）
        └ 任何 new contract caller 可用

Day 0+  App 送審（iOS + Android）

Day N   App 上架 → 新使用者享受新 pipeline

…       使用者定期手動掃 log `narration.legacy_title_path`
        → 流量到心目中低點 → 另一 PR 拆 legacy code
```

**順序鐵則**：Backend 必須**先**上、且確保向下相容。順序反了會炸老使用者。

## 11. Out of scope / Future work

明確劃外（避免 scope creep）：

- ❌ `daily_story/job.py` 也升級到多源（同類問題、但獨立流程，另開 ticket）
- ❌ Google Places editorial summary 整合（先看 Wikipedia + Wikidata 實際效果）
- ❌ Google Custom Search 整合（同上、且要 API key + 費用）
- ❌ 重構 `daily_story/wikipedia.py` 與 `sources/wikipedia.py` 共用程式碼
- ❌ Place 端 cache 改寫入 wikidata_id 欄位（Place.id 已含、無需新欄位）
- ❌ 拆 legacy `wikipedia_title` path（另一個 PR、依 log 量決定時機）
