import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/mock_map_widget.dart';

/// Mock Map Widget Factory for Testing
///
/// 提供建立 Mock Map Widget 的工廠函數，用於測試環境
Widget Function({
  required CameraPosition initialCameraPosition,
  Set<Marker> markers,
  void Function(GoogleMapController)? onMapCreated,
  void Function(CameraPosition)? onCameraMove,
  void Function()? onCameraIdle,
  void Function(LatLng)? onTap,
  MapType mapType,
  bool myLocationEnabled,
  bool myLocationButtonEnabled,
  bool zoomControlsEnabled,
}) createMockMapFactory() {
  return ({
    required CameraPosition initialCameraPosition,
    Set<Marker> markers = const <Marker>{},
    void Function(GoogleMapController)? onMapCreated,
    void Function(CameraPosition)? onCameraMove,
    void Function()? onCameraIdle,
    void Function(LatLng)? onTap,
    MapType mapType = MapType.normal,
    bool myLocationEnabled = false,
    bool myLocationButtonEnabled = false,
    bool zoomControlsEnabled = true,
  }) => MockMapWidget(
    initialCameraPosition: initialCameraPosition,
    markers: markers,
    onMapCreated: onMapCreated,
    onCameraMove: onCameraMove,
    onCameraIdle: onCameraIdle,
    onTap: onTap,
    mapType: mapType,
    myLocationEnabled: myLocationEnabled,
    myLocationButtonEnabled: myLocationButtonEnabled,
    zoomControlsEnabled: zoomControlsEnabled,
  );
}