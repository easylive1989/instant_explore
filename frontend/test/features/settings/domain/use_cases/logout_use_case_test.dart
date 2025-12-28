import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:context_app/features/subscription/data/purchase_repository.dart';
import 'package:context_app/features/settings/domain/use_cases/logout_use_case.dart';

class MockAuthService extends Mock implements AuthService {}

class MockPurchaseRepository extends Mock implements PurchaseRepository {}

void main() {
  late MockAuthService mockAuthService;
  late MockPurchaseRepository mockPurchaseRepository;
  late LogoutUseCase useCase;

  setUp(() {
    mockAuthService = MockAuthService();
    mockPurchaseRepository = MockPurchaseRepository();
    useCase = LogoutUseCase(mockAuthService, mockPurchaseRepository);
  });

  test(
    'execute should call logout on PurchaseRepository and signOut on AuthService',
    () async {
      // Arrange
      when(() => mockPurchaseRepository.logout()).thenAnswer((_) async {});
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      // Act
      await useCase.execute();

      // Assert
      verify(() => mockPurchaseRepository.logout()).called(1);
      verify(() => mockAuthService.signOut()).called(1);
    },
  );
}
