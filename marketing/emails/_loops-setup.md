# Loops 實作指南 — Lorescape Email System
**Date:** 2026-06-26

## Step 0：前置條件

在開始設定 Loops 之前，需要先完成：

| 項目 | 說明 | 狀態 |
|------|------|------|
| Loops 帳號 | 申請 [loops.so](https://loops.so) | ❌ 待完成 |
| Email capture on landing | 讓用戶能訂閱（P1 in audit） | ❌ 待完成 |
| Supabase → Loops webhook | 用戶 sign_up 觸發 | ❌ 待設定 |
| RevenueCat → Loops webhook | 訂閱事件觸發 | ❌ 待設定 |
| Flutter deep links | App URL scheme 設定 | ❌ 確認是否已設定 |

---

## Step 1：在 Loops 建立 Events

以下 event 需要在 Loops 後台 → Events 建立：

| Event Name | 觸發時機 | 來源 |
|------------|---------|------|
| `user.signed_up` | 用戶完成 Google/Apple 登入 | Supabase Auth webhook |
| `user.no_story_24h` | 用戶 24h 未生成故事 | Supabase 排程函式（每小時掃描） |
| `user.first_story_generated` | 用戶生成第一筆故事 | Supabase DB trigger |
| `user.hit_free_limit` | 用戶嘗試選鎖定角度 | Flutter App → backend API → Loops |
| `subscription.expiring_3d` | 訂閱到期前 3 天 | RevenueCat webhook |
| `subscription.expiring_1d` | 訂閱到期前 1 天 | RevenueCat webhook |
| `subscription.started` | 用戶開始付費訂閱 | RevenueCat webhook |
| `subscription.cancelled` | 用戶取消訂閱 | RevenueCat webhook |

---

## Step 2：Contact Properties（用戶屬性）

Loops contact 需要這些自訂欄位：

| Property | 類型 | 來源 | 用途 |
|----------|------|------|------|
| `email` | string | Supabase Auth | 基本必填 |
| `first_name` | string | Supabase Auth（Google 帳號名） | 個人化稱謂 |
| `subscription_status` | string | RevenueCat（`free`/`premium`） | 分眾 |
| `subscription_end_date` | date | RevenueCat | Email 8 placeholder |
| `total_stories_heard` | number | Supabase DB | Email 8 placeholder |
| `locale` | string | App 設定（`zh`/`en`） | 未來多語版本分眾 |

---

## Step 3：Sequence 設定

### Onboarding Sequence（Email 1 → 2 → 3）
```
user.signed_up
  └─ 立即發送 Email 1（歡迎）
       └─ 24h 後：若 story_count = 0 → 發送 Email 2（第一段故事還在等你）
            └─ 觸發 user.first_story_generated 且 4h 未播放 → 發送 Email 3（戴上耳機）
```

### Expiry Sequence（Email 5 → 6）
```
訂閱到期日 - 3d → Email 5
訂閱到期日 - 1d → Email 6
```

### Conversion（Email 4）
```
user.hit_free_limit → 1h 後 → Email 4（解鎖角度）
```

---

## Step 4：Transactional vs. Marketing 分類

| Email | 類型 | 需要 Unsubscribe |
|-------|------|----------------|
| Email 1 歡迎 | Marketing | ✅ 需要 |
| Email 2 第一段故事 | Marketing | ✅ 需要 |
| Email 3 戴上耳機 | Marketing | ✅ 需要 |
| Email 4 解鎖角度 | Marketing | ✅ 需要 |
| Email 5 到期 3 天 | Transactional | ❌ 不需要 |
| Email 6 到期 1 天 | Transactional | ❌ 不需要 |
| Email 7 訂閱確認 | Transactional | ❌ 不需要 |
| Email 8 取消確認 | Transactional | ❌ 不需要 |

---

## Step 5：RevenueCat Webhook 設定

1. RevenueCat Dashboard → Project → Integrations → **Loops**（或 Webhook）
2. 事件對應：
   - `INITIAL_PURCHASE` → `subscription.started`
   - `CANCELLATION` → `subscription.cancelled`
   - `RENEWAL` → 不需要發信
   - `EXPIRATION` → 可擴展為 win-back 觸發點

---

## Step 6：Supabase Webhook 設定

在 `supabase/functions/` 或 Supabase DB Webhooks 設定：

```sql
-- 用戶 sign up 時觸發 Loops
-- Table: auth.users → INSERT → 呼叫 loops_webhook edge function

-- 故事生成觸發
-- Table: public.narrations → INSERT → 更新 Loops contact 的 story_count
```

---

## 實作建議順序

1. 申請 Loops 帳號，建立上述 Events 和 Contact Properties
2. 先手動在 Loops 建立 Email 模板（copy-paste 自 `workspace/emails/`）
3. 實作 Supabase → Loops webhook（`user.signed_up`，Email 1 可先上線）
4. 實作 RevenueCat → Loops webhook（訂閱事件，Email 7/8 上線）
5. 實作 `user.no_story_24h` 排程檢查（Supabase Edge Function + Cron）
6. 實作 `user.first_story_generated` DB trigger
7. P1 email（Email 9-11）在用戶數成長後再上線
