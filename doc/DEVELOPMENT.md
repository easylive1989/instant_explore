# 開發指南

## 📋 系統需求

### 開發環境
- **Flutter SDK:** 3.32.4
- **Dart SDK:** 3.8.4
- **IDE:** Android Studio / VS Code / IntelliJ IDEA
- **版本控制:** Git
- **Google Cloud Platform 帳號**（用於 API 金鑰）

### 平台需求

#### macOS (用於 iOS 開發)
- **macOS:** 10.15 或以上版本
- **Xcode:** 13.0 或以上版本
- **CocoaPods:** 1.11.0 或以上版本

#### Windows / Linux (用於 Android 開發)
- **Android Studio:** 2021.1.1 或以上版本
- **Android SDK:** API level 21 或以上版本
- **Java:** JDK 11 或以上版本

### 支援的裝置
- **iOS:** 11.0 或以上版本
- **Android:** 5.0 (API level 21) 或以上版本
- **Web:** 現代瀏覽器（Chrome、Firefox、Safari、Edge）

## 🚀 快速開始

### 1. 環境準備

#### 安裝 Flutter
```bash
# macOS
brew install flutter

# 或手動下載
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"

# 驗證安裝
flutter doctor
```

#### 安裝 IDE 擴充套件
- **VS Code:** Flutter, Dart
- **Android Studio:** Flutter plugin, Dart plugin

### 2. 專案設定

#### 複製專案
```bash
git clone https://github.com/[your-username]/instant_explore.git
cd instant_explore/frontend
```

#### 安裝相依套件
```bash
flutter pub get
```

#### 驗證設定
```bash
flutter doctor
flutter devices  # 確認可用裝置
```

### 3. API 設定

#### 申請 Google API 金鑰
1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 建立新專案或選擇現有專案
3. 啟用以下 API：
   - Google Places API (New)
   - Google Maps SDK for Android
   - Google Maps SDK for iOS
   - Google Maps JavaScript API
   - Directions API

#### 設定 API 金鑰
建立 `lib/core/config/api_keys.dart` 檔案：

```dart
class ApiKeys {
  static const String googlePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // 開發環境和正式環境可以使用不同的金鑰
  static String get currentPlacesApiKey {
    return const bool.fromEnvironment('dart.vm.product')
        ? googlePlacesApiKey
        : 'YOUR_DEV_PLACES_API_KEY';
  }
}
```

#### 設定平台特定配置

**Android (android/app/src/main/AndroidManifest.xml):**
```xml
<manifest ...>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application ...>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
    </application>
</manifest>
```

**iOS (ios/Runner/Info.plist):**
```xml
<dict>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>需要您的位置來推薦附近的好去處</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>需要您的位置來持續推薦附近的好去處</string>
</dict>
```

### 4. 執行應用程式

```bash
# iOS 模擬器
flutter run -d ios

# Android 模擬器
flutter run -d android

# Web 瀏覽器
flutter run -d chrome

# 指定裝置
flutter devices
flutter run -d [device-id]
```

## 🧪 測試

### 執行測試
```bash
# 執行所有測試
flutter test

# 執行特定測試檔案
flutter test test/unit/services/places_service_test.dart

# 執行整合測試
flutter test integration_test/

# 測試覆蓋率
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 測試指南

#### 單元測試範例
```dart
// test/unit/services/places_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('PlacesService', () {
    late PlacesService placesService;
    late MockHttpService mockHttpService;

    setUp(() {
      mockHttpService = MockHttpService();
      placesService = PlacesService(mockHttpService);
    });

    test('should return places when API call is successful', () async {
      // Arrange
      when(mockHttpService.get(any))
          .thenAnswer((_) async => mockApiResponse);

      // Act
      final result = await placesService.searchNearby(testLocation);

      // Assert
      expect(result, isA<List<Place>>());
      expect(result.length, 5);
    });
  });
}
```

#### Widget 測試範例
```dart
// test/widget/screens/places_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PlacesScreen should display places list', (tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: PlacesScreen(),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('附近推薦'), findsOneWidget);
  });
}
```

## 📏 程式碼規範

### Dart 程式碼風格
使用官方的 [Dart Style Guide](https://dart.dev/guides/language/effective-dart)

#### 重要規則
1. **檔案命名：** 使用 `snake_case`
2. **類別命名：** 使用 `PascalCase`
3. **變數命名：** 使用 `camelCase`
4. **常數命名：** 使用 `lowerCamelCase`

#### 程式碼格式化
```bash
# 格式化程式碼
dart format .

# 檢查程式碼風格
dart analyze

# 自動修正簡單問題
dart fix --apply
```

### Linting 設定
使用 `analysis_options.yaml` 設定：

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - build/**
    - lib/generated/**

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: true
    avoid_unnecessary_containers: true
```

### 資料夾結構規範
```
lib/
├── core/
│   ├── config/
│   ├── constants/
│   ├── utils/
│   └── services/
├── shared/
│   ├── widgets/
│   └── models/
└── features/
    └── [feature_name]/
        ├── models/
        ├── services/
        ├── widgets/
        └── screens/
```

## 🔄 Git 工作流程

### 分支策略
- **main** - 正式版本分支
- **develop** - 開發整合分支
- **feature/[feature-name]** - 功能開發分支
- **hotfix/[issue-name]** - 緊急修復分支

### 提交訊息規範
使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### 範例
```
feat(places): add distance filtering for search results

- Implement distance slider component
- Add distance parameter to search API
- Update places service to handle distance filtering

Closes #123
```

#### 類型說明
- **feat** - 新功能
- **fix** - 修復 bug
- **docs** - 文件更新
- **style** - 程式碼格式調整
- **refactor** - 重構程式碼
- **test** - 測試相關
- **chore** - 建置或工具相關

### 程式碼審查清單
- [ ] 程式碼符合專案風格規範
- [ ] 包含適當的單元測試
- [ ] 更新相關文件
- [ ] 無 console.log 或 print 語句
- [ ] 處理邊界情況和錯誤
- [ ] 效能影響評估

## 🔧 建置與部署

### 建置指令
```bash
# Debug 版本
flutter build apk --debug
flutter build ios --debug

# Release 版本
flutter build apk --release
flutter build ios --release
flutter build web --release

# 分析建置檔案大小
flutter build apk --analyze-size
```

### 環境變數設定
```bash
# 開發環境
flutter run --dart-define=ENVIRONMENT=development

# 正式環境
flutter build apk --dart-define=ENVIRONMENT=production
```

### 程式碼中使用環境變數
```dart
class AppConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
}
```

## ❓ 常見問題

### Q: Flutter Doctor 顯示錯誤怎麼辦？
A: 根據錯誤訊息逐一解決：
- Android toolchain: 安裝 Android Studio 和 SDK
- iOS toolchain: 安裝 Xcode 和 CocoaPods
- IDE plugins: 安裝 Flutter 和 Dart 擴充套件

### Q: 如何解決 iOS 建置錯誤？
A: 常見解決方案：
```bash
cd ios
pod install --repo-update
cd ..
flutter clean
flutter build ios
```

### Q: 如何處理 API 金鑰安全性？
A: 
1. 絕不將 API 金鑰提交到版本控制
2. 使用環境變數或設定檔案
3. 在 CI/CD 中使用密鑰管理服務
4. 為不同環境使用不同的金鑰

### Q: 如何偵錯效能問題？
A: 使用 Flutter 內建工具：
```bash
flutter run --profile
# 在 app 中按 'P' 開啟效能工具
```

### Q: 如何處理狀態管理？
A: 專案使用 Provider 模式：
```dart
// 在 main.dart 中設定
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PlacesProvider()),
    ChangeNotifierProvider(create: (_) => LocationProvider()),
  ],
  child: MyApp(),
)

// 在 widget 中使用
Consumer<PlacesProvider>(
  builder: (context, provider, child) {
    return ListView.builder(
      itemCount: provider.places.length,
      itemBuilder: (context, index) => PlaceCard(provider.places[index]),
    );
  },
)
```

## 📚 參考資源

- [Flutter 官方文件](https://flutter.dev/docs)
- [Dart 語言指南](https://dart.dev/guides)
- [Google Places API 文件](https://developers.google.com/maps/documentation/places/web-service)
- [Flutter 測試指南](https://flutter.dev/docs/testing)
- [Provider 狀態管理](https://pub.dev/packages/provider)