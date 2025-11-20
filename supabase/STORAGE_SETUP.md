# Supabase Storage 設定指南

本文件說明如何在 Supabase 設定圖片儲存功能。

## 1. 建立 Storage Bucket

### 步驟一:登入 Supabase Dashboard

前往 https://supabase.com/dashboard 並登入您的專案

### 步驟二:建立 Bucket

1. 在左側選單選擇 **Storage**
2. 點擊 **New bucket** 按鈕
3. 輸入以下資訊:
   - **Name**: `diary-images`
   - **Public bucket**: 取消勾選 (私人 bucket)
   - **File size limit**: 5 MB (建議值)
   - **Allowed MIME types**: `image/jpeg,image/png,image/webp,image/heic`

4. 點擊 **Create bucket**

## 2. 設定 Bucket 政策

建立 bucket 後,需要設定存取政策:

### 步驟一:新增政策

1. 點擊剛建立的 `diary-images` bucket
2. 選擇 **Policies** 頁籤
3. 點擊 **New policy**

### 步驟二:設定上傳政策

建立以下政策以允許使用者上傳圖片:

**Policy name**: `Users can upload their own images`

**Policy definition**:
```sql
(bucket_id = 'diary-images'::text) AND
(auth.uid()::text = (storage.foldername(name))[1])
```

**Allowed operations**: INSERT

**說明**:
- 檔案路徑格式為 `{user_id}/{filename}`
- 使用者只能上傳到自己的資料夾

### 步驟三:設定讀取政策

建立以下政策以允許使用者讀取自己的圖片:

**Policy name**: `Users can view their own images`

**Policy definition**:
```sql
(bucket_id = 'diary-images'::text) AND
(auth.uid()::text = (storage.foldername(name))[1])
```

**Allowed operations**: SELECT

### 步驟四:設定刪除政策

建立以下政策以允許使用者刪除自己的圖片:

**Policy name**: `Users can delete their own images`

**Policy definition**:
```sql
(bucket_id = 'diary-images'::text) AND
(auth.uid()::text = (storage.foldername(name))[1])
```

**Allowed operations**: DELETE

## 3. 使用 SQL Editor 建立政策 (替代方法)

如果偏好使用 SQL,可以在 SQL Editor 執行以下指令:

```sql
-- 建立 diary-images bucket 的存取政策

-- 上傳政策
CREATE POLICY "Users can upload their own images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'diary-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- 讀取政策
CREATE POLICY "Users can view their own images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'diary-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- 更新政策 (用於更新檔案 metadata)
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

-- 刪除政策
CREATE POLICY "Users can delete their own images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'diary-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

## 4. 檔案路徑結構

使用者上傳的圖片應遵循以下路徑結構:

```
diary-images/
├── {user_id_1}/
│   ├── {diary_id_1}_{timestamp}_1.jpg
│   ├── {diary_id_1}_{timestamp}_2.jpg
│   └── {diary_id_2}_{timestamp}_1.jpg
└── {user_id_2}/
    └── {diary_id_3}_{timestamp}_1.jpg
```

### 檔案命名範例:
```
{user_id}/{diary_id}_{timestamp}_{index}.{ext}

實際範例:
a1b2c3d4-e5f6-7890-abcd-ef1234567890/
  ├── diary1_1705593600000_1.jpg
  ├── diary1_1705593600000_2.jpg
  └── diary2_1705680000000_1.jpg
```

## 5. Flutter 程式碼範例

### 上傳圖片:

```dart
Future<String> uploadImage(File imageFile, String diaryId) async {
  final userId = Supabase.instance.client.auth.currentUser!.id;
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileExt = path.extension(imageFile.path);
  final fileName = '${diaryId}_${timestamp}_${index}${fileExt}';
  final filePath = '$userId/$fileName';

  await Supabase.instance.client.storage
      .from('diary-images')
      .upload(filePath, imageFile);

  return filePath;
}
```

### 取得圖片 URL:

```dart
String getImageUrl(String storagePath) {
  return Supabase.instance.client.storage
      .from('diary-images')
      .getPublicUrl(storagePath);
}
```

### 刪除圖片:

```dart
Future<void> deleteImage(String storagePath) async {
  await Supabase.instance.client.storage
      .from('diary-images')
      .remove([storagePath]);
}
```

## 6. 注意事項

1. **檔案大小限制**: 建議設定為 5 MB 以避免過大的圖片佔用空間
2. **圖片格式**: 支援 JPEG、PNG、WebP 和 HEIC 格式
3. **路徑安全**: 確保檔案路徑包含使用者 ID,避免存取權限問題
4. **圖片壓縮**: 建議在上傳前先壓縮圖片以節省儲存空間和頻寬

## 7. 疑難排解

### 問題:上傳失敗,顯示權限錯誤

**解決方法**:
- 檢查檔案路徑是否以使用者 ID 開頭
- 確認 RLS 政策已正確設定
- 確認使用者已登入 (authenticated)

### 問題:無法讀取圖片

**解決方法**:
- 使用 `getPublicUrl()` 取得圖片 URL
- 對於私人 bucket,使用 `createSignedUrl()` 產生臨時 URL
- 檢查 RLS 政策是否允許 SELECT 操作

## 8. 成本考量

Supabase Free Tier 限制:
- Storage: 1 GB
- Bandwidth: 2 GB/月

建議:
- 壓縮圖片以減少儲存空間
- 使用 CDN 快取以減少頻寬使用
- 考慮付費方案以獲得更多空間
