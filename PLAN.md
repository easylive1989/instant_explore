# 功能實作計劃 (PLAN.md) - DDD 精確版 v2

這份文件嚴格遵循 DDD (領域驅動設計) 和清晰架構 (Clean Architecture) 原則，詳細列出各功能模組的 Use Case、領域模型互動、UI 與 Use Case 的互動模式，並將測試焦點精確地放在 Domain Model 和 Use Case 上。

## 核心領域模型與聚合 (Core Domain Models & Aggregates)

- **`User` (使用者)**: 代表應用的使用者，管理其個人資料和偏好。
- **`Place` (地點)**: 代表一個地理位置或景點，包含其基本資訊和業務規則。
- **`Narration` (導覽)**: 代表一次完整的語音導覽內容，與一個 `Place` 關聯，擁有自身的業務邏輯。
- **`Conversation` (對話)**: 代表一次使用者與 AI 的問答互動，管理消息流和對話狀態。
- **`Passport` (知識護照)**: 代表特定 `User` 的學習足跡，由多個 `PassportEntry` 組成，並管理足跡的相關規則。

---

## 1. 探索與定位 (Exploration & Location) - HomeScreen

### 領域模型互動
- **主要**: 與 `User` 聚合互動，以獲取用戶偏好。
- **次要**: 創建 `Coordinates` (屬於 `Place` 聚合) 值對象。

### Use Cases
- `GetCurrentLocationUseCase`: 獲取用戶當前的 `Coordinates` 和對應的地址。

### 實作計劃
- **Task 1.1: 領域模型**: 確保 `User` 聚合能夠處理語言偏好。
- **Task 1.2: Use Case**: 實現 `GetCurrentLocationUseCase`，注入 `LocationService` (基礎設施層接口)。
- **Task 1.3: 基礎設施**: 實現 `LocationService` 的具體實作 (使用 `geolocator` 套件)。
- **Task 1.4: UI (Riverpod) 層互動**
  - `getCurrentLocationUseCaseProvider`: `Provider`，提供 `GetCurrentLocationUseCase` 的實例。
  - `currentLocationProvider`: `FutureProvider`，調用 Use Case，處理 `Result` 並返回 `Position` 或拋出錯誤。
  - **UI Widget**: `watch` `currentLocationProvider`，並使用其 `when` 方法來顯示加載中、錯誤或成功獲取的位置資訊。
- **Task 1.5: 多國語系 (i18n)**: 將 UI 上的靜態文本 ("探索周邊" 等) 移至語言檔案。

### 測試計劃 (Testing Plan)
- **Use Case Test**: 測試 `GetCurrentLocationUseCase`，mock `LocationService`，驗證其在各種情況下的行為。
- **Domain Model Test**: 若 `User` 或 `Place` 有相關內部規則，則進行測試。

## 2. 附近地點列表 (Nearby Places) - NearbyPlacesScreen

### 領域模型互動
- **主要**: 與 `Place` 聚合互動。
- **流程**: Use Case 調用 `PlaceRepository`，後者從外部 API 獲取數據並構建 `Place` 聚合實例列表。

### Use Cases
- `SearchNearbyPlacesUseCase`: 接收 `Coordinates`，返回 `Result<List<Place>, Error>`。

### 實作計劃
- **Task 2.1: Use Case**: 實現 `SearchNearbyPlacesUseCase`，注入 `PlaceRepository`。
- **Task 2.2: 基礎設施**: 實現 `PlaceRepository` 接口及 `GooglePlacesPlaceRepository` 實作。
- **Task 2.3: UI (Riverpod) 層互動**
  - `searchNearbyPlacesUseCaseProvider`: `Provider`，提供 Use Case 實例。
  - `nearbyPlacesProvider`: `FutureProvider.family`，接收 `Coordinates`，調用 Use Case 並返回 `List<Place>`。
  - **UI Widget**: `watch` `nearbyPlacesProvider(coordinates)`，並使用 `when` 方法渲染 UI。
- **Task 2.4: 多國語系 (i18n)**: 將 "Nearby History" 等文本進行本地化。

### 測試計劃 (Testing Plan)
- **Use Case Test**: 測試 `SearchNearbyPlacesUseCase`，mock `PlaceRepository`，驗證成功與失敗場景。
- **Domain Model Test**: 測試 `Place.create()` 工廠構造函數，確保數據驗證邏輯。

## 3. 導覽設定 (Narration Configuration) - ConfigScreen

### 領域模型互動
- **主要**: 接收一個 `Place` 聚合實例。
- **次要**: 處理 `NarrationStyle` (屬於 `Narration` 聚合) 值對象的選擇。

### Use Cases
- (此畫面業務邏輯較少，可暫不設立 Use Case，或設立一個簡單的 `SelectNarrationStyleUseCase`)

### 實作計劃
- **Task 3.1: UI (Riverpod) 層互動**
  - `narrationStyleProvider`: `StateProvider`，用於管理用戶選擇的 `NarrationStyle` (`brief` 或 `deep_dive`)。
  - **UI Widget**: 接收 `Place` 物件並顯示其資訊。UI 根據 `narrationStyleProvider` 的狀態來更新。點擊按鈕時，將 `Place.id` 和 `ref.read(narrationStyleProvider)` 傳遞給 `PlayerScreen`。
- **Task 3.2: 多國語系 (i18n)**: 將 "選擇解說深度" 等文本移至語言檔案。

### 測試計劃 (Testing Plan)
- (此畫面核心邏輯在 UI 層，可通過 Widget 測試或整合測試覆蓋，暫不需 Domain/Use Case 測試。)

## 4. 導覽播放器 (Narration Player) - PlayerScreen

### 領域模型互動
- **主要**: 與 `Narration` 聚合互動。
- **流程**: Use Case 調用 `NarrationRepository` 構建 `Narration` 聚合。播放器操作會修改 `Narration` 的內部狀態。

### Use Cases
- `StartNarrationUseCase`: 接收 `PlaceId` 和 `NarrationStyle`，返回 `Result<Narration, Error>`。
- `UpdatePlaybackProgressUseCase`: 更新 `Narration` 的播放進度。

### 實作計劃
- **Task 4.1: Domain Model**: 實現 `Narration` 聚合，包含 `play()`, `pause()`, `updateProgress()` 等方法與業務規則。
- **Task 4.2: Use Cases**: 實現 `StartNarrationUseCase` 和 `UpdatePlaybackProgressUseCase`。
- **Task 4.3: 基礎設施**: 實現 `NarrationRepository` (與 AI 互動) 和 `AudioService` (使用 `flutter_tts`)。
- **Task 4.4: UI (Riverpod) 層互動**
  - `playerControllerProvider`: `StateNotifierProvider`，管理播放器的整體狀態 (如 `Narration` 物件、播放狀態等)。
  - `PlayerController` (`StateNotifier`) 會在其內部方法中調用 `StartNarrationUseCase` 等 Use Cases，並更新自身狀態。
  - **UI Widget**: `watch` `playerControllerProvider` 來更新 UI (文字稿、進度條)，並在按鈕點擊時調用 `ref.read(playerControllerProvider.notifier).pause()` 等方法。
- **Task 4.5: 多國語系 (i18n)**: 將 "Audio Guide" 等文本進行本地化。

### 測試計劃 (Testing Plan)
- **Domain Model Test**: 測試 `Narration` 聚合的狀態轉換方法。
- **Use Case Test**: 測試 `StartNarrationUseCase`，mock `NarrationRepository`。

## 5. AI 問答 (AI Q&A) - QAScreen

### 領域模型互動
- **主要**: 與 `Conversation` 聚合互動。
- **流程**: Use Case 加載或創建 `Conversation` 實例，用戶問題被添加到聚合中，`ConversationRepository` 負責持久化和獲取 AI 回答。

### Use Cases
- `GetConversationUseCase`: 獲取或創建一個對話。
- `AskQuestionUseCase`: 接收 `ConversationId` 和 `QuestionText`，返回更新後的 `Conversation`。

### 實作計劃
- **Task 5.1: Domain Model**: 實現 `Conversation` 聚合，包含 `addMessage(Message)` 方法和管理對話歷史的規則。
- **Task 5.2: Use Cases**: 實現 `GetConversationUseCase` 和 `AskQuestionUseCase`。
- **Task 5.3: 基礎設施**: 實現 `ConversationRepository` (與 Gemini API 互動) 和 `SpeechToTextService`。
- **Task 5.4: UI (Riverpod) 層互動**
  - `qaControllerProvider`: `StateNotifierProvider`，管理 `Conversation` 狀態。
  - `QAController` (`StateNotifier`) 會調用 `AskQuestionUseCase`，並在成功後更新其狀態為新的 `Conversation` 物件。
  - **UI Widget**: `watch` `qaControllerProvider` 來顯示對話列表。輸入問題後，調用 `ref.read(qaControllerProvider.notifier).askQuestion(text)`。
- **Task 5.5: 多國語系 (i18n)**: 將 "Ask about..." 等文本本地化。

### 測試計劃 (Testing Plan)
- **Domain Model Test**: 測試 `Conversation` 的 `addMessage` 方法。
- **Use Case Test**: 測試 `AskQuestionUseCase`，mock `ConversationRepository`。

## 6. 知識護照 (Knowledge Passport) - PassportScreen

### 領域模型互動
- **主要**: 與 `Passport` 聚合互動。
- **流程**: Use Case 調用 `PassportRepository` 為當前 `User` 獲取 `Passport` 聚合。

### Use Cases
- `GetMyPassportUseCase`: 接收 `UserId`，返回 `Result<Passport, Error>`。
- `AddEntryToPassportUseCase`: 由領域事件觸發，更新 `Passport`。

### 實作計劃
- **Task 6.1: Domain Model**: 實現 `Passport` 和 `PassportEntry` 模型，定義 `addEntry` 方法和相關業務規則。
- **Task 6.2: Use Cases**: 實現 `GetMyPassportUseCase` 和 `AddEntryToPassportUseCase`。
- **Task 6.3: 基礎設施**: 實現 `PassportRepository` (與 Supabase 互動)。
- **Task 6.4: UI (Riverpod) 層互動**
  - `passportProvider`: `FutureProvider`，調用 `GetMyPassportUseCase` 來獲取並顯示 `Passport` 物件。
  - **UI Widget**: `watch` `passportProvider` 並使用其 `when` 方法來顯示時間軸或錯誤/加載狀態。
- **Task 6.5: 多國語系 (i18n)**: 將 "Knowledge Passport", "Today" 等文本本地化。

### 測試計劃 (Testing Plan)
- **Domain Model Test**: 測試 `Passport` 聚合的 `addEntry` 方法的業務規則。
- **Use Case Test**: 測試 `GetMyPassportUseCase`，mock `PassportRepository`。
