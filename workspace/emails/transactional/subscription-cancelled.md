# Email 8 — 訂閱取消確認

**Trigger:** `subscription.cancelled`
**Segment:** 已取消訂閱的 Premium 用戶
**Stage:** Transactional
**Type:** Transactional（無需取消訂閱連結）
**Send timing:** 立即

## Subject Line
Primary: 收到了。旅途繼續，故事都還在
Variant A: 你的 Premium，先停在這裡了
Variant B: 到 {{subscription_end_date}} 前，仍然是你的

## Preview Text
你聽過的 {{total_stories_heard}} 段故事，都安靜存在旅程手記裡——哪天翻開，還是在那兒。

## Body

收到了。

你的 Premium 已取消，到 {{subscription_end_date}} 為止，所有故事角度還是開著的。

這段旅途，你一共聽過 {{total_stories_heard}} 段故事。它們都留在旅程手記裡，不會消失。哪天你翻開，每一篇都還在那兒等著你。

想繼續的時候，你知道在哪裡找到我。

## CTA
文字: 重新啟動 Premium
動作: 深連結至訂閱頁面 (`lorescape://subscription`)

## Quality Gate Results
- Four U's: 11/16（Unique:3 Useful:3 Ultra-specific:3 Urgent:2）
- AI 廢話: PASS
- Subject 長度: 14 字元/50
- Preview 長度: 40 字元/90（含 placeholder 估算）
- Word count: ~100 字/500
- 單一 CTA: PASS
- 開頭非制式語: PASS
- **Overall: PASS**
