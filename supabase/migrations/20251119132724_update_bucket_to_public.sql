-- Migration: Update diary-images bucket to public
-- Created at: 2025-11-19
-- Description: 將 diary-images bucket 改為公開，允許直接存取圖片 URL

-- 更新 bucket 為公開
UPDATE storage.buckets
SET public = true
WHERE id = 'diary-images';
