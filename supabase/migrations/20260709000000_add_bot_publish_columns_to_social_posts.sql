-- Discord 發布 bot 需要的欄位。
--
-- 新流程：本地只建 pending row（無 discord_message_id）；server bot 輪詢後
-- 貼帶按鈕的審核訊息並回填 message_id，再依按鈕互動寫 review_decision /
-- scheduled_at。排程迴圈到點且 review_decision='approved' 才發布。
--
-- review_decision 與 status 正交：可「已核准未排程」或「已排程未核准」。
-- overdue_notified_at：排程時間到但未核准時只提醒一次的去重欄位。
--
-- 表級 GRANT（20260705120000）已涵蓋後加欄位，無需新 GRANT。
ALTER TABLE public.social_posts
  ADD COLUMN IF NOT EXISTS review_decision TEXT
    CHECK (review_decision IN ('approved', 'rejected')),
  ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reviewed_by TEXT,
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS overdue_notified_at TIMESTAMPTZ;

-- 加一個 'scheduled' 狀態（既有 CHECK 只允許 pending/published/failed/
-- rejected/skipped）。先移除舊 CHECK 再加新的。
ALTER TABLE public.social_posts
  DROP CONSTRAINT IF EXISTS social_posts_status_check;
ALTER TABLE public.social_posts
  ADD CONSTRAINT social_posts_status_check CHECK (
    status IN ('pending', 'scheduled', 'published', 'failed',
               'rejected', 'skipped')
  );
