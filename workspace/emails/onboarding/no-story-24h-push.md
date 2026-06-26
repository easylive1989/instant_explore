# Push 2 — 你的第一段故事還在等你（Push Notification）

**對應 Email:** Email 2（email 版仍保留給有帳號用戶）
**Trigger:** `app.no_story_24h`（安裝或首次開啟後 24 小時，未生成任何故事）
**Segment:** 所有已安裝用戶（有無帳號皆可，依 FCM device token 發送）
**Stage:** Onboarding
**Send timing:** 首次開啟 App 後 24 小時；建議發送時段 09:00–11:00（用戶當地時間）
**Platform:** iOS + Android（FCM）

---

## 主版本

**Title:** 今天的故事，從這裡開始
**Body:** 不用出門。打開每日故事，一則來自世界某個角落的景點就在等你。
**Deep link:** `lorescape://daily`

> Title 13 字 ✅ / Body 30 字 ✅

---

## Variant A（更短，適合 iOS 鎖定畫面截斷場景）

**Title:** 今天有一則新故事
**Body:** 梵蒂岡、伊斯坦堡，還是台灣的老街？打開 App 看看。
**Deep link:** `lorescape://daily`

> Title 9 字 ✅ / Body 24 字 ✅

---

## Variant B（強調「習慣」角度）

**Title:** 早晨五分鐘，讀一個城市的故事
**Body:** 咖啡還沒涼之前，Lorescape 今天的故事就等你翻開。
**Deep link:** `lorescape://daily`

> Title 16 字 ✅ / Body 24 字 ✅

---

## 實作備忘

| 項目 | 說明 |
|------|------|
| Trigger 來源 | 後端排程（Supabase Edge Function + pg_cron）：查詢 FCM token 存在但 story_count = 0 且安裝超過 24h 的設備 |
| FCM token 儲存 | App 啟動時取得 token，寫入 Supabase（不需要帳號，用 device_id 關聯） |
| 發送工具 | Firebase Cloud Messaging（FCM）；後端呼叫 FCM HTTP v1 API |
| 頻率限制 | 每位用戶只發一次，發送後設 flag `push_no_story_sent = true` |
| 不發送條件 | 用戶已生成過至少 1 個故事；用戶已關閉推播授權 |
| A/B 測試 | 隨機分三組各 33%，追蹤 7 天內首次故事生成率 |

---

## 管道優先順序

```
所有已安裝用戶
  └─ 24h 無故事 → Push（本文件）← 主要管道
       └─ 已登入 + 有 email → 額外發 Email 2（email 版）
```
