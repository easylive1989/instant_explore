# 播放頁改造成 Editorial Reader

日期：2026-06-02
狀態：設計已核准，待實作

## 背景

目前的導覽播放頁（`NarrationScreen`）與設計稿 `docs/design`（`screens_story.jsx` 的
`ReaderView` + `ls2.css` 的 `.reader__*` / `.audiobar`）有明顯落差：

- **背景全黑**：`narration_screen.dart` 用 `_nightReadingTokens(...)` 強制把閱讀面覆寫成
  夜間黑（`readBg #1B1611`）。設計稿用暖色紙質閱讀面（`--read-bg #F7F1E6`）。
- **沒有 hero 圖片**：現在開頁就直接進入逐段轉錄 `ListView`，缺少設計稿開頭的
  `reader__hero`（地點照片 + scrim + 標題）。

本設計讓播放頁對齊 editorial reader 外觀，同時保留既有的 TTS 逐段高亮與自動捲動行為。

## 目標

1. 閱讀面從強制夜間黑改為暖色紙質（沿用使用者的 reading-surface 偏好預設）。
2. 加入可捲動的 hero 圖片區，含故事標題與地點小標。
3. 首段加上近似的 drop cap 作為 lede 強調。

非目標：章節徽章（`Anno·I`）與拉丁地名（`ST. PETER'S BASILICA·VATICAN`）——App 無對應資料，
不做。真正文字環繞式的 dropcap（Flutter 無 CSS float）——不做，採內嵌近似。

## 現況資料流

- `SelectStoryHookScreen._onHookSelected(hook)` → `generate(place, language, hook)` → 成功後
  `_navigateToPlayer` 以 extra `{place, narrationContent, autoPlay}` 導到 `player` route。
- `router_config.dart` 的 `player` route 由 extra 建出 `NarrationScreen(place, narrationContent, autoPlay)`。
- 第二個入口：`journey/.../timeline_entry.dart` 也導到 `player`，但建出的是
  **無照片**（`photos: const []`）且無故事標題的 partial `Place`。
- `NarrationContent` 只有 `text / segments / language / grounding`，**沒有**標題或圖片。
- 故事標題只存在於使用者選到的 `StoryHook.title`，目前未傳進播放頁。

## 設計

### 1. 閱讀面：移除強制夜間覆寫

- 刪除 `narration_screen.dart` 的 `_nightReadingTokens(...)` 與包住整頁的 `Theme(...)` wrapper。
- 改用環境中的 `ReadingPalette.of(context)`（暖紙：`readBg #F7F1E6`、`readInk #2A2013`、
  `readDim #6A5A3E`、`readCap #97442A`），與 Field Journal 其餘畫面一致。
- `AnnotatedRegion<SystemUiOverlayStyle>` 由 `light` 改為 `dark`（淺紙底配深色狀態列圖示）。
- `transcript_segment_item.dart` 不改邏輯：active 段落用 `readInk` 深褐 + clay 左標、
  inactive 用 `readDim`，在暖紙上即呈現設計稿「已讀/未讀」對比。
- `narration_transcript_area.dart` 的頂/底漸層遮罩沿用 `palette.readBg`，自動跟著變暖紙色。

### 2. 把故事標題傳進播放頁

- `SelectStoryHookScreen`：在 `_onHookSelected(hook)` 時記住所選 `hook?.title`
  （存成 state 欄位，例如 `String? _selectedStoryTitle`）；`_navigateToPlayer` 時在 extra
  帶上 `storyTitle`。
- `router_config.dart`：`player` route 由 extra 讀 `storyTitle`（optional `String`），
  傳給 `NarrationScreen`。redirect 驗證不需新增（`storyTitle` 可為 null）。
- `NarrationScreen`：新增 `final String? storyTitle;`（可選，預設 null）。
- `timeline_entry.dart`：不帶 `storyTitle` → 播放頁自動 fallback 成地點名稱，**不需改它**。

### 3. 可捲動的 hero（跟著捲走）

- 把目前 `select_story_hook_screen.dart` 內的私有 hero 元件抽成共用 widget
  `features/narration/presentation/widgets/editorial_hero.dart`，兩畫面共用，避免重複 ~80 行：
  - hero 背景（`Image.memory` 截圖 / `CachedNetworkImage` 照片 / 分類色 glyph fallback）
  - hero scrim 漸層常數
  - glyph fallback 背景
  - `select_story_hook_screen.dart` 改為引用此共用元件（順手的小重構，已獲使用者同意）。
- 播放頁的 hero 成為轉錄 `ListView` 的**第一個項目**（取代現在的 `SizedBox(height: 60)`
  頂部留白），往下讀時 hero 隨內容上移捲走（符合設計稿 `reader__hero` 在 `screen__scroll` 內）。
- hero 高度約 300px（設計稿 `.reader__hero { height:300px }`）。
- caption 在左下、壓在 scrim 上：
  - 上方小標（小字、寬字距 ~0.16em、白 82%）= `place.name` — **僅在有 `storyTitle` 時**顯示
  - 主標（`GoogleFonts.notoSerifTc`、白、約 28px、w700）= `storyTitle ?? place.name`
  - 不做章節徽章、不做拉丁地名。
- 圖片來源 `place.primaryPhoto?.url`；無照片 → 分類色 glyph 漸層 fallback。journey 入口因無照片
  會走此 fallback（可接受的優雅退化）。

### 4. 首段 drop cap（近似）

- 在第一段（segment index 0）用 `Text.rich`，把首字以大號 serif、`readCap #97442A` 紅土色
  呈現作為 lede 強調。
- Flutter 無 CSS float，無法做到文字環繞首字的真正 dropcap；此為內嵌近似。真正環繞式 dropcap
  列為後續可能的改進，不在本次範圍。
- drop cap 為第一段的靜態裝飾，與該段是否為 active（TTS 高亮）無關。

## 測試

- 更新既有：`narration_screen_test.dart`、`narration_screen_stop_on_leave_test.dart`
  （新增 `storyTitle` 參數；hero 出現後的結構調整）。
- 新增 widget test：
  - 有 `storyTitle` 時，hero 顯示故事標題（主標）+ 地點名稱（小標）。
  - 無 `storyTitle` 時，hero 主標為地點名稱、不顯示小標。
  - 有照片 → 渲染照片；無照片 → 渲染 glyph fallback。
  - 首段顯示 drop cap 首字。
- `SelectStoryHookScreen`：選擇某個 hook 後導頁，extra 帶上對應的 `storyTitle`。

## 受影響檔案（預估）

- `frontend/lib/features/narration/presentation/screens/narration_screen.dart`（核心）
- `frontend/lib/features/narration/presentation/widgets/editorial_hero.dart`（新增）
- `frontend/lib/features/narration/presentation/widgets/narration_transcript_area.dart`
- `frontend/lib/features/narration/presentation/widgets/transcript_segment_item.dart`
- `frontend/lib/features/narration/presentation/screens/select_story_hook_screen.dart`
- `frontend/lib/app/config/router_config.dart`
- 對應 test 檔
