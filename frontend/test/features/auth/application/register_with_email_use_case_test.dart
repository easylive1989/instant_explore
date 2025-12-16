import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/auth/domain/use_cases/register_with_email_use_case.dart';
import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late RegisterWithEmailUseCase useCase;
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    useCase = RegisterWithEmailUseCase(mockAuthService);
  });

  test('execute calls signUpWithEmail', () async {
    const email = 'test@example.com';
    const password = 'password';
    final mockResponse = AuthResponse(session: null, user: null);

    when(
      () => mockAuthService.signUpWithEmail(email: email, password: password),
    ).thenAnswer((_) async => mockResponse);

    final result = await useCase.execute(email: email, password: password);

    expect(result, mockResponse);
    verify(
      () => mockAuthService.signUpWithEmail(email: email, password: password),
    ).called(1);
  });
}
