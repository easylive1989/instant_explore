import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../features/places/models/place.dart';

/// 首頁畫面
///
/// 顯示已登入使用者的主要介面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  final PlacesService _placesService = PlacesService();
  User? _user;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Place? _selectedRestaurant;
  bool _isLoadingRestaurant = false;

  @override
  void initState() {
    super.initState();
    _user = _authService.currentUser;
    _initializeLocation();
  }

  /// 初始化位置功能
  Future<void> _initializeLocation() async {
    await _requestLocationWithDialog();
  }

  /// 檢查位置權限並顯示相對應的提示對話框
  Future<void> _requestLocationWithDialog() async {
    try {
      // 先檢查位置服務是否已啟用
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationServiceDialog();
        return;
      }

      // 檢查權限狀態
      LocationPermission permission = await _locationService.checkPermission();

      switch (permission) {
        case LocationPermission.denied:
          await _showPermissionRequestDialog();
          break;
        case LocationPermission.deniedForever:
          await _showPermissionDeniedForeverDialog();
          break;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          await _getCurrentLocationAndUpdate();
          break;
        default:
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('位置初始化發生錯誤: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 取得當前位置並更新地圖
  Future<void> _getCurrentLocationAndUpdate() async {
    try {
      Position? position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _updateMapMarkers();
        });

        // 如果地圖控制器已經準備好，就移動相機到當前位置
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 16.0,
                bearing: 0,
                tilt: 0,
              ),
            ),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已定位到您的位置'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('無法取得位置資訊: ${e.toString()}'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: '重試',
              onPressed: _getCurrentLocationAndUpdate,
            ),
          ),
        );
      }
    }
  }

  /// 顯示位置服務未開啟的對話框
  Future<void> _showLocationServiceDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('需要開啟位置服務'),
          content: const Text('為了顯示您在地圖上的位置，請先開啟裝置的位置服務。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('稍後'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _locationService.openLocationSettings();
                // 等待一下後重新檢查
                await Future.delayed(const Duration(seconds: 2));
                _requestLocationWithDialog();
              },
              child: const Text('開啟設定'),
            ),
          ],
        );
      },
    );
  }

  /// 顯示請求位置權限的對話框
  Future<void> _showPermissionRequestDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('需要位置權限'),
          content: const Text('為了在地圖上顯示您的位置，需要取得您的同意來存取位置資訊。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('不允許'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                LocationPermission permission = await _locationService
                    .requestPermission();
                if (permission == LocationPermission.whileInUse ||
                    permission == LocationPermission.always) {
                  await _getCurrentLocationAndUpdate();
                } else {
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('位置權限被拒絕，無法顯示您的位置'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              child: const Text('允許'),
            ),
          ],
        );
      },
    );
  }

  /// 顯示位置權限被永久拒絕的對話框
  Future<void> _showPermissionDeniedForeverDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('位置權限被拒絕'),
          content: const Text('位置權限已被永久拒絕。如要使用位置功能，請前往應用程式設定頁面開啟位置權限。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('稍後'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _locationService.openAppSettings();
              },
              child: const Text('開啟設定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant Explore'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  _handleSignOut();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('登出'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // 如果已經有位置資訊，移動相機到當前位置
              if (_currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 16.0,
                      bearing: 0,
                      tilt: 0,
                    ),
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : const LatLng(25.0339206, 121.5636985), // 預設位置（台北101）
              zoom: 16.0,
              bearing: 0,
              tilt: 0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // 使用自定義按鈕
          ),
          // Top info bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '歡迎回來！',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _user?.email ?? '使用者',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _handleRecenter,
                    tooltip: '重新定位',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingRestaurant ? null : _getRandomRestaurant,
        icon: _isLoadingRestaurant
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.restaurant),
        label: Text(_isLoadingRestaurant ? '搜尋中...' : '隨機推薦'),
        backgroundColor: _isLoadingRestaurant ? Colors.grey : Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// 處理重新定位
  Future<void> _handleRecenter() async {
    if (_mapController != null) {
      // 優先使用當前位置，如果沒有就重新請求位置權限和取得位置
      Position? position = _currentPosition;

      if (position == null) {
        // 檢查位置權限並重新取得位置
        bool hasPermission = await _locationService.ensureLocationPermission();
        if (!hasPermission) {
          await _requestLocationWithDialog();
          return;
        }

        // 重新取得位置
        position = await _locationService.getCurrentPosition();
        if (position != null && mounted) {
          setState(() {
            _currentPosition = position;
            _markers = {
              Marker(
                markerId: const MarkerId('current_location'),
                position: LatLng(position!.latitude, position.longitude),
                infoWindow: const InfoWindow(title: '我的位置'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
              ),
            };
          });
        }
      }

      if (position != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16.0,
              bearing: 0,
              tilt: 0,
            ),
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已重新定位到您的位置'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // 位置取得失敗，顯示錯誤訊息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('無法取得位置資訊'),
              backgroundColor: Colors.red,
              action: SnackBarAction(label: '重試', onPressed: _handleRecenter),
            ),
          );
        }
      }
    }
  }

  /// 更新地圖標記
  void _updateMapMarkers() {
    final markers = <Marker>{};

    // 添加使用者位置標記
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: '我的位置'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // 添加推薦餐廳標記
    if (_selectedRestaurant != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('recommended_restaurant'),
          position: LatLng(
            _selectedRestaurant!.location.latitude,
            _selectedRestaurant!.location.longitude,
          ),
          infoWindow: InfoWindow(
            title: _selectedRestaurant!.name,
            snippet: _selectedRestaurant!.formattedAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _showRestaurantBottomSheet(),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  /// 隨機推薦附近餐廳
  Future<void> _getRandomRestaurant() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先開啟位置權限'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingRestaurant = true;
      _selectedRestaurant = null;
    });

    try {
      final restaurant = await _placesService.getRandomNearbyRestaurant(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 2000, // 2公里範圍內
      );

      if (restaurant != null && mounted) {
        setState(() {
          _selectedRestaurant = restaurant;
          _updateMapMarkers();
        });

        // 調整地圖視角包含使用者和餐廳位置
        if (_mapController != null) {
          await _adjustCameraToShowBothLocations();
        }

        // 顯示餐廳資訊
        _showRestaurantBottomSheet();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('為您推薦：${restaurant.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('附近沒有找到餐廳，請嘗試擴大搜尋範圍'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('推薦餐廳失敗: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '重試',
              onPressed: _getRandomRestaurant,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRestaurant = false;
        });
      }
    }
  }

  /// 調整相機視角顯示使用者和餐廳位置
  Future<void> _adjustCameraToShowBothLocations() async {
    if (_currentPosition == null ||
        _selectedRestaurant == null ||
        _mapController == null) {
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        min(_currentPosition!.latitude, _selectedRestaurant!.location.latitude),
        min(
          _currentPosition!.longitude,
          _selectedRestaurant!.location.longitude,
        ),
      ),
      northeast: LatLng(
        max(_currentPosition!.latitude, _selectedRestaurant!.location.latitude),
        max(
          _currentPosition!.longitude,
          _selectedRestaurant!.location.longitude,
        ),
      ),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  /// 顯示餐廳資訊底部卡片
  void _showRestaurantBottomSheet() {
    if (_selectedRestaurant == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 拖拽手柄
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 餐廳名稱和評分
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedRestaurant!.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_selectedRestaurant!.rating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedRestaurant!.ratingText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 價格等級
                    if (_selectedRestaurant!.priceLevel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedRestaurant!.priceRangeText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // 地址
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedRestaurant!.formattedAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 距離
                    if (_currentPosition != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _placesService.formatDistance(
                              _placesService.calculateDistance(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                                _selectedRestaurant!.location.latitude,
                                _selectedRestaurant!.location.longitude,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // 按鈕區
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _getRandomRestaurant();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('換一家'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: 實作導航功能
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('導航功能即將推出'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation),
                            label: const Text('導航'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 處理登出
  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      // AuthWrapper 會自動導向登入頁面
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已成功登出'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登出失敗: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
