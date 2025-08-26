import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/map_widget.dart';

/// Map Widget Provider
///
/// 提供地圖 Widget，在測試中可透過 overrides 替換成 Mock 版本
final mapWidgetProvider =
    Provider<
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
      })
    >((ref) {
      // 正式版本使用真實的 Google Maps
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
      }) => MapWidget(
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
    });
