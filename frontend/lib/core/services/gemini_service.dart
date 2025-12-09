import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:travel_diary/core/config/api_config.dart';
import 'package:travel_diary/features/places/models/place.dart';

class GeminiService {
  final ApiConfig _apiConfig;

  GeminiService(this._apiConfig);

  Future<String> generateDiaryDescription(Place place) async {
    if (!_apiConfig.isGeminiConfigured) {
      throw Exception('Gemini API key is not configured.');
    }

    final model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiConfig.geminiApiKey,
    );

    final prompt =
        '''
As a travel blogger, please write a vivid and attractive introduction for the following location, suitable for a diary entry. Focus on its key features and what makes it special. Please write in traditional Chinese, within 150 characters. Location details: 
Name: ${place.name}
Address: ${place.formattedAddress}
Types: ${place.types.join(', ')}''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Could not generate description.';
    } catch (e) {
      debugPrint('Error generating content: $e');
      rethrow;
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final apiConfig = ref.watch(apiConfigProvider);
  return GeminiService(apiConfig);
});
