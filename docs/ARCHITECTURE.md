# 架構設計文件

## 🏗️ 整體架構

Instant Explore 採用 **Feature-First** 架構設計，以功能模組為核心組織程式碼，每個功能模組內部遵循 Clean Architecture 原則。

### 架構原則

1. **模組化** - 每個功能獨立封裝，降低耦合度
2. **可擴展** - 新功能可以輕鬆添加，不影響現有模組
3. **可測試** - 清晰的依賴關係，便於單元測試
4. **可維護** - 程式碼組織清晰，便於團隊協作
5. **安全性** - 敏感資訊使用環境變數管理，絕不提交到版本控制
6. **行動優先** - 專注手機使用場景，確保最佳體驗

## 📁 專案結構

```
instant_explore/
├── frontend/                 # Flutter 應用程式
│   ├── lib/
│   │   ├── main.dart         # 應用程式進入點
│   │   ├── core/             # 核心共用功能
│   │   │   ├── config/       # 應用程式設定
│   │   │   │   ├── api_keys.dart      # 安全 API 金鑰管理
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
│   │   │   ├── models/       # 基礎設施資料模型
│   │   │   │   └── api_response.dart
│   │   │   └── services/     # 核心服務
│   │   │       ├── http_service.dart
│   │   │       ├── storage_service.dart
│   │   │       └── analytics_service.dart
│   │   ├── shared/           # 共用元件
│   │   │   ├── widgets/      # 共用 UI 元件
│   │   │   │   ├── custom_button.dart
│   │   │   │   ├── loading_widget.dart
│   │   │   │   └── error_widget.dart
│   │   │   └── models/       # 跨功能業務模型
│   │   │       └── user_preferences.dart
│   │   └── features/         # 功能模組
│   │       ├── location/     # 位置相關功能
│   │       ├── places/       # 地點推薦功能
│   │       ├── voting/       # 多人投票功能
│   │       ├── navigation/   # 導航功能
│   │       └── subscription/ # 訂閱管理功能
│   ├── test/                 # 測試檔案
│   ├── assets/               # 靜態資源
│   ├── ios/                  # iOS 平台檔案
│   ├── android/              # Android 平台檔案
│   └── pubspec.yaml          # Flutter 專案設定檔
├── scripts/                  # 執行腳本（可選）
│   ├── dev.sh               # Unix/Linux/macOS 開發腳本
│   ├── dev.bat              # Windows 開發腳本
│   └── setup.sh             # 環境設定腳本
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

- **config/** - 應用程式設定、主題、安全 API 金鑰管理
- **constants/** - 全域常數定義
- **utils/** - 通用工具函式
- **models/** - 基礎設施資料模型（API 回應格式等）
- **services/** - 核心服務（HTTP、儲存、分析等）

### Shared 模組
提供跨功能的共用元件：

- **widgets/** - 可重用的 UI 元件
- **models/** - 跨功能的業務領域模型（使用者偏好設定等）


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
- **supabase_flutter** - 後端服務（認證、資料庫）
- **google_sign_in** - Google 登入整合
- **sign_in_with_apple** - Apple 登入整合
- **in_app_purchase** - 應用內購買（訂閱管理）
- **shared_preferences** - 本地配額追蹤
- **go_router** - 路由管理

### 開發依賴
- **flutter_test** - 測試框架
- **mocktail** - Mock 框架 (null-safety 支援)
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
```

### 平台特性說明

## 🔒 安全性架構

### API 金鑰管理

```dart
// lib/core/config/api_keys.dart
class ApiKeys {
  // 使用環境變數讀取，絕不硬編碼
  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // 安全性檢查
  static bool get isConfigured {
    return googlePlacesApiKey.isNotEmpty &&
           googleMapsApiKey.isNotEmpty;
  }

  // 安全存取方法
  static String get currentPlacesApiKey {
    if (googlePlacesApiKey.isEmpty) {
      throw ApiKeyNotConfiguredException('GOOGLE_PLACES_API_KEY');
    }
    return googlePlacesApiKey;
  }
}
```

### 環境變數管理

```
專案根目錄/
├── .env                    # 本地環境變數（不提交）
├── .env.example           # 環境變數範例（可提交）
├── .gitignore            # 排除敏感檔案
└── scripts/              # 自動化腳本（可選）
    └── run_dev.sh           # 開發執行腳本
```

### 安全檢查清單

- [ ] API 金鑰使用環境變數
- [ ] .env 檔案已加入 .gitignore
- [ ] CI/CD 使用 GitHub Secrets
- [ ] 應用程式啟動時驗證金鑰
- [ ] 不同環境使用不同金鑰
- [ ] 定期輪換 API 金鑰
