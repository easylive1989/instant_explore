import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../places/models/place.dart';
import '../../places/services/places_service.dart';
import '../../../core/services/location_service.dart';

/// 地點選擇畫面
class PlacePickerScreen extends ConsumerStatefulWidget {
  const PlacePickerScreen({super.key});

  @override
  ConsumerState<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends ConsumerState<PlacePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  List<Place> _places = [];
  bool _isLoading = false;
  bool _isSearching = false;
  Place? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      setState(() {
        _currentLocation = LatLng(position!.latitude, position.longitude);
        _isLoading = false;
      });

      // 自動搜尋附近地點
      _searchNearbyPlaces();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('無法取得位置: $e')));
      }
    }
  }

  Future<void> _searchNearbyPlaces() async {
    if (_currentLocation == null) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final placesService = ref.read(placesServiceProvider);
      final places = await placesService.searchNearbyRestaurants(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radius: 5000, // 5 公里
        maxResults: 20,
      );

      setState(() {
        _places = places;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('搜尋失敗: $e')));
      }
    }
  }

  void _onPlaceSelected(Place place) {
    setState(() {
      _selectedPlace = place;
    });
  }

  void _confirmSelection() {
    if (_selectedPlace != null) {
      Navigator.of(context).pop(_selectedPlace);
    }
  }

  /// 建立地點列表視圖
  Widget _buildPlacesList() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_places.isEmpty) {
      return const Center(child: Text('附近沒有找到地點'));
    }

    return ListView.builder(
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(place.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.formattedAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (place.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(place.rating!.toStringAsFixed(1)),
                    ],
                  ),
              ],
            ),
            onTap: () => _onPlaceSelected(place),
          ),
        );
      },
    );
  }

  /// 建立地圖視圖
  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _selectedPlace!.location.latitude,
          _selectedPlace!.location.longitude,
        ),
        zoom: 16.0,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: {
        Marker(
          markerId: MarkerId(_selectedPlace!.id),
          position: LatLng(
            _selectedPlace!.location.latitude,
            _selectedPlace!.location.longitude,
          ),
          infoWindow: InfoWindow(
            title: _selectedPlace!.name,
            snippet: _selectedPlace!.formattedAddress,
          ),
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _selectedPlace != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedPlace = null;
                  });
                },
              )
            : null,
        title: const Text('選擇地點'),
        actions: [
          if (_selectedPlace != null)
            TextButton(onPressed: _confirmSelection, child: const Text('確定')),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 搜尋框 (未來可擴充為 Autocomplete)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜尋地點...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      // TODO: 實作 Autocomplete 搜尋
                    },
                  ),
                ),

                // 地點列表或地圖顯示
                Expanded(
                  child: _currentLocation == null
                      ? const Center(child: Text('正在取得位置...'))
                      : _selectedPlace == null
                      ? _buildPlacesList()
                      : _buildMapView(),
                ),
              ],
            ),
    );
  }
}
