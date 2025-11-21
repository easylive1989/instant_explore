import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../places/models/place.dart';
import '../../places/models/place_suggestion.dart';
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
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingSuggestion = false;
  Place? _selectedPlace;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _debounce?.cancel();
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

  /// 處理搜尋輸入變更
  void _onSearchChanged(String query) {
    // 取消先前的 debounce timer
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestion = false;
      });
      return;
    }

    // 設定新的 debounce timer（500ms）
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAutocomplete(query);
    });
  }

  /// 執行自動完成搜尋
  Future<void> _searchAutocomplete(String query) async {
    setState(() {
      _isLoadingSuggestion = true;
    });

    try {
      final placesService = ref.read(placesServiceProvider);
      final suggestions = await placesService.searchPlacesAutocomplete(
        input: query,
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
      );

      setState(() {
        _suggestions = suggestions;
        _isLoadingSuggestion = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestion = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('搜尋失敗: $e')));
      }
    }
  }

  /// 處理建議點選
  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final placesService = ref.read(placesServiceProvider);
      final placeDetails = await placesService.getPlaceDetails(
        suggestion.placeId,
      );

      // PlaceDetails 本身就是 Place，可以直接使用
      final place = Place(
        id: placeDetails.id,
        name: placeDetails.name,
        formattedAddress: placeDetails.formattedAddress,
        location: placeDetails.location,
        rating: placeDetails.rating,
        priceLevel: placeDetails.priceLevel,
        types: placeDetails.types,
        photos: placeDetails.photos,
        internationalPhoneNumber: placeDetails.internationalPhoneNumber,
        websiteUri: placeDetails.websiteUri,
        currentOpeningHours: placeDetails.currentOpeningHours,
      );

      setState(() {
        _selectedPlace = place;
        _isLoading = false;
        _searchController.clear();
        _suggestions = [];
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('取得地點詳細資訊失敗: $e')));
      }
    }
  }

  /// 建立搜尋建議列表視圖
  Widget _buildSuggestionsList() {
    if (_isLoadingSuggestion) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestions.isEmpty) {
      return const Center(child: Text('未找到符合的餐廳'));
    }

    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];

        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(suggestion.text),
          subtitle: suggestion.secondaryText != null
              ? Text(
                  suggestion.secondaryText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: () => _onSuggestionSelected(suggestion),
        );
      },
    );
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
                                _debounce?.cancel();
                                setState(() {
                                  _suggestions = [];
                                  _isLoadingSuggestion = false;
                                });
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

                // 地點列表、搜尋建議或地圖顯示
                Expanded(
                  child: _currentLocation == null
                      ? const Center(child: Text('正在取得位置...'))
                      : _selectedPlace != null
                      ? _buildMapView()
                      : _searchController.text.isNotEmpty
                      ? _buildSuggestionsList()
                      : _buildPlacesList(),
                ),
              ],
            ),
    );
  }
}
