import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/auth/services/auth_service.dart';
import 'package:context_app/features/settings/application/logout_use_case.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late LogoutUseCase useCase;

  setUp(() {
    mockAuthService = MockAuthService();
    useCase = LogoutUseCase(mockAuthService);
  });

  test('execute should call signOut on AuthService', () async {
    // Arrange
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});

    // Act
    await useCase.execute();

    // Assert
    verify(() => mockAuthService.signOut()).called(1);
  });
}
