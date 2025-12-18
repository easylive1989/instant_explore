-- 新增 language 欄位（必填，無預設值）
-- 注意：在執行此 migration 前，需先刪除所有現有的 passport_entries 資料
ALTER TABLE public.passport_entries
ADD COLUMN language TEXT NOT NULL;
