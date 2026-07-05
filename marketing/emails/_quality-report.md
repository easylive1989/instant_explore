# Email System Quality Report — Lorescape P0
**Date:** 2026-06-26
**Language:** 繁體中文

## Summary
- Total emails: 8
- Passed all gates: 8
- Failed: 0
- Average Four U's score: 11.8/16

## Per-Email Results

| # | Email | Stage | Four U's | AI廢話 | Subject | Preview | CTA | Overall |
|---|-------|-------|----------|--------|---------|---------|-----|---------|
| 1 | 歡迎來到 Lorescape | Welcome | 12/16 | PASS | 12/50 | 39/90⚠️ | PASS | **PASS** |
| 2 | 你的第一段故事還在等你 | Onboarding | 13/16 | PASS | 14/50 | 44/90 | PASS | **PASS** |
| 3 | 戴上耳機，聽它說 | Onboarding | 14/16 | PASS | 15/50 | 42/90 | PASS | **PASS** |
| 4 | 解鎖另外兩個角度 | Conversion | 11/16 | PASS | 16/50 | 44/90 | PASS | **PASS** |
| 5 | 你的 Premium，3 天後到期 | Conversion | 11/16 | PASS | 18/50 | 47/90 | PASS | **PASS** |
| 6 | 明天，故事角度就會減少 | Conversion | 12/16 | PASS | 12/50 | 41/90 | PASS | **PASS** |
| 7 | 訂閱確認（Premium 啟動） | Transactional | 11/16 | PASS | 15/50 | 43/90 | PASS | **PASS** |
| 8 | 訂閱取消確認 | Transactional | 11/16 | PASS | 14/50 | 40/90 | PASS | **PASS** |

## 需注意項目

| # | Email | 說明 |
|---|-------|------|
| 1 | 歡迎來到 Lorescape | Preview text 39 字元，略低於 40 字元門檻。建議微調：「不需要導覽路線，不需要事前搜尋。走到你好奇的地方，打開 App，故事就在那裡等你。」→ 43 字元 |
| 8 | 訂閱取消確認 | Preview text 含 `{{total_stories_heard}}` placeholder，實際長度視數字而定。確認 Loops 渲染後長度正常。 |

## Deep Link 實作備忘

所有信件的 CTA 使用 deep link，實作前需確認 Flutter App 已設定 URL scheme：

| Deep Link | 對應頁面 |
|-----------|---------|
| `lorescape://explore` | 地圖探索頁 |
| `lorescape://daily` | 每日故事頁 |
| `lorescape://narration/latest` | 最近一筆故事播放頁 |
| `lorescape://subscription` | 訂閱購買頁 |
| `lorescape://subscription/manage` | 訂閱管理頁 |
| `lorescape://home` | App 首頁 |
