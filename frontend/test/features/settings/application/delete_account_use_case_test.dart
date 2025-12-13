import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/auth/services/auth_service.dart';
import 'package:context_app/features/settings/application/delete_account_use_case.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late DeleteAccountUseCase useCase;

  setUp(() {
    mockAuthService = MockAuthService();
    useCase = DeleteAccountUseCase(mockAuthService);
  });

  test('execute should call deleteAccount on AuthService', () async {
    // Arrange
    when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {});

    // Act
    await useCase.execute();

    // Assert
    verify(() => mockAuthService.deleteAccount()).called(1);
  });
}
