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

**重要：絕不將真實 API 金鑰提交到版本控制！**

##### 1. 建立環境變數檔案
在專案根目錄建立 `.env` 檔案（加入 .gitignore）：

```bash
# .env
GOOGLE_PLACES_API_KEY=你的真實_Places_API_金鑰
GOOGLE_MAPS_API_KEY=你的真實_Maps_API_金鑰
```

##### 2. 建立 `lib/core/config/api_keys.dart` 檔案：

```dart
class ApiKeys {
  // 使用環境變數讀取 API 金鑰
  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );
  
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  
  // 檢查 API 金鑰是否已設定
  static bool get isConfigured {
    return googlePlacesApiKey.isNotEmpty && 
           googleMapsApiKey.isNotEmpty;
  }
  
  // 為不同環境提供不同的設定
  static String get currentPlacesApiKey {
    if (googlePlacesApiKey.isEmpty) {
      throw Exception('未設定 GOOGLE_PLACES_API_KEY 環境變數');
    }
    return googlePlacesApiKey;
  }
  
  static String get currentMapsApiKey {
    if (googleMapsApiKey.isEmpty) {
      throw Exception('未設定 GOOGLE_MAPS_API_KEY 環境變數');
    }
    return googleMapsApiKey;
  }
}
```

##### 3. 設定 .gitignore
在專案根目錄的 `.gitignore` 檔案中加入：

```gitignore
# API 金鑰和敏感資訊
.env
.env.local
.env.development
.env.staging
.env.production

# API 金鑰檔案
lib/core/config/api_keys_local.dart
**/api_keys_real.dart
```

##### 4. 建立 .env.example 範例檔案

```bash
# .env.example
# 複製此檔案為 .env 並填入真實的 API 金鑰
GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
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
            android:value="${GOOGLE_MAPS_API_KEY}"/>
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

**Android Studio / IntelliJ IDEA 設定**

1. Run/Debug Configurations → Edit Configurations
2. Environment Variables 中加入：
   - `GOOGLE_PLACES_API_KEY`
   - `GOOGLE_MAPS_API_KEY`
3. Additional Run Args 中加入：
   ```
   --dart-define=GOOGLE_PLACES_API_KEY=$GOOGLE_PLACES_API_KEY --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
   ```

## 🧪 測試

### 執行測試
```bash
# 執行所有測試
flutter test

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
import 'package:mocktail/mocktail.dart';

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
      when(() => mockHttpService.get(any()))
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
1. **絕不將 API 金鑰提交到版本控制**
2. **使用環境變數和 .env 檔案**
3. **設定 .gitignore 排除所有含密鑰的檔案**
4. **在 CI/CD 中使用 GitHub Secrets**
5. **為不同環境使用不同的金鑰**
6. **定期輪換 API 金鑰**
7. **設定 API 金鑰使用限制和配額**

#### GitHub Secrets 設定
1. 在 GitHub 儲存庫設定中加入 Secrets
2. 新增 `GOOGLE_PLACES_API_KEY` 和 `GOOGLE_MAPS_API_KEY`
3. 在 GitHub Actions 中使用：

```yaml
env:
  GOOGLE_PLACES_API_KEY: ${{ secrets.GOOGLE_PLACES_API_KEY }}
  GOOGLE_MAPS_API_KEY: ${{ secrets.GOOGLE_MAPS_API_KEY }}

steps:
  - name: Build APK
    run: |
      flutter build apk --release \
        --dart-define=GOOGLE_PLACES_API_KEY=$GOOGLE_PLACES_API_KEY \
        --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
```

#### API 金鑰狀態檢查
在應用程式启動時檢查：

```dart
void main() {
  // 檢查 API 金鑰設定
  if (!ApiKeys.isConfigured) {
    print('錯誤：未設定 API 金鑰！');
    print('請參考 README.md 中的 API 金鑰設定說明');
    exit(1);
  }
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### Q: 如何偵錯效能問題？
A: 使用 Flutter 內建工具：
```bash
flutter run --profile
# 在 app 中按 'P' 開啟效能工具
```

### Q: 如何處理狀態管理？
A: 專案使用 Riverpod 模式：
```dart
// 在 main.dart 中設定
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

// 定義 Provider
final placesNotifierProvider = StateNotifierProvider<PlacesNotifier, PlacesState>(
  (ref) => PlacesNotifier(),
);

// 在 widget 中使用
class PlacesListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesState = ref.watch(placesNotifierProvider);
    
    return ListView.builder(
      itemCount: placesState.places.length,
      itemBuilder: (context, index) => PlaceCard(placesState.places[index]),
    );
  }
}
```

## 📚 參考資源

- [Flutter 官方文件](https://flutter.dev/docs)
- [Dart 語言指南](https://dart.dev/guides)
- [Google Places API 文件](https://developers.google.com/maps/documentation/places/web-service)
- [Flutter 測試指南](https://flutter.dev/docs/testing)
- [Riverpod 狀態管理](https://pub.dev/packages/flutter_riverpod)

## 🔐 安全性最佳實踐

### API 金鑰安全檢查清單

執行以下檢查確保專案安全：

```bash
# 1. 檢查 .gitignore 是否正確設定
cat .gitignore | grep -E "\.env|api.*key"

# 2. 檢查是否意外提交了敏感檔案
git ls-files | grep -E "\.(env|key|pem)$"

# 3. 檢查程式碼中是否有硬編碼的 API 金鑰
grep -r "AIza[A-Za-z0-9_-]\{35\}" lib/ || echo "未發現硬編碼 API 金鑰"

# 4. 檢查環境變數是否設定
echo "GOOGLE_PLACES_API_KEY=${GOOGLE_PLACES_API_KEY:+已設定}"
echo "GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY:+已設定}"
```

### 完整的 .gitignore 範例

```gitignore
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
flutter_*.png
linked_*.ds
unlinked.ds
unlinked_spec.ds

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# API 金鑰和敏感資訊（重要！）
.env
.env.*
!.env.example
config/secrets.dart
lib/**/api_keys_real.dart
*.key
*.pem
*.p12
*.jks

# 平台特定
ios/Runner/GoogleService-Info.plist
android/app/google-services.json
android/key.properties

# 日誌檔案
*.log

# 測試覆蓋率
coverage/
.nyc_output/

# macOS
.DS_Store

# Windows
Thumbs.db
```

### 環境變數設定指南

#### 1. 本地開發設定

```bash
# 建立 .env 檔案
cat > .env << EOF
# Google APIs
GOOGLE_PLACES_API_KEY=your_places_api_key_here
GOOGLE_MAPS_API_KEY=your_maps_api_key_here

# 環境設定
ENVIRONMENT=development
DEBUG_MODE=true
EOF

# 設定檔案權限（僅本人可讀寫）
chmod 600 .env
```

#### 2. 團隊協作設定

```bash
# 建立 .env.example 供團隊參考
cat > .env.example << EOF
# 複製此檔案為 .env 並填入真實的 API 金鑰

# Google APIs
GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# 環境設定
ENVIRONMENT=development
DEBUG_MODE=true

# API 設定
API_BASE_URL=https://api.example.com
API_TIMEOUT=30000
EOF
```

#### 3. 自動化腳本

建立 `scripts/setup.sh` 協助新團隊成員設定：

```bash
#!/bin/bash
# scripts/setup.sh

echo "🚀 設定 Instant Explore 開發環境..."

# 檢查 Flutter 安裝
if ! command -v flutter &> /dev/null; then
    echo "❌ 請先安裝 Flutter"
    exit 1
fi

# 複製環境變數範例
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ 已建立 .env 檔案，請填入真實的 API 金鑰"
else
    echo "⚠️  .env 檔案已存在"
fi

# 安裝依賴
echo "📦 安裝 Flutter 依賴..."
flutter pub get

# 檢查 API 金鑰設定
echo "🔑 檢查 API 金鑰設定..."
source .env
if [ -z "$GOOGLE_PLACES_API_KEY" ] || [ "$GOOGLE_PLACES_API_KEY" = "your_google_places_api_key_here" ]; then
    echo "❌ 請在 .env 檔案中設定真實的 GOOGLE_PLACES_API_KEY"
    exit 1
fi

if [ -z "$GOOGLE_MAPS_API_KEY" ] || [ "$GOOGLE_MAPS_API_KEY" = "your_google_maps_api_key_here" ]; then
    echo "❌ 請在 .env 檔案中設定真實的 GOOGLE_MAPS_API_KEY"
    exit 1
fi

echo "✅ 環境設定完成！"
echo "🎯 執行 './scripts/dev.sh' 或使用 IDE 配置開始開發"
```

### 持續整合（CI）安全設定

#### GitHub Actions Secrets 設定步驟

1. **前往 GitHub 儲存庫設定**
   - Settings → Secrets and variables → Actions

2. **新增以下 Secrets**
   ```
   GOOGLE_PLACES_API_KEY: [你的 Places API 金鑰]
   GOOGLE_MAPS_API_KEY: [你的 Maps API 金鑰]
   ```

3. **在 workflow 中使用**
   ```yaml
   # .github/workflows/ci.yml
   name: CI/CD Pipeline
   
   on:
     push:
       branches: [ main, develop ]
     pull_request:
       branches: [ main ]
   
   jobs:
     test:
       runs-on: ubuntu-latest
       
       steps:
       - uses: actions/checkout@v3
       
       - name: Setup Flutter
         uses: subosito/flutter-action@v2
         with:
           flutter-version: '3.32.4'
       
       - name: Install dependencies
         run: flutter pub get
       
       - name: Run tests
         run: flutter test
       
       - name: Security check
         run: |
           # 檢查是否意外提交敏感檔案
           if git ls-files | grep -E '\.(env|key|pem)$'; then
             echo "錯誤：發現敏感檔案在版本控制中"
             exit 1
           fi
   
     build:
       needs: test
       runs-on: ubuntu-latest
       
       steps:
       - uses: actions/checkout@v3
       
       - name: Setup Flutter
         uses: subosito/flutter-action@v2
         with:
           flutter-version: '3.32.4'
       
       - name: Build APK
         env:
           GOOGLE_PLACES_API_KEY: ${{ secrets.GOOGLE_PLACES_API_KEY }}
           GOOGLE_MAPS_API_KEY: ${{ secrets.GOOGLE_MAPS_API_KEY }}
         run: |
           flutter build apk --release \
             --dart-define=GOOGLE_PLACES_API_KEY=$GOOGLE_PLACES_API_KEY \
             --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
   ```