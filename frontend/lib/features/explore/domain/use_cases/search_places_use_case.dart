import 'package:context_app/features/explore/domain/repositories/places_repository.dart';
import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

class SearchPlacesUseCase {
  final PlacesRepository _placesRepository;

  SearchPlacesUseCase(this._placesRepository);

  Future<List<Place>> execute(
    String query, {
    required Language language,
  }) async {
    return _placesRepository.searchPlaces(query, language: language);
  }
}
