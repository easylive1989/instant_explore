import 'package:context_app/features/explore/domain/models/place.dart';
import 'package:context_app/features/journey/presentation/screens/save_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('SaveSuccessScreen', () {
    testWidgets(
      'given a saved place, when the screen is shown, '
      'then it displays the place name and success actions',
      (tester) async {
        final place = buildPlace(name: 'Kiyomizu-dera');

        await _givenSaveSuccessScreen(tester, place: place);

        _thenSavedPlaceInfoIsVisible(place);
        _thenPrimaryActionsAreVisible();
      },
    );

    testWidgets(
      'given a view-passport handler, when the user taps view button, '
      'then the handler is invoked',
      (tester) async {
        var viewCount = 0;
        final place = buildPlace();

        await _givenSaveSuccessScreen(
          tester,
          place: place,
          onViewPassport: () => viewCount += 1,
        );
        await _whenUserTapsViewPassport(tester);

        expect(viewCount, equals(1));
      },
    );

    testWidgets(
      'given a continue-tour handler, when the user taps continue, '
      'then the handler is invoked',
      (tester) async {
        var continueCount = 0;
        final place = buildPlace();

        await _givenSaveSuccessScreen(
          tester,
          place: place,
          onContinueTour: () => continueCount += 1,
        );
        await _whenUserTapsContinueTour(tester);

        expect(continueCount, equals(1));
      },
    );

    testWidgets(
      'given no continue handler is provided, when the user taps continue, '
      'then the router pops the screen',
      (tester) async {
        final place = buildPlace();
        final routes = [
          GoRoute(path: '/', builder: (_, __) => const _HostLauncher()),
          GoRoute(
            path: '/success',
            builder: (context, state) => SaveSuccessScreen(
              place: state.extra! as Place,
            ),
          ),
        ];

        await pumpRouterApp(
          tester,
          routes: routes,
          initialLocation: '/',
        );
        await _whenHostLaunchesSuccessScreen(tester, place);
        await _whenUserTapsContinueTour(tester);

        expect(find.byType(SaveSuccessScreen), findsNothing);
        expect(find.byType(_HostLauncher), findsOneWidget);
      },
    );
  });
}

Future<void> _givenSaveSuccessScreen(
  WidgetTester tester, {
  required Place place,
  VoidCallback? onViewPassport,
  VoidCallback? onContinueTour,
}) async {
  await pumpScreen(
    tester,
    child: SaveSuccessScreen(
      place: place,
      onViewPassport: onViewPassport,
      onContinueTour: onContinueTour,
    ),
  );
}

void _thenSavedPlaceInfoIsVisible(Place place) {
  expect(find.text(place.name), findsOneWidget);
  expect(find.text(place.address), findsOneWidget);
}

void _thenPrimaryActionsAreVisible() {
  expect(find.text('passport.view_button'), findsOneWidget);
  expect(find.text('passport.continue_tour'), findsOneWidget);
}

Future<void> _whenUserTapsViewPassport(WidgetTester tester) async {
  await tester.tap(find.text('passport.view_button'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _whenUserTapsContinueTour(WidgetTester tester) async {
  await tester.tap(find.text('passport.continue_tour'));
  await tester.pumpAndSettle();
}

Future<void> _whenHostLaunchesSuccessScreen(
  WidgetTester tester,
  Place place,
) async {
  final BuildContext context = tester.element(find.byType(_HostLauncher));
  GoRouter.of(context).push('/success', extra: place);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _HostLauncher extends StatelessWidget {
  const _HostLauncher();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('host')));
}
