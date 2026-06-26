# Push 3 — 戴上耳機，聽它說（Push Notification）

**對應 Email:** Email 3（email 版仍保留給有帳號用戶）
**Trigger:** `narration.generated_not_played`（故事已生成，4 小時內未點擊播放）
**Segment:** 所有已安裝用戶（依 FCM device token）
**Stage:** Onboarding
**Send timing:** 故事生成後 4 小時未播放時觸發；晚上 22:00 後靜音（隔天早上補發）
**Platform:** iOS + Android（FCM）

---

## 主版本

**Title:** 故事寫好了，差一步
**Body:** 戴上耳機，按下播放——讓它在你耳邊說這個地方的來歷。
**Deep link:** `lorescape://narration/latest`

> Title 9 字 ✅ / Body 28 字 ✅

---

## Variant A（更直接，強調動作）

**Title:** 收起手機，戴上耳機
**Body:** 你的故事準備好了。口袋裡放著手機，耳機裡就有一段歷史。
**Deep link:** `lorescape://narration/latest`

> Title 10 字 ✅ / Body 28 字 ✅

---

## Variant B（強調「這就是 Lorescape 本來的樣子」）

**Title:** 語音，才是完整的 Lorescape
**Body:** 故事生成好了——閉上眼睛或抬起頭，讓它說給你聽。
**Deep link:** `lorescape://narration/latest`

> Title 14 字 ✅ / Body 26 字 ✅

---

## 實作備忘

| 項目 | 說明 |
|------|------|
| Trigger 來源 | App 端事件：`narration_generated` 寫入 Supabase → 後端 4h 後查詢同一 device 是否有 `narration_played` 事件；若無則觸發推播 |
| 靜音時段 | 22:00–08:00 用戶當地時間；若在靜音時段觸發，延至隔天 09:00 發送 |
| 頻率限制 | 每次生成故事後最多觸發一次；若用戶已播放則不發；同一設備 24h 內不重複發送此類 push |
| 不發送條件 | 用戶已關閉推播授權；用戶生成後 4h 內已播放任何故事 |
| Deep link 帶參 | 可帶 `narration_id` 直跳特定故事：`lorescape://narration/{id}` |
| A/B 測試 | 追蹤 48h 內首次音頻播放率；三組各 33% |

---

## 管道優先順序

```
用戶生成故事但未播放音頻（4h）
  └─ Push（本文件）← 主要管道，覆蓋所有安裝用戶
       └─ 已登入 + 有 email → 額外發 Email 3（email 版）
```

---

## 注意：iOS 推播授權

iOS 需要用戶明確同意才能收推播。建議在用戶**第一次生成故事後**，立即詢問推播授權——這是用戶體驗最佳、同意率最高的時機點（剛剛得到了產品價值）。

```dart
// 在 narration 生成完成的 callback 後詢問
FirebaseMessaging.instance.requestPermission(
  alert: true,
  sound: true,
);
```
