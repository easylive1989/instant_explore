import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Standard Map Widget
///
/// 標準地圖 Widget，只提供 Google Maps 功能
/// 用於正式版本，不包含任何測試相關邏輯
class MapWidget extends StatelessWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(CameraPosition)? onCameraMove;
  final void Function()? onCameraIdle;
  final void Function(LatLng)? onTap;
  final MapType mapType;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;

  const MapWidget({
    super.key,
    required this.initialCameraPosition,
    this.markers = const <Marker>{},
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.mapType = MapType.normal,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
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
}
