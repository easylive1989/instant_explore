-- 將 visit_date 從 DATE 改為 TIMESTAMP WITH TIME ZONE
-- 保持向後相容:現有資料的時間部分設為中午 12:00

-- 1. 新增一個臨時欄位來存放 TIMESTAMP
ALTER TABLE diary_entries
ADD COLUMN visit_datetime TIMESTAMP WITH TIME ZONE;

-- 2. 將現有的 DATE 資料轉換為 TIMESTAMP (設定時間為中午 12:00)
UPDATE diary_entries
SET visit_datetime = visit_date::timestamp + INTERVAL '12 hours';

-- 3. 刪除舊的 visit_date 欄位
ALTER TABLE diary_entries
DROP COLUMN visit_date;

-- 4. 重新命名新欄位為 visit_date
ALTER TABLE diary_entries
RENAME COLUMN visit_datetime TO visit_date;

-- 5. 設定 NOT NULL 約束
ALTER TABLE diary_entries
ALTER COLUMN visit_date SET NOT NULL;

-- 6. 新增註解說明
COMMENT ON COLUMN diary_entries.visit_date IS '造訪日期時間,精確到分鐘';
