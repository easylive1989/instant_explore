import 'package:context_app/features/places/models/place.dart';
import 'package:context_app/features/player/models/narration.dart';
import 'package:context_app/features/player/models/narration_content.dart';
import 'package:context_app/features/player/models/narration_style.dart';
import 'package:context_app/features/player/models/playback_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Narration', () {
    // Helper function to create a test place
    Place createTestPlace() {
      return Place(
        id: 'test-place-id',
        name: 'Test Place',
        formattedAddress: 'Test Address',
        location: PlaceLocation(latitude: 25.0330, longitude: 121.5654),
        types: const ['tourist_attraction'],
        photos: const [],
      );
    }

    // Helper function to create test content
    NarrationContent createTestContent() {
      return NarrationContent.fromText('第一句。第二句。第三句。');
    }

    group('create', () {
      test('should create narration in loading state', () {
        final place = createTestPlace();
        final narration = Narration.create(
          id: 'test-id',
          place: place,
          style: NarrationStyle.brief,
        );

        expect(narration.id, 'test-id');
        expect(narration.place, place);
        expect(narration.style, NarrationStyle.brief);
        expect(narration.state, PlaybackState.loading);
        expect(narration.currentPosition, 0);
        expect(narration.currentCharPosition, 0);
        expect(narration.content, isNull);
      });
    });

    group('ready', () {
      test('should transition to ready state with content', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        );

        final content = createTestContent();
        final readyNarration = narration.ready(content);

        expect(readyNarration.state, PlaybackState.ready);
        expect(readyNarration.content, content);
        expect(readyNarration.duration, content.estimatedDuration);
      });
    });

    group('play', () {
      test('should transition from ready to playing', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        ).ready(createTestContent());

        final playingNarration = narration.play();

        expect(playingNarration.state, PlaybackState.playing);
      });

      test('should reset positions when replaying from completed state', () {
        final content = createTestContent();
        // 先更新字符位置，再更新進度到 duration（會自動轉為 completed）
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        )
            .ready(content)
            .play()
            .updateCharPosition(50)
            .updateProgress(content.estimatedDuration); // 會自動轉為 completed

        expect(narration.state, PlaybackState.completed);
        expect(narration.currentPosition, content.estimatedDuration);
        expect(narration.currentCharPosition, 50);

        final replayedNarration = narration.play();

        expect(replayedNarration.state, PlaybackState.playing);
        expect(replayedNarration.currentPosition, 0);
        expect(replayedNarration.currentCharPosition, 0);
      });

      test('should preserve positions when resuming from paused state', () {
        final content = createTestContent();
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        )
            .ready(content)
            .play()
            .updateProgress(0) // 使用小於 duration 的值
            .updateCharPosition(8) // 第三句開頭
            .pause();

        expect(narration.currentPosition, 0);
        expect(narration.currentCharPosition, 8);

        final resumedNarration = narration.play();

        expect(resumedNarration.state, PlaybackState.playing);
        expect(resumedNarration.currentPosition, 0);
        expect(resumedNarration.currentCharPosition, 8);
      });
    });

    group('updateCharPosition', () {
      test('should update char position when playing', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        ).ready(createTestContent()).play();

        final updated = narration.updateCharPosition(10);

        expect(updated.currentCharPosition, 10);
        expect(updated.state, PlaybackState.playing);
      });

      test('should not update char position when not playing', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        ).ready(createTestContent());

        expect(narration.state, PlaybackState.ready);

        final updated = narration.updateCharPosition(10);

        expect(updated.currentCharPosition, 0);
        expect(updated.state, PlaybackState.ready);
      });

      test('should not update char position when paused', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        ).ready(createTestContent()).play().pause();

        expect(narration.state, PlaybackState.paused);

        final updated = narration.updateCharPosition(10);

        expect(updated.currentCharPosition, 0);
      });

      test('should not update char position when completed', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        )
            .ready(createTestContent())
            .copyWith(state: PlaybackState.completed);

        final updated = narration.updateCharPosition(10);

        expect(updated.currentCharPosition, 0);
      });
    });

    group('getCurrentSegmentIndex', () {
      test('should return null when content is null', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        );

        expect(narration.getCurrentSegmentIndex(), isNull);
      });

      test('should return null when in loading state', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        );

        expect(narration.state, PlaybackState.loading);
        expect(narration.getCurrentSegmentIndex(), isNull);
      });

      test('should return correct segment index based on char position', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        ).ready(createTestContent()).play();

        // 第一句："第一句。" (字符 0-3)
        final segment0 = narration.updateCharPosition(0);
        expect(segment0.getCurrentSegmentIndex(), 0);

        final segment0Mid = narration.updateCharPosition(2);
        expect(segment0Mid.getCurrentSegmentIndex(), 0);

        // 第二句："第二句。" (字符 4-7)
        final segment1 = narration.updateCharPosition(4);
        expect(segment1.getCurrentSegmentIndex(), 1);

        final segment1Mid = narration.updateCharPosition(6);
        expect(segment1Mid.getCurrentSegmentIndex(), 1);

        // 第三句："第三句。" (字符 8-11)
        final segment2 = narration.updateCharPosition(8);
        expect(segment2.getCurrentSegmentIndex(), 2);

        final segment2End = narration.updateCharPosition(11);
        expect(segment2End.getCurrentSegmentIndex(), 2);
      });
    });

    group('copyWith', () {
      test('should copy with updated currentCharPosition', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        ).ready(createTestContent());

        final updated = narration.copyWith(currentCharPosition: 42);

        expect(updated.currentCharPosition, 42);
        expect(updated.id, narration.id);
        expect(updated.place, narration.place);
        expect(updated.style, narration.style);
      });

      test('should preserve currentCharPosition when not specified', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        )
            .ready(createTestContent())
            .play()
            .updateCharPosition(25);

        final updated = narration.copyWith(currentPosition: 50);

        expect(updated.currentCharPosition, 25);
        expect(updated.currentPosition, 50);
      });
    });

    group('equality', () {
      test('should be equal when all fields match including currentCharPosition',
          () {
        final place = createTestPlace();
        final content = createTestContent();

        final narration1 = Narration.create(
          id: 'test-id',
          place: place,
          style: NarrationStyle.brief,
        )
            .ready(content)
            .play()
            .updateCharPosition(10);

        final narration2 = Narration.create(
          id: 'test-id',
          place: place,
          style: NarrationStyle.brief,
        )
            .ready(content)
            .play()
            .updateCharPosition(10);

        expect(narration1, equals(narration2));
        expect(narration1.hashCode, equals(narration2.hashCode));
      });

      test('should not be equal when currentCharPosition differs', () {
        final place = createTestPlace();
        final content = createTestContent();

        final narration1 = Narration.create(
          id: 'test-id',
          place: place,
          style: NarrationStyle.brief,
        )
            .ready(content)
            .play()
            .updateCharPosition(10);

        final narration2 = Narration.create(
          id: 'test-id',
          place: place,
          style: NarrationStyle.brief,
        )
            .ready(content)
            .play()
            .updateCharPosition(20);

        expect(narration1, isNot(equals(narration2)));
      });
    });

    group('business rules', () {
      test('should only update char position in playing state', () {
        final narration = Narration.create(
          id: 'test-id',
          place: createTestPlace(),
          style: NarrationStyle.brief,
        ).ready(createTestContent());

        // Test all non-playing states
        expect(narration.state, PlaybackState.ready);
        expect(narration.updateCharPosition(10).currentCharPosition, 0);

        final paused =
            narration.play().updateCharPosition(5).pause();
        expect(paused.state, PlaybackState.paused);
        expect(paused.updateCharPosition(10).currentCharPosition, 5);

        final completed = narration.copyWith(state: PlaybackState.completed);
        expect(completed.updateCharPosition(10).currentCharPosition, 0);

        final error = narration.error('test error');
        expect(error.state, PlaybackState.error);
        expect(error.updateCharPosition(10).currentCharPosition, 0);
      });
    });
  });
}
