import 'package:context_app/features/explore/domain/models/place_category.dart';

/// Maps Wikidata P31 (instance of) class IDs to app [PlaceCategory].
///
/// Returns null if none of the class IDs is in the whitelist, signalling
/// that the corresponding place should be dropped.
class WikidataCategoryMapper {
  static const Map<String, PlaceCategory> _whitelist = {
    // --- historical & cultural ---
    'Q5393308': PlaceCategory.historicalCultural, // Buddhist temple
    'Q845945': PlaceCategory.historicalCultural, // Shinto shrine
    'Q2680845': PlaceCategory.historicalCultural, // Chinese temple
    'Q16970': PlaceCategory.historicalCultural, // church building
    'Q32815': PlaceCategory.historicalCultural, // mosque
    'Q23413': PlaceCategory.historicalCultural, // castle
    'Q16560': PlaceCategory.historicalCultural, // palace
    'Q4989906': PlaceCategory.historicalCultural, // monument
    'Q839954': PlaceCategory.historicalCultural, // archaeological site
    'Q22746': PlaceCategory.historicalCultural, // historic site
    'Q123314524': PlaceCategory.historicalCultural, // yamajiro
    'Q667783': PlaceCategory.historicalCultural, // sandō
    'Q162633': PlaceCategory.historicalCultural, // academy (書院)
    // --- museum / art ---
    'Q33506': PlaceCategory.museumArt, // museum
    'Q207694': PlaceCategory.museumArt, // art museum
    'Q2065736': PlaceCategory.museumArt, // cultural institution
    'Q7075': PlaceCategory.museumArt, // library
    // --- natural landscape ---
    'Q22698': PlaceCategory.naturalLandscape, // park
    'Q46831': PlaceCategory.naturalLandscape, // mountain range
    'Q8502': PlaceCategory.naturalLandscape, // mountain
    'Q23397': PlaceCategory.naturalLandscape, // lake
    'Q34038': PlaceCategory.naturalLandscape, // waterfall
    'Q46169': PlaceCategory.naturalLandscape, // national park
    'Q40080': PlaceCategory.naturalLandscape, // beach
    'Q43501': PlaceCategory.naturalLandscape, // zoo
    'Q130003': PlaceCategory.naturalLandscape, // aquarium
    // --- modern / urban ---
    'Q570116': PlaceCategory.modernUrban, // tourist attraction
    'Q12280': PlaceCategory.modernUrban, // bridge
    'Q11303': PlaceCategory.modernUrban, // skyscraper
    'Q44782': PlaceCategory.modernUrban, // urban park
  };

  /// Returns the [PlaceCategory] of the first whitelisted P31 class id,
  /// or null if none match.
  static PlaceCategory? categorize(List<String> p31ClassIds) {
    for (final id in p31ClassIds) {
      final category = _whitelist[id];
      if (category != null) return category;
    }
    return null;
  }
}
