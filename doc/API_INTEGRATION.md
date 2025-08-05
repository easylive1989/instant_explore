# API 整合文件

## 🗺️ Google APIs 整合

Instant Explore 主要整合以下 Google APIs：

### 核心 APIs
- **Google Places API (New)** - 地點搜尋和詳細資訊
- **Google Maps SDK** - 地圖顯示和互動
- **Directions API** - 路線規劃和導航

## 📍 Google Places API 整合

### API 設定

#### 1. 啟用 API 服務
在 [Google Cloud Console](https://console.cloud.google.com/) 中啟用：
- Places API (New)
- Places API (Legacy) - 用於向後相容
- Geocoding API - 地址轉換

#### 2. 建立和設定 API 金鑰
```bash
# 建立 API 金鑰
gcloud services enable places-backend.googleapis.com
gcloud auth application-default set-quota-project PROJECT_ID
```

#### 3. 設定應用程式限制
- **Android:** 加入 SHA-1 指紋和套件名稱
- **iOS:** 加入 Bundle ID
- **Web:** 加入網域名稱

### Flutter 整合

#### 安裝套件
```yaml
# pubspec.yaml
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^11.0.0
  http: ^1.2.0
  google_places_api: ^1.1.0
```

#### 基本設定
```dart
// lib/core/services/places_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlacesService {
  static const String _baseUrl = 'https://places.googleapis.com/v1';
  final String _apiKey;
  
  PlacesService(this._apiKey);
  
  // Nearby Search API 呼叫
  Future<List<Place>> searchNearby({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String? type,
    int maxResults = 20,
  }) async {
    final url = Uri.parse('$_baseUrl/places:searchNearby');
    
    final requestBody = {
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': radius,
        },
      },
      'maxResultCount': maxResults,
      if (type != null) 'includedTypes': [type],
      'fieldMask': 'places.id,places.displayName,places.formattedAddress,places.rating,places.priceLevel,places.photos',
    };
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress',
        },
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parsePlaces(data['places'] ?? []);
      } else {
        throw PlacesApiException('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      throw PlacesApiException('Network error: $e');
    }
  }
  
  // Place Details API 呼叫
  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    final url = Uri.parse('$_baseUrl/places/$placeId');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'id,displayName,formattedAddress,rating,priceLevel,openingHours,phoneNumber,website,reviews',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaceDetails.fromJson(data);
      } else {
        throw PlacesApiException('Failed to get place details: ${response.statusCode}');
      }
    } catch (e) {
      throw PlacesApiException('Network error: $e');
    }
  }
  
  List<Place> _parsePlaces(List<dynamic> placesData) {
    return placesData.map((data) => Place.fromJson(data)).toList();
  }
}
```

### 資料模型

#### Place 模型
```dart
// lib/features/places/models/place.dart
class Place {
  final String id;
  final String name;
  final String address;
  final double? rating;
  final int? priceLevel;
  final List<String> types;
  final PlaceLocation location;
  final List<PlacePhoto> photos;
  
  Place({
    required this.id,
    required this.name,
    required this.address,
    this.rating,
    this.priceLevel,
    required this.types,
    required this.location,
    required this.photos,
  });
  
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] ?? '',
      name: json['displayName']?['text'] ?? '',
      address: json['formattedAddress'] ?? '',
      rating: json['rating']?.toDouble(),
      priceLevel: json['priceLevel'],
      types: List<String>.from(json['types'] ?? []),
      location: PlaceLocation.fromJson(json['location'] ?? {}),
      photos: (json['photos'] as List?)
          ?.map((photo) => PlacePhoto.fromJson(photo))
          .toList() ?? [],
    );
  }
}

class PlaceLocation {
  final double latitude;
  final double longitude;
  
  PlaceLocation({required this.latitude, required this.longitude});
  
  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }
}
```

### 支援的地點類型

```dart
// lib/core/constants/place_types.dart
class PlaceTypes {
  static const Map<String, String> categories = {
    'restaurant': '餐廳',
    'tourist_attraction': '旅遊景點',
    'cafe': '咖啡廳',
    'shopping_mall': '購物中心',
    'amusement_park': '遊樂園',
    'museum': '博物館',
    'park': '公園',
    'movie_theater': '電影院',
    'gas_station': '加油站',
    'hospital': '醫院',
    'pharmacy': '藥局',
    'bank': '銀行',
    'atm': 'ATM',
    'gym': '健身房',
    'beauty_salon': '美容院',
    'lodging': '住宿',
  };
  
  static const List<String> popularTypes = [
    'restaurant',
    'tourist_attraction',
    'cafe',
    'shopping_mall',
    'park',
  ];
}
```

## 🗺️ Google Maps SDK 整合

### 地圖元件
```dart
// lib/shared/widgets/custom_google_map.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomGoogleMap extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;
  final Function(LatLng)? onTap;
  final Function(GoogleMapController)? onMapCreated;
  
  const CustomGoogleMap({
    Key? key,
    required this.initialPosition,
    this.markers = const {},
    this.onTap,
    this.onMapCreated,
  }) : super(key: key);
  
  @override
  State<CustomGoogleMap> createState() => _CustomGoogleMapState();
}

class _CustomGoogleMapState extends State<CustomGoogleMap> {
  GoogleMapController? _controller;
  
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: 15.0,
      ),
      markers: widget.markers,
      onTap: widget.onTap,
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      compassEnabled: true,
      trafficEnabled: false,
    );
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
```

### 標記管理
```dart
// lib/features/places/services/marker_service.dart
class MarkerService {
  Set<Marker> createPlaceMarkers(List<Place> places, Function(Place) onTap) {
    return places.map((place) {
      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.location.latitude, place.location.longitude),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.address,
        ),
        onTap: () => onTap(place),
        icon: _getMarkerIcon(place.types.first),
      );
    }).toSet();
  }
  
  BitmapDescriptor _getMarkerIcon(String type) {
    switch (type) {
      case 'restaurant':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'tourist_attraction':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'cafe':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }
}
```

## 🧭 Directions API 整合

### 路線服務
```dart
// lib/features/navigation/services/directions_service.dart
class DirectionsService {
  final String _apiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  
  DirectionsService(this._apiKey);
  
  Future<DirectionsResult> getDirections({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
    bool alternatives = false,
  }) async {
    final url = Uri.parse('$_baseUrl').replace(queryParameters: {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': _getTravelModeString(travelMode),
      'alternatives': alternatives.toString(),
      'key': _apiKey,
    });
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return DirectionsResult.fromJson(data);
        } else {
          throw DirectionsException('API Error: ${data['status']}');
        }
      } else {
        throw DirectionsException('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw DirectionsException('Network error: $e');
    }
  }
  
  String _getTravelModeString(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.transit:
        return 'transit';
      case TravelMode.bicycling:
        return 'bicycling';
    }
  }
}

enum TravelMode { driving, walking, transit, bicycling }
```

## 🔧 錯誤處理和重試機制

### 自訂例外類別
```dart
// lib/core/exceptions/api_exceptions.dart
class PlacesApiException implements Exception {
  final String message;
  final int? statusCode;
  
  PlacesApiException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'PlacesApiException: $message';
}

class DirectionsException implements Exception {
  final String message;
  
  DirectionsException(this.message);
  
  @override
  String toString() => 'DirectionsException: $message';
}
```

### 重試機制
```dart
// lib/core/services/api_retry_service.dart
class ApiRetryService {
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        // 指數退避策略
        await Future.delayed(delay * attempts);
      }
    }
    
    throw Exception('Max retry attempts reached');
  }
}
```

## 📊 配額管理和最佳實踐

### API 配額限制
| API | 每天免費配額 | 超出後價格 (每 1000 次) |
|-----|-------------|------------------------|
| Places Nearby Search | $200 免費額度 | $32.00 |
| Places Details | $200 免費額度 | $17.00 |
| Maps SDK | 28,000 次載入 | $7.00 |
| Directions API | $200 免費額度 | $5.00 |

### 快取策略
```dart
// lib/core/services/cache_service.dart
class CacheService {
  static final Map<String, CacheEntry> _cache = {};
  static const Duration _defaultTtl = Duration(minutes: 15);
  
  static void set<T>(String key, T data, {Duration? ttl}) {
    _cache[key] = CacheEntry(
      data: data,
      expiry: DateTime.now().add(ttl ?? _defaultTtl),
    );
  }
  
  static T? get<T>(String key) {
    final entry = _cache[key];
    
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data as T?;
  }
  
  static void clear() {
    _cache.clear();
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiry;
  
  CacheEntry({required this.data, required this.expiry});
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}
```

### Field Masking 最佳實踐
```dart
// 只請求必要的欄位以降低成本
class FieldMasks {
  static const String placesBasic = 'places.id,places.displayName,places.formattedAddress';
  static const String placesWithRating = '$placesBasic,places.rating,places.priceLevel';
  static const String placesDetailed = '$placesWithRating,places.openingHours,places.phoneNumber,places.website';
  static const String placesWithPhotos = '$placesDetailed,places.photos';
}
```

### 請求批次處理
```dart
// lib/core/services/batch_request_service.dart
class BatchRequestService {
  static const int _maxBatchSize = 10;
  static const Duration _batchDelay = Duration(milliseconds: 100);
  
  final List<ApiRequest> _pendingRequests = [];
  Timer? _batchTimer;
  
  Future<T> addRequest<T>(ApiRequest<T> request) async {
    final completer = Completer<T>();
    request.completer = completer;
    
    _pendingRequests.add(request);
    
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchDelay, _processBatch);
    
    if (_pendingRequests.length >= _maxBatchSize) {
      _processBatch();
    }
    
    return completer.future;
  }
  
  void _processBatch() async {
    if (_pendingRequests.isEmpty) return;
    
    final batch = List<ApiRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    
    // 並行處理請求
    final futures = batch.map((request) => request.execute());
    await Future.wait(futures);
  }
}
```

## 🔒 安全性考量

### API 金鑰安全管理

#### 1. 環境變數設定

**絕不將 API 金鑰硬編碼到程式中！**

```dart
// ✗ 錯誤做法 - 絕不這樣做！
class ApiKeys {
  static const String googlePlacesApiKey = 'AIzaSy...'; // 危險！
}

// ✓ 正確做法 - 使用環境變數
class ApiKeys {
  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );
  
  // 安全檢查
  static void validateKeys() {
    if (googlePlacesApiKey.isEmpty) {
      throw Exception('未設定 GOOGLE_PLACES_API_KEY 環境變數');
    }
    
    // 檢查金鑰格式
    if (!googlePlacesApiKey.startsWith('AIza')) {
      throw Exception('Google API 金鑰格式不正確');
    }
  }
}
```

#### 2. .env 檔案管理

```bash
# .env (加入 .gitignore)
GOOGLE_PLACES_API_KEY=AIzaSyBvOkBo...your_actual_key
GOOGLE_MAPS_API_KEY=AIzaSyBvOkBo...your_actual_key

# 對於不同環境
# .env.development
GOOGLE_PLACES_API_KEY=AIzaSy...dev_key

# .env.production  
GOOGLE_PLACES_API_KEY=AIzaSy...prod_key
```

#### 3. .gitignore 設定

```gitignore
# API 金鑰和敏感資訊
.env
.env.*
!.env.example

# 備用設定檔
config/secrets.dart
lib/**/api_keys_real.dart
```

#### 4. 安全 HTTP 服務實作

```dart
// lib/core/services/secure_places_service.dart
class SecurePlacesService extends PlacesService {
  SecurePlacesService() : super(ApiKeys.currentPlacesApiKey) {
    // 啟動時驗證金鑰
    ApiKeys.validateKeys();
  }
  
  @override
  Future<List<Place>> searchNearby({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String? type,
    int maxResults = 20,
  }) async {
    // 加入請求限制檢查
    if (radius > 50000) {
      throw ArgumentError('搜尋半徑不能超過 50km');
    }
    
    if (maxResults > 60) {
      throw ArgumentError('每次最多可取 60 筆結果');
    }
    
    try {
      return await super.searchNearby(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        type: type,
        maxResults: maxResults,
      );
    } catch (e) {
      // 記錄錯誤但不暴露金鑰資訊
      logger.error('地點搜尋失敗', error: e);
      rethrow;
    }
  }
}
```

#### 5. API 金鑰限制設定

在 Google Cloud Console 中設定：

```json
{
  "restrictions": {
    "android_key_restrictions": {
      "allowed_applications": [
        {
          "sha1_fingerprint": "SHA1_FINGERPRINT",
          "package_name": "com.example.instant_explore"
        }
      ]
    },
    "ios_key_restrictions": {
      "allowed_bundle_ids": [
        "com.example.instant-explore"
      ]
    },
    "browser_key_restrictions": {
      "allowed_referrers": [
        "https://instant-explore.app/*",
        "https://*.instant-explore.app/*"
      ]
    }
  },
  "quota": {
    "requests_per_minute_per_user": 100,
    "requests_per_day": 25000
  }
}
```

#### 6. 金鑰輪換策略

```dart
// lib/core/services/api_key_rotation.dart
class ApiKeyRotation {
  static const int rotationIntervalDays = 90;
  
  static void checkKeyAge() {
    final lastRotation = getLastRotationDate();
    final daysSinceRotation = DateTime.now().difference(lastRotation).inDays;
    
    if (daysSinceRotation > rotationIntervalDays) {
      showKeyRotationWarning();
    }
  }
  
  static void showKeyRotationWarning() {
    // 提醒管理員輪換金鑰
    logger.warning('建議輪換 API 金鑰，上次輪換已超過 $rotationIntervalDays 天');
  }
}
```

### 伺服器端代理（進階安全）

對於高安全性需求，建議透過後端服務代理 API 請求：

#### 優勢
- API 金鑰完全不暴露給用戶端
- 可以實作更細粒度的存取控制
- 集中管理 API 成本和配額
- 可以加入用戶認證和權限檢查

```dart
// lib/core/services/proxy_service.dart
class ProxyService {
  static const String _proxyBaseUrl = 'https://your-backend.com/api';
  
  Future<List<Place>> searchPlacesViaProxy({
    required double latitude,
    required double longitude,
    String? type,
  }) async {
    final url = Uri.parse('$_proxyBaseUrl/places/search');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'type': type,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['places'] as List)
          .map((place) => Place.fromJson(place))
          .toList();
    } else {
      throw ProxyException('Proxy request failed: ${response.statusCode}');
    }
  }
}

class ProxyException implements Exception {
  final String message;
  ProxyException(this.message);
  
  @override
  String toString() => 'ProxyException: $message';
}
```

### GitHub Actions CI/CD 安全設定

```yaml
# .github/workflows/build.yml
name: Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
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
    
    - name: Build APK with secrets
      env:
        GOOGLE_PLACES_API_KEY: ${{ secrets.GOOGLE_PLACES_API_KEY }}
        GOOGLE_MAPS_API_KEY: ${{ secrets.GOOGLE_MAPS_API_KEY }}
      run: |
        flutter build apk --release \
          --dart-define=GOOGLE_PLACES_API_KEY=$GOOGLE_PLACES_API_KEY \
          --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
    
    # 安全性檢查
    - name: Security audit
      run: |
        # 檢查是否意外提交了敏感檔案
        if git ls-files | grep -E '\.(env|key|pem|p12)$'; then
          echo "錯誤：發現敏感檔案在版本控制中"
          exit 1
        fi
        
        # 檢查程式碼中是否有硬編碼的 API 金鑰
        if grep -r "AIza[A-Za-z0-9_-]\{35\}" lib/; then
          echo "錯誤：發現硬編碼的 Google API 金鑰"
          exit 1
        fi
```

### 開發環境安全檢查

```dart
// lib/core/utils/security_checker.dart
class SecurityChecker {
  static void performStartupChecks() {
    checkApiKeyConfiguration();
    checkBuildConfiguration();
    warnIfDebugMode();
  }
  
  static void checkApiKeyConfiguration() {
    if (!ApiKeys.isConfigured) {
      throw SecurityException('未正確設定 API 金鑰');
    }
    
    // 檢查是否使用測試金鑰
    if (ApiKeys.googlePlacesApiKey.contains('test') || 
        ApiKeys.googlePlacesApiKey.contains('demo')) {
      logger.warning('正在使用測試 API 金鑰');
    }
  }
  
  static void checkBuildConfiguration() {
    if (kDebugMode) {
      logger.info('當前為 Debug 模式');
    }
    
    if (kReleaseMode && !ApiKeys.isConfigured) {
      throw SecurityException('Release 模式下必須設定正式 API 金鑰');
    }
  }
  
  static void warnIfDebugMode() {
    if (kDebugMode) {
      // 在 Debug 模式下顯示警告
      Future.delayed(Duration(seconds: 2), () {
        logger.warning('當前為開發模式，請勿在生產環境使用');
      });
    }
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}
```

## 📝 測試

### API 服務測試
```dart
// test/unit/services/places_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockClient extends Mock implements http.Client {}

void main() {
  group('PlacesService', () {
    late PlacesService service;
    late MockClient mockClient;
    
    setUp(() {
      mockClient = MockClient();
      service = PlacesService('test-api-key', client: mockClient);
    });
    
    test('should return places when API responds successfully', () async {
      // Arrange
      when(() => mockClient.post(
        any(), 
        headers: any(named: 'headers'), 
        body: any(named: 'body')
      )).thenAnswer((_) async => http.Response(mockSuccessResponse, 200));
      
      // Act
      final result = await service.searchNearby(
        latitude: 25.0330,
        longitude: 121.5654,
      );
      
      // Assert
      expect(result, isA<List<Place>>());
      expect(result.length, greaterThan(0));
    });
    
    test('should throw exception when API fails', () async {
      // Arrange
      when(() => mockClient.post(
        any(), 
        headers: any(named: 'headers'), 
        body: any(named: 'body')
      )).thenAnswer((_) async => http.Response('Error', 400));
      
      // Act & Assert
      expect(
        () => service.searchNearby(latitude: 25.0330, longitude: 121.5654),
        throwsA(isA<PlacesApiException>()),
      );
    });
  });
}

const mockSuccessResponse = '''
{
  "places": [
    {
      "id": "ChIJN1t_tDeuEmsRUsoyG83frY4",
      "displayName": {"text": "測試餐廳"},
      "formattedAddress": "台北市信義區信義路五段7號",
      "rating": 4.5,
      "priceLevel": "PRICE_LEVEL_MODERATE"
    }
  ]
}
''';
```

## 📚 參考資源

- [Google Places API (New) 文件](https://developers.google.com/maps/documentation/places/web-service/op-overview)
- [Google Maps Flutter 套件](https://pub.dev/packages/google_maps_flutter)
- [Directions API 文件](https://developers.google.com/maps/documentation/directions)
- [Flutter HTTP 請求最佳實踐](https://flutter.dev/docs/cookbook/networking/fetch-data)