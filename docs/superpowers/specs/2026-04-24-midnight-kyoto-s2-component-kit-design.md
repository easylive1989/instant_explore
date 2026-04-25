# Midnight Kyoto S2 — Component Kit 設計文件

- 日期：2026-04-24
- Sprint：S2（共 3 個 sprint：S1 token、S2 元件庫、S3 feature 翻新）
- 範圍：`frontend/lib/shared/widgets/midnight/`（新增）、`frontend/lib/common/config/theme_config.dart`、`frontend/lib/app.dart`

## 背景與目標

S1 把 token 與 ThemeData 鋪平，但 Midnight Kyoto 的視覺語彙（玻璃 card、pill button、status chip、blur dock 導航、全局氣氛背景）還是要靠**自家共用 widget** 才能落地。S2 的工作是把這套語彙先做成可重複使用的元件，**搭配 widget tests 一次到位**，不動既有 feature screen——這樣 S3 才有現成詞彙可換。

## 已決策事項（與用戶確認）

| 議題 | 決定 |
|---|---|
| AmbientBackdrop 圖片紋理 | S2 暫不綁，僅做 base + gradient + pulse；widget 暴露 `decorationImage` hook 供之後加 asset |
| `scaffoldBackgroundColor` | 改成 `Colors.transparent`，與 backdrop 接線放同一個 task |
| 既有 `MidnightKyotoBackdrop` | 維持不動；onboarding/paywall 雙層 backdrop 屬可接受的「hero punch-up」 |
| 互動動畫 | 抽出共用 `_PressScale` helper widget，包 `AnimatedScale`，被需要 active-scale 的元件共用 |
| 元件目錄 | `frontend/lib/shared/widgets/midnight/`（自成一個資料夾） |
| 命名 | 大多 `GlassCard / PillButton`（無 prefix），但 `MidnightAppBar / MidnightBottomNav` 加 prefix 避免與 Material `AppBar` / `BottomNavigationBar` 混淆 |

## 不在 S2 範圍

- ❌ 套用到任何 feature screen（→ S3）
- ❌ 移除既有 `MidnightKyotoBackdrop`（→ 保留作為 hero 圖層）
- ❌ 圖片紋理 asset（→ 留 hook 給未來）
- ❌ 動畫框架／物理引擎調整
- ❌ Light theme 變體（→ 永久 out of scope）

## 設計

### 共用 helper：`_PressScale`

私有內部 widget，包 `AnimatedScale`：

```dart
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, this.onTap, this.scale = 0.95});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  // ...
}
```

按下縮到 0.95、放開回 1.0、150ms ease-out。`onTap` null 時不縮（disabled 狀態）。**不對外 export**——只在 midnight/ 內部用。

### 元件 1：`AmbientBackdrop`

```dart
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({
    super.key,
    required this.child,
    this.decorationImage,  // 預設 null；未來丟入 asset 即啟用
  });
  final Widget child;
  final DecorationImage? decorationImage;
}
```

實作三層 Stack：
1. 底層：`backgroundDark` 純色
2. 中層：若 `decorationImage` 非 null，套圖片（mix-blend-overlay 經 `BlendMode.overlay`）
3. 頂層：垂直漸層 `[backgroundDark, transparent, backgroundDark]` 確保上下文字易讀
4. 中央偏上的「neon pulse」呼吸光暈：用 `RepaintBoundary` + `TweenAnimationBuilder` 4 秒週期淡入淡出 `primaryContainer`

`child` 直接疊在最上層。

### 元件 2：`GlassCard`

```dart
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
}
```

實作：
- `ClipRRect` 包 `BackdropFilter(ImageFilter.blur(sigmaX: 12, sigmaY: 12))`
- 內層 `DecoratedBox`：`color: surfaceVariant`（white@8%）、`border: outlineVariant`、`borderRadius: borderRadius ?? BorderRadius.circular(12)`
- `padding` 套在內容外
- 若 `onTap` 非 null：用 `_PressScale` 包整體 + `Material(InkWell)` 提供 ripple

### 元件 3：`PillButton`

```dart
enum PillButtonVariant { primary, secondary, ghost }

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.icon,           // 可選 leading icon
    this.fullWidth = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
}
```

樣式對照：

| variant | background | foreground | shadow |
|---|---|---|---|
| primary | `primary` | `onPrimary` | `BoxShadow(color: primary @ 20%, blur: 16)` |
| secondary | `surfaceContainerHigh` + 1px `outlineVariant` 邊 | `onSurface` | 無 |
| ghost | 透明（hover 時 `primary @ 10%`）| `primary` | 無 |

共用：
- `StadiumBorder()` 形狀
- 高度 44px（`padding: 24h × 14v`）
- text style: 14px / w700
- `_PressScale(onTap: onPressed, child: ...)`
- 若 `onPressed == null` → bg/fg 套 50% 透明，並停用 PressScale

### 元件 4：`PillIconButton`

```dart
enum PillIconButtonVariant { filled, ghost }

class PillIconButton extends StatelessWidget {
  const PillIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = PillIconButtonVariant.filled,
    this.size = 48,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final PillIconButtonVariant variant;
  final double size;
  final String? tooltip;
}
```

| variant | background | iconColor |
|---|---|---|
| filled | `primary` + `shadow primary @ 20%` | `onPrimary` |
| ghost | `surfaceContainerHigh` + `outlineVariant` border | `onSurface` |

圓形（`shape: CircleBorder()`）、`Tooltip` wrap、`_PressScale`。

### 元件 5：`StatusChip`

```dart
enum StatusChipTone { active, neutral, error, warning, success }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusChipTone.neutral,
    this.icon,  // 可選 leading icon (12px)
  });
}
```

樣式對照：

| tone | background | foreground |
|---|---|---|
| active | `primaryContainer` | `primary` |
| neutral | `surfaceContainerHigh` | `onSurface` |
| error | `errorContainer` | `error` |
| warning | `tertiaryContainer` | `tertiary` |
| success | `secondaryContainer` | `secondary` |

實作：高度 ~24px、圓角 4px、padding 8h × 4v、text 10px uppercase w700 letterSpacing 1.5（MK metadata 規範）。

### 元件 6：`MidnightAppBar`

```dart
class MidnightAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MidnightAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.uppercaseTitle = true,
    this.blurSigma = 12,
  });
  // ...
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

實作：
- 透明 `AppBar` 用 `BackdropFilter(blur)` 包整體
- `surface @ 80%` 半透明覆蓋以增強對比
- bottom 1px `outlineVariant` divider
- title style: 18px w700 letterSpacing -0.3，若 `uppercaseTitle` 為 true 則套 `text.toUpperCase()`

### 元件 7：`MidnightBottomNav`

```dart
class MidnightBottomNavItem {
  const MidnightBottomNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });
}

class MidnightBottomNav extends StatelessWidget {
  const MidnightBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });
}
```

實作：
- 透明 + `BackdropFilter(blur 16)`
- top 1px `outlineVariant` divider
- 每個 item 用 `_PressScale`，scale 0.9（比 PillButton 更明顯）
- active item 額外用 `primaryContainer` 圓角背景 + `primary` icon/label
- inactive item 用 `onSurfaceVariant` 40% opacity
- label 10px uppercase w700 letterSpacing 1.5

### 全局接線：`AmbientBackdrop` → `MaterialApp.builder`

`app.dart` 修改：

```dart
return MaterialApp.router(
  // ...
  builder: (context, child) {
    return AmbientBackdrop(
      child: Stack(
        children: [
          child!,
          if (pendingShare != null && pendingShare.isLoading)
            const _ShareLoadingOverlay(),
        ],
      ),
    );
  },
);
```

`theme_config.dart` 修改：
- `scaffoldBackgroundColor: Colors.transparent`（從 `backgroundDark`）
- `appBarTheme.backgroundColor` 已經是 `Colors.transparent`（S1 已設）

### 統一 export

新增 `frontend/lib/shared/widgets/midnight/midnight.dart`：

```dart
export 'ambient_backdrop.dart';
export 'glass_card.dart';
export 'pill_button.dart';
export 'pill_icon_button.dart';
export 'status_chip.dart';
export 'midnight_app_bar.dart';
export 'midnight_bottom_nav.dart';
```

S3 各 feature 只 import 這一個檔即可拿到全部。

## 測試策略

### Widget tests（每個元件一個 test 檔）

通用 contract：
- 渲染不 crash（`expect(find.byType(X), findsOneWidget)`）
- 主要視覺 token 正確（針對 `Container.color` 或 `Material.color` 斷言）
- 互動：`onPressed/onTap` 正確觸發（`tester.tap` + verify callback called）
- 停用狀態：null callback 不觸發（`tester.tap` 不會 throw、callback 維持 0 次）
- 變體（variant）：每個 variant 用 group 包，斷言對應顏色

特殊：
- `AmbientBackdrop`：驗證 child 出現在 stack 頂層
- `GlassCard`：驗證 BackdropFilter 存在
- `MidnightAppBar`：驗證 `preferredSize.height == kToolbarHeight`
- `MidnightBottomNav`：驗證 currentIndex 對應 active 樣式

### 整合驗證

- `fvm flutter analyze --fatal-infos`：S2 新增的所有檔必須 0 issues（既有的 33 個 deprecation 不變）
- `fvm flutter test`：357 + 新增 ≈ 380+ tests 全 pass

## 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| `BackdropFilter` 多層疊加效能差（AmbientBackdrop + GlassCard + MidnightAppBar/Nav 都有 blur）| 中 | 用 `RepaintBoundary` 隔離 + `BlendMode.srcOver` 而非 dstIn；後續 profile 看 |
| `scaffoldBackgroundColor: transparent` 觸發既有 widget test 視覺斷言 fail | 中 | 既有 widget tests 多數不斷顏色；若 fail 在 task 內就地修 |
| `_PressScale` 與 `InkWell` ripple 動畫衝突 | 低 | `_PressScale` 包外、`InkWell` 包內，ripple 在 child 內反而與 scale 形成漂亮疊加效果 |
| `MidnightAppBar` 透明背景在無 backdrop 的 widget test 中看不到 | 低 | 測試時用 `MaterialApp` + 簡單 background 即可 |
| Pulse 動畫永不停止 → ProviderScope dispose 後 leak | 中 | `TweenAnimationBuilder` 跟隨 widget lifecycle，無 leak；用 `RepaintBoundary` 隔離以避免 entire screen invalidate |

## 成功指標

1. 7 個元件 + 1 個 helper 全部建好，每個有 widget test。
2. AmbientBackdrop 接線到 MaterialApp，`scaffoldBackgroundColor: transparent`。
3. 全 357+ tests pass + 新增 widget tests pass。
4. `fvm flutter analyze --fatal-infos` 對 S2 新增檔 0 issues。
5. `frontend/lib/shared/widgets/midnight/midnight.dart` barrel export 提供一致的 import 路徑。
6. **跑起來看時**：app 整體有玻璃 + 電光藍 + 黑底氣氛，但既有 feature screen 仍是舊樣式（S3 才換）。
