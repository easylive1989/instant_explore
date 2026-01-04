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

  @override
  List<Object?> get props => [id, name, address, imageUrl];
}
