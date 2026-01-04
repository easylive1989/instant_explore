import 'package:equatable/equatable.dart';

/// 地點位置資料模型
class PlaceLocation extends Equatable {
  final double latitude;
  final double longitude;

  const PlaceLocation({required this.latitude, required this.longitude});

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() {
    return 'PlaceLocation(latitude: $latitude, longitude: $longitude)';
  }
}
