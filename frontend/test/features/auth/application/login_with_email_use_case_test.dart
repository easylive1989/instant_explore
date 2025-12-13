import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/auth/application/login_with_email_use_case.dart';
import 'package:context_app/features/auth/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late LoginWithEmailUseCase useCase;
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    useCase = LoginWithEmailUseCase(mockAuthService);
  });

  test('execute calls signInWithEmail', () async {
    const email = 'test@example.com';
    const password = 'password';
    final mockResponse = AuthResponse(session: null, user: null);

    when(
      () => mockAuthService.signInWithEmail(email: email, password: password),
    ).thenAnswer((_) async => mockResponse);

    final result = await useCase.execute(email: email, password: password);

    expect(result, mockResponse);
    verify(
      () => mockAuthService.signInWithEmail(email: email, password: password),
    ).called(1);
  });
}
