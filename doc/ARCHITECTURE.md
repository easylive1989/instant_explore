# 架構設計文件

## 🏗️ 整體架構

Instant Explore 採用 **Feature-First** 架構設計，以功能模組為核心組織程式碼，每個功能模組內部遵循 Clean Architecture 原則。

### 架構原則

1. **模組化** - 每個功能獨立封裝，降低耦合度
2. **可擴展** - 新功能可以輕鬆添加，不影響現有模組
3. **可測試** - 清晰的依賴關係，便於單元測試
4. **可維護** - 程式碼組織清晰，便於團隊協作

## 📁 專案結構

```
instant_explore/
├── frontend/                 # Flutter 應用程式
│   ├── lib/
│   │   ├── main.dart         # 應用程式進入點
│   │   ├── core/             # 核心共用功能
│   │   │   ├── config/       # 應用程式設定
│   │   │   │   ├── api_keys.dart
│   │   │   │   ├── app_config.dart
│   │   │   │   └── theme_config.dart
│   │   │   ├── constants/    # 常數定義
│   │   │   │   ├── app_constants.dart
│   │   │   │   ├── api_constants.dart
│   │   │   │   └── ui_constants.dart
│   │   │   ├── utils/        # 工具函式
│   │   │   │   ├── date_utils.dart
│   │   │   │   ├── validation_utils.dart
│   │   │   │   └── format_utils.dart
│   │   │   └── services/     # 核心服務
│   │   │       ├── http_service.dart
│   │   │       ├── storage_service.dart
│   │   │       └── analytics_service.dart
│   │   ├── shared/           # 共用元件
│   │   │   ├── widgets/      # 共用 UI 元件
│   │   │   │   ├── custom_button.dart
│   │   │   │   ├── loading_widget.dart
│   │   │   │   └── error_widget.dart
│   │   │   └── models/       # 共用資料模型
│   │   │       ├── api_response.dart
│   │   │       └── user_preferences.dart
│   │   └── features/         # 功能模組
│   │       ├── location/     # 位置相關功能
│   │       ├── places/       # 地點推薦功能
│   │       ├── voting/       # 多人投票功能
│   │       └── navigation/   # 導航功能
│   ├── test/                 # 測試檔案
│   ├── assets/               # 靜態資源
│   ├── web/                  # Web 平台檔案
│   ├── ios/                  # iOS 平台檔案
│   ├── android/              # Android 平台檔案
│   └── pubspec.yaml          # Flutter 專案設定檔
├── doc/                      # 專案文件
└── README.md                 # 專案說明文件
```

## 🧩 Feature 模組結構

每個 Feature 模組內部採用 Clean Architecture 分層：

```
features/[feature_name]/
├── models/                   # 資料模型層
│   ├── [feature]_model.dart      # 資料實體
│   └── [feature]_repository.dart # 資料倉庫介面
├── services/                 # 業務邏輯層
│   ├── [feature]_service.dart     # 業務邏輯實作
│   └── [feature]_repository_impl.dart # 資料倉庫實作
├── widgets/                  # UI 元件層
│   ├── [feature]_card.dart        # 功能相關元件
│   └── [feature]_list.dart        # 清單元件
└── screens/                  # 畫面層
    ├── [feature]_screen.dart      # 主畫面
    └── [feature]_detail_screen.dart # 詳情畫面
```

## 🎯 核心模組說明

### Core 模組
負責應用程式的核心基礎設施：

- **config/** - 應用程式設定、主題、API 金鑰管理
- **constants/** - 全域常數定義
- **utils/** - 通用工具函式
- **services/** - 核心服務（HTTP、儲存、分析等）

### Shared 模組
提供跨功能的共用元件：

- **widgets/** - 可重用的 UI 元件
- **models/** - 跨模組共用的資料模型

### Features 模組

#### 1. Location 模組
- **職責：** 位置服務、GPS 定位、位置權限管理
- **主要功能：** 取得使用者位置、位置更新監聽

#### 2. Places 模組
- **職責：** 地點搜尋、推薦演算法、地點資訊管理
- **主要功能：** 附近地點搜尋、分類篩選、距離篩選

#### 3. Voting 模組
- **職責：** 多人協作決策、群組管理、投票機制
- **主要功能：** 建立群組、加入投票、結果統計

#### 4. Navigation 模組
- **職責：** 路線規劃、導航整合、交通方式選擇
- **主要功能：** 路線計算、導航啟動、ETA 預估

## 🔄 資料流架構

```
UI Layer (Screens/Widgets)
    ↕
Business Logic Layer (Services)
    ↕
Data Layer (Repository)
    ↕
External APIs (Google APIs)
```

### 資料流說明

1. **UI Layer** - 處理使用者互動和畫面渲染
2. **Business Logic Layer** - 處理業務邏輯和狀態管理
3. **Data Layer** - 處理資料存取和 API 呼叫
4. **External APIs** - Google Places API、Google Maps API

## 🎨 狀態管理

採用 **Riverpod** 模式進行狀態管理：

```dart
// 範例：地點狀態管理
@immutable
class PlacesState {
  final List<Place> places;
  final bool isLoading;
  final String? error;
  
  const PlacesState({
    this.places = const [],
    this.isLoading = false,
    this.error,
  });
  
  PlacesState copyWith({
    List<Place>? places,
    bool? isLoading,
    String? error,
  }) {
    return PlacesState(
      places: places ?? this.places,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PlacesNotifier extends StateNotifier<PlacesState> {
  PlacesNotifier(this._placesService) : super(const PlacesState());
  
  final PlacesService _placesService;
  
  Future<void> searchNearbyPlaces(LatLng location) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final places = await _placesService.searchNearby(location);
      state = state.copyWith(places: places, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: e.toString(),
      );
    }
  }
}

// Provider 定義
final placesNotifierProvider = StateNotifierProvider<PlacesNotifier, PlacesState>(
  (ref) => PlacesNotifier(ref.read(placesServiceProvider)),
);
```

## 🧪 測試架構

```
test/
├── unit/                     # 單元測試
│   ├── services/
│   ├── models/
│   └── utils/
├── widget/                   # Widget 測試
│   ├── screens/
│   └── widgets/
└── integration/              # 整合測試
    └── app_test.dart
```

## 📦 依賴管理

### 核心依賴
- **flutter** - 核心框架
- **flutter_riverpod** - 狀態管理
- **http** - HTTP 請求
- **shared_preferences** - 本地儲存

### 功能依賴
- **google_maps_flutter** - 地圖顯示
- **geolocator** - 位置服務
- **permission_handler** - 權限管理

### 開發依賴
- **flutter_test** - 測試框架
- **mockito** - Mock 框架
- **flutter_lints** - 程式碼規範

## 🔧 建置與部署

### 開發環境
```bash
flutter run --debug
```

### 生產環境
```bash
flutter build apk --release    # Android
flutter build ios --release    # iOS
flutter build web --release    # Web
```

## 📈 效能考量

### 優化策略
1. **圖片優化** - 使用 cached_network_image 快取圖片
2. **API 快取** - 實作 API 回應快取機制
3. **延遲載入** - 大型清單使用 ListView.builder
4. **記憶體管理** - 適當的 dispose 資源清理

### 監控指標
- API 回應時間
- 記憶體使用量
- 電池消耗
- 網路使用量

## 🔮 未來擴展

### 計劃中的模組
1. **Profile 模組** - 使用者個人資料管理
2. **History 模組** - 歷史記錄和收藏
3. **Social 模組** - 社交分享功能
4. **Notification 模組** - 推播通知

### 技術債務
1. 持續優化 Riverpod 狀態管理模式
2. 添加 GraphQL 支援
3. 實作離線快取策略
4. 添加國際化支援