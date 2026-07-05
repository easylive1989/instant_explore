# Lorescape Email System Map
**Generated:** 2026-06-25
**Platform target:** Loops
**Language:** 繁體中文（主）；English 版本標註需求者

## 設計原則

Lorescape 是 B2C 行動 App，lifecycle 與 B2B SaaS 不同：
- 無「團隊邀請」環節（個人用戶）
- 登入為 Google/Apple OAuth → 無 password reset 需求
- Aha moment = 站在實景前，第一次聽到故事語音
- 升級觸發 = 免費用量耗盡 or 看到高質量角度被 Premium lock
- 主要語言 = 繁體中文；未來可加英語版本

---

## Lifecycle Map

| # | Email Name | Loops Event / Trigger | Stage | Priority | Segment |
|---|-----------|----------------------|-------|----------|---------|
| 1 | 歡迎來到 Lorescape | `user.signed_up` | Welcome | **P0** | 所有新用戶 |
| 2 | 你的第一段故事還在等你 | `user.no_story_24h` (24h 後無故事生成) | Onboarding | **P0** | 0 stories |
| 3 | 戴上耳機，聽它說 | `user.first_story_generated` (未播放音頻) | Onboarding | **P0** | 生成但未聽 |
| 4 | 解鎖另外兩個角度 | `user.hit_free_limit` or `user.saw_locked_angle` | Conversion | **P0** | 免費用戶 |
| 5 | 你的 Premium 3 天後到期 | `subscription.expiring_3d` | Conversion | **P0** | 訂閱即將到期 |
| 6 | 明天就到期了 | `subscription.expiring_1d` | Conversion | **P0** | 訂閱即將到期 |
| 7 | 訂閱確認 | `subscription.started` | Transactional | **P0** | 新付費用戶 |
| 8 | 訂閱取消確認 | `subscription.cancelled` | Transactional | **P0** | 取消用戶 |
| 9 | 世界還在等你 | `user.inactive_7d` | Retention | **P1** | 7 天未開 App |
| 10 | 本週隱藏故事 | `weekly_digest.every_monday` (排程) | Digest | **P1** | 所有訂閱用戶 |
| 11 | 一則故事，從遠方寄來 | `user.inactive_30d` | Win-back | **P1** | 30 天未開 App |

---

## 暫不需要的 Email

| 跳過項目 | 原因 |
|---------|------|
| Password reset | Google/Apple OAuth，無密碼 |
| Invoice / receipt | RevenueCat + App Store/Play 已自動處理 |
| Invite team | 個人 App，無協作功能 |
| Security alert | OAuth 安全由 Google/Apple 處理 |

---

## 實作前置條件

| 條件 | 狀態 |
|------|------|
| Email capture on landing page | ❌ 尚未建立 (P1 in audit) |
| Loops account | ❌ 尚未設定 |
| Supabase → Loops webhook | ❌ 尚未設定 |
| RevenueCat → Loops webhook | ❌ 尚未設定 |

> 先把 email copy 寫好；Loops 整合可在下一個 sprint 完成。
