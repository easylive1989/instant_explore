import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/explore/domain/models/place_category.dart';
import 'package:context_app/features/explore/domain/models/place_location.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';

/// Builds a hard-coded Fushimi Inari narration so first-time users can
/// always experience the audio-guide flow, even if the backend is down.
///
/// The text lives in the repo (not in i18n JSON) because it is intentionally
/// curated sample copy, not UI chrome — and because keeping it here avoids
/// bloating the translation file with long-form prose.
class DemoNarrationFactory {
  const DemoNarrationFactory();

  static const String _demoPlaceId = 'onboarding-demo-fushimi-inari';

  /// The sample place used to drive the narration player.
  Place buildPlace() {
    return const Place(
      id: _demoPlaceId,
      name: '伏見稻荷大社',
      formattedAddress: '68 Fukakusa Yabunouchicho, Fushimi Ward, Kyoto',
      location: PlaceLocation(latitude: 34.9671, longitude: 135.7727),
      types: ['tourist_attraction', 'place_of_worship'],
      photos: [],
      category: PlaceCategory.historicalCultural,
    );
  }

  /// Returns a non-empty narration for the given language.
  ///
  /// Falls back to Traditional Chinese copy if the requested language has
  /// no hand-crafted sample yet.
  NarrationContent buildContent(Language language) {
    final text = _textFor(language);
    return NarrationContent.create(text, language: language);
  }

  String _textFor(Language language) {
    if (language.code.startsWith('en')) {
      return _englishText;
    }
    return _traditionalChineseText;
  }

  /// True when the given place id was produced by this factory.
  static bool isDemoPlace(String placeId) => placeId == _demoPlaceId;

  static const String _traditionalChineseText =
      '歡迎來到伏見稻荷大社，這裡是日本全國約三萬座稻荷神社的總本社，'
      '自西元 711 年創建以來，便是守護稻米豐收與生意興隆的信仰中心。'
      '穿過莊嚴的樓門，你會看見通往稻荷山的千本鳥居，'
      '每一座朱紅色的鳥居，都是來自全日本企業與個人的奉納，'
      '象徵對神明許下的感謝與祈願。'
      '沿著山徑緩步而上，狐狸石像靜靜守望著參拜者，'
      '牠們被視為稻荷大神的使者，口中常叼著稻穗或鑰匙，'
      '寓意掌管穀倉與財富的神聖力量。'
      '若時間允許，不妨一路走到山頂，'
      '你會聽見風穿過鳥居之間的聲響，像千年來未曾間斷的低語，'
      '提醒旅人：信仰並非遙遠的故事，而是當下的風景。';

  static const String _englishText =
      'Welcome to Fushimi Inari Taisha, the head shrine of some thirty '
      'thousand Inari shrines across Japan. Founded in 711 CE, it has '
      'long been the spiritual heart of prayers for bountiful rice '
      'harvests and thriving businesses. '
      'Passing through the grand romon gate, you will see the famous '
      'Senbon Torii — thousands of vermilion gates winding up Mount '
      'Inari. Each one was donated by a company or individual, carrying '
      'a personal thank-you to the kami. '
      'As you climb, stone foxes quietly watch over pilgrims. Believed '
      'to be messengers of Inari Okami, they often carry a sheaf of '
      'rice or a key in their mouths, symbols of the divine power over '
      'granaries and prosperity. '
      'If time allows, walk all the way to the summit. Listen to the '
      'wind slipping between the gates — a thousand-year whisper '
      'reminding travellers that faith, here, is not a distant story '
      'but the landscape itself.';
}
