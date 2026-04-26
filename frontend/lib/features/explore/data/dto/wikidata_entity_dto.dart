class WikidataEntityDto {
  final String id;
  final List<String> p31ClassIds;

  /// Coordinate location from Wikidata P625, or null if absent.
  final (double, double)? coordinates;

  const WikidataEntityDto({
    required this.id,
    required this.p31ClassIds,
    this.coordinates,
  });

  factory WikidataEntityDto.fromEntity(Map<String, dynamic> entity) {
    final claims = entity['claims'];

    final p31Claims = (claims is Map ? claims['P31'] : null) as List? ?? [];
    final classIds = <String>[];
    for (final claim in p31Claims) {
      if (claim is! Map) continue;
      final mainsnak = claim['mainsnak'];
      if (mainsnak is! Map) continue;
      final datavalue = mainsnak['datavalue'];
      if (datavalue is! Map) continue;
      final value = datavalue['value'];
      if (value is! Map) continue;
      final classId = value['id'];
      if (classId is String) classIds.add(classId);
    }

    (double, double)? coordinates;
    final p625Claims = (claims is Map ? claims['P625'] : null) as List? ?? [];
    if (p625Claims.isNotEmpty) {
      final claim = p625Claims.first;
      if (claim is Map) {
        final mainsnak = claim['mainsnak'];
        if (mainsnak is Map) {
          final datavalue = mainsnak['datavalue'];
          if (datavalue is Map) {
            final value = datavalue['value'];
            if (value is Map) {
              final lat = (value['latitude'] as num?)?.toDouble();
              final lon = (value['longitude'] as num?)?.toDouble();
              if (lat != null && lon != null) coordinates = (lat, lon);
            }
          }
        }
      }
    }

    return WikidataEntityDto(
      id: entity['id'] as String,
      p31ClassIds: classIds,
      coordinates: coordinates,
    );
  }
}
