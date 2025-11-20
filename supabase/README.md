# Supabase 資料庫管理

本目錄包含 Supabase 專案的資料庫設定、migrations 和管理腳本。

## 📁 目錄結構

```
supabase/
├── config.toml              # Supabase CLI 設定檔
├── migrations/              # 資料庫 migration 檔案
│   └── 20250118_create_diary_tables.sql
├── STORAGE_SETUP.md        # Storage 設定說明
└── README.md               # 本文件
```

## 🚀 快速開始

### 前置需求

1. 安裝 Supabase CLI：
   ```bash
   brew install supabase/tap/supabase
   ```

2. 登入 Supabase（如果尚未登入）：
   ```bash
   supabase login
   ```
   或設定環境變數：
   ```bash
   export SUPABASE_ACCESS_TOKEN=<your-token>
   ```

### 專案資訊

- **專案 URL**: `https://supabase.url`
- **Project Ref**: `project-ref`

## 📝 常用指令

### 推送 Migrations 到遠端資料庫

```bash
supabase db push
```

### 從遠端資料庫拉取 Schema 變更

```bash
supabase db pull
```

### 建立新的 Migration

```bash
supabase migration new <migration_name>
```

### 查看專案狀態

```bash
supabase status
```

### 查看遠端 Migrations 歷史

```bash
supabase migration list
```

## 📊 現有資料表

已建立的資料表（由 `20250118_create_diary_tables.sql` 建立）：

### 1. diary_entries
日記主表，儲存使用者的旅遊與美食日記

**欄位**：
- `id` (UUID) - 主鍵
- `user_id` (UUID) - 使用者 ID（外鍵到 auth.users）
- `title` (TEXT) - 標題
- `content` (TEXT) - 內容
- `place_id` (TEXT) - Google Place ID
- `place_name` (TEXT) - 地點名稱
- `place_address` (TEXT) - 地點地址
- `latitude` (DOUBLE PRECISION) - 緯度
- `longitude` (DOUBLE PRECISION) - 經度
- `visit_date` (DATE) - 造訪日期
- `rating` (INTEGER) - 評分（1-5 星）
- `created_at` (TIMESTAMPTZ) - 建立時間
- `updated_at` (TIMESTAMPTZ) - 更新時間

**RLS 政策**：✅ 已啟用，使用者只能存取自己的日記

### 2. diary_tags
標籤表，使用者可自訂標籤

**欄位**：
- `id` (UUID) - 主鍵
- `user_id` (UUID) - 使用者 ID（外鍵到 auth.users）
- `name` (TEXT) - 標籤名稱（同一使用者不可重複）
- `created_at` (TIMESTAMPTZ) - 建立時間

**RLS 政策**：✅ 已啟用

### 3. diary_entry_tags
日記與標籤的關聯表（多對多關係）

**欄位**：
- `diary_entry_id` (UUID) - 日記 ID（外鍵到 diary_entries）
- `tag_id` (UUID) - 標籤 ID（外鍵到 diary_tags）

**主鍵**：複合主鍵 (diary_entry_id, tag_id)

**RLS 政策**：✅ 已啟用

### 4. diary_images
日記圖片表

**欄位**：
- `id` (UUID) - 主鍵
- `diary_entry_id` (UUID) - 日記 ID（外鍵到 diary_entries）
- `storage_path` (TEXT) - Supabase Storage 中的檔案路徑
- `display_order` (INTEGER) - 圖片顯示順序
- `created_at` (TIMESTAMPTZ) - 建立時間

**RLS 政策**：✅ 已啟用

## 🔒 安全性

所有資料表都已啟用 Row Level Security (RLS)，確保：

- ✅ 使用者只能查看自己的日記
- ✅ 使用者只能新增自己的日記
- ✅ 使用者只能更新自己的日記
- ✅ 使用者只能刪除自己的日記
- ✅ 使用者只能存取自己的標籤和圖片

## 📖 Migration 開發流程

### 1. 建立新的 Migration

```bash
./scripts/supabase_migration_new.sh add_new_feature
```

這會在 `supabase/migrations/` 目錄建立新的 SQL 檔案。

### 2. 編輯 Migration 檔案

在新建立的檔案中撰寫 SQL：

```sql
-- 範例：新增欄位
ALTER TABLE diary_entries ADD COLUMN new_field TEXT;

-- 範例：建立索引
CREATE INDEX idx_diary_entries_new_field ON diary_entries(new_field);

-- 範例：新增 RLS 政策
CREATE POLICY "policy_name"
  ON table_name FOR SELECT
  USING (auth.uid() = user_id);
```

### 3. 推送到遠端資料庫

```bash
./scripts/supabase_push.sh
```

### 4. 驗證變更

檢查 Supabase Dashboard 或使用 MCP 工具驗證表格結構。

## 🔄 同步遠端變更

如果在 Supabase Dashboard 手動修改了資料庫結構：

```bash
./scripts/supabase_pull.sh
```

這會將遠端變更同步到本地 migrations。

## ⚠️ 注意事項

1. **永遠不要直接修改已推送的 migration 檔案**
   - 如需修改，請建立新的 migration

2. **測試 Migration**
   - 在推送到生產環境前，建議先在開發環境測試

3. **備份重要資料**
   - 在執行破壞性變更前，先備份重要資料

4. **Migration 檔案命名**
   - 使用有意義的名稱，例如 `add_user_preferences` 而非 `update`

## 🛠️ 疑難排解

### 連結失敗

如果 `supabase link` 失敗：

1. 確認已登入：`supabase login`
2. 確認 project-ref 正確：`ymndmrefqprhtjxhgsei`
3. 檢查網路連線

### 推送失敗

如果 `supabase db push` 失敗：

1. 檢查 SQL 語法是否正確
2. 確認沒有衝突的表格或欄位
3. 查看錯誤訊息並修正

### 需要重置本地資料庫

**警告**：這會刪除所有本地資料！

```bash
supabase db reset
```

## 📚 相關文件

- [Supabase CLI 官方文件](https://supabase.com/docs/guides/cli)
- [Migration 最佳實踐](https://supabase.com/docs/guides/cli/local-development#database-migrations)
- [Storage 設定說明](./STORAGE_SETUP.md)
