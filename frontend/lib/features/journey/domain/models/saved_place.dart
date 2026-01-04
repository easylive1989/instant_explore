import 'package:equatable/equatable.dart';

class SavedPlace extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;

  const SavedPlace({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
  });

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'address': address, 'image_url': imageUrl};
  }

  @override
  List<Object?> get props => [id, name, address, imageUrl];
}
