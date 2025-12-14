import 'package:context_app/features/places/domain/repositories/places_repository.dart';
import 'package:context_app/features/places/models/place.dart';

class SearchPlacesUseCase {
  final PlacesRepository _placesRepository;

  SearchPlacesUseCase(this._placesRepository);

  Future<List<Place>> execute(String query, {String? languageCode}) async {
    return _placesRepository.searchPlaces(query, languageCode: languageCode);
  }
}
