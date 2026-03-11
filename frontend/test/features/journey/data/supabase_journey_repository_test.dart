import 'dart:async';
import 'dart:io';

import 'package:context_app/core/errors/app_error.dart';
import 'package:context_app/features/journey/data/supabase_journey_repository.dart';
import 'package:context_app/features/journey/domain/errors/journey_error.dart';
import 'package:context_app/features/journey/domain/models/journey_entry.dart';
import 'package:context_app/features/journey/domain/models/saved_place.dart';
import 'package:context_app/features/narration/domain/models/narration_aspect.dart';
import 'package:context_app/features/narration/domain/models/narration_content.dart';
import 'package:context_app/features/settings/domain/models/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase 使用 builder pattern（from().select().eq().order()），
// 模擬整個鏈很複雜。這裡選擇讓 from() 本身拋出例外，
// 足以驗證 try-catch 邏輯是否正確攔截特定錯誤型別。
class MockSupabaseClient extends Mock implements SupabaseClient {}

JourneyEntry _buildEntry() {
  return JourneyEntry(
    id: 'entry-1',
    userId: 'user-1',
    place: const SavedPlace(id: 'p1', name: 'Test Place', address: 'Addr'),
    narrationContent: NarrationContent.create(
      '這是一段測試導覽文本，描述測試地點的歷史背景。',
      language: Language.traditionalChinese,
    ),
    narrationAspect: NarrationAspect.historicalBackground,
    createdAt: DateTime(2024, 1, 1),
    language: Language.traditionalChinese,
  );
}

void main() {
  late MockSupabaseClient mockClient;
  late SupabaseJourneyRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = SupabaseJourneyRepository(mockClient);
  });

  group('getJourneyEntries', () {
    test(
      '拋出 AppError(networkError) 當 SocketException 發生時',
      () async {
        when(
          () => mockClient.from('passport_entries'),
        ).thenThrow(const SocketException('Network unreachable'));

        await expectLater(
          () => repository.getJourneyEntries('user-1'),
          throwsA(
            isA<AppError>()
                .having((e) => e.type, 'type', JourneyError.networkError)
                .having(
                  (e) => e.originalException,
                  'originalException',
                  isA<SocketException>(),
                ),
          ),
        );
      },
    );

    test(
      '拋出 AppError(networkError) 當 TimeoutException 發生時',
      () async {
        when(
          () => mockClient.from('passport_entries'),
        ).thenThrow(TimeoutException('Connection timed out'));

        await expectLater(
          () => repository.getJourneyEntries('user-1'),
          throwsA(
            isA<AppError>()
                .having((e) => e.type, 'type', JourneyError.networkError)
                .having(
                  (e) => e.originalException,
                  'originalException',
                  isA<TimeoutException>(),
                ),
          ),
        );
      },
    );
  });

  group('addJourneyEntry', () {
    test(
      '拋出 AppError(networkError) 當 SocketException 發生時',
      () async {
        when(
          () => mockClient.from('passport_entries'),
        ).thenThrow(const SocketException('Network unreachable'));

        await expectLater(
          () => repository.addJourneyEntry(_buildEntry()),
          throwsA(
            isA<AppError>()
                .having((e) => e.type, 'type', JourneyError.networkError)
                .having(
                  (e) => e.originalException,
                  'originalException',
                  isA<SocketException>(),
                ),
          ),
        );
      },
    );

    test(
      '拋出 AppError(networkError) 當 TimeoutException 發生時',
      () async {
        when(
          () => mockClient.from('passport_entries'),
        ).thenThrow(TimeoutException('Connection timed out'));

        await expectLater(
          () => repository.addJourneyEntry(_buildEntry()),
          throwsA(
            isA<AppError>()
                .having((e) => e.type, 'type', JourneyError.networkError)
                .having(
                  (e) => e.originalException,
                  'originalException',
                  isA<TimeoutException>(),
                ),
          ),
        );
      },
    );
  });

  group('deleteJourneyEntry', () {
    test(
      '拋出 AppError(networkError) 當 SocketException 發生時',
      () async {
        when(
          () => mockClient.from('passport_entries'),
        ).thenThrow(const SocketException('Network unreachable'));

        await expectLater(
          () => repository.deleteJourneyEntry('entry-1'),
          throwsA(
            isA<AppError>()
                .having((e) => e.type, 'type', JourneyError.networkError)
                .having(
                  (e) => e.originalException,
                  'originalException',
                  isA<SocketException>(),
                ),
          ),
        );
      },
    );

    test(
      '拋出 AppError(networkError) 當 TimeoutException 發生時',
      () async {
        when(
          () => mockClient.from('passport_entries'),
        ).thenThrow(TimeoutException('Connection timed out'));

        await expectLater(
          () => repository.deleteJourneyEntry('entry-1'),
          throwsA(
            isA<AppError>()
                .having((e) => e.type, 'type', JourneyError.networkError)
                .having(
                  (e) => e.originalException,
                  'originalException',
                  isA<TimeoutException>(),
                ),
          ),
        );
      },
    );
  });
}
