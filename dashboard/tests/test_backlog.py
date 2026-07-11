"""backlog collector 的解析測試（fixture 取自現行 BACKLOG.md 的結構縮影）。"""
from datetime import date

from lorescape_dashboard.collectors.backlog import parse_backlog

SAMPLE = """\
# Lorescape Backlog

說明文字，不解析。

## Epic E1: 補齊漏斗上層流量
- 狀態: 進行中
- 目標: 讓落地頁流量提升到穩定兩位數/天
- 政策: 現階段主線＝補流量
- [ ] 2026-08-04 回顧：檢視補流量主線是否推動指標

## ⚠️ 待部署（程式已在 repo，尚未上生產，2026-07-08）

以下改動已 commit + push 到 master：

- [x] **落地頁**（`landing/`）：已部署到 `lorescape.app`
- [ ] **App**（`frontend/`）：重新 build 並送商店審核
  - 註：商店端 7 天試用本身已對現有 App 生效
- 已是生產狀態、不需部署：App Store 的試用設定

## F1: IG 導流 CTA (epic: E1)
- 狀態: 已完成
- 來源: marketing/audits/cro-2026-07-06.md（P0）
- [x] T1: Reel caption 預設 CTA 改為導向個人檔案連結
- [x] T2: IG bio 導引文案與連結

## F7: 免費方案文案/程式一致性查核

- 狀態: 已完成（2026-07-08）
- [x] T1/T2/T3: 移除 settings「每日使用」區塊

## F9: 景點 SEO 著陸頁 (epic: E1)

- 狀態: 進行中（首批已上線 2026-07-09）
- [x] T1: 建 place 路由 + 首批 5 景點
- [x] T2: GSC 對 10 個新網址催索引（加速收錄）
  - 2026-07-10 已催 9/10
- [ ] T3: 1–4 週後回看 GSC 曝光/查詢
"""

TODAY = date(2026, 7, 11)


def _parse():
    return parse_backlog(SAMPLE, today=TODAY)


class TestEpic:
    def test_解析_epic_基本欄位(self):
        epic = _parse()["epics"][0]
        assert epic["id"] == "E1"
        assert epic["title"] == "補齊漏斗上層流量"
        assert epic["status"] == "進行中"
        assert epic["goal"] == "讓落地頁流量提升到穩定兩位數/天"

    def test_解析檢核點日期與倒數天數(self):
        checkpoint = _parse()["epics"][0]["checkpoints"][0]
        assert checkpoint["date"] == "2026-08-04"
        assert checkpoint["done"] is False
        assert checkpoint["days_left"] == 24

    def test_epic_進度統計掛上該_epic_的_features(self):
        epic = _parse()["epics"][0]
        # F1（已完成）與 F9（進行中）屬 E1；F7 不屬
        assert epic["features_total"] == 2
        assert epic["features_done"] == 1


class TestPendingDeploy:
    def test_解析待部署段落(self):
        pending = _parse()["pending_deploy"]
        assert "待部署" in pending["title"]
        assert [i["done"] for i in pending["items"]] == [True, False]
        assert "落地頁" in pending["items"][0]["text"]


class TestFeatures:
    def test_解析_feature_編號_標題_epic_狀態(self):
        features = {f["id"]: f for f in _parse()["features"]}
        assert features["F1"]["title"] == "IG 導流 CTA"
        assert features["F1"]["epic"] == "E1"
        assert features["F1"]["status"] == "已完成"
        assert features["F1"]["done"] is True
        assert features["F7"]["epic"] is None
        assert features["F9"]["done"] is False

    def test_解析_tasks_與完成狀態(self):
        f9 = next(f for f in _parse()["features"] if f["id"] == "F9")
        assert len(f9["tasks"]) == 3
        assert f9["tasks"][0]["text"].startswith("T1:")
        assert [t["done"] for t in f9["tasks"]] == [True, True, False]
        assert f9["tasks_done"] == 2
        assert f9["tasks_total"] == 3

    def test_縮排的子項目不算獨立_task(self):
        f9 = next(f for f in _parse()["features"] if f["id"] == "F9")
        assert all("已催 9/10" not in t["text"] for t in f9["tasks"])
