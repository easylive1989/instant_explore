import 'package:equatable/equatable.dart';

/// 使用者建立的旅程（Trip）。
///
/// Phase 1 僅實作 [id]、[name]、[startDate]、[endDate]、[createdAt]。
/// [coverImageUrl] 與 [description] 為 Phase 2 擴充欄位，保留在 model 中
/// 以減少後續資料遷移成本。
class Trip extends Equatable {
  final String id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? coverImageUrl;
  final String? description;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.name,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.coverImageUrl,
    this.description,
  });

  Trip copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    String? description,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'cover_image_url': coverImageUrl,
    'description': description,
    'created_at': createdAt.toIso8601String(),
  };

  factory Trip.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? v) =>
        v is String && v.isNotEmpty ? DateTime.parse(v) : null;

    return Trip(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      coverImageUrl: json['cover_image_url'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    startDate,
    endDate,
    coverImageUrl,
    description,
    createdAt,
  ];
}
