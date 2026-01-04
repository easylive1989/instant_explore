import 'package:equatable/equatable.dart';

/// 地點位置資料模型
class PlaceLocation extends Equatable {
  final double latitude;
  final double longitude;

  const PlaceLocation({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}
