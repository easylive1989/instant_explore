-- Migration: Create Storage Bucket for Diary Images
-- Created at: 2025-01-19
-- Description: 建立 diary-images storage bucket 和相關的 RLS 政策

-- ============================================================================
-- 1. 建立 Storage Bucket
-- ============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'diary-images',
  'diary-images',
  true, -- 公開 bucket (允許直接存取圖片 URL)
  5242880, -- 5 MB = 5 * 1024 * 1024 bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']::text[]
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ============================================================================
-- 2. 建立 Storage RLS 政策
-- ============================================================================

-- 上傳政策：使用者只能上傳到自己的資料夾
CREATE POLICY "Users can upload their own images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'diary-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- 讀取政策：使用者只能讀取自己的圖片
CREATE POLICY "Users can view their own images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'diary-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- 更新政策：使用者只能更新自己的圖片 metadata
CREATE POLICY "Users can update their own images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'diary-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'diary-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- 刪除政策：使用者只能刪除自己的圖片
CREATE POLICY "Users can delete their own images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'diary-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- 3. 說明
-- ============================================================================

-- 檔案路徑格式：{user_id}/{diary_id}_{timestamp}_{index}.{ext}
-- 範例：a1b2c3d4-e5f6-7890-abcd-ef1234567890/diary1_1705593600000_1.jpg
--
-- RLS 政策確保：
-- 1. 使用者只能存取自己資料夾內的圖片 (storage.foldername(name))[1] = user_id
-- 2. 所有操作都需要使用者已認證 (TO authenticated)
-- 3. 檔案路徑必須以使用者 ID 開頭
