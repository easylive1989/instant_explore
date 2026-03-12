import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:context_app/features/auth/data/auth_service.dart';
import 'package:context_app/features/subscription/domain/services/subscription_service.dart';
import 'package:context_app/features/settings/domain/use_cases/logout_use_case.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late MockAuthService mockAuthService;
  late MockSubscriptionService mockSubscriptionService;
  late LogoutUseCase useCase;

  setUp(() {
    mockAuthService = MockAuthService();
    mockSubscriptionService = MockSubscriptionService();
    useCase = LogoutUseCase(mockAuthService, mockSubscriptionService);
  });

  test('execute should call RevenueCat logOut then signOut', () async {
    when(() => mockAuthService.signOut()).thenAnswer((_) async {});
    when(() => mockSubscriptionService.logOut()).thenAnswer((_) async {});

    await useCase.execute();

    verify(() => mockSubscriptionService.logOut()).called(1);
    verify(() => mockAuthService.signOut()).called(1);
  });
}
