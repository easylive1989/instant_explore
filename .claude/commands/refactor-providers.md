---
allowed-tools: Read, Write, Edit, Grep, Bash(fvm dart format:*), Bash(fvm dart analyze:*)
description: 將直接實例化的服務轉換為 Riverpod Providers
argument-hint: [檔案或目錄路徑]
---

# Riverpod Provider 重構工具

你是一個 Riverpod 專家，專門協助將直接實例化的服務轉換為依賴注入模式。

## 任務

找出 `$ARGUMENTS` 中所有直接實例化服務的地方，並轉換為使用 Riverpod Provider。

## 分析步驟

### 1. 掃描直接實例化模式

使用 Grep 搜尋常見的實例化模式：

```bash
# 搜尋 Repository 實例化
!`cd frontend && grep -r "= .*Repository()" lib/ --include="*.dart" | head -20`

# 搜尋 Service 實例化
!`cd frontend && grep -r "= .*Service()" lib/ --include="*.dart" | head -20`

# 搜尋在 initState 中實例化
!`cd frontend && grep -B3 -A3 "initState" lib/ --include="*.dart" | grep -A2 "Repository\|Service" | head -30`
```

### 2. 讀取相關檔案

對於每個發現的檔案，讀取完整內容以了解上下文。

### 3. 檢查是否已有 Provider

檢查專案中是否已經有對應的 Provider 定義：

```bash
# 搜尋現有 Providers
!`cd frontend && grep -r "Provider" lib/ --include="*.dart" | grep "final.*Provider" | head -20`
```

## 反模式偵測

### ❌ 反模式 1：在 Widget 中直接 new

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late final DiaryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = DiaryRepositoryImpl();  // ❌ 直接實例化
  }
}
```

### ❌ 反模式 2：在類別欄位直接實例化

```dart
class MyScreen extends State<SomeWidget> {
  final DiaryRepository _repository = DiaryRepositoryImpl();  // ❌
  final ImageService _imageService = ImageService();  // ❌
}
```

### ❌ 反模式 3：在方法中直接建立

```dart
Future<void> saveData() async {
  final repository = DiaryRepositoryImpl();  // ❌
  await repository.save(data);
}
```

## 重構模式

### ✅ 模式 1：建立 Provider (如果不存在)

#### 步驟 1：找到服務類別定義

讀取服務類別的原始碼，了解：
- 建構子參數
- 依賴的其他服務
- 是否為單例

#### 步驟 2：建立 Provider 定義

在服務檔案的同一目錄建立或更新 `providers.dart`：

```dart
// lib/features/diary/providers/diary_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/diary_repository.dart';
import '../services/diary_repository_impl.dart';

// Provider 定義
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();
});
```

如果服務有依賴：

```dart
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final supabase = ref.read(supabaseClientProvider);
  return ImageUploadService(supabase);
});
```

### ✅ 模式 2：轉換 StatefulWidget 為 ConsumerStatefulWidget

```dart
// ❌ 重構前
class DiaryCreateScreen extends StatefulWidget {
  const DiaryCreateScreen({super.key});

  @override
  State<DiaryCreateScreen> createState() => _DiaryCreateScreenState();
}

class _DiaryCreateScreenState extends State<DiaryCreateScreen> {
  late final DiaryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = DiaryRepositoryImpl();  // ❌
  }
}

// ✅ 重構後
class DiaryCreateScreen extends ConsumerStatefulWidget {
  const DiaryCreateScreen({super.key});

  @override
  ConsumerState<DiaryCreateScreen> createState() => _DiaryCreateScreenState();
}

class _DiaryCreateScreenState extends ConsumerState<DiaryCreateScreen> {
  late final DiaryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(diaryRepositoryProvider);  // ✅
  }
}
```

### ✅ 模式 3：轉換 StatelessWidget 為 ConsumerWidget

```dart
// ❌ 重構前
class DiaryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repository = DiaryRepositoryImpl();  // ❌
    // ...
  }
}

// ✅ 重構後
class DiaryList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(diaryRepositoryProvider);  // ✅
    // ...
  }
}
```

### ✅ 模式 4：在方法中使用 ref.read

```dart
// ❌ 重構前
class _MyScreenState extends State<MyScreen> {
  Future<void> saveData() async {
    final repository = DiaryRepositoryImpl();  // ❌
    await repository.save(data);
  }
}

// ✅ 重構後
class _MyScreenState extends ConsumerState<MyScreen> {
  Future<void> saveData() async {
    final repository = ref.read(diaryRepositoryProvider);  // ✅
    await repository.save(data);
  }
}
```

## 重構執行流程

### 1. 分析階段

輸出發現的所有問題：

```markdown
# Provider 轉換分析報告

## 發現 5 個直接實例化問題

### 1. DiaryCreateScreen - diary_create_screen.dart:45
**服務**: DiaryRepositoryImpl
**位置**: initState 方法
**類型**: StatefulWidget → ConsumerStatefulWidget

### 2. DiaryDetailScreen - diary_detail_screen.dart:38
**服務**: DiaryRepositoryImpl, ImageUploadService
**位置**: 類別欄位
**類型**: StatefulWidget → ConsumerStatefulWidget

### 3. DiaryListScreen - diary_list_screen.dart:234
**服務**: ImageUploadService
**位置**: _buildScrollView 方法
**類型**: ConsumerStatefulWidget (已是，直接修正)

## 需要建立的 Providers

### 1. diaryRepositoryProvider ❌ 不存在
**服務**: DiaryRepository
**實作**: DiaryRepositoryImpl
**依賴**: Supabase client

### 2. imageUploadServiceProvider ❌ 不存在
**服務**: ImageUploadService
**依賴**: Supabase client

### 3. imagePickerServiceProvider ❌ 不存在
**服務**: ImagePickerService
**依賴**: 無
```

### 2. 確認階段

詢問使用者：

```
發現 5 個需要轉換的地方，需要建立 3 個新的 Providers。

是否執行重構？

1. ✅ 全部執行 (建議)
2. 📝 逐個確認
3. 🎯 只建立 Providers，不修改檔案
4. ❌ 只顯示報告

請選擇 (1-4):
```

### 3. 執行階段

#### 步驟 1：建立 Providers

建立或更新 `lib/features/[feature]/providers/[feature]_providers.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/diary_repository.dart';
import '../services/diary_repository_impl.dart';
import '../../images/services/image_upload_service.dart';
import '../../images/services/image_picker_service.dart';

// Supabase Client Provider (如果不存在)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Diary Repository Provider
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();
});

// Image Upload Service Provider
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService();
});

// Image Picker Service Provider
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});
```

#### 步驟 2：修改使用服務的檔案

對每個檔案：

1. 添加 import
   ```dart
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import '../providers/diary_providers.dart';
   ```

2. 轉換 Widget 類型
   - `StatefulWidget` → `ConsumerStatefulWidget`
   - `State<T>` → `ConsumerState<T>`
   - `StatelessWidget` → `ConsumerWidget`

3. 替換實例化
   - `= SomeService()` → `= ref.read(someServiceProvider)`
   - 在 build 方法中使用 `ref.watch` 如果需要響應變化

#### 步驟 3：更新 imports

確保所有必要的 import 都已添加：
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

#### 步驟 4：驗證

```bash
!`cd frontend && fvm dart format $ARGUMENTS`
!`cd frontend && fvm dart analyze $ARGUMENTS`
```

## 最佳實踐

### Provider 命名規範

- Repository: `xxxRepositoryProvider`
- Service: `xxxServiceProvider`
- Notifier: `xxxNotifierProvider`
- State: `xxxStateProvider`

### Provider 組織

建議結構：

```
lib/features/diary/
├── providers/
│   └── diary_providers.dart    # 所有 diary 相關 Providers
├── services/
│   ├── diary_repository.dart
│   └── diary_repository_impl.dart
└── screens/
    └── diary_list_screen.dart
```

### 使用 ref.read vs ref.watch

- **ref.read**: 一次性讀取，用於事件處理器、initState
- **ref.watch**: 監聽變化，用於 build 方法中需要響應更新的地方

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ 監聽狀態變化
  final diaryState = ref.watch(diaryListNotifierProvider);

  return ElevatedButton(
    onPress: () {
      // ✅ 一次性呼叫
      ref.read(diaryRepositoryProvider).save(data);
    },
    child: Text('Save'),
  );
}
```

### 避免在 Provider 中建立狀態

```dart
// ❌ 不好
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl()..init();  // 有副作用
});

// ✅ 好
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl();  // 純粹建立實例
});
```

## 驗證清單

重構完成後確認：

- [ ] 所有直接實例化都已移除
- [ ] 所有 Provider 都已定義
- [ ] 所有使用的 Widget 都已轉換為 Consumer 版本
- [ ] Import 正確
- [ ] Dart Analyzer 無錯誤
- [ ] 程式能夠編譯
- [ ] 功能運作正常

開始分析 $ARGUMENTS。
