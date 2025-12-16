import 'package:flutter_test/flutter_test.dart';
import 'package:context_app/features/explore/models/place.dart';
import 'package:context_app/features/explore/models/place_category.dart';
import 'package:context_app/features/narration/models/narration.dart';
import 'package:context_app/features/narration/models/narration_content.dart';
import 'package:context_app/features/narration/models/narration_aspect.dart';
import 'package:context_app/features/narration/models/playback_state.dart';

void main() {
  group('Narration Aggregate', () {
    final place = Place(
      id: 'place-1',
      name: 'Test Place',
      formattedAddress: 'Test Address',
      location: PlaceLocation(latitude: 0, longitude: 0),
      types: [],
      photos: [],
      category: PlaceCategory.historicalCultural,
    );

    test('create factory returns Narration in loading state', () {
      final narration = Narration.create(
        id: 'narration-1',
        place: place,
        aspect: NarrationAspect.historicalBackground,
      );

      expect(narration.state, PlaybackState.loading);
      expect(narration.content, isNull);
    });

    test('ready updates state and content', () {
      final narration = Narration.create(
        id: 'narration-1',
        place: place,
        aspect: NarrationAspect.historicalBackground,
      );
      final content = NarrationContent.fromText('Test content');

      final readyNarration = narration.ready(content);

      expect(readyNarration.state, PlaybackState.ready);
      expect(readyNarration.content, content);
      expect(readyNarration.duration, content.estimatedDuration);
    });

    test('play transitions from ready to playing', () {
      var narration = Narration.create(
        id: 'narration-1',
        place: place,
        aspect: NarrationAspect.historicalBackground,
      );
      final content = NarrationContent.fromText('Test content');
      narration = narration.ready(content);

      final playingNarration = narration.play();

      expect(playingNarration.state, PlaybackState.playing);
    });

    test('pause transitions from playing to paused', () {
      final narration = Narration(
        id: '1',
        place: place,
        aspect: NarrationAspect.historicalBackground,
        state: PlaybackState.playing,
        content: NarrationContent.fromText('test'),
      );

      final pausedNarration = narration.pause();

      expect(pausedNarration.state, PlaybackState.paused);
    });

    test('seekForward updates position correctly', () {
      final narration = Narration(
        id: '1',
        place: place,
        aspect: NarrationAspect.historicalBackground,
        state: PlaybackState.playing,
        content: NarrationContent.fromText('test'),
        duration: 100,
        currentPosition: 10,
      );

      final forwarded = narration.seekForward(15);
      expect(forwarded.currentPosition, 25);

      final clamped = narration.seekForward(200);
      expect(clamped.currentPosition, 100);
    });

    test('seekBackward updates position correctly', () {
      final narration = Narration(
        id: '1',
        place: place,
        aspect: NarrationAspect.historicalBackground,
        state: PlaybackState.playing,
        content: NarrationContent.fromText('test'),
        duration: 100,
        currentPosition: 50,
      );

      final backward = narration.seekBackward(15);
      expect(backward.currentPosition, 35);

      final clamped = narration.seekBackward(200);
      expect(clamped.currentPosition, 0);
    });

    test('updateProgress updates position and completes if needed', () {
      final narration = Narration(
        id: '1',
        place: place,
        aspect: NarrationAspect.historicalBackground,
        state: PlaybackState.playing,
        content: NarrationContent.fromText('test'),
        duration: 100,
      );

      final updated = narration.updateProgress(50);
      expect(updated.currentPosition, 50);
      expect(updated.state, PlaybackState.playing);

      final completed = narration.updateProgress(100);
      expect(completed.currentPosition, 100);
      expect(completed.state, PlaybackState.completed);
    });
  });
}
