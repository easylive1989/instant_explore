# Midnight Kyoto S3-bb — Narration Aspect Screen 設計文件

- 日期：2026-04-24
- Sprint：S3-bb（S3 第三個 mini-sprint，narration feature 第二段）
- 範圍：`frontend/lib/features/narration/presentation/screens/select_narration_aspect_screen.dart`（484 行，6 個 widget）

## 背景與目標

S3-b 完成了 player 翻新；S3-bb 處理「導覽生成前的 aspect 選擇畫面」——也就是地點頁進入 narration 之前的配置 hero 螢幕。它有：
- 全屏背景照片
- 漸層遮罩 + 地點名稱大字 + 類別 badge + 地址
- 多選的 aspect 卡片清單（如 "Brief" / "Deep dive"）
- Start 按鈕觸發 narration 生成

整個 screen 設計就是 hero 編輯感——這是 MK 樣式最該發揮的舞台之一。

## 影響範圍

| Widget | 角色 | 動作 |
|---|---|---|
| `SelectNarrationAspectScreen` | 主 Scaffold + Stack 編排 | 重 |
| `_GeneratingIndicator` | 生成中 spinner + 文字 | 中 |
| `_BackgroundImage` | 全屏照片 + 黑遮罩 | 小（保留 image filter）|
| `_CategoryBadge` | hero 地點類別標籤 | 重（與 S3-a chip 統一風格）|
| `_AddressRow` | 地點地址列 | 中 |
| `AspectOption`（公開）| 選項卡片 | 重（核心視覺）|

**測試**：`select_narration_aspect_screen_test.dart`（378 行，~9 testWidgets）。多數用 `find.byIcon` / `find.text` / `find.byType(AspectOption)`，預期可最小修改。

## 已決策事項

| 議題 | 決定 |
|---|---|
| 背景照片暗遮罩 | **保留 `Color(0x66000000)`（black @ 40%）**——這是照片處理 filter，不是主題色，務求照片在任何條件下可讀 |
| 漸層遮罩底色 | 改用 `colorScheme.surface` 與 `cs.surface.withValues(alpha: 0.8)` 取代硬編碼 |
| Place name typography | `textTheme.displayMedium`（28/w800/letterSpacing -0.3）取代 hardcoded 32/w700 |
| `_CategoryBadge` 動態色 | **保留 `place.category.color`**——MK 化外觀（4px radius、no border / "no-line" 規則、10px uppercase letterSpacing 1.5），與 S3-a 的 PlaceCard chip 統一 |
| `_AddressRow` icon + text | 顏色用 `cs.onSurfaceVariant`，文字用 `textTheme.bodyLarge` |
| `_GeneratingIndicator` | spinner 用 `cs.primary`、文字用 `textTheme.bodyLarge.copyWith(color: cs.onSurfaceVariant)` |
| Aspect title (18px bold) | `textTheme.headlineMedium` |
| `AspectOption` selected 描述文字色 | `cs.onPrimaryContainer`（MK 已定義為 `#A8C8FF` light blue），取代 `Colors.blue[200]` |
| `AspectOption` icon container | **保留為非互動 Container**（不是 button），但用 MK token 著色：selected 用 `primary` / `onPrimary`、unselected 用 `surfaceContainerHigh` / `onSurface` |
| `AspectOption` 整體互動 | 從 `InkWell` 升級為 `PressScale + InkWell`——保留 ripple，加上 active-scale feedback |
| `AspectOption` selected 邊框 | `cs.primary` 2px；unselected 用 `cs.outlineVariant`，仍保 1px（MK 「ghost border」例外，這裡需要可見邊以呈現「卡片」感）|
| Start 按鈕 | `PillButton(label, icon: play_arrow, fullWidth, primary)`——取代 `AdaptiveButton(expanded, AppColors.primary)` |
| Top AppBar back icon | `cs.onSurface` 取代 `Colors.white`（兩者在深色主題下相同，但 token 化）|

## 不在 S3-bb 範圍

- ❌ Aspect 模型本身或 controller / state
- ❌ 影像 Cache（`PlaceImageCacheManager`）
- ❌ Watch ad dialog（subscription feature）
- ❌ 路由邏輯
- ❌ 翻譯字串

## 設計細節

### 1. `SelectNarrationAspectScreen.build`

底部漸層改：

```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Theme.of(context).colorScheme.surface,
      Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
      Colors.transparent,
    ],
  ),
),
```

Place name 改：

```dart
Text(
  widget.place.name,
  style: Theme.of(context).textTheme.displayMedium,
),
```

Aspect title 改：

```dart
Text(
  'config_screen.select_aspect_title'.tr(),
  style: Theme.of(context).textTheme.headlineMedium,
),
```

Start 按鈕改：

```dart
PillButton(
  label: 'config_screen.start_button'.tr(),
  icon: Icons.play_arrow,
  fullWidth: true,
  onPressed: selectedAspects.isEmpty ? null : _onStartPressed,
),
```

Top AppBar back icon 改：

```dart
AdaptiveIconButton(
  icon: Icon(
    Icons.arrow_back_ios_new,
    color: Theme.of(context).colorScheme.onSurface,
  ),
  onPressed: () => context.pop(),
),
```

### 2. `_GeneratingIndicator`

```dart
class _GeneratingIndicator extends StatelessWidget {
  const _GeneratingIndicator();
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AdaptiveProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'config_screen.generating'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

⚠️ Class constructor 改成 `const`（原本沒寫）。

### 3. `_BackgroundImage`

幾乎不動——只是把 `Container(color: Colors.black)` placeholder/error 改成 `ColoredBox(color: cs.surfaceContainerLowest)`。`Color(0x66000000)` 維持（image filter 是顏色，不是主題 token）。

### 4. `_CategoryBadge`

完全重寫成 MK chip 風格（與 PlaceCard 的 `_CategoryChip` 統一）：

```dart
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final color = place.category.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(place.category.icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              place.category.translationKey.tr().toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

⚠️ 失去原本「16px icon + 12px bold 文字 + 1px border + 16px radius」的視覺強度——變得跟 PlaceCard 一樣小巧。**權衡**：hero 螢幕的 badge 變小，但跟 explore screen 的 PlaceCard chip 一致，整體系統視覺更收斂。

如果用戶覺得這個 badge 太小、需要更 hero 一點，可在後續 spec review 時調整成「hero size variant」（例如 14px text、6 + 12 padding）。

### 5. `_AddressRow`

```dart
class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.location_on, color: cs.onSurfaceVariant, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            place.formattedAddress,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
```

### 6. `AspectOption`（公開 widget，是 test 直接抓 `find.byType` 的對象）

```dart
class AspectOption extends StatelessWidget {
  final NarrationAspect aspect;
  final bool isSelected;
  final VoidCallback onTap;

  const AspectOption({
    super.key,
    required this.aspect,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final containerDecoration = BoxDecoration(
      color: isSelected ? cs.primaryContainer : cs.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSelected ? cs.primary : cs.outlineVariant,
        width: isSelected ? 2 : 1,
      ),
    );

    final iconBoxDecoration = BoxDecoration(
      color: isSelected ? cs.primary : cs.surfaceContainerHigh,
      shape: BoxShape.circle,
    );

    return PressScale(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: containerDecoration,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: iconBoxDecoration,
                    child: Icon(
                      aspect.icon,
                      color: isSelected ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aspect.translationKey.tr(),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          aspect.descriptionKey.tr(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

⚠️ **不用 GlassCard**——AspectOption 需要條件式的 selected 狀態與顯眼邊框，GlassCard 是固定樣式。直接 Container 控制 decoration 更直接。

### 7. Imports

新增：
- `package:context_app/shared/widgets/midnight/midnight.dart`（barrel）
- `package:context_app/shared/widgets/midnight/_press_scale.dart`（直接）

移除：
- `package:context_app/common/config/app_colors.dart`（如果這個檔內所有 AppColors 都走光）

確認後若 `AppColors.primary` 還有其他殘留引用就保留 import。

## 測試策略

`select_narration_aspect_screen_test.dart` 既有 9 個 testWidgets，使用：
- `find.byType(AspectOption)` → 仍有效（class 名不變）
- `find.byIcon(Icons.check_box)` → 仍有效
- `find.text('config_screen.start_button')` → 仍有效（從 `AdaptiveButton` 包文字 → `PillButton.label`，文字仍透過 Text widget 出現）

**最小修改**：可能需要的細部調整：
- 若有測試斷言 `Container` 的 `BoxDecoration.color` 是 `Color(0xCC192633)`，要改成判斷 `surfaceVariant`（white@8%）。
- 若測試找 `Container.shape` 為圓形 → 仍 valid（icon container 仍是圓形）。

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| `_CategoryBadge` 縮小後 hero 感變弱 | 中 | 與 PlaceCard 一致是設計意圖；如果體驗不好，後續加 hero size 變體 |
| `AspectOption` selected 邊框 + ghost-border 規則衝突 | 低 | "no-line" 規則的目的是區隔 layout sections；selected 邊框是「強調此卡被選擇」，與 spec 不衝突 |
| Start `PillButton` 預設 padding 14v 可能視覺上比舊 `AdaptiveButton` 的 16v 矮 | 低 | 接受 MK 標準高度（一致性大於微差） |
| Test 384 個 stable assertion 可能因 widget tree 改變斷裂 | 中 | 跑 `select_narration_aspect_screen_test.dart`，逐個調整 — 預計 ≤3 個會壞 |

## 成功指標

1. 6 個 widgets 都 MK 化；hardcoded `Color(0x...)` 為 0；`AppColors.amber` 引用為 0（這個檔本來也沒有）。
2. 既有 `select_narration_aspect_screen_test.dart` 全 pass（最小修改）。
3. analyzer 對改動 file clean。
4. 全 suite 維持 390+ pass。
5. **跑起來看**：背景照片透過漸層平滑過渡到 surface；place name 顯眼；aspect 卡片有玻璃背景 + clear selected state（電光藍邊框 + 圖示色翻轉）；Start 按鈕是統一的 PillButton。
