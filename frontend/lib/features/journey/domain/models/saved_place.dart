class SavedPlace {
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SavedPlace &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, address, imageUrl);
  }
}
