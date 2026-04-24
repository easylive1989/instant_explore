class WikidataEntityDto {
  final String id;
  final List<String> p31ClassIds;

  const WikidataEntityDto({required this.id, required this.p31ClassIds});

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

    return WikidataEntityDto(id: entity['id'] as String, p31ClassIds: classIds);
  }
}
