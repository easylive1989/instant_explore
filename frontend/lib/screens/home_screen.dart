import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

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
  User? _user;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};

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
          _markers = {
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: const InfoWindow(title: '我的位置'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
          };
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
