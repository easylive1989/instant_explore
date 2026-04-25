import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/explore/data/dto/wiki_geo_search_result_dto.dart';
import 'package:context_app/features/explore/data/dto/wikidata_entity_dto.dart';
import 'package:context_app/features/explore/data/mappers/wikidata_category_mapper.dart';
import 'package:context_app/features/explore/data/services/wikipedia_places_service.dart';
import 'package:context_app/features/explore/domain/errors/place_error.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/explore/domain/models/place_photo.dart';
import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final WikipediaPlacesService _service;

  PlacesRepositoryImpl(this._service);

  static const int _minResultsBeforeRetry = 3;
  static const double _retryRadiusFactor = 5.0;

  @override
  Future<List<Place>> getNearbyPlaces(
    PlaceLocation location, {
    required Language language,
    required double radius,
  }) async {
    try {
      final wikiLang = _wikiLang(language);
      final initial = await _searchWithRetry(location, wikiLang, radius);
      if (initial.isNotEmpty || wikiLang == 'en') return initial;

      return _searchWithRetry(location, 'en', radius);
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.unknown,
        message: '獲取附近地點失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<Place>> _searchWithRetry(
    PlaceLocation location,
    String wikiLang,
    double radius,
  ) async {
    final places = await _searchAtRadius(location, wikiLang, radius);
    if (places.length >= _minResultsBeforeRetry) return places;
    final retried = await _searchAtRadius(
      location,
      wikiLang,
      radius * _retryRadiusFactor,
    );
    return retried.length > places.length ? retried : places;
  }

  Future<List<Place>> _searchAtRadius(
    PlaceLocation location,
    String wikiLang,
    double radius,
  ) async {
    final dtos = await _service.geoSearch(
      lat: location.latitude,
      lon: location.longitude,
      radiusMeters: radius,
      wikiLang: wikiLang,
    );
    return _buildPlaces(dtos);
  }

  @override
  Future<List<Place>> searchPlaces(
    String query, {
    required Language language,
  }) async {
    try {
      final wikiLang = _wikiLang(language);
      final dtos = await _service.searchByText(query, wikiLang: wikiLang);
      return _buildPlaces(dtos);
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.unknown,
        message: '搜尋地點失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  static const String _wikidataPrefix = 'wikidata:';

  @override
  Future<Place?> getPlaceById(
    String placeId, {
    required Language language,
  }) async {
    if (!placeId.startsWith(_wikidataPrefix)) return null;
    final wikidataId = placeId.substring(_wikidataPrefix.length);

    try {
      final wikiLang = _wikiLang(language);
      final combined = await _service.fetchEntityById(
        wikidataId,
        wikiLang: wikiLang,
      );
      if (combined == null) return null;

      final category = WikidataCategoryMapper.categorize(
        combined.entity.p31ClassIds,
      );
      if (category == null) return null;

      return _placeFromDto(combined.dto, combined.entity, category);
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      throw AppError(
        type: PlaceError.unknown,
        message: '取得地點詳情失敗',
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<Place>> _buildPlaces(List<WikiGeoSearchResultDto> dtos) async {
    final withIds = dtos.where((dto) => dto.wikidataId != null).toList();
    if (withIds.isEmpty) return const [];

    final entities = await _service.fetchEntities(
      withIds.map((dto) => dto.wikidataId!).toList(),
    );

    final places = <Place>[];
    for (final dto in withIds) {
      final entity = entities[dto.wikidataId!];
      if (entity == null) continue;
      final category = WikidataCategoryMapper.categorize(entity.p31ClassIds);
      if (category == null) continue;
      places.add(_placeFromDto(dto, entity, category));
    }
    return places;
  }

  Place _placeFromDto(
    WikiGeoSearchResultDto dto,
    WikidataEntityDto entity,
    PlaceCategory category,
  ) {
    return Place(
      id: 'wikidata:${entity.id}',
      name: dto.title,
      formattedAddress: '',
      location: PlaceLocation(latitude: dto.lat, longitude: dto.lon),
      types: entity.p31ClassIds,
      photos: dto.thumbnailUrl == null
          ? const []
          : [
              PlacePhoto(
                url: dto.thumbnailUrl!,
                widthPx: dto.thumbnailWidth ?? 0,
                heightPx: dto.thumbnailHeight ?? 0,
                authorAttributions: const [],
              ),
            ],
      category: category,
    );
  }

  String _wikiLang(Language language) =>
      language.code.split('-').first.toLowerCase();
}
