-- Migration: Create diary tables
-- Created at: 2025-01-18
-- Description: 建立旅食日記所需的資料表、索引、觸發器和 RLS 政策

-- ============================================================================
-- 1. 建立資料表
-- ============================================================================

-- 建立 diary_entries 資料表 (日記主表)
CREATE TABLE IF NOT EXISTS diary_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  place_id TEXT,
  place_name TEXT,
  place_address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  visit_date DATE NOT NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE diary_entries IS '日記主表,儲存使用者的旅遊與美食日記';
COMMENT ON COLUMN diary_entries.place_id IS 'Google Place ID';
COMMENT ON COLUMN diary_entries.visit_date IS '造訪日期';
COMMENT ON COLUMN diary_entries.rating IS '評分 (1-5 星)';

-- 建立 diary_tags 資料表 (使用者自訂標籤)
CREATE TABLE IF NOT EXISTS diary_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, name)
);

COMMENT ON TABLE diary_tags IS '標籤表,使用者可自訂標籤';
COMMENT ON COLUMN diary_tags.name IS '標籤名稱,同一使用者不可重複';

-- 建立 diary_entry_tags 關聯表 (多對多關係)
CREATE TABLE IF NOT EXISTS diary_entry_tags (
  diary_entry_id UUID NOT NULL REFERENCES diary_entries(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES diary_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (diary_entry_id, tag_id)
);

COMMENT ON TABLE diary_entry_tags IS '日記與標籤的關聯表';

-- 建立 diary_images 資料表
CREATE TABLE IF NOT EXISTS diary_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diary_entry_id UUID NOT NULL REFERENCES diary_entries(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE diary_images IS '日記圖片表';
COMMENT ON COLUMN diary_images.storage_path IS 'Supabase Storage 中的檔案路徑';
COMMENT ON COLUMN diary_images.display_order IS '圖片顯示順序';

-- ============================================================================
-- 2. 建立索引以提升查詢效能
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_diary_entries_user_id
  ON diary_entries(user_id);

CREATE INDEX IF NOT EXISTS idx_diary_entries_visit_date
  ON diary_entries(visit_date DESC);

CREATE INDEX IF NOT EXISTS idx_diary_entries_user_visit_date
  ON diary_entries(user_id, visit_date DESC);

CREATE INDEX IF NOT EXISTS idx_diary_tags_user_id
  ON diary_tags(user_id);

CREATE INDEX IF NOT EXISTS idx_diary_images_diary_entry_id
  ON diary_images(diary_entry_id);

-- ============================================================================
-- 3. 建立觸發器
-- ============================================================================

-- 更新 updated_at 欄位的函數
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 為 diary_entries 建立觸發器
CREATE TRIGGER update_diary_entries_updated_at
  BEFORE UPDATE ON diary_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 4. 啟用 Row Level Security (RLS)
-- ============================================================================

ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE diary_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE diary_entry_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE diary_images ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. 建立 RLS 政策 - diary_entries
-- ============================================================================

-- 查詢:只能查看自己的日記
CREATE POLICY "Users can view their own diary entries"
  ON diary_entries FOR SELECT
  USING (auth.uid() = user_id);

-- 新增:只能新增自己的日記
CREATE POLICY "Users can insert their own diary entries"
  ON diary_entries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 更新:只能更新自己的日記
CREATE POLICY "Users can update their own diary entries"
  ON diary_entries FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 刪除:只能刪除自己的日記
CREATE POLICY "Users can delete their own diary entries"
  ON diary_entries FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 6. 建立 RLS 政策 - diary_tags
-- ============================================================================

CREATE POLICY "Users can view their own tags"
  ON diary_tags FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tags"
  ON diary_tags FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tags"
  ON diary_tags FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tags"
  ON diary_tags FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 7. 建立 RLS 政策 - diary_entry_tags
-- ============================================================================

CREATE POLICY "Users can view their own diary entry tags"
  ON diary_entry_tags FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM diary_entries
      WHERE diary_entries.id = diary_entry_tags.diary_entry_id
      AND diary_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own diary entry tags"
  ON diary_entry_tags FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM diary_entries
      WHERE diary_entries.id = diary_entry_tags.diary_entry_id
      AND diary_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own diary entry tags"
  ON diary_entry_tags FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM diary_entries
      WHERE diary_entries.id = diary_entry_tags.diary_entry_id
      AND diary_entries.user_id = auth.uid()
    )
  );

-- ============================================================================
-- 8. 建立 RLS 政策 - diary_images
-- ============================================================================

CREATE POLICY "Users can view their own diary images"
  ON diary_images FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM diary_entries
      WHERE diary_entries.id = diary_images.diary_entry_id
      AND diary_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own diary images"
  ON diary_images FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM diary_entries
      WHERE diary_entries.id = diary_images.diary_entry_id
      AND diary_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own diary images"
  ON diary_images FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM diary_entries
      WHERE diary_entries.id = diary_images.diary_entry_id
      AND diary_entries.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM diary_entries
      WHERE diary_entries.id = diary_images.diary_entry_id
      AND diary_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own diary images"
  ON diary_images FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM diary_entries
      WHERE diary_entries.id = diary_images.diary_entry_id
      AND diary_entries.user_id = auth.uid()
    )
  );
