import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/auth/application/login_with_google_use_case.dart';
import 'package:context_app/features/auth/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late LoginWithGoogleUseCase useCase;
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    useCase = LoginWithGoogleUseCase(mockAuthService);
  });

  test(
    'execute calls signInWithGoogle and returns AuthResponse on success',
    () async {
      final mockResponse = AuthResponse(session: null, user: null);
      when(
        () => mockAuthService.signInWithGoogle(),
      ).thenAnswer((_) async => mockResponse);

      final result = await useCase.execute();

      expect(result, mockResponse);
      verify(() => mockAuthService.signInWithGoogle()).called(1);
    },
  );

  test(
    'execute calls signInWithGoogle and returns null on cancellation',
    () async {
      when(
        () => mockAuthService.signInWithGoogle(),
      ).thenAnswer((_) async => null);

      final result = await useCase.execute();

      expect(result, isNull);
      verify(() => mockAuthService.signInWithGoogle()).called(1);
    },
  );

  test('execute rethrows exception on failure', () async {
    final exception = Exception('Google sign in failed');
    when(() => mockAuthService.signInWithGoogle()).thenThrow(exception);

    expect(() => useCase.execute(), throwsA(exception));
    verify(() => mockAuthService.signInWithGoogle()).called(1);
  });
}
